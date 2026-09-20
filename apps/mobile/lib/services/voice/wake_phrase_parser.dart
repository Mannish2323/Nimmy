class WakePhraseParser {
  const WakePhraseParser();

  static final _leadingWakePhrase = RegExp(
    r'^\s*(?:(?:hey|hi|okay|ok)[\s,;:!?.-]+)?nimmy\b[\s,;:!?.-]*',
    caseSensitive: false,
  );

  String stripLeadingWakePhrase(String transcript) {
    return transcript.replaceFirst(_leadingWakePhrase, '').trim();
  }

  bool startsWithWakePhrase(String transcript) {
    return _leadingWakePhrase.hasMatch(transcript);
  }

  bool isCancellation(String transcript) {
    final normalized = _normalize(transcript);
    return const {
      'cancel',
      'stop',
      'wait',
      'never mind',
      'nevermind',
      'do not',
      "don't",
    }.contains(normalized);
  }

  bool isAffirmative(String transcript) {
    final normalized = _normalize(transcript);
    return const {
      'yes',
      'yeah',
      'yep',
      'confirm',
      'do it',
      'okay',
      'ok',
      'haan',
      'ha',
    }.contains(normalized);
  }

  bool isNegative(String transcript) {
    final normalized = _normalize(transcript);
    return const {
      'no',
      'nope',
      'reject',
      'cancel',
      'never mind',
      'nevermind',
      'nahi',
    }.contains(normalized);
  }

  String _normalize(String value) {
    return stripLeadingWakePhrase(value)
        .toLowerCase()
        .replaceAll(RegExp(r"[^a-z0-9\s']"), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
