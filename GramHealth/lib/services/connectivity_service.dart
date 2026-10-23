import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

enum NetworkStatus { online, weak, offline }

class ConnectivityService {
  static final ConnectivityService instance = ConnectivityService._init();
  ConnectivityService._init();

  final Connectivity _connectivity = Connectivity();
  final _statusController = StreamController<NetworkStatus>.broadcast();

  NetworkStatus _currentStatus = NetworkStatus.online;
  Timer? _pingTimer;

  Stream<NetworkStatus> get statusStream => _statusController.stream;
  NetworkStatus get currentStatus => _currentStatus;
  bool get isOnline => _currentStatus != NetworkStatus.offline;

  /// Returns true if connected via Wi-Fi or Ethernet (unmetered / broadband).
  Future<bool> isWifiOrEthernet() async {
    try {
      final results = await _connectivity.checkConnectivity();
      return results.contains(ConnectivityResult.wifi) ||
          results.contains(ConnectivityResult.ethernet);
    } catch (_) {
      return false;
    }
  }

  /// Returns true if connected via mobile cellular data.
  Future<bool> isMobileData() async {
    try {
      final results = await _connectivity.checkConnectivity();
      return results.contains(ConnectivityResult.mobile);
    } catch (_) {
      return false;
    }
  }

  /// Starts listening to network interface changes and pings.
  void initialize() {
    _connectivity.onConnectivityChanged.listen((result) {
      _assessConnectivity(
        result.isEmpty ? ConnectivityResult.none : result.first,
      );
    });
    // Fallback constant ping every 10 seconds to detect "Weak" networks
    // and truly verify internet reachability (prevent false positive Wi-Fi limits)
    _pingTimer = Timer.periodic(const Duration(seconds: 10), (_) => _pingServer());
    
    // Initial check
    _connectivity.checkConnectivity().then((res) => _assessConnectivity(
          res.isEmpty ? ConnectivityResult.none : res.first,
        ));
  }

  /// Performs an immediate interface and reachability check before a
  /// latency-sensitive action such as joining a consultation.
  Future<NetworkStatus> refresh() async {
    // connectivity_plus can briefly report `none` while Android is changing
    // network state (for example after rotation or a permission prompt). The
    // backend reachability check is the source of truth for an API/Jitsi
    // action, so always probe the configured backend here instead of relying
    // on a possibly stale interface result.
    await _pingServer();
    return _currentStatus;
  }

  void dispose() {
    _pingTimer?.cancel();
    _statusController.close();
  }

  Future<void> _assessConnectivity(ConnectivityResult interfaceStatus) async {
    if (interfaceStatus == ConnectivityResult.none) {
      _updateStatus(NetworkStatus.offline);
      return;
    }
    await _pingServer();
  }

  Future<void> _pingServer() async {
    try {
      final startTime = DateTime.now();
      final response = await http.get(Uri.parse('${AppConfig.baseUrl}/api/health')).timeout(
        const Duration(seconds: 5),
      );

      if (response.statusCode == 200) {
        final latency = DateTime.now().difference(startTime).inMilliseconds;
        if (latency > 1500) {
          _updateStatus(NetworkStatus.weak);
        } else {
          _updateStatus(NetworkStatus.online);
        }
      } else {
        _updateStatus(NetworkStatus.offline);
      }
    } on TimeoutException {
      _updateStatus(NetworkStatus.weak);
    } catch (e) {
      // An unreachable backend is not the same as a device with no network.
      // Keep the call path available as a weak connection and let API calls
      // decide whether they need to be queued for later synchronization.
      _updateStatus(NetworkStatus.weak);
    }
  }

  void _updateStatus(NetworkStatus newStatus) {
    if (_currentStatus != newStatus) {
      _currentStatus = newStatus;
      _statusController.add(_currentStatus);
      print('Network Status Changed: ${_currentStatus.name.toUpperCase()}');
    }
  }
}
