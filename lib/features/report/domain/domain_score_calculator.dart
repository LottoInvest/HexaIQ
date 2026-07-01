import '../../../core/domain/domain_result.dart';
import '../../../core/domain/intelligence_domain.dart';
import '../../../core/domain/question_difficulty.dart';
import '../../hexaiq/domain/hexaiq_models.dart';
import '../../test/domain/models/question_record.dart';

class DomainScoreCalculator {
  const DomainScoreCalculator();

  DomainResult calculate({
    required IntelligenceDomain domain,
    required List<QuestionRecord> records,
  }) {
    if (records.isEmpty) {
      return DomainResult(domain: domain);
    }

    final correct = records.where((record) => record.correct == true).length;
    final elapsed = records.fold<int>(
      0,
      (sum, record) => sum + record.elapsedSeconds,
    );
    final accuracy = correct / records.length;
    final theta = records.last.thetaAfter.isFinite
        ? records.last.thetaAfter
        : 0.0;
    final difficulty = _averageDifficultyIndex(records);
    final score = domainScore(
      accuracy: accuracy.toDouble(),
      theta: theta,
      difficultyLevel: _averageDifficultyLevel(records),
    );

    return DomainResult(
      domain: domain,
      correctCount: correct,
      totalCount: records.length,
      accuracy: accuracy.toDouble(),
      elapsedSeconds: elapsed,
      theta: theta,
      difficulty: difficulty,
      domainScore: score.toDouble(),
      iqContribution: (score / 100).toDouble(),
    );
  }

  DomainResult calculateFromResponses({
    required IntelligenceDomain domain,
    required List<QuestionResponse> responses,
  }) {
    final domainResponses = responses
        .where((response) => response.question.domain == domain)
        .toList(growable: false);
    if (domainResponses.isEmpty) {
      return DomainResult(domain: domain);
    }

    final correct = domainResponses
        .where((response) => response.isCorrect)
        .length;
    final accuracy = correct / domainResponses.length;
    final thetaProxy = (accuracy * 6 - 3).toDouble();
    final difficultyLevel =
        domainResponses
            .map((response) => response.question.difficulty.level)
            .reduce((a, b) => a + b) /
        domainResponses.length;
    final difficultyIndex =
        domainResponses
            .map((response) => response.question.difficultyIndex)
            .reduce((a, b) => a + b) /
        domainResponses.length;
    final score = domainScore(
      accuracy: accuracy.toDouble(),
      theta: thetaProxy,
      difficultyLevel: difficultyLevel,
    );

    return DomainResult(
      domain: domain,
      correctCount: correct,
      totalCount: domainResponses.length,
      accuracy: accuracy.toDouble(),
      theta: thetaProxy,
      difficulty: difficultyIndex,
      domainScore: score.toDouble(),
      iqContribution: (score / 100).toDouble(),
    );
  }

  List<DomainScore> scoresFromResults(
    Map<IntelligenceDomain, DomainResult> results,
  ) {
    return [
      for (final info in domainCatalog)
        _scoreFromResult(
          info,
          results[info.domain] ?? DomainResult(domain: info.domain),
        ),
    ];
  }

  int domainScore({
    required double accuracy,
    required double theta,
    required double difficultyLevel,
  }) {
    final safeAccuracy = accuracy.isFinite ? accuracy.clamp(0.0, 1.0) : 0.0;
    return (safeAccuracy * 100).round().clamp(0, 100);
  }

  DomainScore _scoreFromResult(DomainInfo info, DomainResult result) {
    final hasData = result.total > 0;
    final score = hasData ? result.domainScore.round().clamp(0, 100) : 0;

    return DomainScore(
      domain: info.domain,
      score: score,
      percentile: hasData ? score.clamp(1, 99) : 0,
      growth: 0,
      comment: hasData
          ? '${info.label}: 응답한 문항의 정답률을 기준으로 계산했습니다.'
          : '${info.label}: 데이터 없음',
      isComingSoon: false,
    );
  }

  double _averageDifficultyIndex(List<QuestionRecord> records) {
    return records
            .map((record) => record.difficultyIndex)
            .reduce((a, b) => a + b) /
        records.length;
  }

  double _averageDifficultyLevel(List<QuestionRecord> records) {
    return records
            .map((record) => record.difficulty.level)
            .reduce((a, b) => a + b) /
        records.length;
  }
}
