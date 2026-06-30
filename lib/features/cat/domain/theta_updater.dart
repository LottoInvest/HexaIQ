import 'dart:math' as math;

import '../../../core/domain/question_difficulty.dart';
import 'theta_estimate.dart';

class ThetaUpdater {
  const ThetaUpdater();

  ThetaEstimate update({
    required ThetaEstimate current,
    required QuestionDifficulty difficulty,
    required bool isCorrect,
    DateTime? updatedAt,
  }) {
    final delta = isCorrect
        ? 0.15 * difficulty.weight
        : -0.12 * difficulty.weight;
    final answeredCount = current.answeredCount + 1;
    final theta = (current.theta + delta).clamp(-3.0, 3.0).toDouble();
    final standardError = math.max(0.25, 1.0 / math.sqrt(answeredCount + 1));
    return ThetaEstimate(
      theta: theta,
      standardError: standardError,
      answeredCount: answeredCount,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
