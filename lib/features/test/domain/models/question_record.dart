import '../../../../core/domain/intelligence_domain.dart';
import '../../../../core/domain/question_difficulty.dart';
import '../../../hexaiq/domain/hexaiq_models.dart';

class QuestionRecord {
  const QuestionRecord({
    required this.question,
    required this.difficulty,
    required this.seed,
    required this.domain,
    required this.difficultyIndex,
    required this.discrimination,
    required this.guessing,
    required this.itemId,
    required this.selectionScore,
    this.correct,
    this.elapsedSeconds = 0,
    this.responseTime = Duration.zero,
    this.thetaEstimate = 0,
  });

  factory QuestionRecord.fromQuestion({
    required TestQuestion question,
    required bool correct,
    required int elapsedSeconds,
  }) {
    return QuestionRecord(
      question: question,
      difficulty: question.difficulty,
      correct: correct,
      elapsedSeconds: elapsedSeconds,
      responseTime: Duration(seconds: elapsedSeconds),
      seed: question.seed,
      domain: question.domain,
      difficultyIndex: question.difficultyIndex,
      discrimination: question.discrimination,
      guessing: question.guessing,
      itemId: question.itemId ?? question.id,
      selectionScore: question.selectionScore,
      thetaEstimate: 0,
    );
  }

  final TestQuestion question;
  final QuestionDifficulty difficulty;
  final bool? correct;
  final int elapsedSeconds;
  final Duration responseTime;
  final int seed;
  final IntelligenceDomain domain;
  final double difficultyIndex;
  final double discrimination;
  final double guessing;
  final String itemId;
  final double selectionScore;
  final double thetaEstimate;
}
