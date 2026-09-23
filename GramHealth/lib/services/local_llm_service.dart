import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

import '../config/offline_ai_config.dart';

/// Abstract wrapper around the LiteRT-LM runtime.
///
/// Implementation uses a Flutter method-channel bridge to native Android code
/// (see android/src/main/kotlin/com/gramhealth/offline_llm/).
///
/// The abstraction ensures the LiteRT-LM runtime can be swapped without
/// touching any Flutter service that calls this class.
abstract class LocalLlmService {
  Future<void> initialize({required String modelPath});
  Future<void> dispose();
  Future<bool> isReady();

  /// Stream generated tokens progressively.
  ///
  /// [prompt] is the full user + context prompt.
  /// [systemPrompt] is the strict instruction prefix.
  Stream<String> generate({
    required String prompt,
    required String systemPrompt,
  });
}

/// Production implementation backed by the native LiteRT-LM Android SDK
/// via a Flutter method channel.
///
/// Channel name: `gramhealth/offline_llm`
///
/// The Android Kotlin counterpart lives in:
///   android/src/main/kotlin/com/gramhealth/GramhealthLlmPlugin.kt
class LiteRtLmService implements LocalLlmService {
  static const _channel = MethodChannel('gramhealth/offline_llm');
  static const _tokenChannel = EventChannel('gramhealth/offline_llm_tokens');

  bool _ready = false;
  StreamSubscription<dynamic>? _activeSub;
  bool _generating = false;

  @override
  Future<void> initialize({required String modelPath}) async {
    if (!Platform.isAndroid) {
      throw UnsupportedError('LiteRT-LM is only supported on Android.');
    }
    try {
      await _channel.invokeMethod<void>('initialize', {
        'modelPath': modelPath,
        'maxTokens': OfflineAiConfig.maxNewTokens,
        'temperature': OfflineAiConfig.temperature,
        'topP': OfflineAiConfig.topP,
        'topK': OfflineAiConfig.topK,
      });
      _ready = true;
    } on PlatformException catch (e) {
      _ready = false;
      throw LocalLlmException(
        'Failed to initialize LiteRT-LM: ${e.message}',
        platformCode: e.code,
      );
    }
  }

  @override
  Future<void> dispose() async {
    _ready = false;
    await _activeSub?.cancel();
    _activeSub = null;
    _generating = false;
    try {
      await _channel.invokeMethod<void>('dispose');
    } catch (_) {
      // Ignore errors during disposal.
    }
  }

  @override
  Future<bool> isReady() async => _ready;

  @override
  Stream<String> generate({
    required String prompt,
    required String systemPrompt,
  }) {
    if (!_ready) {
      return Stream.error(
        const LocalLlmException('Model is not initialized.'),
      );
    }
    if (_generating) {
      return Stream.error(
        const LocalLlmException(
          'A generation is already in progress. Cancel it first.',
        ),
      );
    }

    final controller = StreamController<String>();

    _generating = true;

    // Start generation on the native side asynchronously.
    _channel
        .invokeMethod<void>('generate', {
          'systemPrompt': systemPrompt,
          'prompt': prompt,
        })
        .catchError((Object e) {
          _generating = false;
          if (!controller.isClosed) {
            controller.addError(
              LocalLlmException('Generation start failed: $e'),
            );
            controller.close();
          }
        });

    // Subscribe to the token event channel.
    _activeSub = _tokenChannel.receiveBroadcastStream().listen(
      (dynamic event) {
        if (event is String) {
          if (event == '__EOS__') {
            _generating = false;
            if (!controller.isClosed) controller.close();
            _activeSub?.cancel();
          } else {
            if (!controller.isClosed) controller.add(event);
          }
        }
      },
      onError: (Object err) {
        _generating = false;
        if (!controller.isClosed) {
          controller.addError(LocalLlmException('Token stream error: $err'));
          controller.close();
        }
      },
      cancelOnError: true,
    );

    return controller.stream;
  }

  /// Attempt to cancel an in-progress generation.
  Future<void> cancel() async {
    if (!_generating) return;
    try {
      await _channel.invokeMethod<void>('cancel');
    } catch (_) {}
    _generating = false;
    await _activeSub?.cancel();
  }

  bool get isGenerating => _generating;
}

/// Thrown when the local LLM encounters a runtime error.
class LocalLlmException implements Exception {
  const LocalLlmException(this.message, {this.platformCode});
  final String message;
  final String? platformCode;

  @override
  String toString() => platformCode != null
      ? 'LocalLlmException[$platformCode]: $message'
      : 'LocalLlmException: $message';
}
