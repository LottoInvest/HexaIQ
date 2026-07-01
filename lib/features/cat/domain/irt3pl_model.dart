import 'dart:math' as math;

enum IRTModelType {
  twoPL('2PL'),
  threePL('3PL');

  const IRTModelType(this.label);

  final String label;
}

class IRT3PLItemParameters {
  const IRT3PLItemParameters({
    required this.difficulty,
    required this.discrimination,
    this.guessing = 0,
    this.upperAsymptote = 1,
  });

  final double difficulty;
  final double discrimination;
  final double guessing;
  final double upperAsymptote;

  bool get isValid {
    return difficulty.isFinite &&
        discrimination.isFinite &&
        discrimination > 0 &&
        guessing.isFinite &&
        guessing >= 0 &&
        guessing < 1 &&
        upperAsymptote.isFinite &&
        upperAsymptote > guessing &&
        upperAsymptote <= 1;
  }
}

class IRT3PLModel {
  const IRT3PLModel();

  double probability({
    required double theta,
    required IRT3PLItemParameters item,
  }) {
    if (!theta.isFinite || !item.isValid) {
      return 0.5;
    }
    final logistic = _logistic(
      theta: theta,
      difficulty: item.difficulty,
      discrimination: item.discrimination,
    );
    final probability =
        item.guessing + (item.upperAsymptote - item.guessing) * logistic;
    if (!probability.isFinite) {
      return 0.5;
    }
    return probability.clamp(1e-9, 1 - 1e-9).toDouble();
  }

  double information({
    required double theta,
    required IRT3PLItemParameters item,
  }) {
    final probability = this.probability(theta: theta, item: item);
    if (!probability.isFinite ||
        probability <= 1e-9 ||
        probability >= 1 - 1e-9 ||
        !item.isValid) {
      return 0;
    }

    final denominator = item.upperAsymptote - item.guessing;
    final derivative =
        item.discrimination *
        (probability - item.guessing) *
        (item.upperAsymptote - probability) /
        denominator;
    final information =
        derivative * derivative / (probability * (1 - probability));
    if (!information.isFinite || information < 0) {
      return 0;
    }
    return information;
  }

  double _logistic({
    required double theta,
    required double difficulty,
    required double discrimination,
  }) {
    final exponent = -discrimination * (theta - difficulty);
    return switch (exponent) {
      > 700 => 0.0,
      < -700 => 1.0,
      _ => 1 / (1 + math.exp(exponent)),
    };
  }
}
