import 'dart:async';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/offline_ai_config.dart';
import '../models/local_model_status.dart';
import '../models/offline_model_metadata.dart';
import 'local_llm_service.dart';
import 'local_model_download_service.dart';

/// Manages the full lifecycle of the on-device LiteRT-LM model.
///
/// State machine:
///   unavailable → checking → [downloading → verifying →] ready
///                                                          ↓
///                                                       loading
///                                                          ↓
///                                                       loaded  ←→ generating
///   Any state → error (recoverable)
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

  double _downloadProgress = 0.0;
  double get downloadProgress => _downloadProgress;

  OfflineModelMetadata? _metadata;
  OfflineModelMetadata? get metadata => _metadata;

  LocalModelCompatibility? _compatibility;
  LocalModelCompatibility? get compatibility => _compatibility;

  final _statusController =
      StreamController<LocalModelStatus>.broadcast();
  Stream<LocalModelStatus> get statusStream => _statusController.stream;

  // ---------------------------------------------------------------------------
  // Initialisation (call on app startup)
  // ---------------------------------------------------------------------------

  /// Checks whether the model is already present and verified.
  /// Non-blocking: does NOT download or load the model automatically.
  Future<void> checkModelOnStartup() async {
    _setStatus(LocalModelStatus.checking);
    try {
      _compatibility = await _checkCompatibility();
      if (!_compatibility!.canProceed) {
        _setStatus(LocalModelStatus.unavailable);
        _log('Device incompatible: ${_compatibility!.reason}');
        return;
      }

      await _loadPersistedMetadata();
      final path = await _expectedModelPath();
      final file = File(path);

      if (!await file.exists()) {
        _setStatus(LocalModelStatus.unavailable);
        return;
      }

      // File exists — verify it.
      _setStatus(LocalModelStatus.verifying);
      final ok = await _verifyFile(file);
      if (ok) {
        _modelPath = path;
        _setStatus(LocalModelStatus.ready);
        _log('Model ready at $path');
      } else {
        // Corrupted — delete and mark unavailable.
        await file.delete().catchError((_) {});
        _setStatus(LocalModelStatus.unavailable);
        _setError('Model checksum mismatch; file deleted for re-download.');
      }
    } catch (e) {
      _setStatus(LocalModelStatus.error);
      _setError('Startup check failed: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Download
  // ---------------------------------------------------------------------------

  /// Start (or resume) the model download.
  /// Progress is reported via [downloadProgress] and [statusStream].
  Future<void> startDownload() async {
    if (_status == LocalModelStatus.downloading) return;
    if (!(_compatibility?.canProceed ?? false)) {
      _setError('Device not compatible.');
      return;
    }

    _setStatus(LocalModelStatus.downloading);
    _downloadProgress = 0.0;

    try {
      final destPath = await _expectedModelPath();
      await downloadService.download(
        url: OfflineAiConfig.modelDownloadUrl,
        destinationPath: destPath,
        expectedSizeBytes: OfflineAiConfig.modelExpectedSizeBytes,
        onProgress: (received, total) {
          _downloadProgress = total > 0 ? received / total : 0;
          _statusController.add(_status); // nudge listeners
        },
      );

      _setStatus(LocalModelStatus.verifying);
      final file = File(destPath);
      final ok = await _verifyFile(file);
      if (!ok) {
        await file.delete().catchError((_) {});
        _setStatus(LocalModelStatus.error);
        _setError('Checksum verification failed after download.');
        return;
      }

      _modelPath = destPath;
      await _persistMetadata(verified: true);
      _setStatus(LocalModelStatus.ready);
      _log('Download complete and verified.');
    } catch (e) {
      _setStatus(LocalModelStatus.error);
      _setError('Download failed: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Load into memory
  // ---------------------------------------------------------------------------

  /// Load the model into the LiteRT-LM runtime.
  Future<void> loadModel() async {
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
      _setStatus(LocalModelStatus.error);
      _setError('Failed to load model: $e');
    }
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
    // Android version check via platform channel is in native code.
    // Here we check storage.
    try {
      final dir = await getApplicationDocumentsDirectory();
      final stat = await FileStat.stat(dir.path);
      // Free space is not directly available in Dart; use a heuristic:
      // if model file doesn't exist yet and we can proceed, assume OK
      // unless we have a MemoryInfo from native.
      // Native side (GramhealthLlmPlugin.kt) fills in memory/api checks.
      return const LocalModelCompatibility(
        supported: true,
        enoughStorage: true, // refined by native check before download
        enoughMemory: true,  // refined by native check before load
      );
    } catch (e) {
      return LocalModelCompatibility(
        supported: false,
        enoughStorage: false,
        enoughMemory: false,
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
    final expected = OfflineAiConfig.modelExpectedSizeBytes;
    if (expected > 0) {
      final ratio = stat.size / expected;
      if (ratio < 0.9 || ratio > 1.1) {
        _log('File size mismatch: ${stat.size} vs expected ~$expected');
        return false;
      }
    }

    // SHA-256 checksum (skip if not configured)
    final expectedSha = OfflineAiConfig.modelSha256;
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

  Future<void> _persistMetadata({required bool verified}) async {
    _metadata = OfflineModelMetadata(
      modelId: 'qwen2.5-0.5b-litert-q8',
      version: OfflineAiConfig.modelVersion,
      filename: OfflineAiConfig.modelFilename,
      sha256: OfflineAiConfig.modelSha256,
      sizeBytes: OfflineAiConfig.modelExpectedSizeBytes,
      downloadUrl: OfflineAiConfig.modelDownloadUrl,
      license: OfflineAiConfig.modelLicense,
      downloadedAt: DateTime.now(),
      verified: verified,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      OfflineAiConfig.prefsModelMetadata,
      _metadata!.toJsonString(),
    );
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
    await unloadModel();
    await _statusController.close();
  }
}
