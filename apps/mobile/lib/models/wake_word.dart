enum WakeWordStatus {
  unsupported,
  stopped,
  starting,
  active,
  paused,
  wakeDetected,
  error,
}

WakeWordStatus wakeWordStatusFromWire(Object? value) {
  return switch (value?.toString()) {
    'stopped' => WakeWordStatus.stopped,
    'starting' => WakeWordStatus.starting,
    'active' => WakeWordStatus.active,
    'paused' => WakeWordStatus.paused,
    'wake_detected' => WakeWordStatus.wakeDetected,
    'error' => WakeWordStatus.error,
    _ => WakeWordStatus.unsupported,
  };
}

class WakeWordCapabilities {
  const WakeWordCapabilities({
    required this.supported,
    required this.local,
    required this.serviceRunning,
    required this.status,
    required this.microphonePermission,
    required this.notificationPermission,
    required this.modelInstalled,
    required this.featureModelsInstalled,
    required this.missingAssets,
    required this.phrases,
    required this.requiresVisibleNotification,
    required this.canAutoStartAfterBoot,
  });

  const WakeWordCapabilities.unavailable()
    : supported = false,
      local = false,
      serviceRunning = false,
      status = WakeWordStatus.unsupported,
      microphonePermission = false,
      notificationPermission = false,
      modelInstalled = false,
      featureModelsInstalled = false,
      missingAssets = const [],
      phrases = const ['Hey Nimmy', 'Nimmy'],
      requiresVisibleNotification = true,
      canAutoStartAfterBoot = false;

  final bool supported;
  final bool local;
  final bool serviceRunning;
  final WakeWordStatus status;
  final bool microphonePermission;
  final bool notificationPermission;
  final bool modelInstalled;
  final bool featureModelsInstalled;
  final List<String> missingAssets;
  final List<String> phrases;
  final bool requiresVisibleNotification;
  final bool canAutoStartAfterBoot;

  bool get ready =>
      supported &&
      local &&
      microphonePermission &&
      notificationPermission &&
      modelInstalled &&
      featureModelsInstalled;

  factory WakeWordCapabilities.fromMap(Map<Object?, Object?> map) {
    return WakeWordCapabilities(
      supported: map['supported'] == true,
      local: map['local'] == true,
      serviceRunning: map['serviceRunning'] == true,
      status: wakeWordStatusFromWire(map['status']),
      microphonePermission: map['microphonePermission'] == true,
      notificationPermission: map['notificationPermission'] == true,
      modelInstalled: map['modelInstalled'] == true,
      featureModelsInstalled: map['featureModelsInstalled'] == true,
      missingAssets: (map['missingAssets'] as List? ?? const [])
          .map((item) => item.toString())
          .toList(growable: false),
      phrases: (map['phrases'] as List? ?? const ['Hey Nimmy', 'Nimmy'])
          .map((item) => item.toString())
          .toList(growable: false),
      requiresVisibleNotification:
          map['requiresVisibleNotification'] != false,
      canAutoStartAfterBoot: map['canAutoStartAfterBoot'] == true,
    );
  }
}

class WakeWordEvent {
  const WakeWordEvent({
    required this.type,
    required this.status,
    required this.timestamp,
    required this.local,
    this.phrase,
    this.score,
    this.reason,
    this.errorCode,
    this.message,
    this.recovery,
  });

  final String type;
  final WakeWordStatus status;
  final DateTime timestamp;
  final bool local;
  final String? phrase;
  final double? score;
  final String? reason;
  final String? errorCode;
  final String? message;
  final String? recovery;

  bool get isDetection => type == 'wake_detected';
  bool get isError => type == 'error';

  factory WakeWordEvent.fromMap(Map<Object?, Object?> map) {
    final timestamp = switch (map['timestamp']) {
      int value => DateTime.fromMillisecondsSinceEpoch(value),
      num value => DateTime.fromMillisecondsSinceEpoch(value.toInt()),
      _ => DateTime.now(),
    };
    return WakeWordEvent(
      type: map['type']?.toString() ?? 'status',
      status: wakeWordStatusFromWire(map['status']),
      timestamp: timestamp,
      local: map['local'] == true,
      phrase: map['phrase']?.toString(),
      score: (map['score'] as num?)?.toDouble(),
      reason: map['reason']?.toString(),
      errorCode: map['errorCode']?.toString(),
      message: map['message']?.toString(),
      recovery: map['recovery']?.toString(),
    );
  }
}

class WakeWordOperationResult {
  const WakeWordOperationResult({
    required this.success,
    this.status,
    this.errorCode,
    this.message,
    this.recovery,
  });

  final bool success;
  final WakeWordStatus? status;
  final String? errorCode;
  final String? message;
  final String? recovery;

  factory WakeWordOperationResult.fromMap(Map<Object?, Object?> map) {
    return WakeWordOperationResult(
      success: map['success'] == true,
      status: map['status'] == null
          ? null
          : wakeWordStatusFromWire(map['status']),
      errorCode: map['errorCode']?.toString(),
      message: map['message']?.toString(),
      recovery: map['recovery']?.toString(),
    );
  }
}
