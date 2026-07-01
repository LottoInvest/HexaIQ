import 'domain_score_calculator.dart';
import 'hexagon_score_mapper.dart';
import 'iq_score_normalizer.dart';
import 'korean_report_text_resolver.dart';
import 'strength_weakness_resolver.dart';
import 'test_score_policy.dart';

class ReliableReportScore {
  const ReliableReportScore({
    required this.iqScore,
    required this.domainScores,
    required this.hexagonScores,
    required this.domainDescriptions,
    required this.overallDescription,
    required this.strengthWeakness,
  });

  final int iqScore;
  final List<ReliableDomainScore> domainScores;
  final Map<String, double> hexagonScores;
  final Map<String, String> domainDescriptions;
  final String overallDescription;
  final StrengthWeaknessResult strengthWeakness;
}

class ReportScoreMapper {
  const ReportScoreMapper({
    this.iqScoreNormalizer = const IqScoreNormalizer(),
    this.hexagonScoreMapper = const HexagonScoreMapper(),
    this.textResolver = const KoreanReportTextResolver(),
    this.strengthWeaknessResolver = const StrengthWeaknessResolver(),
  });

  final IqScoreNormalizer iqScoreNormalizer;
  final HexagonScoreMapper hexagonScoreMapper;
  final KoreanReportTextResolver textResolver;
  final StrengthWeaknessResolver strengthWeaknessResolver;

  ReliableReportScore map({
    required List<ReliableDomainScore> domainScores,
    required TestScorePolicy policy,
  }) {
    final available = domainScores
        .where((score) => score.totalCount > 0)
        .toList();
    final overall = available.isEmpty
        ? 0.0
        : available.fold<double>(0, (sum, score) => sum + score.score) /
              available.length;
    final iq = iqScoreNormalizer.normalize(
      overallScore: overall,
      policy: policy,
    );
    return ReliableReportScore(
      iqScore: iq,
      domainScores: domainScores,
      hexagonScores: hexagonScoreMapper.mapAll(domainScores),
      domainDescriptions: {
        for (final score in domainScores)
          score.domain.name: textResolver.getDomainDescription(
            score.domain,
            score.band,
          ),
      },
      overallDescription: textResolver.getOverallDescription(iq),
      strengthWeakness: strengthWeaknessResolver.resolve(domainScores),
    );
  }
}
