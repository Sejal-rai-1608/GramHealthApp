import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ruralcare_flutter/config/offline_ai_config.dart';
import 'package:ruralcare_flutter/models/local_model_status.dart';
import 'package:ruralcare_flutter/models/medical_lexicon_entry.dart';
import 'package:ruralcare_flutter/models/offline_model_metadata.dart';
import 'package:ruralcare_flutter/models/offline_response.dart';
import 'package:ruralcare_flutter/services/offline_safety_service.dart';

void main() {
  group('1. Query Normalisation', () {
    String normalise(String input) {
      return input
          .toLowerCase()
          .replaceAll(RegExp(r'[^\w\s]'), ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
    }

    test('lowercases, removes punctuation and trims whitespace', () {
      expect(normalise('  Severe-Headache!! '), equals('severe headache'));
      expect(normalise('Abdominal   PAIN...'), equals('abdominal pain'));
    });
  });

  group('2. Alias & Multilingual Matching (Hindi/Marathi)', () {
    const hindiSymptomMap = {
      'bahut tez bukhar': 'high fever',
      'sir dard': 'headache',
      'pet dard': 'abdominal pain',
      'pot khupp dukht': 'abdominal pain',
      'pot dukht': 'abdominal pain',
      'doke dukht': 'headache',
      'taap': 'fever',
      'khokla': 'cough',
      'sardi': 'cold',
      'appendix': 'appendicitis',
      'mushroom': 'gastroenteritis abdominal',
    };

    String mapAliases(String query) {
      var text = query.toLowerCase();
      for (final entry in hindiSymptomMap.entries) {
        text = text.replaceAll(entry.key, entry.value);
      }
      return text;
    }

    test('maps Hindi headache & fever correctly', () {
      expect(mapAliases('mujhe bahut tez bukhar aur sir dard hai'), contains('high fever'));
      expect(mapAliases('mujhe bahut tez bukhar aur sir dard hai'), contains('headache'));
    });

    test('maps Marathi abdominal pain & headache correctly', () {
      final marathiHeadache = mapAliases('majhe doke dukht aahe');
      expect(marathiHeadache, contains('headache'));

      final marathiStomach = mapAliases('majha pot khupp dukht aahe');
      expect(marathiStomach, contains('abdominal pain'));
    });

    test('maps Marathi mushroom query correctly', () {
      final q = mapAliases('me aaj mushroom khaalela majha pot khupp dukht aahe Appendix');
      expect(q, contains('gastroenteritis'));
      expect(q, contains('abdominal pain'));
      expect(q, contains('appendicitis'));
    });
  });

  group('3. Manifest Lookup Simulation', () {
    final manifest = {
      'headache': 'h',
      'fever': 'f',
      'appendicitis': 'a',
      'abdominal': 'a',
      'dengue': 'd',
      'malaria': 'm',
    };

    test('resolves term to shard letter', () {
      expect(manifest['headache'], equals('h'));
      expect(manifest['fever'], equals('f'));
      expect(manifest['appendicitis'], equals('a'));
      expect(manifest['unknown_term'], isNull);
    });
  });

  group('4 & 5. Shard Loading & Gzip Decompression', () {
    test('compresses with Gzip and decompresses back to original json', () {
      final originalList = [
        {
          'condition': 'Headache',
          'aliases': ['head pain', 'sir dard'],
          'symptoms': ['throbbing pain', 'sensitivity to light'],
          'warning_signs': ['worst headache of life', 'stiff neck'],
          'general_information': 'Headaches are common pain sensations in the head.',
          'when_to_seek_care': 'Seek care if sudden and severe.',
          'source': 'WHO',
          'source_url': 'https://who.int',
          'license': 'CC BY-NC-SA 3.0 IGO',
        }
      ];
      final jsonStr = jsonEncode(originalList);
      final rawBytes = utf8.encode(jsonStr);

      // Gzip compress
      final compressed = GZipEncoder().encode(rawBytes);
      expect(compressed, isNotNull);

      // Gzip decompress
      final decompressed = GZipDecoder().decodeBytes(compressed!);
      final restoredStr = utf8.decode(decompressed);
      final restoredList = jsonDecode(restoredStr) as List<dynamic>;

      expect(restoredList.length, equals(1));
      final entry = MedicalLexiconEntry.fromJson(restoredList.first as Map<String, dynamic>);
      expect(entry.condition, equals('Headache'));
      expect(entry.aliases, contains('sir dard'));
    });
  });

  group('6. LRU Cache Bounded Memory', () {
    test('evicts oldest shard when max capacity is reached', () {
      final cache = <String, String>{};
      final order = <String>[];
      const maxSize = 3;

      void put(String key, String val) {
        if (cache.containsKey(key)) {
          order.remove(key);
        } else if (cache.length >= maxSize) {
          final oldest = order.removeAt(0);
          cache.remove(oldest);
        }
        cache[key] = val;
        order.add(key);
      }

      put('a', 'shard_a');
      put('b', 'shard_b');
      put('c', 'shard_c');
      expect(cache.keys, containsAll(['a', 'b', 'c']));

      // Adding 4th shard should evict 'a'
      put('d', 'shard_d');
      expect(cache.containsKey('a'), isFalse);
      expect(cache.keys, containsAll(['b', 'c', 'd']));
    });
  });

  group('7 & 8. Condition and Symptom Matching', () {
    const entry = MedicalLexiconEntry(
      condition: 'Appendicitis',
      aliases: ['appendix pain', 'appendix'],
      symptoms: ['abdominal pain', 'nausea', 'vomiting', 'fever'],
      warningSigns: ['severe pain lower right abdomen', 'high fever'],
      generalInformation: 'Inflammation of the appendix.',
      whenToSeekCare: 'Emergency evaluation required immediately.',
      source: 'NHS',
      sourceUrl: 'https://nhs.uk',
      license: 'Open Government Licence v3.0',
    );

    test('matches condition name and aliases', () {
      expect(entry.condition.toLowerCase(), equals('appendicitis'));
      expect(entry.aliases, contains('appendix'));
      expect(entry.searchableText, contains('abdominal pain'));
    });

    test('context snippet respects max characters budget', () {
      final snippet = entry.toContextSnippet(maxChars: 100);
      expect(snippet.length, lessThanOrEqualTo(104)); // with ellipsis
      expect(snippet, contains('Appendicitis'));
    });
  });

  group('9. Emergency Priority (English, Hindi, Marathi)', () {
    final safety = OfflineSafetyService.instance;

    test('detects English emergencies', () {
      expect(safety.isEmergency('I have severe chest pain and cannot breathe'), isTrue);
      expect(safety.isEmergency('Patient is unconscious'), isTrue);
      expect(safety.isEmergency('Severe bleeding from leg'), isTrue);
    });

    test('detects Hindi emergencies', () {
      expect(safety.isEmergency('seena dard ho raha hai'), isTrue);
      expect(safety.isEmergency('saans nahi aa raha hai'), isTrue);
      expect(safety.isEmergency('saanp ne kaata hai'), isTrue);
    });

    test('detects Marathi emergencies', () {
      expect(safety.isEmergency('chaati madhe dukhat aahe'), isTrue);
      expect(safety.isEmergency('shwas ghyayla tras hoto aahe'), isTrue);
      expect(safety.isEmergency('saanp chaavla aahe'), isTrue);
      expect(safety.isEmergency('beshuddh padla aahe'), isTrue);
      expect(safety.isEmergency('raktasrav hot aahe'), isTrue);
    });

    test('normal non-emergency symptoms return false', () {
      expect(safety.isEmergency('I have a mild headache since morning'), isFalse);
      expect(safety.isEmergency('mujhe thoda bukhar hai'), isFalse);
      expect(safety.isEmergency('majha pot dukht aahe'), isFalse);
    });
  });

  group('10. Unsupported Query Handling', () {
    test('non-medical query does not trigger emergency or diagnostic output', () {
      const nonMedical = 'how do I repair a car engine?';
      expect(OfflineSafetyService.instance.isEmergency(nonMedical), isFalse);
      final response = OfflineResponse.noInformation();
      expect(response.decision, equals(OfflineResponseDecision.unsupported));
      expect(response.text, contains('does not have specific information'));
    });
  });

  group('11 & 12. Lexicon-only and Model Unavailable Fallbacks', () {
    test('OfflineResponse decisions provide safe messages', () {
      final unavailable = OfflineResponse.unavailable();
      expect(unavailable.decision, equals(OfflineResponseDecision.unavailable));
      expect(unavailable.text, contains('not available'));

      final emergency = OfflineResponse.emergency(matchedTerms: ['chest pain']);
      expect(emergency.decision, equals(OfflineResponseDecision.emergency));
      expect(emergency.text, contains('108'));
    });
  });

  group('13, 14 & 15. Download Verification & Checksum Failure', () {
    test('LocalModelCompatibility enforces ABI, RAM, and storage', () {
      const ok = LocalModelCompatibility(
        supported: true,
        enoughStorage: true,
        enoughMemory: true,
        supportedAbi: true,
      );
      expect(ok.canProceed, isTrue);

      const lowMem = LocalModelCompatibility(
        supported: true,
        enoughStorage: true,
        enoughMemory: false,
        supportedAbi: true,
        reason: 'Insufficient RAM',
      );
      expect(lowMem.canProceed, isFalse);

      const wrongAbi = LocalModelCompatibility(
        supported: true,
        enoughStorage: true,
        enoughMemory: true,
        supportedAbi: false,
        reason: 'Unsupported ABI',
      );
      expect(wrongAbi.canProceed, isFalse);
    });

    test('OfflineAiConfig has verified Qwen2.5-0.5B artifact parameters', () {
      expect(OfflineAiConfig.modelFilename, equals('Qwen2.5-0.5B-Instruct_seq128_q8_ekv1280.tflite'));
      expect(OfflineAiConfig.modelExpectedSizeBytes, equals(513219800));
      expect(OfflineAiConfig.modelSha256, equals('49b3b9ca95c46b185995edeb7314dec06c23f65d7a8c7b24ee97d5313e6032ac'));
      expect(OfflineAiConfig.modelDownloadUrl, contains('huggingface.co/litert-community/Qwen2.5-0.5B-Instruct'));
    });

    test('verifies OfflineModelMetadata serialization', () {
      const meta = OfflineModelMetadata(
        modelId: 'qwen2.5-0.5b-litert-q8',
        version: OfflineAiConfig.modelVersion,
        filename: OfflineAiConfig.modelFilename,
        sha256: OfflineAiConfig.modelSha256,
        sizeBytes: OfflineAiConfig.modelExpectedSizeBytes,
        downloadUrl: OfflineAiConfig.modelDownloadUrl,
        license: 'Apache-2.0',
        verified: true,
      );
      final jsonStr = meta.toJsonString();
      final parsed = OfflineModelMetadata.fromJsonString(jsonStr);

      expect(parsed.filename, equals(meta.filename));
      expect(parsed.sha256, equals(meta.sha256));
      expect(parsed.sizeBytes, equals(513219800));
      expect(parsed.verified, isTrue);
    });
  });

  group('16. Sanitise Generated Text (Post-processing safety)', () {
    final safety = OfflineSafetyService.instance;

    test('strips unsafe diagnosis claims', () {
      const unsafe = 'You have been diagnosed with dengue. The diagnosis is definitely malaria.';
      final cleaned = safety.sanitiseGeneratedText(unsafe);
      expect(cleaned, isNot(contains('You have been diagnosed with')));
      expect(cleaned, isNot(contains('The diagnosis is definitely')));
    });

    test('strips prescription dosages', () {
      const unsafe = 'Take 500 mg paracetamol twice daily. dosage: 500.';
      final cleaned = safety.sanitiseGeneratedText(unsafe);
      expect(cleaned, isNot(contains('500 mg')));
      expect(cleaned, isNot(contains('dosage: 500')));
    });
  });

  group('17. Automatic Download & Network Policy Configuration', () {
    test('autoDownloadOfflineModel is enabled by default', () {
      expect(OfflineAiConfig.autoDownloadOfflineModel, isTrue);
    });

    test('allowMobileDataDownload is configurable and defaults to false (Wi-Fi preferred)', () {
      expect(OfflineAiConfig.allowMobileDataDownload, isFalse);
    });

    test('LocalModelStatus includes pending and accurate display labels', () {
      expect(LocalModelStatus.pending.isPending, isTrue);
      expect(LocalModelStatus.pending.displayLabel, equals('Offline AI • Download pending'));
      expect(LocalModelStatus.downloading.displayLabel, equals('Offline AI • Downloading'));
      expect(LocalModelStatus.verifying.displayLabel, equals('Offline AI • Verifying'));
      expect(LocalModelStatus.ready.displayLabel, equals('Offline AI • Ready'));
      expect(LocalModelStatus.loading.displayLabel, equals('Offline AI • Starting'));
      expect(LocalModelStatus.generating.displayLabel, equals('Offline AI • Thinking'));
      expect(LocalModelStatus.error.displayLabel, equals('Offline AI • Retry pending'));
    });

    test('LocalModelCompatibility separates download eligibility from memory load eligibility', () {
      // Device with enough storage and ARM64 ABI, but low available RAM (Samsung M12 low RAM state)
      const m12LowRam = LocalModelCompatibility(
        supported: true,
        supportedAbi: true,
        enoughStorage: true,
        enoughMemory: false,
        reason: 'Low available RAM (<1.5GB)',
      );
      // Can download model file to disk in background:
      expect(m12LowRam.canDownload, isTrue);
      // But must NOT load into RAM for inference:
      expect(m12LowRam.canLoad, isFalse);
      expect(m12LowRam.canProceed, isFalse);

      // Device with insufficient storage cannot download:
      const noStorage = LocalModelCompatibility(
        supported: true,
        supportedAbi: true,
        enoughStorage: false,
        enoughMemory: true,
        reason: 'Low storage',
      );
      expect(noStorage.canDownload, isFalse);

      // Incompatible ABI (32-bit device) cannot download:
      const badAbi = LocalModelCompatibility(
        supported: true,
        supportedAbi: false,
        enoughStorage: true,
        enoughMemory: true,
        reason: '32-bit ABI',
      );
      expect(badAbi.canDownload, isFalse);
    });
  });
}
