import 'dart:convert';

/// Persisted metadata for the locally downloaded LiteRT-LM model.
///
/// Stored in SharedPreferences as JSON under [_kPrefsKey].
class OfflineModelMetadata {
  static const String _kPrefsKey = 'gramhealth_offline_model_metadata';

  final String modelId;
  final String version;
  final String filename;
  final String sha256;
  final int sizeBytes;
  final String downloadUrl;
  final String license;
  final DateTime? downloadedAt;
  final bool verified;

  const OfflineModelMetadata({
    required this.modelId,
    required this.version,
    required this.filename,
    required this.sha256,
    required this.sizeBytes,
    required this.downloadUrl,
    required this.license,
    this.downloadedAt,
    this.verified = false,
  });

  static String get prefsKey => _kPrefsKey;

  OfflineModelMetadata copyWith({
    String? modelId,
    String? version,
    String? filename,
    String? sha256,
    int? sizeBytes,
    String? downloadUrl,
    String? license,
    DateTime? downloadedAt,
    bool? verified,
  }) {
    return OfflineModelMetadata(
      modelId: modelId ?? this.modelId,
      version: version ?? this.version,
      filename: filename ?? this.filename,
      sha256: sha256 ?? this.sha256,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      license: license ?? this.license,
      downloadedAt: downloadedAt ?? this.downloadedAt,
      verified: verified ?? this.verified,
    );
  }

  Map<String, dynamic> toJson() => {
        'modelId': modelId,
        'version': version,
        'filename': filename,
        'sha256': sha256,
        'sizeBytes': sizeBytes,
        'downloadUrl': downloadUrl,
        'license': license,
        'downloadedAt': downloadedAt?.toIso8601String(),
        'verified': verified,
      };

  factory OfflineModelMetadata.fromJson(Map<String, dynamic> json) {
    return OfflineModelMetadata(
      modelId: json['modelId'] as String,
      version: json['version'] as String,
      filename: json['filename'] as String,
      sha256: json['sha256'] as String,
      sizeBytes: json['sizeBytes'] as int,
      downloadUrl: json['downloadUrl'] as String,
      license: json['license'] as String? ?? 'Apache-2.0',
      downloadedAt: json['downloadedAt'] != null
          ? DateTime.tryParse(json['downloadedAt'] as String)
          : null,
      verified: json['verified'] as bool? ?? false,
    );
  }

  factory OfflineModelMetadata.fromJsonString(String s) =>
      OfflineModelMetadata.fromJson(
          jsonDecode(s) as Map<String, dynamic>);

  String toJsonString() => jsonEncode(toJson());

  String get sizeMb => '${(sizeBytes / (1024 * 1024)).toStringAsFixed(0)} MB';

  @override
  String toString() =>
      'OfflineModelMetadata($modelId v$version, ${sizeMb}, verified=$verified)';
}

/// Compatibility assessment for loading the local model on this device.
class LocalModelCompatibility {
  final bool supported;
  final bool enoughStorage;
  final bool enoughMemory;
  final bool supportedAbi;
  final bool nativeRuntimeSupported;
  final bool modelFormatSupported;
  final bool runtimeVersionSupported;
  final bool backendSupported;
  final bool smokeTestPassed;
  final String? manufacturer;
  final String? deviceModel;
  final int? apiLevel;
  final String? abi;
  final int? availableRamBytes;
  final int? totalRamBytes;
  final int? availableStorageBytes;
  final String? runtimeVersion;
  final String? selectedBackend;
  final String? reason;

  const LocalModelCompatibility({
    required this.supported,
    required this.enoughStorage,
    required this.enoughMemory,
    this.supportedAbi = true,
    this.nativeRuntimeSupported = true,
    this.modelFormatSupported = true,
    this.runtimeVersionSupported = true,
    this.backendSupported = true,
    this.smokeTestPassed = false,
    this.manufacturer,
    this.deviceModel,
    this.apiLevel,
    this.abi,
    this.availableRamBytes,
    this.totalRamBytes,
    this.availableStorageBytes,
    this.runtimeVersion,
    this.selectedBackend,
    this.reason,
  });

  bool get canDownload => supported && supportedAbi && enoughStorage;
  bool get canLoad =>
      supported &&
      enoughStorage &&
      enoughMemory &&
      supportedAbi &&
      nativeRuntimeSupported &&
      modelFormatSupported &&
      runtimeVersionSupported &&
      backendSupported;
  bool get isReadyForGeneration => canLoad && smokeTestPassed;
  bool get canProceed => canLoad;

  Map<String, dynamic> get deviceDiagnostics => {
        'manufacturer': manufacturer,
        'deviceModel': deviceModel,
        'apiLevel': apiLevel,
        'abi': abi,
        'availableRamBytes': availableRamBytes,
        'totalRamBytes': totalRamBytes,
        'availableStorageBytes': availableStorageBytes,
        'runtimeVersion': runtimeVersion,
        'selectedBackend': selectedBackend,
        'canDownload': canDownload,
        'canLoad': canLoad,
        'reason': reason,
      };

  factory LocalModelCompatibility.fromMap(Map<dynamic, dynamic> map) {
    return LocalModelCompatibility(
      supported: map['supported'] as bool? ?? false,
      enoughStorage: map['enoughStorage'] as bool? ?? false,
      enoughMemory: map['enoughMemory'] as bool? ?? false,
      supportedAbi: map['supportedAbi'] as bool? ?? true,
      nativeRuntimeSupported: map['nativeRuntimeSupported'] as bool? ?? true,
      modelFormatSupported: map['modelFormatSupported'] as bool? ?? true,
      runtimeVersionSupported: map['runtimeVersionSupported'] as bool? ?? true,
      backendSupported: map['backendSupported'] as bool? ?? true,
      smokeTestPassed: map['smokeTestPassed'] as bool? ?? false,
      manufacturer: map['manufacturer'] as String?,
      deviceModel: map['deviceModel'] as String?,
      apiLevel: map['apiLevel'] as int?,
      abi: map['abi'] as String?,
      availableRamBytes: map['availableRam'] as int?,
      totalRamBytes: map['totalRam'] as int?,
      availableStorageBytes: map['availableStorage'] as int?,
      runtimeVersion: map['runtimeVersion'] as String?,
      selectedBackend: map['selectedBackend'] as String?,
      reason: map['reason'] as String?,
    );
  }

  @override
  String toString() =>
      'LocalModelCompatibility(supported=$supported, '
      'device=$manufacturer $deviceModel, '
      'storage=$enoughStorage, memory=$enoughMemory, abi=$supportedAbi, '
      'runtime=$nativeRuntimeSupported ($runtimeVersion), backend=$selectedBackend, '
      'smokeTestPassed=$smokeTestPassed, reason=$reason)';
}
