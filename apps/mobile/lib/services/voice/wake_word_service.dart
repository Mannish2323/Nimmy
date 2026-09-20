import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/logging/nimmy_logger.dart';
import '../../models/wake_word.dart';
import 'wake_word_platform.dart';

class WakeWordService extends ChangeNotifier {
  WakeWordService({required WakeWordPlatform platform}) : _platform = platform;

  final WakeWordPlatform _platform;
  final _detections = StreamController<WakeWordEvent>.broadcast();
  StreamSubscription<WakeWordEvent>? _subscription;

  WakeWordCapabilities _capabilities =
      const WakeWordCapabilities.unavailable();
  WakeWordStatus _status = WakeWordStatus.unsupported;
  String? _errorCode;
  String? _message;
  String? _recovery;

  WakeWordCapabilities get capabilities => _capabilities;
  WakeWordStatus get status => _status;
  String? get errorCode => _errorCode;
  String? get message => _message;
  String? get recovery => _recovery;
  Stream<WakeWordEvent> get detections => _detections.stream;

  bool get isEnabled =>
      _capabilities.serviceRunning ||
      switch (_status) {
        WakeWordStatus.starting ||
        WakeWordStatus.active ||
        WakeWordStatus.paused ||
        WakeWordStatus.wakeDetected => true,
        _ => false,
      };

  bool get canEnable =>
      _capabilities.supported &&
      _capabilities.local &&
      _capabilities.modelInstalled &&
      _capabilities.featureModelsInstalled;

  Future<void> initialize() async {
    _subscription ??= _platform.events.listen(
      _handleEvent,
      onError: (Object error, StackTrace stackTrace) {
        _status = WakeWordStatus.error;
        _errorCode = 'WAKE_EVENT_STREAM_FAILED';
        _message = 'Wake detection status is unavailable.';
        _recovery = 'Restart Nimmy or use the microphone button.';
        NimmyLogger.error(
          'Wake-word event stream failed',
          category: LogCategory.voice,
          error: error,
          stackTrace: stackTrace,
        );
        notifyListeners();
      },
    );
    await refreshCapabilities();
  }

  Future<void> refreshCapabilities() async {
    _capabilities = await _platform.capabilities();
    _status = _capabilities.status;
    notifyListeners();
  }

  Future<WakeWordOperationResult> enable({double threshold = 0.50}) async {
    _clearError();
    final result = await _platform.start(threshold: threshold);
    _applyOperation(result);
    if (result.success) {
      _status = result.status ?? WakeWordStatus.starting;
    }
    await _refreshAfterOperation(failed: !result.success);
    return result;
  }

  Future<WakeWordOperationResult> disable() async {
    final result = await _platform.stop();
    _applyOperation(result);
    if (result.success) _status = WakeWordStatus.stopped;
    await _refreshAfterOperation(failed: !result.success);
    return result;
  }

  Future<WakeWordOperationResult> pause({required String reason}) async {
    if (!isEnabled) {
      return const WakeWordOperationResult(
        success: false,
        errorCode: 'SERVICE_NOT_RUNNING',
        message: 'Wake detection is not active.',
        recovery: 'Enable wake detection first.',
      );
    }
    final result = await _platform.pause(reason: reason);
    _applyOperation(result);
    if (result.success) {
      _status = WakeWordStatus.paused;
      notifyListeners();
      // The native AudioRecord is released asynchronously after cancellation.
      await Future<void>.delayed(const Duration(milliseconds: 180));
    }
    return result;
  }

  Future<WakeWordOperationResult> resume() async {
    if (!isEnabled) {
      return const WakeWordOperationResult(
        success: false,
        errorCode: 'SERVICE_NOT_RUNNING',
        message: 'Wake detection is not active.',
        recovery: 'Enable wake detection first.',
      );
    }
    final result = await _platform.resume();
    _applyOperation(result);
    if (result.success) _status = WakeWordStatus.starting;
    notifyListeners();
    return result;
  }

  void _handleEvent(WakeWordEvent event) {
    _status = event.status;
    if (event.isError) {
      _errorCode = event.errorCode;
      _message = event.message;
      _recovery = event.recovery;
      NimmyLogger.warn(
        'Wake-word service error',
        category: LogCategory.voice,
        context: {'errorCode': event.errorCode},
      );
    } else if (event.isDetection) {
      _clearError();
      _detections.add(event);
      NimmyLogger.info(
        'Local wake phrase detected',
        category: LogCategory.voice,
        context: {'score': event.score, 'local': event.local},
      );
    }
    notifyListeners();
  }

  void _applyOperation(WakeWordOperationResult result) {
    if (result.success) {
      _clearError();
      return;
    }
    _status = WakeWordStatus.error;
    _errorCode = result.errorCode;
    _message = result.message;
    _recovery = result.recovery;
    notifyListeners();
  }

  Future<void> _refreshAfterOperation({bool failed = false}) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    _capabilities = await _platform.capabilities();
    if (failed) {
      _status = WakeWordStatus.error;
    } else {
      _status = _capabilities.status;
    }
    notifyListeners();
  }

  void _clearError() {
    _errorCode = null;
    _message = null;
    _recovery = null;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _detections.close();
    super.dispose();
  }
}
