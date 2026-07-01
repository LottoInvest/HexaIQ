import 'package:flutter_test/flutter_test.dart';
import 'package:hexaiq_app/core/domain/question_difficulty.dart';
import 'package:hexaiq_app/features/export/domain/pdf_export_service.dart';
import 'package:hexaiq_app/features/hexaiq/domain/hexaiq_models.dart';
import 'package:hexaiq_app/features/result/domain/result_integrity_validator.dart';
import 'package:hexaiq_app/features/result/domain/test_result_payload.dart';
import 'package:hexaiq_app/features/test/domain/models/test_mode.dart';

void main() {
  test('home, history, report, and pdf can read the same persisted result', () {
    final result = _result();
    final payload = TestResultPayload.fromResult(result);
    final integrity = const ResultIntegrityValidator().validate(result);
    final pdf = const PdfExportService().buildProfessionalReport(result);

    expect(integrity.isValid, isTrue);
    expect(payload.resultId, result.id);
    expect(payload.profileId, result.profileId);
    expect(payload.totalQuestions, result.questionCount);
    expect(payload.correctCount, 14);
    expect(payload.accuracyPercent, 39);
    expect(pdf, contains('결과 ID: same-result'));
    expect(pdf, contains('문항 수: 36'));
    expect(pdf, contains('정답: 14'));
    expect(pdf, contains('풀이 시간: 6분'));
  });
}

TestResultSummary _result() {
  final payload = TestResultPayload(
    resultId: 'same-result',
    profileId: 'profile-1',
    testMode: TestMode.quickIq,
    totalQuestions: 36,
    answeredQuestions: 36,
    correctCount: 14,
    accuracy: 14 / 36,
    totalElapsedSeconds: 360,
    averageElapsedSeconds: 10,
    questionIds: List.generate(36, (index) => 'q-$index'),
    domainScores: const {},
  );
  return TestResultSummary(
    id: 'same-result',
    profileId: 'profile-1',
    startedAt: DateTime(2026, 7),
    completedAt: DateTime(2026, 7, 1, 0, 6),
    theta: -0.2,
    standardError: 0.6,
    estimatedIQ: 96,
    percentile: 42,
    abilityLevel: '평균',
    averageDifficulty: QuestionDifficulty.normal,
    averageElapsedSeconds: 10,
    questionCount: 36,
    payloadJson: payload.encode(),
  );
}
