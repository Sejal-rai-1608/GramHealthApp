import '../config/app_config.dart';
import '../services/api_client.dart';

/// Model matching the backend Doctor + User join response.
class DoctorModel {
  final String id;
  final String name;
  final String specialization;
  final int experienceYears;
  final double rating;
  final bool isAvailable;
  final String? profileImageUrl;
  final String? consultationFee;
  final String? bio;
  final String? hospital;

  DoctorModel({
    required this.id,
    required this.name,
    required this.specialization,
    required this.experienceYears,
    required this.rating,
    required this.isAvailable,
    this.profileImageUrl,
    this.consultationFee,
    this.bio,
    this.hospital,
  });

  factory DoctorModel.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>? ?? {};
    return DoctorModel(
      id: json['id']?.toString() ?? '',
      name: user['name']?.toString() ?? json['name']?.toString() ?? 'Unknown Doctor',
      specialization: json['specialization']?.toString() ?? 'General Physician',
      experienceYears: (json['experienceYears'] as num?)?.toInt() ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      isAvailable: json['isAvailable'] as bool? ?? false,
      profileImageUrl: json['profileImageUrl']?.toString(),
      consultationFee: json['consultationFee']?.toString(),
      bio: json['bio']?.toString(),
      hospital: json['hospital']?.toString(),
    );
  }

  // Compatibility getters so existing widgets work without changes
  String get spec => specialization;
  String get exp => '$experienceYears yrs';
  String get reviews => '—';
  bool get online => isAvailable;
  String get image => profileImageUrl ?? 'https://images.unsplash.com/photo-1559839734-2b71ea197ec2?w=400';
  String get fee => consultationFee != null ? '₹$consultationFee' : '—';
  String get patients => '—';
  String get about => bio ?? 'No bio available.';
}

class DoctorService {
  DoctorService._();

  /// Returns a list of doctors (accessible to PATIENT, ASHA, ADMIN).
  static Future<List<DoctorModel>> getDoctors({
    String? specialization,
    int page = 1,
    int limit = 20,
  }) async {
    String url = '${AppConfig.apiDoctors}?page=$page&limit=$limit';
    if (specialization != null) url += '&specialization=$specialization';

    final response = await ApiClient.get(url);
    final List<dynamic> items = response['data'] as List<dynamic>? ?? [];
    return items
        .map((e) => DoctorModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Returns a single doctor by ID.
  static Future<DoctorModel> getDoctorById(String id) async {
    final response = await ApiClient.get('${AppConfig.apiDoctors}/$id');
    return DoctorModel.fromJson(response['data'] as Map<String, dynamic>);
  }
}
