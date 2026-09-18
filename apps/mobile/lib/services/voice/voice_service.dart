import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../core/native/nimmy_bridge.dart';

typedef TranscriptCallback = void Function(String text, bool isFinal);

class VoiceService {
  VoiceService({SpeechToText? speech}) : _speech = speech ?? SpeechToText();

  final SpeechToText _speech;
  bool _initialized = false;

  bool get isListening => _speech.isListening;

  Future<bool> initialize() async {
    if (_initialized) return true;
    _initialized = await _speech.initialize();
    return _initialized;
  }

  Future<bool> startListening(TranscriptCallback onTranscript) async {
    final ready = await initialize();
    if (!ready) return false;

    await _speech.listen(
      onResult: (SpeechRecognitionResult result) {
        onTranscript(result.recognizedWords, result.finalResult);
      },
      listenOptions: SpeechListenOptions(
        partialResults: true,
        cancelOnError: true,
        listenMode: ListenMode.confirmation,
      ),
    );
    return true;
  }

  Future<void> stopListening() => _speech.stop();

  Future<void> cancelListening() => _speech.cancel();

  Future<void> speak(String text) async {
    await NimmyNativeBridge.speak(text);
  }

  Future<void> stopSpeaking() async {
    await NimmyNativeBridge.stopSpeaking();
  }
}
