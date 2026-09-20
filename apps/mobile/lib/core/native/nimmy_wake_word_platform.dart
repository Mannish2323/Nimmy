import 'package:flutter/services.dart';

import '../../models/wake_word.dart';
import '../../services/voice/wake_word_platform.dart';

class NimmyNativeWakeWordPlatform implements WakeWordPlatform {
  static const _methodChannel = MethodChannel('ai.nimmy.nimmy/bridge');
  static const _eventChannel = EventChannel('ai.nimmy.nimmy/wake_events');

  Stream<WakeWordEvent>? _events;

  @override
  Stream<WakeWordEvent> get events => _events ??= _eventChannel
      .receiveBroadcastStream()
      .where((event) => event is Map)
      .map(
        (event) => WakeWordEvent.fromMap(
          Map<Object?, Object?>.from(event as Map),
        ),
      )
      .asBroadcastStream();

  @override
  Future<WakeWordCapabilities> capabilities() async {
    try {
      final value = await _methodChannel.invokeMapMethod<Object?, Object?>(
        'getWakeWordCapabilities',
      );
      if (value == null) return const WakeWordCapabilities.unavailable();
      return WakeWordCapabilities.fromMap(value);
    } on PlatformException {
      return const WakeWordCapabilities.unavailable();
    } on MissingPluginException {
      return const WakeWordCapabilities.unavailable();
    }
  }

  @override
  Future<WakeWordOperationResult> start({double threshold = 0.50}) {
    return _operation('startWakeWordDetection', {'threshold': threshold});
  }

  @override
  Future<WakeWordOperationResult> stop() {
    return _operation('stopWakeWordDetection');
  }

  @override
  Future<WakeWordOperationResult> pause({required String reason}) {
    return _operation('pauseWakeWordDetection', {'reason': reason});
  }

  @override
  Future<WakeWordOperationResult> resume() {
    return _operation('resumeWakeWordDetection');
  }

  Future<WakeWordOperationResult> _operation(
    String method, [
    Map<String, Object?>? arguments,
  ]) async {
    try {
      final value = await _methodChannel.invokeMapMethod<Object?, Object?>(
        method,
        arguments,
      );
      if (value == null) {
        return const WakeWordOperationResult(
          success: false,
          errorCode: 'NATIVE_BRIDGE_UNAVAILABLE',
          message: 'The Android wake-word bridge did not return a result.',
          recovery: 'Use the microphone button or type your command.',
        );
      }
      return WakeWordOperationResult.fromMap(value);
    } on PlatformException catch (error) {
      return WakeWordOperationResult(
        success: false,
        errorCode: error.code,
        message: error.message,
        recovery: 'Use the microphone button or type your command.',
      );
    } on MissingPluginException {
      return const WakeWordOperationResult(
        success: false,
        errorCode: 'NATIVE_BRIDGE_UNAVAILABLE',
        message: 'Hands-free wake detection is available only on Android.',
        recovery: 'Use the microphone button or type your command.',
      );
    }
  }
}
