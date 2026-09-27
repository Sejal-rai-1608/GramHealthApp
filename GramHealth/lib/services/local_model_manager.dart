import 'dart:async';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/offline_ai_config.dart';
import '../models/local_model_status.dart';
import '../models/offline_model_metadata.dart';
import 'connectivity_service.dart';
import 'local_llm_service.dart';
import 'local_model_download_service.dart';

/// Manages the full lifecycle of the on-device LiteRT-LM model.
///
/// State machine:
///   unavailable → checking → pending → downloading → verifying → ready
///                                                                 ↓
///                                                              loading
///                                                                 ↓
///                                                              loaded  ←→ generating
///   Any state → error / pending (recoverable)
class LocalModelManager {
  LocalModelManager({
    required this.downloadService,
    required this.llmService,
  });

  final LocalModelDownloadService downloadService;
  final LiteRtLmService llmService;

  // ---------------------------------------------------------------------------
  // State
  // ---------------------------------------------------------------------------

  LocalModelStatus _status = LocalModelStatus.unavailable;
  LocalModelStatus get status => _status;

  String? _modelPath;
  String? get modelPath => _modelPath;

  String? _lastError;
  String? get lastError => _lastError;

  String? _statusReason;
  String? get statusReason => _statusReason;

  double _downloadProgress = 0.0;
  double get downloadProgress => _downloadProgress;

  int _downloadedBytes = 0;
  int get downloadedBytes => _downloadedBytes;

  int _expectedBytes = OfflineAiConfig.modelExpectedSizeBytes;
  int get expectedBytes => _expectedBytes;

  OfflineModelMetadata? _metadata;
  OfflineModelMetadata? get metadata => _metadata;

  LocalModelCompatibility? _compatibility;
  LocalModelCompatibility? get compatibility => _compatibility;

  final _statusController =
      StreamController<LocalModelStatus>.broadcast();
  Stream<LocalModelStatus> get statusStream => _statusController.stream;

  StreamSubscription<NetworkStatus>? _connectivitySub;
  Timer? _retryTimer;
  int _retryCount = 0;

  // ---------------------------------------------------------------------------
  // Initialisation (called after login / on Home screen)
  // ---------------------------------------------------------------------------

