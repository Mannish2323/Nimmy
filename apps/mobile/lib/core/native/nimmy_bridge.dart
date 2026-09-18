// 🟣 NIMMY — Flutter Dart Platform Bridge to Kotlin Android Core
// ==============================================================
import 'package:flutter/services.dart';

class NimmyNativeBridge {
  static const MethodChannel _channel = MethodChannel('ai.nimmy.nimmy/bridge');

  /// Speak through Android's visible system TTS engine. The call is best
  /// effort; the text response remains the source of truth if TTS is absent.
  static Future<bool> speak(String text) async {
    try {
      final result = await _channel.invokeMethod<bool>('speak', {'text': text});
      return result ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  static Future<bool> stopSpeaking() async {
    try {
      final result = await _channel.invokeMethod<bool>('stopSpeaking');
      return result ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  /// Deferred until the visible, user-started recording milestone.
  static Future<bool> startBackgroundService() async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'startBackgroundService',
      );
      return result ?? false;
    } on PlatformException {
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Deferred until the visible, user-started recording milestone.
  static Future<bool> stopBackgroundService() async {
    try {
      final result = await _channel.invokeMethod<bool>('stopBackgroundService');
      return result ?? false;
    } on PlatformException {
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Check the deferred recording service status.
  static Future<bool> isServiceRunning() async {
    try {
      final result = await _channel.invokeMethod<bool>('isServiceRunning');
      return result ?? false;
    } on PlatformException {
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Deferred until visible foreground recording is implemented.
  static Future<Map<String, dynamic>> startVoiceRecording() async {
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>(
        'startVoiceRecording',
      );
      return result ?? {'status': 'unavailable', 'filePath': null};
    } on PlatformException catch (e) {
      return {'status': 'error', 'message': e.message};
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }

  /// Deferred until visible foreground recording is implemented.
  static Future<Map<String, dynamic>> stopVoiceRecording() async {
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>(
        'stopVoiceRecording',
      );
      return result ??
          {'status': 'unavailable', 'filePath': null, 'fileSizeBytes': 0};
    } on PlatformException catch (e) {
      return {'status': 'error', 'message': e.message};
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }

  /// Schedule an inexact, user-confirmed Android alarm.
  static Future<Map<String, dynamic>> scheduleAlarm({
    required String title,
    required String body,
    required DateTime scheduledTime,
    int? id,
  }) async {
    try {
      final result = await _channel
          .invokeMapMethod<String, dynamic>('scheduleAlarm', {
            'title': title,
            'body': body,
            'triggerAtMillis': scheduledTime.millisecondsSinceEpoch,
            'id': id ?? scheduledTime.millisecondsSinceEpoch ~/ 1000,
          });
      return result ?? {'scheduled': false};
    } on PlatformException catch (e) {
      return {'scheduled': false, 'error': e.message};
    } catch (e) {
      return {'scheduled': false, 'error': e.toString()};
    }
  }

  static Future<bool> cancelAlarm(int id) async {
    try {
      final result = await _channel.invokeMethod<bool>('cancelAlarm', {
        'id': id,
      });
      return result ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  /// Retrieve device hardware telemetry when the Android bridge is available.
  static Future<Map<String, dynamic>> getDeviceInfo() async {
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>(
        'getDeviceInfo',
      );
      return result ??
          {'available': false, 'error': 'NATIVE_BRIDGE_UNAVAILABLE'};
    } on PlatformException {
      return {'available': false, 'error': 'NATIVE_BRIDGE_UNAVAILABLE'};
    } catch (_) {
      return {'available': false, 'error': 'NATIVE_BRIDGE_UNAVAILABLE'};
    }
  }

  /// Launch external application by package name
  static Future<bool> launchApp(String packageName) async {
    try {
      final result = await _channel.invokeMethod<bool>('launchApp', {
        'packageName': packageName,
      });
      return result ?? false;
    } on PlatformException {
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Check runtime audio and notification permissions
  static Future<Map<String, bool>> checkPermissions() async {
    try {
      final result = await _channel.invokeMapMethod<String, bool>(
        'checkPermissions',
      );
      return result ?? {'recordAudio': false, 'notifications': false};
    } on PlatformException {
      return {'recordAudio': false, 'notifications': false};
    } catch (_) {
      return {'recordAudio': false, 'notifications': false};
    }
  }
}
