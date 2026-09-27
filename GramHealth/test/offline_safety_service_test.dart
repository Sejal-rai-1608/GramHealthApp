import 'package:flutter_test/flutter_test.dart';

// Inline copy of OfflineSafetyService for test isolation
// (In the real project, import from the service directly)
bool isEmergency(String query) {
  final keywords = [
    'difficulty breathing', 'trouble breathing', 'can\'t breathe',
    'cannot breathe', 'short of breath', 'breathlessness',
    'saans nahi', 'choking', 'suffocating',
    'chest pain', 'severe chest pain', 'heart attack', 'seena dard',
    'stroke', 'face drooping', 'arm weakness',
    'unconscious', 'unresponsive', 'fainted', 'passed out', 'behosh',
    'seizure', 'convulsion', 'fits', 'mirgi',
    'severe bleeding', 'heavy bleeding', 'khoon aa raha',
    'anaphylaxis', 'allergic reaction', 'throat swelling',
    'suicidal', 'suicide', 'self-harm', 'want to die', 'kill myself',
    'snake bite', 'snakebite', 'saanp ne kaata',
    'poisoning', 'swallowed poison', 'overdose',
  ];
  final normalised = query.toLowerCase()
      .replaceAll(RegExp(r'[^\w\s]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ');
  return keywords.any((kw) => normalised.contains(kw));
}

void main() {
  group('OfflineSafetyService', () {
    // Test 1: Breathing emergency
    test('detects breathing difficulty as emergency', () {
      expect(isEmergency('I have difficulty breathing and chest pain'), isTrue);
    });

    // Test 2: Chest pain emergency
    test('detects chest pain as emergency', () {
      expect(isEmergency('I have severe chest pain'), isTrue);
    });

    // Test 3: Unconscious emergency
    test('detects unconscious as emergency', () {
      expect(isEmergency('patient is unconscious and not responding'), isTrue);
    });

    // Test 4: Seizure emergency
    test('detects seizure / fits as emergency', () {
      expect(isEmergency('child is having fits and shaking'), isTrue);
    });

    // Test 5: Hindi emergency (saans nahi)
    test('detects Hindi breathing emergency', () {
      expect(isEmergency('saans nahi aa raha hai'), isTrue);
    });

    // Test 6: Suicidal emergency
    test('detects suicidal/self-harm emergency', () {
      expect(isEmergency('I want to kill myself'), isTrue);
    });

    // Test 7: Snake bite emergency
    test('detects snake bite as emergency', () {
      expect(isEmergency('saanp ne kaata mujhe'), isTrue);
    });

    // Test 8: Normal headache is NOT emergency
    test('does not flag ordinary headache as emergency', () {
      expect(isEmergency('I have a headache and mild fever'), isFalse);
    });

    // Test 9: Normal cold is NOT emergency
    test('does not flag common cold as emergency', () {
      expect(isEmergency('runny nose and mild cough since yesterday'), isFalse);
    });

    // Test 10: Diarrhea is NOT emergency (unless dehydration is severe)
    test('does not flag ordinary diarrhea as emergency', () {
      expect(isEmergency('loose stools since this morning'), isFalse);
    });
  });

  group('Query normalisation', () {
    String normalise(String q) => q
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    // Test 1: Lowercase
    test('lowercases input', () {
      expect(normalise('FEVER'), equals('fever'));
    });

    // Test 2: Punctuation removal
    test('removes punctuation', () {
      expect(normalise('head-ache!'), equals('head ache'));
    });

    // Test 3: Whitespace
    test('collapses whitespace', () {
      expect(normalise('  chest   pain  '), equals('chest pain'));
    });
  });

  group('LRU cache', () {
    // Test: LRU evicts oldest entry
    test('evicts oldest entry when full', () {
      final cache = _LruCache<String, int>(maxSize: 2);
      cache.put('a', 1);
      cache.put('b', 2);
      cache.put('c', 3); // should evict 'a'
      expect(cache.get('a'), isNull);
      expect(cache.get('b'), equals(2));
      expect(cache.get('c'), equals(3));
    });

    // Test: LRU promotes on access
    test('promotes accessed entry', () {
      final cache = _LruCache<String, int>(maxSize: 2);
      cache.put('a', 1);
      cache.put('b', 2);
      cache.get('a'); // access 'a', making 'b' oldest
      cache.put('c', 3); // should evict 'b'
      expect(cache.get('b'), isNull);
      expect(cache.get('a'), equals(1));
    });
  });
}

// Minimal _LruCache copy for test
class _LruCache<K, V> {
  _LruCache({required this.maxSize});
  final int maxSize;
  final _map = <K, V>{};
  final _order = <K>[];
  V? get(K key) {
    if (!_map.containsKey(key)) return null;
    _order.remove(key);
    _order.add(key);
    return _map[key];
  }
  void put(K key, V value) {
    if (_map.containsKey(key)) {
      _order.remove(key);
    } else if (_map.length >= maxSize) {
      final oldest = _order.removeAt(0);
      _map.remove(oldest);
    }
    _map[key] = value;
    _order.add(key);
  }
}
