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

  double _normalCdf(double z) {
    final sign = z < 0 ? -1 : 1;
    final x = z.abs() / math.sqrt2;
    final erf = _erfApproximation(x);
    return 0.5 * (1 + sign * erf);
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
