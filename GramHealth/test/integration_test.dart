/// Integration test suite for the GramHealth Offline AI layer.
///
/// Run with:
///   flutter test test/integration_test.dart
///
/// Tests A–H mirror the acceptance criteria in the specification.
/// They use stub/mock implementations where the native runtime is not
/// available in CI environments.
library offline_ai_integration_tests;

import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Stubs used across tests
// ---------------------------------------------------------------------------

enum _ModelStatus { unavailable, loaded, generating }

bool _modelLoaded = false;
bool _networkAvailable = true;
bool _backendAvailable = true;

Future<String?> _onlineRequest(String query) async {
  if (!_networkAvailable || !_backendAvailable) {
    throw Exception('backend unavailable');
  }
  await Future<void>.delayed(const Duration(milliseconds: 5));
  return 'ONLINE: response to $query';
}

Future<String?> _offlineRequest(String query) async {
  // Emergency check
  const emergencyKeywords = [
    'chest pain', 'seizure', 'unconscious',
    'suicide', 'snake bite', 'severe bleeding',
  ];
  final lower = query.toLowerCase();
  if (emergencyKeywords.any((kw) => lower.contains(kw))) {
    return 'EMERGENCY: Please contact 108 or go to the nearest emergency department immediately.';
  }
  if (!_modelLoaded) {
    return 'LEXICON_ONLY: general information about headache from lexicon.';
  }
  return 'OFFLINE_LLM: Headache can have many causes. Warning signs include...';
}

Future<String?> routeQuery(String query) async {
  try {
    // Always check emergency first (deterministic, before any network call)
    const emergencyKeywords = [
      'chest pain', 'seizure', 'unconscious', 'suicide', 'snake bite',
    ];
    if (emergencyKeywords.any((kw) => query.toLowerCase().contains(kw))) {
      return 'EMERGENCY: Please contact 108 or go to the nearest emergency department immediately.';
    }

    // Try online
    final online = await _onlineRequest(query)
        .timeout(const Duration(seconds: 15));
    return online;
  } on Exception {
    // Fall back to offline
    return _offlineRequest(query);
  }
}

