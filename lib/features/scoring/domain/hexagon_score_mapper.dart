import 'domain_score_calculator.dart';

class HexagonScoreMapper {
  const HexagonScoreMapper();

  double mapDomain(ReliableDomainScore score) {
    if (score.totalCount == 0) {
      return 0;
    }
    final accuracy = score.accuracy.clamp(0, 1);
    return accuracy.toDouble();
  }

  Map<String, double> mapAll(Iterable<ReliableDomainScore> scores) {
    return {for (final score in scores) score.domain.name: mapDomain(score)};
  }
}
