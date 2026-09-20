enum VoiceInteractionState {
  idle,
  wakeDetected,
  listening,
  transcribing,
  thinking,
  confirmation,
  executing,
  speaking,
  success,
  error,
  cancelled,
  offline,
}

enum MicrophoneActivity { off, ready, wakeDetection, listening, processing }

extension VoiceInteractionStatePolicy on VoiceInteractionState {
  Duration? get timeout => switch (this) {
    VoiceInteractionState.wakeDetected => const Duration(seconds: 6),
    VoiceInteractionState.listening => const Duration(seconds: 18),
    VoiceInteractionState.transcribing => const Duration(seconds: 8),
    VoiceInteractionState.thinking => const Duration(seconds: 30),
    VoiceInteractionState.confirmation => const Duration(seconds: 20),
    VoiceInteractionState.executing => const Duration(seconds: 30),
    VoiceInteractionState.speaking => const Duration(seconds: 45),
    VoiceInteractionState.success ||
    VoiceInteractionState.error ||
    VoiceInteractionState.cancelled => const Duration(seconds: 3),
    VoiceInteractionState.idle || VoiceInteractionState.offline => null,
  };

  bool get canCancel => switch (this) {
    VoiceInteractionState.wakeDetected ||
    VoiceInteractionState.listening ||
    VoiceInteractionState.transcribing ||
    VoiceInteractionState.thinking ||
    VoiceInteractionState.confirmation ||
    VoiceInteractionState.speaking => true,
    _ => false,
  };

  MicrophoneActivity get microphoneActivity => switch (this) {
    VoiceInteractionState.idle => MicrophoneActivity.ready,
    VoiceInteractionState.wakeDetected => MicrophoneActivity.processing,
    VoiceInteractionState.listening => MicrophoneActivity.listening,
    VoiceInteractionState.transcribing ||
    VoiceInteractionState.thinking ||
    VoiceInteractionState.confirmation ||
    VoiceInteractionState.executing ||
    VoiceInteractionState.speaking ||
    VoiceInteractionState.success ||
    VoiceInteractionState.error ||
    VoiceInteractionState.cancelled => MicrophoneActivity.processing,
    VoiceInteractionState.offline => MicrophoneActivity.off,
  };
}

enum VoiceFailureCode {
  micPermissionDenied,
  micUnavailable,
  wakeEngineUnavailable,
  sttFailed,
  sttTimeout,
  noSpeech,
  networkError,
  aiTimeout,
  invalidIntent,
  toolValidationFailed,
  confirmationTimeout,
  toolExecutionFailed,
  ttsFailed,
  backgroundRestriction,
  batteryRestriction,
  storageError,
  offline,
  unknown,
}

enum VoiceRecoveryAction { retry, cancel, edit, typeInstead, openSettings }

class VoiceFailure {
  const VoiceFailure({
    required this.code,
    required this.message,
    required this.recovery,
    required this.action,
  });

  final VoiceFailureCode code;
  final String message;
  final String recovery;
  final VoiceRecoveryAction action;
}