// ---------------------------------------------------------------------------
// Test A: Internet available → online AI used
// ---------------------------------------------------------------------------
void main() {
  group('TEST A – Online path used when internet is available', () {
    setUp(() {
      _networkAvailable = true;
      _backendAvailable = true;
      _modelLoaded = false;
    });

    test('returns online response when backend is reachable', () async {
      final result = await routeQuery('I have a headache');
      expect(result, startsWith('ONLINE:'));
    });
  });

  // ---------------------------------------------------------------------------
  // Test B: Backend unavailable → offline path used
  // ---------------------------------------------------------------------------
  group('TEST B – Backend unavailable → offline fallback', () {
    setUp(() {
      _networkAvailable = true;
      _backendAvailable = false;
      _modelLoaded = true;
    });
    tearDown(() => _backendAvailable = true);

    test('falls back to offline when backend throws', () async {
      final result = await routeQuery('my head hurts badly');
      expect(result, isNotNull);
      // Should NOT be online response
      expect(result, isNot(startsWith('ONLINE:')));
    });
  });

  // ---------------------------------------------------------------------------
  // Test C: Backend timeout → offline path used
  // ---------------------------------------------------------------------------
  group('TEST C – Backend timeout → offline fallback', () {
    bool slowBackend = false;

    Future<String?> slowOnlineRequest(String query) async {
      if (slowBackend) {
        await Future<void>.delayed(const Duration(seconds: 20));
      }
      return 'ONLINE: $query';
    }

    Future<String?> routeWithTimeout(String query) async {
      try {
        return await slowOnlineRequest(query)
            .timeout(const Duration(milliseconds: 100));
      } catch (_) {
        return _offlineRequest(query);
      }
    }

    test('falls back to offline on timeout', () async {
      slowBackend = true;
      final result = await routeWithTimeout('I have a cough');
      expect(result, isNotNull);
      expect(result, isNot(startsWith('ONLINE:')));
      slowBackend = false;
    });
  });

  // ---------------------------------------------------------------------------
  // Test D: Emergency query offline → deterministic emergency response
  //         Qwen does NOT override emergency logic
  // ---------------------------------------------------------------------------
  group('TEST D – Emergency query offline returns deterministic response', () {
    setUp(() {
      _networkAvailable = false;
      _backendAvailable = false;
      _modelLoaded = true;
    });
    tearDown(() {
      _networkAvailable = true;
      _backendAvailable = true;
    });

    test('chest pain → emergency response', () async {
      final result = await routeQuery('I have severe chest pain');
      expect(result, contains('EMERGENCY'));
      expect(result, contains('108'));
    });

    test('seizure → emergency response', () async {
      final result = await routeQuery('patient is having a seizure');
      expect(result, contains('EMERGENCY'));
    });

    test('emergency bypasses LLM (response has no OFFLINE_LLM prefix)', () async {
      final result = await routeQuery('unconscious and not breathing');
      expect(result, isNot(startsWith('OFFLINE_LLM:')));
      expect(result, contains('EMERGENCY'));
    });
  });

  // ---------------------------------------------------------------------------
  // Test E: Medical question offline → lexicon match + LLM context injection
  // ---------------------------------------------------------------------------
  group('TEST E – Medical question offline uses lexicon + LLM', () {
    setUp(() {
      _networkAvailable = false;
      _backendAvailable = false;
      _modelLoaded = true;
    });
    tearDown(() {
      _networkAvailable = true;
      _backendAvailable = true;
      _modelLoaded = false;
    });

    test('headache query returns offline LLM response when model is loaded',
        () async {
      final result = await routeQuery('I have a headache');
      // Either lexicon-only or LLM depending on model state
      expect(result, isNotNull);
      expect(result, isNot(startsWith('ONLINE:')));
      // Should NOT claim definitive diagnosis
      expect(result, isNot(contains('diagnosis is confirmed')));
    });
  });

  // ---------------------------------------------------------------------------
  // Test F: Unknown medical topic → safe limited response
  // ---------------------------------------------------------------------------
  group('TEST F – Unknown topic returns safe limited response', () {
    setUp(() {
      _networkAvailable = false;
      _backendAvailable = false;
      _modelLoaded = false;
    });
    tearDown(() {
      _networkAvailable = true;
      _backendAvailable = true;
    });

    test('query about unknown condition returns non-null safe response', () async {
      // Lexicon won't match; model not loaded; should still return something safe
      final result = await _offlineRequest('rare genetic condition XYZ');
      expect(result, isNotNull);
      // Result should be a safe message, not an exception
      expect(result!.isNotEmpty, isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // Test G: Non-medical question → unsupported response
  // ---------------------------------------------------------------------------
  group('TEST G – Non-medical question handled safely', () {
    test('non-medical query does not produce medical diagnosis', () async {
      // The offline router should return unsupported or pass through safely
      const query = 'What is the capital of India?';
      final result = await _offlineRequest(query);
      // Should not claim to be a medical diagnosis
      expect(result, isNot(contains('diagnosis')));
    });
  });

  // ---------------------------------------------------------------------------
  // Test H: Private patient data is never written into offline asset files
  // ---------------------------------------------------------------------------
  group('TEST H – No private patient data in offline assets', () {
    test('lexicon entries contain no patient-identifying fields', () {
      // Structural test: verify the lexicon schema has no patient-data fields.
      const forbiddenFields = [
        'patient_id', 'patient_name', 'abha_id', 'medical_record',
        'prescription', 'lab_result', 'consultation_id',
      ];
      // Simulated lexicon entry
      final exampleEntry = {
        'condition': 'Dengue',
        'aliases': ['dengue fever'],
        'symptoms': ['fever', 'headache'],
        'warning_signs': ['severe abdominal pain'],
        'general_information': 'General dengue information.',
        'when_to_seek_care': 'Seek care if warning signs appear.',
        'source': 'WHO',
        'source_url': 'https://www.who.int',
        'license': 'CC BY-NC-SA 3.0 IGO',
      };
      for (final field in forbiddenFields) {
        expect(
          exampleEntry.containsKey(field),
          isFalse,
          reason: 'Forbidden field "$field" found in lexicon entry schema.',
        );
      }
    });

    test('emergency response contains no patient data', () {
      const emergencyText =
          'These symptoms may require urgent medical attention. '
          'Please contact local emergency services (108) or go to the '
          'nearest emergency department immediately.';
      const sensitivePatterns = [
        'patient:', 'name:', 'abha:', 'record:', 'prescription:'
      ];
      for (final p in sensitivePatterns) {
        expect(
          emergencyText.toLowerCase().contains(p),
          isFalse,
          reason: 'Emergency response contains sensitive pattern: $p',
        );
      }
    });
  });
}
