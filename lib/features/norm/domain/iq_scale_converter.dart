import 'norm_profile.dart';

class IQScaleConverter {
  const IQScaleConverter();

  static const minIQ = 55;
  static const maxIQ = 145;

  double scaledScore({
    required double theta,
    NormProfile profile = NormProfile.defaultProfile,
  }) {
    if (!theta.isFinite || !profile.meanTheta.isFinite) {
      return 0;
    }
    final value = (theta - profile.meanTheta) / profile.safeSdTheta;
    return value.isFinite ? value : 0;
  }

  int estimatedIQ({
    required double theta,
    NormProfile profile = NormProfile.defaultProfile,
  }) {
    final scaled = scaledScore(theta: theta, profile: profile);
    final raw = profile.meanIQ + scaled * profile.sdIQ;
    if (!raw.isFinite) {
      return profile.meanIQ.clamp(minIQ, maxIQ);
    }
    return raw.round().clamp(minIQ, maxIQ);
  }
}
