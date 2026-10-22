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
  int _consecutiveFailures = 0;

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
      _assessConnectivity(result.first);
    });
    // Fallback constant ping every 10 seconds to detect "Weak" networks
    // and truly verify internet reachability (prevent false positive Wi-Fi limits)
    _pingTimer = Timer.periodic(const Duration(seconds: 10), (_) => _pingServer());
    
    // Initial check
    _connectivity.checkConnectivity().then((res) => _assessConnectivity(res.first));
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
    // If the interface says we're offline, don't ping.
    final interfaces = await _connectivity.checkConnectivity();
    if (interfaces.contains(ConnectivityResult.none)) {
      _updateStatus(NetworkStatus.offline);
      _consecutiveFailures = 0;
      return;
    }

    try {
      final startTime = DateTime.now();
      final response = await http.get(Uri.parse('${AppConfig.baseUrl}/api/health')).timeout(
        const Duration(seconds: 30),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final latency = DateTime.now().difference(startTime).inMilliseconds;
        if (latency > 5000) {
          _updateStatus(NetworkStatus.weak);
        } else {
          _updateStatus(NetworkStatus.online);
        }
        _consecutiveFailures = 0;
      } else {
        // Don't immediately mark offline - could be temporary
        if (_currentStatus != NetworkStatus.offline) {
          _updateStatus(NetworkStatus.weak);
        }
        _consecutiveFailures++;
      }
    } on TimeoutException {
      // Don't immediately mark offline on timeout - could be cold start
      if (_currentStatus != NetworkStatus.offline) {
        _updateStatus(NetworkStatus.weak);
      }
      _consecutiveFailures++;
    } catch (e) {
      // Only mark offline after confirming it's not a transient error
      _consecutiveFailures++;
      if (_consecutiveFailures >= 3) {
        _updateStatus(NetworkStatus.offline);
      } else {
        _updateStatus(NetworkStatus.weak);
      }
    }
  }

  void _updateStatus(NetworkStatus newStatus) {
    if (_currentStatus != newStatus) {
      _currentStatus = newStatus;
      _statusController.add(_currentStatus);
      print('Network Status Changed: \${_currentStatus.name.toUpperCase()}');
    }
  }
}
