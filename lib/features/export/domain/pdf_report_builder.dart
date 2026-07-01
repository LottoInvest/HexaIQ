import '../../hexaiq/domain/hexaiq_models.dart';
import '../../result/domain/test_result_payload.dart';

class PdfReportBuilder {
  const PdfReportBuilder();

  String build({
    required TestResultSummary result,
    List<GrowthPoint> growth = const [],
    List<String> recommendations = const [],
  }) {
    final payload = TestResultPayload.fromResult(result);
    final growthText = growth.isEmpty
        ? '성장 그래프: 누적 결과가 더 필요합니다.'
        : '성장 그래프: ${growth.map((point) => '${point.month} ${point.score}').join(' / ')}';
    final trainingText = recommendations.isEmpty
        ? '훈련 추천: 약한 영역을 기준으로 자동 추천합니다.'
        : '훈련 추천: ${recommendations.join(', ')}';
    return '''
HexaIQ 전문 리포트
결과 ID: ${result.id}
추정 IQ: ${result.estimatedIQ}
상위 비율: ${result.percentile}%
능력 수준: ${result.abilityLevel}
문항 수: ${payload.totalQuestions}
응답 문항: ${payload.answeredQuestions}
정답: ${payload.correctCount}
정답률: ${payload.accuracyPercent}%
풀이 시간: ${payload.elapsedLabel}

패턴 문항: 공간지각, 추론, 기억, 처리속도 문항을 Material Grid로 기록합니다.
영역별 상세 분석: 정답률, 평균 난이도, 평균 반응시간, 능력 추정값을 함께 표시합니다.
$growthText
$trainingText
검사 이력 요약: 저장된 검사 결과를 기준으로 누적 변화를 비교합니다.
''';
  }
}
