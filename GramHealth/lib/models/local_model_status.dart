/// Status enum for the local on-device LLM lifecycle.
///
/// Transitions:
///   unavailable → checking → downloading → verifying → ready
///   ready → loading → loaded → generating → loaded
///   Any state → error (recoverable; reverts to ready/unavailable)
enum LocalModelStatus {
  /// Model file does not exist locally.
  unavailable,

  /// Checking whether the model exists and verifying its integrity.
  checking,

  /// Model download is pending (waiting for Wi-Fi, network, or retry backoff).
  pending,

  /// Model is actively downloading from the remote source.
  downloading,

  /// Download complete; verifying checksum.
  verifying,

  /// Model file verified on disk (SHA-256 matches).
  verified,

  /// Model and device are confirmed compatible.
  compatible,

  /// Model passed smoke test and is verified safe to load.
  loadable,

  /// Model is downloaded, verified, and ready to be loaded into memory.
  ready,

  /// Model is being loaded into the LiteRT-LM runtime.
  loading,

  /// Model is loaded in memory and accepting generation requests.
  loaded,

  /// A generation request is currently in progress.
  generating,

  /// Native model execution bypassed or failed; offline AI operating in safe lexicon mode.
  lexiconOnly,

  /// A recoverable or unrecoverable error has occurred.
  /// Inspect [LocalModelManager.lastError] for details.
  error,
}

extension LocalModelStatusX on LocalModelStatus {
  bool get isUsable => this == LocalModelStatus.loaded;
  bool get isLexiconOnly => this == LocalModelStatus.lexiconOnly;
  bool get isBusy =>
      this == LocalModelStatus.loading ||
      this == LocalModelStatus.generating;
  bool get isDownloading => this == LocalModelStatus.downloading;
  bool get isPending => this == LocalModelStatus.pending;
  bool get isError => this == LocalModelStatus.error;

  String get displayLabel {
    switch (this) {
      case LocalModelStatus.unavailable:
        return 'Offline AI • Not downloaded';
      case LocalModelStatus.checking:
        return 'Offline AI • Checking';
      case LocalModelStatus.pending:
        return 'Offline AI • Download pending';
      case LocalModelStatus.downloading:
        return 'Offline AI • Downloading';
      case LocalModelStatus.verifying:
        return 'Offline AI • Verifying';
      case LocalModelStatus.verified:
        return 'Offline AI • Verified';
      case LocalModelStatus.compatible:
        return 'Offline AI • Compatible';
      case LocalModelStatus.loadable:
        return 'Offline AI • Loadable';
      case LocalModelStatus.ready:
        return 'Offline AI • Ready';
      case LocalModelStatus.loading:
        return 'Offline AI • Starting';
      case LocalModelStatus.loaded:
        return 'AI • Offline';
      case LocalModelStatus.generating:
        return 'Offline AI • Thinking';
      case LocalModelStatus.lexiconOnly:
        return 'Offline AI • Knowledge mode';
      case LocalModelStatus.error:
        return 'Offline AI • Retry pending';
    }
  }
}