  /// Checks whether the model exists and verifies its integrity.
  /// If missing and eligible, automatically starts the background download.
  Future<void> checkModelOnStartup({bool autoDownload = true}) async {
    _setStatus(LocalModelStatus.checking);
    _statusReason = 'Checking offline AI status...';

    try {
      // 1. Device compatibility check (ABI, RAM, Storage)
      _compatibility = await _checkCompatibility();
      if (!(_compatibility?.canDownload ?? false)) {
        _setStatus(LocalModelStatus.unavailable);
        _setError('Device not eligible for offline model: ${_compatibility?.reason}');
        _log('Device ineligible for model download: ${_compatibility?.reason}. Preserving lexicon fallback.');
        return;
      }

      // 2. Load persisted metadata & resume state
      await _loadPersistedMetadata();
      final path = await _expectedModelPath();
      final file = File(path);

      // Check current partial download bytes if .tmp file exists
      _downloadedBytes = await downloadService.getDownloadedBytes(path);
      if (_downloadedBytes > 0 && _downloadedBytes < OfflineAiConfig.modelExpectedSizeBytes) {
        _downloadProgress = _downloadedBytes / OfflineAiConfig.modelExpectedSizeBytes;
      }

      // 3. If final model file already exists, verify it
      if (await file.exists()) {
        if (_metadata != null &&
            _metadata!.version == OfflineAiConfig.modelVersion &&
            _metadata!.verified) {
          _modelPath = path;
          _downloadProgress = 1.0;
          _downloadedBytes = OfflineAiConfig.modelExpectedSizeBytes;
          if (!OfflineAiConfig.enableLocalLlmRuntime) {
            _statusReason = 'Offline AI • Knowledge mode';
            _setStatus(LocalModelStatus.lexiconOnly);
            _log('Model verified on disk, safe mode active (enableLocalLlmRuntime = false). Transitioned to lexiconOnly.');
            return;
          }
          _statusReason = null;
          _setStatus(LocalModelStatus.ready);
          _log('Model already downloaded, verified, and READY (v${_metadata!.version}).');
          return;
        }

        // File exists but needs verification
        _setStatus(LocalModelStatus.verifying);
        _statusReason = 'Verifying model integrity...';
        final ok = await _verifyFile(file);
        if (ok) {
          _modelPath = path;
          _downloadProgress = 1.0;
          _downloadedBytes = OfflineAiConfig.modelExpectedSizeBytes;
          await _persistMetadata(verified: true);
          if (!OfflineAiConfig.enableLocalLlmRuntime) {
            _statusReason = 'Offline AI • Knowledge mode';
            _setStatus(LocalModelStatus.lexiconOnly);
            _log('Model verified on disk, safe mode active (enableLocalLlmRuntime = false). Transitioned to lexiconOnly.');
            return;
          }
          _statusReason = null;
          _setStatus(LocalModelStatus.ready);
          _log('Model verified and marked READY at $path');
          return;
        } else {
          // Checksum mismatch or corrupted: delete safely
          try {
            await file.delete();
          } catch (_) {}
          _log('Corrupted model file deleted.');
        }
      }

      // 4. Model is missing or invalid: start automatic download if enabled
      if (!autoDownload || !OfflineAiConfig.autoDownloadOfflineModel) {
        _setStatus(LocalModelStatus.unavailable);
        return;
      }

      await checkNetworkAndTriggerDownload();
    } catch (e) {
      _setStatus(LocalModelStatus.error);
      _setError('Startup check failed: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Automatic Network Check & Download Trigger
  // ---------------------------------------------------------------------------

  /// Evaluates network connectivity and starts/resumes background download.
  Future<void> checkNetworkAndTriggerDownload() async {
    if (_status == LocalModelStatus.downloading ||
        _status == LocalModelStatus.ready ||
        _status == LocalModelStatus.loaded ||
        _status == LocalModelStatus.generating) {
      return;
    }

    final isOnline = ConnectivityService.instance.isOnline;
    if (!isOnline) {
      _statusReason = 'Download pending — waiting for connection';
      _setStatus(LocalModelStatus.pending);
      _log('Network offline: download pending until connection is available.');
      _listenForConnectivityChanges();
      return;
    }

    final isWifi = await ConnectivityService.instance.isWifiOrEthernet();
    final isMobile = await ConnectivityService.instance.isMobileData();

    if (!isWifi && isMobile && !OfflineAiConfig.allowMobileDataDownload) {
      _statusReason = 'Offline AI download waiting for Wi-Fi';
      _setStatus(LocalModelStatus.pending);
      _log('Connected on mobile data but large downloads restricted to Wi-Fi. Waiting for Wi-Fi.');
      _listenForConnectivityChanges();
      return;
    }

    // Network is available and eligible -> start download in background
    _statusReason = null;
    await startDownload();
  }

  void _listenForConnectivityChanges() {
    _connectivitySub?.cancel();
    _connectivitySub = ConnectivityService.instance.statusStream.listen((netStatus) {
      if (netStatus != NetworkStatus.offline) {
        if (_status == LocalModelStatus.pending || _status == LocalModelStatus.error) {
          _log('Connectivity restored ($netStatus). Retrying download check...');
          _retryCount = 0; // reset retry counter on fresh connectivity
          unawaited(checkNetworkAndTriggerDownload());
        }
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Background Download
  // ---------------------------------------------------------------------------

  /// Start (or resume) the model download non-blockingly.
  /// Progress is reported via [downloadProgress] and [statusStream].
  Future<void> startDownload() async {
    if (_status == LocalModelStatus.downloading) return;
    if (!(_compatibility?.canDownload ?? false)) {
      _setError('Device not compatible: ${_compatibility?.reason}');
      return;
    }

    _setStatus(LocalModelStatus.downloading);
    _lastError = null;
    _statusReason = null;

    try {
      final destPath = await _expectedModelPath();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        OfflineAiConfig.prefsLastDownloadAttempt,
        DateTime.now().toIso8601String(),
      );

      await downloadService.download(
        url: OfflineAiConfig.modelDownloadUrl,
        destinationPath: destPath,
        expectedSizeBytes: OfflineAiConfig.modelExpectedSizeBytes,
        onProgress: (received, total) {
          _downloadedBytes = received;
          _expectedBytes = total > 0 ? total : OfflineAiConfig.modelExpectedSizeBytes;
          _downloadProgress = total > 0 ? (received / total).clamp(0.0, 1.0) : 0.0;
          _statusController.add(_status); // nudge UI listeners
          _persistProgress();
        },
      );

      _setStatus(LocalModelStatus.verifying);
      _statusReason = 'Verifying model integrity...';
      final file = File(destPath);
      final ok = await _verifyFile(file);
      if (!ok) {
        try {
          await file.delete();
        } catch (_) {}
        _setStatus(LocalModelStatus.error);
        _setError('Checksum verification failed after download.');
        _handleDownloadFailure(isVerificationFailure: true);
        return;
      }

      _modelPath = destPath;
      _downloadProgress = 1.0;
      _downloadedBytes = OfflineAiConfig.modelExpectedSizeBytes;
      await _persistMetadata(verified: true);
      _retryCount = 0;
      if (!OfflineAiConfig.enableLocalLlmRuntime) {
        _statusReason = 'Offline AI • Knowledge mode';
        _setStatus(LocalModelStatus.lexiconOnly);
        _log('Download complete and verified. Safe mode active (enableLocalLlmRuntime = false) -> lexiconOnly.');
        return;
      }
      _statusReason = null;
      _setStatus(LocalModelStatus.ready);
      _log('Download complete, verified, and READY.');
    } catch (e) {
      if (e is DownloadCancelledException) {
        _setStatus(LocalModelStatus.pending);
        _statusReason = 'Download paused';
        return;
      }
      _log('Download failed: $e');
      _handleDownloadFailure(errorMsg: e.toString());
    }
  }

  void _handleDownloadFailure({bool isVerificationFailure = false, String? errorMsg}) {
    if (isVerificationFailure) {
      _setStatus(LocalModelStatus.error);
      _setError('Model verification failed. Re-download scheduled when connection refreshes.');
      _listenForConnectivityChanges();
      return;
    }

    final isOnline = ConnectivityService.instance.isOnline;
    if (!isOnline) {
      _statusReason = 'Download pending — waiting for connection';
      _setStatus(LocalModelStatus.pending);
      _listenForConnectivityChanges();
      return;
    }

    if (_retryCount < OfflineAiConfig.maxDownloadRetries) {
      _retryCount++;
      final backoffSec = 2 * _retryCount;
      _statusReason = 'Retry pending (attempt $_retryCount/${OfflineAiConfig.maxDownloadRetries} in ${backoffSec}s)...';
      _setStatus(LocalModelStatus.pending);
      _retryTimer?.cancel();
      _retryTimer = Timer(Duration(seconds: backoffSec), () {
        checkNetworkAndTriggerDownload();
      });
    } else {
      _setStatus(LocalModelStatus.error);
      _setError('Offline AI download paused after $_retryCount attempts.');
      _statusReason = 'Download paused • Will retry when connection refreshes';
      _listenForConnectivityChanges();
    }
  }

  // ---------------------------------------------------------------------------
  // Load into memory (lazy, Samsung M12 RAM-safe)
  // ---------------------------------------------------------------------------

  /// Load the model into the LiteRT-LM runtime.
  /// Hard safe mode & low-memory devices safely bypass Qwen loading to prevent crashes.
  Future<void> loadModel() async {
    if (!OfflineAiConfig.enableLocalLlmRuntime) {
      _statusReason = 'Offline AI • Knowledge mode';
      _setStatus(LocalModelStatus.lexiconOnly);
      _log('loadModel called but enableLocalLlmRuntime is false. Preserving lexicon-only mode.');
      return;
    }

    // Re-verify RAM right before allocating LiteRT-LM memory
    _compatibility = await _checkCompatibility();
    if (!(_compatibility?.canLoad ?? false)) {
      _log('Device memory insufficient to load LLM (${_compatibility?.reason}). Avoiding Qwen load to prevent crash.');
      _setError(_compatibility?.reason ?? 'Device memory insufficient to run local LLM.');
      _statusReason = 'Device memory insufficient — Knowledge mode active';
      _setStatus(LocalModelStatus.lexiconOnly);
      return;
    }

    if (_status != LocalModelStatus.ready) {
      _log('Cannot load: status is $_status');
      return;
    }
    if (_modelPath == null) {
      _setError('Model path unknown.');
      return;
    }

    _setStatus(LocalModelStatus.loading);
    try {
      await llmService.initialize(modelPath: _modelPath!);
      _setStatus(LocalModelStatus.loaded);
      _log('Model loaded into runtime.');
    } catch (e) {
      _setStatus(LocalModelStatus.lexiconOnly);
      _setError('Failed to load model into memory: $e');
      _statusReason = 'Offline AI • Knowledge mode (Native engine unavailable)';
      _log('Model load failed: $e. Reverting to lexicon-only fallback.');
    }
  }

  /// Run an isolated native smoke test without switching general app state.
  Future<Map<String, dynamic>> runNativeSmokeTest({String prompt = 'Say OK'}) async {
    final path = _modelPath ?? await _expectedModelPath();
    final file = File(path);
    if (!await file.exists()) {
      return {'success': false, 'error': 'Model file does not exist on disk'};
    }
    return llmService.runSmokeTest(modelPath: path, testPrompt: prompt);
  }

  /// Unload the model to free RAM.
  Future<void> unloadModel() async {
    try {
      await llmService.dispose();
    } catch (_) {}
    if (_status == LocalModelStatus.loaded ||
        _status == LocalModelStatus.generating) {
      _setStatus(LocalModelStatus.ready);
    }
  }

  // ---------------------------------------------------------------------------
  // Compatibility
  // ---------------------------------------------------------------------------

  Future<LocalModelCompatibility> _checkCompatibility() async {
    try {
      final compat = await llmService.checkCompatibility();
      return compat;
    } catch (e) {
      return LocalModelCompatibility(
        supported: false,
        enoughStorage: false,
        enoughMemory: false,
        supportedAbi: false,
        reason: 'Could not check device capabilities: $e',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // File verification
  // ---------------------------------------------------------------------------

  Future<bool> _verifyFile(File file) async {
    if (!await file.exists()) return false;

    final stat = await file.stat();
    _log('File size: ${stat.size} bytes '
        '(expected ~${OfflineAiConfig.modelExpectedSizeBytes})');

    // Size sanity check (±10%)
    const expected = OfflineAiConfig.modelExpectedSizeBytes;
    if (expected > 0) {
      final ratio = stat.size / expected;
      if (ratio < 0.9 || ratio > 1.1) {
        _log('File size mismatch: ${stat.size} vs expected ~$expected');
        return false;
      }
    }

    // SHA-256 checksum (skip if not configured)
    const expectedSha = OfflineAiConfig.modelSha256;
    if (expectedSha.isEmpty) {
      _log('SHA-256 not configured — skipping checksum.');
      return true;
    }

    final computed = await downloadService.computeSha256(file.path);
    final match = computed == expectedSha.toLowerCase();
    _log('SHA-256 match: $match');
    return match;
  }

  // ---------------------------------------------------------------------------
  // Persistence
  // ---------------------------------------------------------------------------

  Future<void> _loadPersistedMetadata() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(OfflineAiConfig.prefsModelMetadata);
      if (raw != null) {
        _metadata = OfflineModelMetadata.fromJsonString(raw);
      }
    } catch (_) {}
  }

  Future<void> _persistProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(OfflineAiConfig.prefsDownloadedBytes, _downloadedBytes);
      await prefs.setDouble(OfflineAiConfig.prefsDownloadProgress, _downloadProgress);
    } catch (_) {}
  }

  Future<void> _persistMetadata({required bool verified}) async {
    final now = DateTime.now();
    _metadata = OfflineModelMetadata(
      modelId: 'qwen2.5-0.5b-litert-q8',
      version: OfflineAiConfig.modelVersion,
      filename: OfflineAiConfig.modelFilename,
      sha256: OfflineAiConfig.modelSha256,
      sizeBytes: OfflineAiConfig.modelExpectedSizeBytes,
      downloadUrl: OfflineAiConfig.modelDownloadUrl,
      license: OfflineAiConfig.modelLicense,
      downloadedAt: now,
      verified: verified,
    );
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        OfflineAiConfig.prefsModelMetadata,
        _metadata!.toJsonString(),
      );
      await prefs.setString(OfflineAiConfig.prefsModelVersion, OfflineAiConfig.modelVersion);
      await prefs.setString(OfflineAiConfig.prefsModelSha256, OfflineAiConfig.modelSha256);
      if (_modelPath != null) {
        await prefs.setString(OfflineAiConfig.prefsModelPath, _modelPath!);
      }
      await prefs.setInt(OfflineAiConfig.prefsExpectedSizeBytes, OfflineAiConfig.modelExpectedSizeBytes);
      await prefs.setInt(OfflineAiConfig.prefsDownloadedBytes, _downloadedBytes);
      await prefs.setDouble(OfflineAiConfig.prefsDownloadProgress, _downloadProgress);
      if (verified) {
        await prefs.setString(OfflineAiConfig.prefsLastSuccessfulVerification, now.toIso8601String());
      }
    } catch (_) {}
  }

  Future<String> _expectedModelPath() async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/${OfflineAiConfig.modelFilename}';
  }

  // ---------------------------------------------------------------------------
  // State helpers
  // ---------------------------------------------------------------------------

  void _setStatus(LocalModelStatus s) {
    _status = s;
    _statusController.add(s);
    _log('Status → $s');
  }

  void _setError(String msg) {
    _lastError = msg;
    _log('ERROR: $msg');
  }

  void _log(String msg) {
    if (OfflineAiConfig.enableDiagnostics) {
      // ignore: avoid_print
      print('[LocalModelManager] $msg');
    }
  }

  Future<void> dispose() async {
    _retryTimer?.cancel();
    _connectivitySub?.cancel();
    await unloadModel();
    await _statusController.close();
  }
}
