import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../config/offline_ai_config.dart';
import '../models/medical_lexicon_entry.dart';

/// Efficient sharded offline medical lexicon lookup.
///
/// Architecture:
///   1. manifest.json  →  term → shard letter
///   2. shards/<letter>.json.gz  →  compressed array of entries
///   3. LRU shard cache (max [OfflineAiConfig.shardCacheMaxSize] shards)
///
/// Only the shard(s) needed for a query are decompressed.
class OfflineMedicalLookupService {
  OfflineMedicalLookupService._();
  static final OfflineMedicalLookupService instance =
      OfflineMedicalLookupService._();

  /// term (lowercase) → shard letter
  Map<String, String>? _manifest;

  /// LRU cache: shard letter → list of entries
  final _shardCache = _LruCache<String, List<MedicalLexiconEntry>>(
    maxSize: OfflineAiConfig.shardCacheMaxSize,
  );

  bool _initialised = false;

  // ---------------------------------------------------------------------------
  // Initialisation
  // ---------------------------------------------------------------------------

  Future<void> initialise() async {
    if (_initialised) return;
    final raw = await rootBundle.loadString(
      OfflineAiConfig.lexiconManifestPath,
    );
    final json = jsonDecode(raw) as Map<String, dynamic>;
    _manifest = json.map((k, v) => MapEntry(k, v as String));
    _initialised = true;
  }

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Full-text search across condition names, aliases, and symptoms.
  Future<List<MedicalLexiconEntry>> search(String query) async {
    await _ensureReady();
    final terms = _extractMedicalTerms(query);
    if (terms.isEmpty) return [];

    final shardLetters = _shardsForTerms(terms);
    final results = <MedicalLexiconEntry>{};

    for (final letter in shardLetters) {
      final entries = await _loadShard(letter);
      for (final entry in entries) {
        for (final term in terms) {
          if (entry.searchableText.contains(term)) {
            results.add(entry);
            break;
          }
        }
      }
    }

    return results.take(OfflineAiConfig.offlineMaxEntries).toList();
  }

  /// Exact condition name lookup (case-insensitive).
  Future<MedicalLexiconEntry?> findCondition(String condition) async {
    await _ensureReady();
    final key = _normalise(condition);
    final letter = _manifest![key];
    if (letter == null) return null;

    final entries = await _loadShard(letter);
    for (final entry in entries) {
      if (_normalise(entry.condition) == key) return entry;
      if (entry.aliases.any((a) => _normalise(a) == key)) return entry;
    }
    return null;
  }

  /// Find entries where any of the supplied symptoms is mentioned.
  Future<List<MedicalLexiconEntry>> findBySymptoms(
    List<String> symptoms,
  ) async {
    await _ensureReady();
    final normalised = symptoms.map(_normalise).toList();
    final shardLetters = _shardsForTerms(normalised);

    final scored = <MedicalLexiconEntry, int>{};
    for (final letter in shardLetters) {
      final entries = await _loadShard(letter);
      for (final entry in entries) {
        var score = 0;
        for (final sym in normalised) {
          if (entry.symptoms.any((s) => _normalise(s).contains(sym))) {
            score++;
          }
        }
        if (score > 0) scored[entry] = score;
      }
    }

    final sorted = scored.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted
        .take(OfflineAiConfig.offlineMaxEntries)
        .map((e) => e.key)
        .toList();
  }

  // ---------------------------------------------------------------------------
  // Query normalisation
  // ---------------------------------------------------------------------------

  static const Map<String, String> _hindiSymptomMap = {
    'bukhar': 'fever',
    'tez bukhar': 'high fever',
    'sir dard': 'headache',
    'sar dard': 'headache',
    'sirdard': 'headache',
    'khasi': 'cough',
    'khansi': 'cough',
    'nakam bahna': 'runny nose',
    'naak bahna': 'runny nose',
    'ulti': 'vomiting',
    'vomiting': 'vomiting',
    'dast': 'diarrhea',
    'pet dard': 'abdominal pain',
    'seena dard': 'chest pain',
    'saans': 'breathing',
    'thakan': 'fatigue',
    'kamzori': 'weakness',
    'chakkhar': 'dizziness',
    'chakkar': 'dizziness',
    'jukam': 'cold',
    'sardard': 'headache',
    'sar': 'head',
    'badan dard': 'body pain',
    'jod dard': 'joint pain',
    'peeda': 'pain',
    'dard': 'pain',
    'sujan': 'swelling',
    'laal aankh': 'red eye',
    'aankhon mein dard': 'eye pain',
    'peshab mein jalan': 'burning urination',
    'khaaj': 'itching',
    'daane': 'rash',
  };

