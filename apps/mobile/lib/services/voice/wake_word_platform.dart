import '../../models/wake_word.dart';

abstract interface class WakeWordPlatform {
  Stream<WakeWordEvent> get events;

  Future<WakeWordCapabilities> capabilities();

  Future<WakeWordOperationResult> start({double threshold = 0.50});

  Future<WakeWordOperationResult> stop();

  Future<WakeWordOperationResult> pause({required String reason});

  Future<WakeWordOperationResult> resume();
}
