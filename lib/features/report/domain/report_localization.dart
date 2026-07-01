import '../../../core/domain/domain_result.dart';
import '../../../core/domain/intelligence_domain.dart';

class ReportLocalization {
  const ReportLocalization._();

  static const summary = '검사 결과는 응답한 영역을 기준으로 계산되었습니다.';

  static List<String> trainingRecommendations(
    Map<IntelligenceDomain, DomainResult> results,
  ) {
    final answered = results.entries
        .where((entry) => entry.value.total > 0)
        .toList(growable: false);
    if (answered.isEmpty) {
      return const [
        '빠른 IQ를 활용하여 6개 영역을 모두 검사해 보세요.',
        '약한 영역을 반복 훈련하면 인지 능력을 더욱 향상시킬 수 있습니다.',
        '처리속도는 정확도와 반응시간을 함께 확인하세요.',
      ];
    }
    final weak = [...answered]
      ..sort((a, b) => a.value.domainScore.compareTo(b.value.domainScore));
    final weakest = weak.first;
    return [
      '${weakest.key.label} 영역이 상대적으로 약합니다.',
      _domainTraining(weakest.key),
      '처리속도는 정확도와 반응시간을 함께 확인하세요.',
    ];
  }

  static String _domainTraining(IntelligenceDomain domain) {
    return switch (domain) {
      IntelligenceDomain.numerical => '등차수열, 등비수열, 행렬 문제를 추천합니다.',
      IntelligenceDomain.verbal => '유의어, 반의어, 문맥 추론 문제를 추천합니다.',
      IntelligenceDomain.spatial => '회전, 대칭, 도형 패턴 문제를 추천합니다.',
      IntelligenceDomain.memory => '숫자 기억, 역순 기억, 시퀀스 문제를 추천합니다.',
      IntelligenceDomain.logic => '조건, 명제, 포함관계 문제를 추천합니다.',
      IntelligenceDomain.processing => '기호 찾기, 빠른 비교, 시각 탐색 문제를 추천합니다.',
    };
  }
}
