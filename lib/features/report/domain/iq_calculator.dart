import '../../norm/domain/norm_profile.dart';

class IQCalculator {
  const IQCalculator();

  static const minIQ = 40;
  static const maxIQ = 160;
  static const reliableMinIQ = 55;
  static const reliableMaxIQ = 145;

  double accuracyScore(double accuracy) {
    final safeAccuracy = accuracy.isFinite ? accuracy.clamp(0.0, 1.0) : 0.5;
    return (safeAccuracy - 0.5) * 6;
  }

  double overallTheta({
    required double theta,
    required double accuracy,
    NormProfile profile = NormProfile.defaultProfile,
  }) {
    final safeTheta = theta.isFinite
        ? theta.clamp(-3.0, 3.0)
        : profile.meanTheta;
    final safeAccuracy = accuracy.isFinite ? accuracy.clamp(0.0, 1.0) : 0.5;
    final accuracyTheta = (safeAccuracy - 0.5) * 4.8;
    final value = accuracyTheta * 0.85 + safeTheta * 0.15;
    return value.clamp(-4.0, 4.0).toDouble();
  }

  int estimatedIQ({
    required double theta,
    required double accuracy,
    NormProfile profile = NormProfile.defaultProfile,
  }) {
    final safeAccuracy = accuracy.isFinite ? accuracy.clamp(0.0, 1.0) : 0.5;
    final accuracyIq = 55 + safeAccuracy * 85;
    final thetaAdjustment = theta.isFinite ? theta.clamp(-3.0, 3.0) * 2.0 : 0.0;
    final value = accuracyIq + thetaAdjustment;
    if (!value.isFinite) {
      return profile.meanIQ.clamp(minIQ, maxIQ);
    }
    return value.round().clamp(reliableMinIQ, reliableMaxIQ);
  }
}
