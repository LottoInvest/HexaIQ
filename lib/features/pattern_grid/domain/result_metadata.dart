class PatternResultMetadata {
  const PatternResultMetadata({
    required this.questionId,
    required this.packId,
    required this.testType,
    required this.domain,
    required this.difficulty,
    required this.ruleType,
    required this.elementType,
    required this.isCorrect,
    required this.responseTime,
    required this.selectedAnswer,
    required this.correctAnswer,
    this.rawScore = 0,
    this.weightedScore = 0,
    this.domainScore = 0,
    this.timestamp,
  });

  final String questionId;
  final String packId;
  final String testType;
  final String domain;
  final String difficulty;
  final String ruleType;
  final String elementType;
  final bool isCorrect;
  final Duration responseTime;
  final int selectedAnswer;
  final int correctAnswer;
  final double rawScore;
  final double weightedScore;
  final int domainScore;
  final DateTime? timestamp;

  Map<String, Object?> toJson() {
    return {
      'questionId': questionId,
      'packId': packId,
      'testType': testType,
      'domain': domain,
      'difficulty': difficulty,
      'ruleType': ruleType,
      'elementType': elementType,
      'isCorrect': isCorrect,
      'responseTimeMs': responseTime.inMilliseconds,
      'selectedAnswer': selectedAnswer,
      'correctAnswer': correctAnswer,
      'rawScore': rawScore,
      'weightedScore': weightedScore,
      'domainScore': domainScore,
      'timestamp': (timestamp ?? DateTime.now()).toIso8601String(),
    };
  }
}
