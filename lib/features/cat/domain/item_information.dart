import 'dart:math' as math;

double itemInformation({
  required double theta,
  required double difficultyIndex,
  required double discrimination,
  double guessing = 0.0,
}) {
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
