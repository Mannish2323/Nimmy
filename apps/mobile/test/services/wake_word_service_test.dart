import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:nimmy/models/wake_word.dart';
import 'package:nimmy/services/voice/wake_word_platform.dart';
import 'package:nimmy/services/voice/wake_word_service.dart';

void main() {
  test('forwards local detections and updates active status', () async {
    final platform = _FakeWakeWordPlatform();
    final service = WakeWordService(platform: platform);
    final detections = <WakeWordEvent>[];
    final subscription = service.detections.listen(detections.add);
    addTearDown(() async {
      await subscription.cancel();
      service.dispose();
      await platform.dispose();
    });

    await service.initialize();
    final result = await service.enable();
    platform.eventsController.add(
      WakeWordEvent(
        type: 'wake_detected',
        status: WakeWordStatus.wakeDetected,
        timestamp: DateTime.utc(2026, 9, 20),
        local: true,
        phrase: 'Hey Nimmy',
        score: 0.91,
      ),
    );
    await Future<void>.delayed(Duration.zero);

    expect(result.success, isTrue);
    expect(service.status, WakeWordStatus.wakeDetected);
    expect(detections.single.phrase, 'Hey Nimmy');
  });
}

class _FakeWakeWordPlatform implements WakeWordPlatform {
  final eventsController = StreamController<WakeWordEvent>.broadcast();

  @override
  Stream<WakeWordEvent> get events => eventsController.stream;

  @override
  Future<WakeWordCapabilities> capabilities() async => WakeWordCapabilities(
    supported: true,
    local: true,
    serviceRunning: false,
    status: WakeWordStatus.stopped,
    microphonePermission: true,
    notificationPermission: true,
    modelInstalled: true,
    featureModelsInstalled: true,
    missingAssets: const [],
    phrases: const ['Hey Nimmy', 'Nimmy'],
    requiresVisibleNotification: true,
    canAutoStartAfterBoot: false,
  );

  @override
  Future<WakeWordOperationResult> start({double threshold = 0.5}) async =>
      const WakeWordOperationResult(
        success: true,
        status: WakeWordStatus.active,
      );

  @override
  Future<WakeWordOperationResult> stop() async => const WakeWordOperationResult(
    success: true,
    status: WakeWordStatus.stopped,
  );

  @override
  Future<WakeWordOperationResult> pause({required String reason}) async =>
      const WakeWordOperationResult(
        success: true,
        status: WakeWordStatus.paused,
      );

  @override
  Future<WakeWordOperationResult> resume() async =>
      const WakeWordOperationResult(
        success: true,
        status: WakeWordStatus.active,
      );

  Future<void> dispose() => eventsController.close();
}
