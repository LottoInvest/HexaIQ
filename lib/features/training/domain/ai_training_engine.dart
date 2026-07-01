import '../../../core/domain/domain_result.dart';
import '../../../core/domain/intelligence_domain.dart';
import '../../hexaiq/domain/hexaiq_models.dart';

class TrainingRecommendation {
  const TrainingRecommendation({
    required this.domain,
    required this.title,
    required this.reason,
    required this.focusAreas,
    required this.targetDifficulty,
    required this.estimatedMinutes,
  });

  final IntelligenceDomain domain;
  final String title;
  final String reason;
  final List<String> focusAreas;
  final String targetDifficulty;
  final int estimatedMinutes;
}

class AITrainingEngine {
  const AITrainingEngine();

  List<TrainingRecommendation> recommend({
    ReportSummary? report,
    int limit = 3,
  }) {
    final results = report?.domainResults ?? const {};
    if (results.isEmpty) {
      return _fallbackRecommendations().take(limit).toList(growable: false);
    }

    final domains =
        IntelligenceDomain.values.where((domain) {
          final result = results[domain];
          return result != null && result.totalCount > 0;
        }).toList()..sort((a, b) {
          final left = _weaknessScore(results[a]!);
          final right = _weaknessScore(results[b]!);
          return right.compareTo(left);
        });

    if (domains.isEmpty) {
      return _fallbackRecommendations().take(limit).toList(growable: false);
    }

    return [
      for (final domain in domains.take(limit))
        _recommendationFor(domain, results[domain]!),
    ];
  }

  double _weaknessScore(DomainResult result) {
    final accuracyGap = 1 - result.accuracy.clamp(0, 1);
    final thetaGap = ((0.5 - result.theta).clamp(0, 3)) / 3;
    return accuracyGap * 0.7 + thetaGap * 0.3;
  }

  TrainingRecommendation _recommendationFor(
    IntelligenceDomain domain,
    DomainResult result,
  ) {
    final areas = _focusAreas[domain] ?? const ['기초 규칙', '응용 문제'];
    final difficulty = result.accuracy < 0.45
        ? '기초부터 회복'
        : result.accuracy < 0.7
        ? '보통 난이도 강화'
        : '어려운 문제 도전';
    return TrainingRecommendation(
      domain: domain,
      title: '${domain.label} 맞춤 훈련',
      reason:
          '정답률 ${(result.accuracy * 100).round()}%와 능력 추정값을 기준으로 약한 유형을 우선 추천합니다.',
      focusAreas: areas,
      targetDifficulty: difficulty,
      estimatedMinutes: 10 + (areas.length * 2),
    );
  }

  List<TrainingRecommendation> _fallbackRecommendations() {
    return [
      for (final domain in IntelligenceDomain.values)
        TrainingRecommendation(
          domain: domain,
          title: '${domain.label} 기초 점검',
          reason: '아직 충분한 검사 기록이 없어 각 영역을 균형 있게 추천합니다.',
          focusAreas: _focusAreas[domain] ?? const ['기초 규칙'],
          targetDifficulty: '기초',
          estimatedMinutes: 10,
        ),
    ];
  }
}

const _focusAreas = {
  IntelligenceDomain.numerical: ['등차수열', '수열', '비례식'],
  IntelligenceDomain.verbal: ['어휘 관계', '문장 추론', '핵심 파악'],
  IntelligenceDomain.spatial: ['회전 패턴', '대칭', '블록 이동'],
  IntelligenceDomain.memory: ['숫자 기억', '위치 기억', '패턴 기억'],
  IntelligenceDomain.processing: ['기호 탐색', '빠른 비교', '색상 일치'],
  IntelligenceDomain.logic: ['논리 규칙', '조건 추론', '관계 추론'],
};
