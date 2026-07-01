import 'dart:math' as math;

import 'irt3pl_model.dart';

double itemInformation({
  required double theta,
  required double difficultyIndex,
  required double discrimination,
  double guessing = 0.0,
  double upperAsymptote = 1.0,
  IRTModelType modelType = IRTModelType.twoPL,
}) {
  if (modelType == IRTModelType.threePL) {
    return const IRT3PLModel().information(
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
    return 0;
  }

  final exponent = -discrimination * (theta - difficultyIndex);
  final probability = switch (exponent) {
    > 700 => 0.0,
    < -700 => 1.0,
    _ => 1 / (1 + math.exp(exponent)),
  };
  final information =
      discrimination * discrimination * probability * (1 - probability);
  if (!information.isFinite || information < 0) {
    return 0;
  }
  return information;
}
