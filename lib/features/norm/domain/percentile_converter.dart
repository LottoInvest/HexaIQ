import 'dart:math' as math;

import 'norm_profile.dart';

class PercentileConverter {
  const PercentileConverter();

  int percentile({
    required double theta,
    NormProfile profile = NormProfile.defaultProfile,
  }) {
    if (!theta.isFinite || !profile.meanTheta.isFinite) {
      return 50;
    }
    final z = (theta - profile.meanTheta) / profile.safeSdTheta;
    if (!z.isFinite) {
      return 50;
    }
    final value = (_normalCdf(z) * 100).round();
    return value.clamp(1, 99);
  }

  int topPercentFromAccuracy(double accuracy) {
    final safeAccuracy = accuracy.isFinite ? accuracy.clamp(0.0, 1.0) : 0.5;
    if (safeAccuracy <= 0.10) {
      return _interpolateTopPercent(safeAccuracy, 0.00, 0.10, 99, 95);
    }
    if (safeAccuracy <= 0.25) {
      return _interpolateTopPercent(safeAccuracy, 0.11, 0.25, 94, 80);
    }
    if (safeAccuracy <= 0.40) {
      return _interpolateTopPercent(safeAccuracy, 0.26, 0.40, 79, 60);
    }
    if (safeAccuracy <= 0.60) {
      return _interpolateTopPercent(safeAccuracy, 0.41, 0.60, 59, 40);
    }
    if (safeAccuracy <= 0.75) {
      return _interpolateTopPercent(safeAccuracy, 0.61, 0.75, 39, 20);
    }
    if (safeAccuracy <= 0.90) {
      return _interpolateTopPercent(safeAccuracy, 0.76, 0.90, 19, 5);
    }
    return _interpolateTopPercent(safeAccuracy, 0.91, 1.00, 4, 1);
  }

  String bandLabelFromTopPercent(int topPercent) {
    final safeTop = topPercent.clamp(1, 99);
    if (safeTop <= 4) {
      return '매우 우수';
    }
    if (safeTop <= 19) {
      return '우수';
    }
    if (safeTop <= 39) {
      return '평균 이상';
    }
    if (safeTop <= 59) {
      return '평균권';
    }
    if (safeTop <= 79) {
      return '평균 이하';
    }
    return '낮은 구간';
  }

  double _normalCdf(double z) {
    final sign = z < 0 ? -1 : 1;
    final x = z.abs() / math.sqrt2;
    final erf = _erfApproximation(x);
    return 0.5 * (1 + sign * erf);
  }

  int _interpolateTopPercent(
    double accuracy,
    double minAccuracy,
    double maxAccuracy,
    int lowAccuracyTopPercent,
    int highAccuracyTopPercent,
  ) {
    final span = maxAccuracy - minAccuracy;
    if (span <= 0) {
      return lowAccuracyTopPercent.clamp(1, 99);
    }
    final ratio = ((accuracy - minAccuracy) / span).clamp(0.0, 1.0);
    final value =
        lowAccuracyTopPercent +
        (highAccuracyTopPercent - lowAccuracyTopPercent) * ratio;
    return value.round().clamp(1, 99);
  }

  double _erfApproximation(double x) {
    const a1 = 0.254829592;
    const a2 = -0.284496736;
    const a3 = 1.421413741;
    const a4 = -1.453152027;
    const a5 = 1.061405429;
    const p = 0.3275911;
    final t = 1 / (1 + p * x);
    final y =
        1 -
        (((((a5 * t + a4) * t) + a3) * t + a2) * t + a1) * t * math.exp(-x * x);
    return y.isFinite ? y : 0;
  }
}
