import '../config/app_config.dart';
import '../services/api_client.dart';

class PatientModel {
  final String id;
  final String userId;
  final String? bloodGroup;
  final String? allergies;
  final String? chronicConditions;

  PatientModel({
    required this.id,
    required this.userId,
    this.bloodGroup,
    this.allergies,
    this.chronicConditions,
  });

  factory PatientModel.fromJson(Map<String, dynamic> json) {
    return PatientModel(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      bloodGroup: json['bloodGroup']?.toString(),
      allergies: json['allergies']?.toString(),
      chronicConditions: json['chronicConditions']?.toString(),
    );
  }
}

class PatientService {
  PatientService._();

  /// Fetch the logged-in patient's own profile.
  static Future<PatientModel> getMyPatient() async {
    final response = await ApiClient.get('${AppConfig.apiPatients}/me');
    return PatientModel.fromJson(response['data'] as Map<String, dynamic>);
  }

  /// Update the logged-in patient's profile.
  static Future<PatientModel> updateMyPatient(
      Map<String, dynamic> data) async {
    final response = await ApiClient.patch('${AppConfig.apiPatients}/me', data);
    return PatientModel.fromJson(response['data'] as Map<String, dynamic>);
  }
}
