import '../../report/domain/iq_calculator.dart';
import 'norm_profile.dart';

class IQScaleConverter {
  const IQScaleConverter();

  static const minIQ = IQCalculator.reliableMinIQ;
  static const maxIQ = IQCalculator.reliableMaxIQ;

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
    double accuracy = 0.5,
    NormProfile profile = NormProfile.defaultProfile,
  }) {
    return const IQCalculator().estimatedIQ(
      theta: theta,
      accuracy: accuracy,
      profile: profile,
    );
  }
}
