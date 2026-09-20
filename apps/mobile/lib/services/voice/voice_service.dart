import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../core/native/nimmy_bridge.dart';
import '../../models/voice_interaction_state.dart';

typedef TranscriptCallback = void Function(String text, bool isFinal);
typedef VoiceCaptureErrorCallback = void Function(VoiceCaptureError error);
typedef VoiceCaptureStatusCallback = void Function(String status);
typedef VoiceSoundLevelCallback = void Function(double level);

class VoiceCaptureError {
  const VoiceCaptureError({
    required this.code,
    required this.message,
    required this.permanent,
  });

  final VoiceFailureCode code;
  final String message;
  final bool permanent;
}

enum VoiceCaptureStartStatus { started, unavailable, alreadyListening, failed }

class VoiceCaptureStartResult {
  const VoiceCaptureStartResult(this.status, {this.error});

  final VoiceCaptureStartStatus status;
  final VoiceCaptureError? error;

  bool get started => status == VoiceCaptureStartStatus.started;
}

abstract interface class VoiceGateway {
  bool get isListening;

  Future<VoiceCaptureStartResult> startCommandCapture({
    required TranscriptCallback onTranscript,
    required VoiceCaptureErrorCallback onError,
    required VoiceCaptureStatusCallback onStatus,
    VoiceSoundLevelCallback? onSoundLevel,
    bool onDevice,
    Duration listenFor,
    Duration pauseFor,
  });

  Future<void> stopListening();

  Future<void> cancelListening();

  Future<bool> speak(String text);

  Future<bool> stopSpeaking();
}

class VoiceService implements VoiceGateway {
  VoiceService({SpeechToText? speech}) : _speech = speech ?? SpeechToText();

  final SpeechToText _speech;
  bool _initialized = false;
  VoiceCaptureErrorCallback? _onError;
  VoiceCaptureStatusCallback? _onStatus;

  @override
  bool get isListening => _speech.isListening;

  Future<bool> initialize() async {
    if (_initialized) return true;
    _initialized = await _speech.initialize(
      onError: _handleSpeechError,
      onStatus: (status) => _onStatus?.call(status),
    );
    return _initialized;
  }

  @override
  Future<VoiceCaptureStartResult> startCommandCapture({
    required TranscriptCallback onTranscript,
    required VoiceCaptureErrorCallback onError,
    required VoiceCaptureStatusCallback onStatus,
    VoiceSoundLevelCallback? onSoundLevel,
    bool onDevice = false,
    Duration listenFor = const Duration(seconds: 15),
    Duration pauseFor = const Duration(seconds: 2),
  }) async {
    if (_speech.isListening) {
      return const VoiceCaptureStartResult(
        VoiceCaptureStartStatus.alreadyListening,
      );
    }

    _onError = onError;
    _onStatus = onStatus;
    final ready = await initialize();
    if (!ready) {
      return const VoiceCaptureStartResult(
        VoiceCaptureStartStatus.unavailable,
        error: VoiceCaptureError(
          code: VoiceFailureCode.micUnavailable,
          message: 'Speech recognition is unavailable on this device.',
          permanent: true,
        ),
      );
    }

    try {
      await _speech.listen(
        onResult: (SpeechRecognitionResult result) {
          onTranscript(result.recognizedWords, result.finalResult);
        },
        onSoundLevelChange: onSoundLevel,
        listenOptions: SpeechListenOptions(
          partialResults: true,
          cancelOnError: true,
          onDevice: onDevice,
          listenMode: ListenMode.dictation,
          localeId: 'en_IN',
          listenFor: listenFor,
          pauseFor: pauseFor,
        ),
      );
      return const VoiceCaptureStartResult(VoiceCaptureStartStatus.started);
    } catch (error) {
      final failure = VoiceCaptureError(
        code: VoiceFailureCode.sttFailed,
        message: 'Speech recognition could not start.',
        permanent: false,
      );
      onError(failure);
      return VoiceCaptureStartResult(
        VoiceCaptureStartStatus.failed,
        error: failure,
      );
    }
  }

  /// Compatibility wrapper for existing tap-to-talk callers.
  Future<bool> startListening(TranscriptCallback onTranscript) async {
    final result = await startCommandCapture(
      onTranscript: onTranscript,
      onError: (_) {},
      onStatus: (_) {},
    );
    return result.started;
  }

  @override
  Future<void> stopListening() => _speech.stop();

  @override
  Future<void> cancelListening() => _speech.cancel();

  @override
  Future<bool> speak(String text) => NimmyNativeBridge.speak(text);

  @override
  Future<bool> stopSpeaking() => NimmyNativeBridge.stopSpeaking();

  void _handleSpeechError(SpeechRecognitionError error) {
    final normalized = error.errorMsg.toLowerCase();
    final code = switch (normalized) {
      String value when value.contains('permission') =>
        VoiceFailureCode.micPermissionDenied,
      String value when value.contains('network') =>
        VoiceFailureCode.networkError,
      String value when value.contains('timeout') =>
        VoiceFailureCode.sttTimeout,
      String value when value.contains('no_match') ||
          value.contains('no speech') =>
        VoiceFailureCode.noSpeech,
      String value when value.contains('busy') ||
          value.contains('audio') =>
        VoiceFailureCode.micUnavailable,
      _ => VoiceFailureCode.sttFailed,
    };
    _onError?.call(
      VoiceCaptureError(
        code: code,
        message: error.errorMsg,
        permanent: error.permanent,
      ),
    );
  }
}
