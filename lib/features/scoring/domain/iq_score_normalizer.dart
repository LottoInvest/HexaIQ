import 'test_score_policy.dart';

class IqScoreNormalizer {
  const IqScoreNormalizer();

  int normalize({
    required double overallScore,
    required TestScorePolicy policy,
  }) {
    final safeScore = overallScore.isFinite ? overallScore.clamp(0, 100) : 0;
    final iq = policy.minIq + (safeScore / 100) * (policy.maxIq - policy.minIq);
    return iq.round().clamp(policy.minIq, policy.maxIq);
  }
}
