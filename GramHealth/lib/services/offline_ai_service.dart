import 'dart:async';

import '../config/offline_ai_config.dart';
import '../models/local_model_status.dart';
import '../models/offline_response.dart';
import '../models/offline_model_metadata.dart';
import 'local_model_manager.dart';
import 'local_model_download_service.dart';
import 'local_llm_service.dart';
import 'offline_ai_router.dart';
import 'offline_medical_lookup_service.dart';
import 'offline_safety_service.dart';

/// Top-level coordinator for the offline AI feature.
///
/// Usage in Flutter (typically a ChangeNotifier provider):
///
/// ```dart
/// final service = OfflineAiService.instance;
/// await service.initialise();
/// // Check onStartup — never downloads automatically
/// await service.checkModelOnStartup();
///
/// // Show setup card if status == unavailable
/// // User taps DOWNLOAD
/// await service.startDownload();
/// // Load model lazily when user opens chat
/// await service.ensureModelLoaded();
///
/// // In AI chat:
/// service.queryOffline('mujhe sir dard hai').listen((token) {
///   uiBuffer.write(token);
/// });
/// ```
class OfflineAiService {
  OfflineAiService._();
  static final OfflineAiService instance = OfflineAiService._();

  late LocalModelManager _modelManager;
  late OfflineAiRouter _router;
  late OfflineMedicalLookupService _lookupService;

  bool _initialised = false;

  // ---------------------------------------------------------------------------
  // Initialisation
  // ---------------------------------------------------------------------------

  Future<void> initialise() async {
    if (_initialised) return;

    final downloadService = LocalModelDownloadService();
    final llmService = LiteRtLmService();

    _modelManager = LocalModelManager(
      downloadService: downloadService,
      llmService: llmService,
    );

    _lookupService = OfflineMedicalLookupService.instance;

    _router = OfflineAiRouter(
      safetyService: OfflineSafetyService.instance,
      lookupService: _lookupService,
      modelManager: _modelManager,
      llmService: llmService,
    );

    // Pre-load manifest (cheap, ~5 KB)
    try {
      await _lookupService.initialise();
    } catch (e) {
      _log('Lexicon init failed (non-fatal): $e');
    }

    _initialised = true;
  }

  // ---------------------------------------------------------------------------
  // Startup check (non-blocking)
  // ---------------------------------------------------------------------------

  /// Run on app startup. Checks if model is already downloaded and verified.
  /// Does NOT start a download automatically.
  Future<void> checkModelOnStartup() async {
    _ensureInit();
    await _modelManager.checkModelOnStartup();
  }

  // ---------------------------------------------------------------------------
  // Download controls
  // ---------------------------------------------------------------------------

  Future<void> startDownload() async {
    _ensureInit();
    await _modelManager.startDownload();
  }

  void cancelDownload() {
    // Delegate to download service via manager
    _modelManager.downloadService.cancel();
  }

  // ---------------------------------------------------------------------------
  // Model lifecycle
  // ---------------------------------------------------------------------------

  /// Lazily load the model into memory.
  /// Call when the user opens the AI chat screen.
  Future<void> ensureModelLoaded() async {
    _ensureInit();
    if (_modelManager.status == LocalModelStatus.ready) {
      await _modelManager.loadModel();
    }
  }

  Future<void> unloadModel() async {
    _ensureInit();
    await _modelManager.unloadModel();
  }

  // ---------------------------------------------------------------------------
  // Offline query (streaming)
  // ---------------------------------------------------------------------------

  /// Returns a stream of text tokens for the offline response.
  ///
  /// The first emitted item describes the decision; subsequent items
  /// are progressive LLM tokens (or a single static string if lexicon-only).
  Stream<String> queryOffline(String query) async* {
    _ensureInit();
    try {
      final result = await _router.route(query);
      yield* result.stream;
    } catch (e) {
      _log('queryOffline error: $e');
      yield OfflineResponse.noInformation().text;
    }
  }

  // ---------------------------------------------------------------------------
  // Emergency check (synchronous convenience)
  // ---------------------------------------------------------------------------

  bool isEmergency(String query) =>
      OfflineSafetyService.instance.isEmergency(query);

  OfflineResponse buildEmergencyResponse(String query) {
    final terms =
        OfflineSafetyService.instance.matchedEmergencyTerms(query);
    return OfflineSafetyService.instance.buildEmergencyResponse(terms);
  }

  // ---------------------------------------------------------------------------
  // Observability
  // ---------------------------------------------------------------------------

  LocalModelStatus get modelStatus => _modelManager.status;
  double get downloadProgress => _modelManager.downloadProgress;
  String? get lastError => _modelManager.lastError;
  OfflineModelMetadata? get modelMetadata => _modelManager.metadata;
  LocalModelCompatibility? get compatibility => _modelManager.compatibility;

  Stream<LocalModelStatus> get statusStream =>
      _initialised ? _modelManager.statusStream : const Stream.empty();

  // ---------------------------------------------------------------------------
  // Diagnostics
  // ---------------------------------------------------------------------------

  Map<String, dynamic> diagnostics() =>
  {
    'ai_mode': _isModelUsable() ? 'offline' : 'unavailable',
    'offline_model': modelStatus.name,
    'lexicon': 'bundled',
    'model_version': modelMetadata?.version ?? 'unknown',
    'model_size': modelMetadata?.sizeMb ?? 'unknown',
    'download_progress':
        '${(downloadProgress * 100).toStringAsFixed(0)}%',
    'last_error': lastError ?? 'none',
  };

  bool _isModelUsable() =>
      modelStatus == LocalModelStatus.loaded ||
      modelStatus == LocalModelStatus.generating;

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  void _ensureInit() {
    if (!_initialised) {
      throw StateError(
        'OfflineAiService not initialised. Call initialise() first.',
      );
    }
  }

  void _log(String msg) {
    if (OfflineAiConfig.enableDiagnostics) {
      // ignore: avoid_print
      print('[OfflineAiService] $msg');
    }
  }

  Future<void> dispose() async {
    if (_initialised) {
      await _modelManager.dispose();
      _lookupService.dispose();
      _initialised = false;
    }
  }
}
