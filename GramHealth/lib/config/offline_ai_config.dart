/// Central configuration for all offline AI parameters.
///
/// All values are configurable here; do not scatter magic numbers
/// across services.
class OfflineAiConfig {
  OfflineAiConfig._();

  // ────────────────────────────────────────────────────────────
  // Model source
  // NOTE: Verify the exact filename, size, and SHA-256 from the
  // official HuggingFace model card before releasing:
  // https://huggingface.co/litert-community/Qwen2.5-0.5B-Instruct
  //
  // The values below are placeholders that must be confirmed by
  // running the model-verification script in /docs/verify_model.sh
  // ────────────────────────────────────────────────────────────

  /// HuggingFace repository (community LiteRT builds).
  static const String modelRepoId = 'litert-community/Qwen2.5-0.5B-Instruct';

  /// Filename as it appears in the repository.
  static const String modelFilename =
      'Qwen2.5-0.5B-Instruct_seq128_q8_ekv1280.tflite';

  /// Canonical download URL (HTTPS only, no redirects).
  static const String modelDownloadUrl =
      'https://huggingface.co/litert-community/Qwen2.5-0.5B-Instruct'
      '/resolve/main/Qwen2.5-0.5B-Instruct_seq128_q8_ekv1280.tflite';

  /// Expected file size in bytes (513,219,800 bytes).
  static const int modelExpectedSizeBytes = 513219800;

  /// Verified SHA-256 checksum from HuggingFace LFS metadata.
  static const String modelSha256 =
      '49b3b9ca95c46b185995edeb7314dec06c23f65d7a8c7b24ee97d5313e6032ac';

  /// Semantic version of this model registration entry.
  static const String modelVersion = '1.0.0';

  /// SPDX license of the model weights.
  static const String modelLicense = 'Apache-2.0';

  // ────────────────────────────────────────────────────────────
  // Device compatibility thresholds
  // ────────────────────────────────────────────────────────────

  /// Minimum free storage (bytes) required before downloading.
  /// Model + 20 % headroom.
  static const int minFreeStorageBytes = 700000000; // 700 MB

  /// Minimum available RAM (bytes) before loading the model.
  /// Conservative threshold for low-end Android devices.
  static const int minAvailableRamBytes = 1500000000; // 1.5 GB

  /// Minimum Android API level (Android 8.0 = API 26).
  static const int minAndroidApiLevel = 26;

  // ────────────────────────────────────────────────────────────
  // Offline lexicon
  // ────────────────────────────────────────────────────────────

  static const String lexiconAssetBase = 'assets/offline_medical';
  static const String lexiconManifestPath =
      '$lexiconAssetBase/manifest.json';
  static const String lexiconMetadataPath =
      '$lexiconAssetBase/metadata.json';
  static const String lexiconShardsPath = '$lexiconAssetBase/shards';

  /// Maximum number of decompressed shards to keep in the LRU cache.
  static const int shardCacheMaxSize = 4;

  // ────────────────────────────────────────────────────────────
  // Context / token budget
  // ────────────────────────────────────────────────────────────

  /// Maximum number of lexicon entries injected per request.
  static const int offlineMaxEntries = 3;

  /// Maximum total characters of medical context injected into the prompt.
  static const int offlineContextMaxCharacters = 1500;

  /// Approximate max tokens for the full prompt (system + context + query).
  /// Qwen2.5-0.5B has a 32 k context window; stay well under it.
  static const int offlineMaxPromptTokens = 1024;

  // ────────────────────────────────────────────────────────────
  // Generation parameters
  // ────────────────────────────────────────────────────────────

  static const int maxNewTokens = 400;
  static const double temperature = 0.2; // conservative for medical
  static const double topP = 0.9;
  static const int topK = 40;

  // ────────────────────────────────────────────────────────────
  // Download / networking
  // ────────────────────────────────────────────────────────────

  /// HTTP timeout for each chunk download.
  static const Duration downloadChunkTimeout = Duration(seconds: 30);

  /// Size of each HTTP range-request chunk.
  static const int downloadChunkBytes = 4 * 1024 * 1024; // 4 MB

  /// Maximum download retry attempts before surfacing an error.
  static const int maxDownloadRetries = 3;

  // ────────────────────────────────────────────────────────────
  // SharedPreferences keys
  // ────────────────────────────────────────────────────────────

  static const String prefsModelMetadata = 'gramhealth_offline_model_meta';
  static const String prefsDownloadProgress =
      'gramhealth_offline_download_progress';
  static const String prefsDownloadedBytes =
      'gramhealth_offline_downloaded_bytes';

  // ────────────────────────────────────────────────────────────
  // Connectivity / online fallback
  // ────────────────────────────────────────────────────────────

  /// How long to wait for the online backend before falling back offline.
  static const Duration onlineRequestTimeout = Duration(seconds: 15);

  // ────────────────────────────────────────────────────────────
  // Observability  (development only; never log patient data)
  // ────────────────────────────────────────────────────────────

  /// Enable verbose diagnostic logging in debug builds.
  static const bool enableDiagnostics = true;
}
