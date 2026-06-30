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
    this.thetaBefore = 0,
    this.thetaAfter = 0,
    this.itemInformation = 0,
    this.catSelectionScore = 0,
    this.expectedProbability = 0.5,
    this.likelihood = 1,
    this.residual = 0,
    this.totalInformation = 0,
    this.correct,
    this.elapsedSeconds = 0,
    this.responseTime = Duration.zero,
    this.thetaEstimate = 0,
  });

  factory QuestionRecord.fromQuestion({
    required TestQuestion question,
    required bool correct,
    required int elapsedSeconds,
    double thetaBefore = 0,
    double thetaAfter = 0,
    double expectedProbability = 0.5,
    double likelihood = 1,
    double residual = 0,
    double totalInformation = 0,
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
      thetaBefore: thetaBefore,
      thetaAfter: thetaAfter,
      itemInformation: question.itemInformation,
      catSelectionScore: question.catSelectionScore,
      expectedProbability: expectedProbability,
      likelihood: likelihood,
      residual: residual,
      totalInformation: totalInformation,
      thetaEstimate: thetaAfter,
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
  final double thetaBefore;
  final double thetaAfter;
  final double itemInformation;
  final double catSelectionScore;
  final double expectedProbability;
  final double likelihood;
  final double residual;
  final double totalInformation;
  final double thetaEstimate;

  QuestionRecord copyWith({
    TestQuestion? question,
    QuestionDifficulty? difficulty,
    bool? correct,
    int? elapsedSeconds,
    Duration? responseTime,
    int? seed,
    IntelligenceDomain? domain,
    double? difficultyIndex,
    double? discrimination,
    double? guessing,
    String? itemId,
    double? selectionScore,
    double? thetaBefore,
    double? thetaAfter,
    double? itemInformation,
    double? catSelectionScore,
    double? expectedProbability,
    double? likelihood,
    double? residual,
    double? totalInformation,
    double? thetaEstimate,
  }) {
    return QuestionRecord(
      question: question ?? this.question,
      difficulty: difficulty ?? this.difficulty,
      correct: correct ?? this.correct,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      responseTime: responseTime ?? this.responseTime,
      seed: seed ?? this.seed,
      domain: domain ?? this.domain,
      difficultyIndex: difficultyIndex ?? this.difficultyIndex,
      discrimination: discrimination ?? this.discrimination,
      guessing: guessing ?? this.guessing,
      itemId: itemId ?? this.itemId,
      selectionScore: selectionScore ?? this.selectionScore,
      thetaBefore: thetaBefore ?? this.thetaBefore,
      thetaAfter: thetaAfter ?? this.thetaAfter,
      itemInformation: itemInformation ?? this.itemInformation,
      catSelectionScore: catSelectionScore ?? this.catSelectionScore,
      expectedProbability: expectedProbability ?? this.expectedProbability,
      likelihood: likelihood ?? this.likelihood,
      residual: residual ?? this.residual,
      totalInformation: totalInformation ?? this.totalInformation,
      thetaEstimate: thetaEstimate ?? this.thetaEstimate,
    );
  }
}
