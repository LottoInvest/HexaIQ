import '../../hexaiq/domain/hexaiq_models.dart';
import '../../payment/domain/purchase_status.dart';
import 'pdf_report_builder.dart';

class PdfExportPreview {
  const PdfExportPreview({
    required this.title,
    required this.content,
    required this.hasWatermark,
    required this.canSave,
  });

  final String title;
  final String content;
  final bool hasWatermark;
  final bool canSave;
}

class PdfExportService {
  const PdfExportService();

  static const _builder = PdfReportBuilder();

  PdfExportPreview samplePreview({required PurchaseStatus status}) {
    final purchased = status.hasProfessionalAccess;
    return PdfExportPreview(
      title: '전문 리포트 미리보기',
      hasWatermark: !purchased,
      canSave: purchased,
      content: '''
추정 IQ: 124
상위 비율: 5%
육각형 차트: 수리, 언어, 공간, 기억, 처리속도, 추론 영역 요약
패턴 문항 예시: 공간, 추론, 기억, 처리속도 문항의 시각 자료 포함
영역별 상세 분석: 강점과 보완 영역을 함께 표시
성장 그래프: 최근 검사 변화 요약
훈련 추천: 약한 영역을 우선 훈련하도록 제안
전문가 의견: CAT 기반 응답 패턴과 풀이 시간을 함께 해석
''',
    );
  }

  bool canExportPdf(PurchaseStatus status) => status.hasProfessionalAccess;

  String buildProfessionalReport(TestResultSummary result) {
    return _builder.build(result: result);
  }
}
