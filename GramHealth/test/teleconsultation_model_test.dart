import 'package:flutter_test/flutter_test.dart';
import 'package:ruralcare_flutter/services/call_service.dart';
import 'package:ruralcare_flutter/services/consultation_service.dart';

void main() {
  group('Teleconsultation data flow', () {
    test('parses the structured appointment and participant contact data', () {
      final consultation = ConsultationModel.fromJson({
        'id': 'consultation-1',
        'status': 'ACTIVE',
        'type': 'VIDEO',
        'reason': 'General Fever',
        'symptoms': 'Fever for two days',
        'scheduledAt': '2026-10-25T09:00:00.000Z',
        'doctorId': 'doctor-1',
        'patientId': 'patient-1',
        'doctor': {
          'user': {'name': 'Dr. Anita Joshi', 'phone': '+911234567890'},
        },
        'patient': {
          'user': {'name': 'Ramesh Patel', 'phone': '+919876543210'},
        },
      });

      expect(consultation.reason, 'General Fever');
      expect(consultation.scheduledAt, '2026-10-25T09:00:00.000Z');
      expect(consultation.scheduledTime, contains('2026-10-25'));
      expect(consultation.doctorName, 'Dr. Anita Joshi');
      expect(consultation.doctorPhone, '+911234567890');
      expect(consultation.patientPhone, '+919876543210');
    });

    test('keeps compatibility with legacy preferred-time notes', () {
      final consultation = ConsultationModel.fromJson({
        'id': 'consultation-2',
        'status': 'PENDING',
        'type': 'AUDIO',
        'notes': 'General Fever\nPreferred time: Morning (9 AM - 12 PM)',
      });

      expect(consultation.reason, 'General Fever');
      expect(consultation.scheduledTime, 'Morning (9 AM - 12 PM)');
    });

    test('uses the same safe Jitsi room name for both participants', () {
      expect(
        CallService.roomNameForConsultation('abc/123'),
        'gramhealth_call_abc_123',
      );
    });
  });
}
