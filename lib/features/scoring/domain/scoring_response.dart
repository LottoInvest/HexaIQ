import '../../hexaiq/domain/hexaiq_models.dart' show TestType;
import '../../pattern_grid/domain/pattern_difficulty.dart';
import 'cognitive_domain.dart';

class ScoringResponse {
  const ScoringResponse({
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
    this.estimatedTime = const Duration(seconds: 30),
    this.timestamp,
  });

  final String questionId;
  final String packId;
  final TestType testType;
  final CognitiveDomain domain;
  final PatternDifficulty difficulty;
  final String ruleType;
  final String elementType;
  final bool isCorrect;
  final Duration responseTime;
  final int selectedAnswer;
  final int correctAnswer;
  final Duration estimatedTime;
  final DateTime? timestamp;
}
