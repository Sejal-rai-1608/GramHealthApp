import 'dart:async';
import 'doctors_data.dart';

// Simulate network delay
Future<void> _delay(int ms) => Future.delayed(Duration(milliseconds: ms));

// ─── Auth ──────────────────────────────────────────────────────────────────

class AuthService {
  static Future<Map<String, dynamic>> login(
      String username, String password) async {
    await _delay(800);
    return {
      'token': 'mock-jwt-token-xyz',
      'user': {
        'id': '1',
        'username': username.isEmpty ? 'SEJAL' : username,
        'name': 'SEJAL',
        'email': 'SEJAL@example.com',
      }
    };
  }
}

// ─── Doctors ───────────────────────────────────────────────────────────────

class DoctorService {
  static Future<List<Doctor>> getDoctors() async {
    await _delay(500);
    return kDoctors;
  }

  static Future<Doctor> getDoctorById(String id) async {
    await _delay(300);
    final doctor = kDoctors.firstWhere(
      (d) => d.id == id,
      orElse: () => kDoctors.first,
    );
    return doctor;
  }
}

// ─── Symptoms ──────────────────────────────────────────────────────────────

class SymptomResult {
  final String condition;
  final String advice;
  final String action;

  SymptomResult({
    required this.condition,
    required this.advice,
    required this.action,
  });
}

class SymptomService {
  static Future<SymptomResult> checkSymptoms(List<String> symptoms) async {
    await _delay(1000);
    return SymptomResult(
      condition: 'Viral Fever',
      advice:
          'Drink plenty of fluids, rest well, and take Paracetamol if fever is high.',
      action:
          'Consult a general physician if symptoms persist for more than 3 days.',
    );
  }
}

// ─── Medicine ──────────────────────────────────────────────────────────────

class Medicine {
  final String id;
  final String name;
  final bool available;
  final int count;

  const Medicine({
    required this.id,
    required this.name,
    required this.available,
    required this.count,
  });
}

class MedicineService {
  static Future<List<Medicine>> searchMedicines(String query) async {
    await _delay(600);
    return const [
      Medicine(id: '1', name: 'Paracetamol 500mg', available: true, count: 50),
      Medicine(id: '2', name: 'Amoxicillin 250mg', available: true, count: 20),
      Medicine(id: '3', name: 'Cetirizine 10mg', available: false, count: 0),
    ];
  }
}

// ─── Health Records ────────────────────────────────────────────────────────

class HealthRecord {
  final String id;
  final String date;
  final String doctor;
  final String illness;
  final String diagnosis;
  final String prescription;

  HealthRecord({
    required this.id,
    required this.date,
    required this.doctor,
    required this.illness,
    required this.diagnosis,
    required this.prescription,
  });
}

class RecordsService {
  static Future<List<HealthRecord>> getHealthRecords() async {
    await _delay(700);
    return [
      HealthRecord(
        id: '1',
        date: 'Oct 12, 2025',
        doctor: 'Dr. Anita Joshi',
        illness: 'Viral Fever',
        diagnosis: 'Mild Viral Fever',
        prescription: 'Paracetamol, Vitamin C',
      ),
      HealthRecord(
        id: '2',
        date: 'Aug 24, 2025',
        doctor: 'Dr. Rajesh Kumar',
        illness: 'Checkup',
        diagnosis: 'Routine Pediatric Checkup',
        prescription: 'N/A',
      ),
    ];
  }
}
