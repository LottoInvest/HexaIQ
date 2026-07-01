import 'dart:math' as math;

import 'irt3pl_model.dart';
import 'item_information.dart';

class LikelihoodCalculator {
  const LikelihoodCalculator({this.irt3plModel = const IRT3PLModel()});

  final IRT3PLModel irt3plModel;

  double probability({
    required double theta,
    required double difficultyIndex,
    required double discrimination,
    double guessing = 0,
    double upperAsymptote = 1,
    IRTModelType modelType = IRTModelType.twoPL,
  }) {
    if (modelType == IRTModelType.threePL) {
      return irt3plModel.probability(
        theta: theta,
        item: IRT3PLItemParameters(
          difficulty: difficultyIndex,
          discrimination: discrimination,
          guessing: guessing,
          upperAsymptote: upperAsymptote,
        ),
      );
    }

    if (!theta.isFinite ||
        !difficultyIndex.isFinite ||
        !discrimination.isFinite ||
        discrimination <= 0) {
      return 0.5;
    }

    final exponent = -discrimination * (theta - difficultyIndex);
    final probability = switch (exponent) {
      > 700 => 0.0,
      < -700 => 1.0,
      _ => 1 / (1 + math.exp(exponent)),
    };
    if (!probability.isFinite) {
      return 0.5;
    }
    return probability.clamp(1e-9, 1 - 1e-9).toDouble();
  }

  double likelihood({
    required double theta,
    required double difficultyIndex,
    required double discrimination,
    required bool isCorrect,
    double guessing = 0,
    double upperAsymptote = 1,
    IRTModelType modelType = IRTModelType.twoPL,
  }) {
    final p = probability(
      theta: theta,
      difficultyIndex: difficultyIndex,
      discrimination: discrimination,
      guessing: guessing,
      upperAsymptote: upperAsymptote,
      modelType: modelType,
    );
    final value = isCorrect ? p : 1 - p;
    if (!value.isFinite) {
      return 0;
    }
    return value.clamp(0.0, 1.0).toDouble();
  }

  double residual({
    required double theta,
    required double difficultyIndex,
    required double discrimination,
    required bool isCorrect,
    double guessing = 0,
    double upperAsymptote = 1,
    IRTModelType modelType = IRTModelType.twoPL,
  }) {
    final p = probability(
      theta: theta,
      difficultyIndex: difficultyIndex,
      discrimination: discrimination,
      guessing: guessing,
      upperAsymptote: upperAsymptote,
      modelType: modelType,
    );
    final value = (isCorrect ? 1.0 : 0.0) - p;
    return value.isFinite ? value : 0;
  }

  double information({
    required double theta,
    required double difficultyIndex,
    required double discrimination,
    double guessing = 0,
    double upperAsymptote = 1,
    IRTModelType modelType = IRTModelType.twoPL,
  }) {
    return itemInformation(
      theta: theta,
      difficultyIndex: difficultyIndex,
      discrimination: discrimination,
      guessing: guessing,
      upperAsymptote: upperAsymptote,
      modelType: modelType,
    );
  }
}
