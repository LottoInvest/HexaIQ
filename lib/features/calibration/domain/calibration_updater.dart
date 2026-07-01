import '../../test/domain/models/question_record.dart';
import 'calibration_config.dart';
import 'calibration_profile.dart';

class CalibrationUpdater {
  const CalibrationUpdater({this.config = const CalibrationConfig()});

  final CalibrationConfig config;

  CalibrationProfile update({
    required CalibrationProfile current,
    required QuestionRecord response,
    DateTime? updatedAt,
  }) {
    final isCorrect = response.correct == true;
    final nextCount = current.responseCount + 1;
    final nextCorrect = current.correctCount + (isCorrect ? 1 : 0);
    final correctRate = nextCorrect / nextCount;
    final averageTheta = _runningAverage(
      current.averageTheta,
      response.thetaAfter,
      current.responseCount,
    );
    final averageTimeMs = _runningAverage(
      current.averageResponseTimeMs,
      response.responseTime.inMilliseconds.toDouble(),
      current.responseCount,
    );
    final residual = response.residual.isFinite ? response.residual : 0.0;
    final difficulty = (current.difficulty - config.learningRate * residual)
        .clamp(config.minDifficulty, config.maxDifficulty)
        .toDouble();
    final discrimination =
        (current.discrimination +
                config.learningRate * (response.itemInformation - 0.2))
            .clamp(config.minDiscrimination, config.maxDiscrimination)
            .toDouble();
    final guessing =
        (current.guessing +
                (isCorrect && response.expectedProbability < 0.25
                    ? config.learningRate * 0.1
                    : -config.learningRate * 0.02))
            .clamp(config.minGuessing, config.maxGuessing)
            .toDouble();

    return CalibrationProfile(
      itemId: current.itemId,
      responseCount: nextCount,
      correctCount: nextCorrect,
      correctRate: correctRate.isFinite ? correctRate : current.correctRate,
      averageTheta: averageTheta,
      averageResponseTimeMs: averageTimeMs,
      difficulty: difficulty,
      discrimination: discrimination,
      guessing: guessing,
      upperAsymptote: current.upperAsymptote,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  double _runningAverage(double current, double value, int previousCount) {
    if (!value.isFinite) {
      return current.isFinite ? current : 0;
    }
    if (previousCount <= 0 || !current.isFinite) {
      return value;
    }
    return current + (value - current) / (previousCount + 1);
  }
}
