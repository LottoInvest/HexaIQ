import 'cognitive_domain.dart';
import 'difficulty_weight_resolver.dart';
import 'response_time_analyzer.dart';
import 'scoring_response.dart';
import 'score_band.dart';
import 'test_score_policy.dart';

class ReliableDomainScore {
  const ReliableDomainScore({
    required this.domain,
    required this.correctCount,
    required this.totalCount,
    required this.accuracy,
    required this.averageResponseTime,
    required this.rawScore,
    required this.weightedScore,
    required this.score,
    required this.band,
  });

  final CognitiveDomain domain;
  final int correctCount;
  final int totalCount;
  final double accuracy;
  final Duration averageResponseTime;
  final double rawScore;
  final double weightedScore;
  final int score;
  final ScoreBand band;
}

class DomainScoreCalculator {
  const DomainScoreCalculator({
    this.difficultyWeightResolver = const DifficultyWeightResolver(),
    this.responseTimeAnalyzer = const ResponseTimeAnalyzer(),
  });

  final DifficultyWeightResolver difficultyWeightResolver;
  final ResponseTimeAnalyzer responseTimeAnalyzer;

  ReliableDomainScore calculate({
    required CognitiveDomain domain,
    required List<ScoringResponse> responses,
    required TestScorePolicy policy,
  }) {
    final domainResponses = responses
        .where((response) => response.domain == domain)
        .toList(growable: false);
    if (domainResponses.isEmpty) {
      return ReliableDomainScore(
        domain: domain,
        correctCount: 0,
        totalCount: 0,
        accuracy: 0,
        averageResponseTime: Duration.zero,
        rawScore: 0,
        weightedScore: 0,
        score: 0,
        band: ScoreBand.veryLow,
      );
    }
    final correctCount = domainResponses.where((item) => item.isCorrect).length;
    final totalWeight = domainResponses.fold<double>(
      0,
      (sum, response) =>
          sum +
          difficultyWeightResolver.weightFor(
            response.difficulty,
            policy.testType,
          ),
    );
    var weightedCorrect = 0.0;
    for (final response in domainResponses) {
      if (!response.isCorrect) {
        continue;
      }
      final weight = difficultyWeightResolver.weightFor(
        response.difficulty,
        policy.testType,
      );
      final time = responseTimeAnalyzer.analyze(
        isCorrect: response.isCorrect,
        responseTime: response.responseTime,
        estimatedTime: response.estimatedTime,
        useBonus: policy.useResponseTimeBonus,
      );
      weightedCorrect += weight * time.multiplier;
    }
    final accuracy = correctCount / domainResponses.length;
    final rawScore = accuracy * 100;
    final weightedScore = totalWeight <= 0
        ? 0
        : (weightedCorrect / totalWeight) * 100;
    final score = weightedScore.round().clamp(0, 100);
    final elapsedMs = domainResponses.fold<int>(
      0,
      (sum, response) => sum + response.responseTime.inMilliseconds,
    );
    return ReliableDomainScore(
      domain: domain,
      correctCount: correctCount,
      totalCount: domainResponses.length,
      accuracy: accuracy,
      averageResponseTime: Duration(
        milliseconds: elapsedMs ~/ domainResponses.length,
      ),
      rawScore: rawScore,
      weightedScore: weightedScore.clamp(0, 100).toDouble(),
      score: score,
      band: scoreBandFor(score),
    );
  }
}
