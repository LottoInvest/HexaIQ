import 'dart:math' as math;

class PriorDistribution {
  const PriorDistribution.normal({this.mean = 0.0, this.sd = 1.0});

  static const _minTheta = -4.0;
  static const _maxTheta = 4.0;
  static const _invalidLogDensity = -1e12;

  final double mean;
  final double sd;

  double density(double theta) {
    final logValue = logDensity(theta);
    if (!logValue.isFinite || logValue <= _invalidLogDensity) {
      return 0;
    }
    final value = math.exp(logValue.clamp(-745.0, 709.0).toDouble());
    return value.isFinite ? value : 0;
  }

  double logDensity(double theta) {
    if (!theta.isFinite || !mean.isFinite || !sd.isFinite || sd <= 0) {
      return _invalidLogDensity;
    }
    final safeTheta = theta.clamp(_minTheta, _maxTheta).toDouble();
    final z = (safeTheta - mean) / sd;
    final logValue = -math.log(sd * math.sqrt(2 * math.pi)) - 0.5 * z * z;
    return logValue.isFinite ? logValue : _invalidLogDensity;
  }
}
