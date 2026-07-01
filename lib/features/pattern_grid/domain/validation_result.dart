class ValidationResult {
  const ValidationResult({
    required this.questionId,
    required this.packId,
    this.errors = const [],
    this.warnings = const [],
    this.canAutoFix = false,
  });

  final String questionId;
  final String packId;
  final List<String> errors;
  final List<String> warnings;
  final bool canAutoFix;

  bool get isValid => errors.isEmpty;

  bool get hasFatalError => errors.isNotEmpty;

  String debugLog() {
    final buffer = StringBuffer(
      '[PatternValidator] question_id: $questionId pack: $packId',
    );
    for (final error in errors) {
      buffer.writeln();
      buffer.write('ERROR: $error');
    }
    for (final warning in warnings) {
      buffer.writeln();
      buffer.write('WARNING: $warning');
    }
    return buffer.toString();
  }
}