  static const Map<String, String> _spellingVariants = {
    'diarhea': 'diarrhea',
    'diarrhoea': 'diarrhea',
    'haedache': 'headache',
    'headche': 'headache',
    'malaira': 'malaria',
    'dengue fever': 'dengue',
    'typhoid fever': 'typhoid',
    'jaundis': 'jaundice',
    'anaemia': 'anemia',
    'haemorrhage': 'hemorrhage',
    'breathlessness': 'difficulty breathing',
    'dyspnoea': 'difficulty breathing',
    'hypertension': 'high blood pressure',
    'hyperglycemia': 'high blood sugar',
    'uti': 'urinary tract infection',
    'uri': 'upper respiratory infection',
    'urti': 'upper respiratory infection',
  };

  /// Normalise a raw query into searchable tokens.
  List<String> _extractMedicalTerms(String query) {
    var text = _normalise(query);

    // Apply Hindi transliteration map
    for (final entry in _hindiSymptomMap.entries) {
      text = text.replaceAll(entry.key, entry.value);
    }

    // Apply spelling variant map
    for (final entry in _spellingVariants.entries) {
      text = text.replaceAll(entry.key, entry.value);
    }

    // Extract individual meaningful words (3+ chars)
    final words = text.split(RegExp(r'\s+')).where((w) => w.length >= 3);
    final stopWords = {
      'the', 'and', 'for', 'with', 'from', 'have', 'has',
      'what', 'when', 'where', 'how', 'why', 'who', 'are',
      'can', 'get', 'meri', 'mera', 'mujhe', 'kya', 'hai',
      'kar', 'raha', 'rahi', 'bahut', 'zyada',
    };
    return words.where((w) => !stopWords.contains(w)).toList();
  }

  String _normalise(String input) {
    return input
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  // ---------------------------------------------------------------------------
  // Shard resolution
  // ---------------------------------------------------------------------------

  Set<String> _shardsForTerms(List<String> terms) {
    final letters = <String>{};
    for (final term in terms) {
      final letter = _manifest![term];
      if (letter != null) {
        letters.add(letter);
      } else {
        // Partial match: check if any manifest key starts with a token
        for (final key in _manifest!.keys) {
          if (key.contains(term) || term.contains(key)) {
            letters.add(_manifest![key]!);
          }
        }
      }
    }
    return letters;
  }

  // ---------------------------------------------------------------------------
  // Shard loading (with LRU cache)
  // ---------------------------------------------------------------------------

  Future<List<MedicalLexiconEntry>> _loadShard(String letter) async {
    final cached = _shardCache.get(letter);
    if (cached != null) return cached;

    final path =
        '${OfflineAiConfig.lexiconShardsPath}/$letter.json.gz';
    final byteData = await rootBundle.load(path);
    final compressed = byteData.buffer.asUint8List();

    final decompressed = GZipDecoder().decodeBytes(compressed);
    final jsonStr = utf8.decode(decompressed);
    final jsonList = jsonDecode(jsonStr) as List<dynamic>;

    final entries = jsonList
        .map((e) =>
            MedicalLexiconEntry.fromJson(e as Map<String, dynamic>))
        .toList();

    _shardCache.put(letter, entries);
    return entries;
  }

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  Future<void> _ensureReady() async {
    if (!_initialised) await initialise();
  }

  void dispose() {
    _shardCache.clear();
    _manifest = null;
    _initialised = false;
  }
}

// ---------------------------------------------------------------------------
// Simple LRU cache
// ---------------------------------------------------------------------------

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

  void clear() {
    _map.clear();
    _order.clear();
  }
}
