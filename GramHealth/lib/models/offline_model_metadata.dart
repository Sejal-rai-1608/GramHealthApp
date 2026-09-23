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
  final String? reason;

  const LocalModelCompatibility({
    required this.supported,
    required this.enoughStorage,
    required this.enoughMemory,
    this.reason,
  });

  bool get canProceed => supported && enoughStorage && enoughMemory;

  @override
  String toString() =>
      'LocalModelCompatibility(supported=$supported, '
      'storage=$enoughStorage, memory=$enoughMemory, reason=$reason)';
}
