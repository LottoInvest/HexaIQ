import '../../hexaiq/domain/hexaiq_models.dart' show TestType;
import 'cognitive_domain.dart';
import 'difficulty_weight_resolver.dart';
import 'domain_score_calculator.dart';
import 'hexagon_score_mapper.dart';
import 'iq_score_normalizer.dart';
import 'report_score_mapper.dart';
import 'response_time_analyzer.dart';
import 'scoring_response.dart';
import 'test_score_policy.dart';

class ScoringReliabilityEngine {
  const ScoringReliabilityEngine({
    this.domainScoreCalculator = const DomainScoreCalculator(),
    this.difficultyWeightResolver = const DifficultyWeightResolver(),
    this.responseTimeAnalyzer = const ResponseTimeAnalyzer(),
    this.iqScoreNormalizer = const IqScoreNormalizer(),
    this.hexagonScoreMapper = const HexagonScoreMapper(),
    this.reportScoreMapper = const ReportScoreMapper(),
  });

  final DomainScoreCalculator domainScoreCalculator;
  final DifficultyWeightResolver difficultyWeightResolver;
  final ResponseTimeAnalyzer responseTimeAnalyzer;
  final IqScoreNormalizer iqScoreNormalizer;
  final HexagonScoreMapper hexagonScoreMapper;
  final ReportScoreMapper reportScoreMapper;

  ReliableReportScore calculate({
    required List<ScoringResponse> responses,
    TestType testType = TestType.basic,
  }) {
    final policy = TestScorePolicy.forTestType(
      responses.isEmpty ? testType : responses.first.testType,
    );
    final domainScores = [
      for (final domain in CognitiveDomain.values)
        domainScoreCalculator.calculate(
          domain: domain,
          responses: responses,
          policy: policy,
        ),
    ];
    return reportScoreMapper.map(domainScores: domainScores, policy: policy);
  }
}
