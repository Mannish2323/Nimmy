// 🟣 NIMMY — Flutter Dart Platform Bridge to Kotlin Android Core
// ==============================================================
import 'package:flutter/services.dart';

class NimmyNativeBridge {
  static const MethodChannel _channel = MethodChannel('ai.nimmy.nimmy/bridge');

  /// Start native Android foreground daemon service
  static Future<bool> startBackgroundService() async {
    try {
      final result = await _channel.invokeMethod<bool>('startBackgroundService');
      return result ?? false;
    } on PlatformException {
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Stop native Android foreground daemon service
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

  /// Check if the native foreground service is actively running
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

  /// Start hardware microphone capture via AudioRecord daemon
  static Future<Map<String, dynamic>> startVoiceRecording() async {
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>('startVoiceRecording');
      return result ?? {'status': 'error', 'filePath': null};
    } on PlatformException catch (e) {
      return {'status': 'error', 'message': e.message};
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }

  /// Stop hardware microphone capture and retrieve recorded PCM file metadata
  static Future<Map<String, dynamic>> stopVoiceRecording() async {
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>('stopVoiceRecording');
      return result ?? {'status': 'stopped', 'filePath': null, 'fileSizeBytes': 0};
    } on PlatformException catch (e) {
      return {'status': 'error', 'message': e.message};
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }

  /// Schedule exact hardware alarm using AlarmManager
  static Future<Map<String, dynamic>> scheduleAlarm({
    required String title,
    required String body,
    required DateTime scheduledTime,
    int? id,
  }) async {
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>('scheduleAlarm', {
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

  /// Retrieve device hardware telemetry
  static Future<Map<String, dynamic>> getDeviceInfo() async {
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>('getDeviceInfo');
      return result ?? {
        'manufacturer': 'LocalHost',
        'model': 'Simulation',
        'batteryLevel': 100,
        'isBackgroundServiceRunning': false,
      };
    } on PlatformException {
      return {
        'manufacturer': 'LocalHost',
        'model': 'Simulation',
        'batteryLevel': 100,
        'isBackgroundServiceRunning': false,
      };
    } catch (_) {
      return {
        'manufacturer': 'LocalHost',
        'model': 'Simulation',
        'batteryLevel': 100,
        'isBackgroundServiceRunning': false,
      };
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
      final result = await _channel.invokeMapMethod<String, bool>('checkPermissions');
      return result ?? {'recordAudio': false, 'notifications': false};
    } on PlatformException {
      return {'recordAudio': false, 'notifications': false};
    } catch (_) {
      return {'recordAudio': false, 'notifications': false};
    }
  }
}
