import 'package:flutter_test/flutter_test.dart';
import 'package:hexaiq_app/core/domain/intelligence_domain.dart';
import 'package:hexaiq_app/core/domain/question_difficulty.dart';
import 'package:hexaiq_app/features/export/domain/pdf_export_service.dart';
import 'package:hexaiq_app/features/hexaiq/domain/hexaiq_models.dart';
import 'package:hexaiq_app/features/result/domain/result_integrity_validator.dart';
import 'package:hexaiq_app/features/result/domain/test_result_builder.dart';
import 'package:hexaiq_app/features/result/domain/test_result_payload.dart';
import 'package:hexaiq_app/features/test/domain/models/test_mode.dart';
import 'package:hexaiq_app/features/test/domain/models/test_session.dart';

void main() {
  test('saved TestResultSummary keeps total, answered, and correct counts', () {
    final questions = List.generate(
      36,
      (index) => _question('q-$index', answerIndex: index.isEven ? 1 : 0),
    );
    final selectedAnswers = {
      for (var i = 0; i < questions.length; i++)
        questions[i].id: i < 20 ? questions[i].answerIndex : 3,
    };
    final elapsed = {for (final question in questions) question.id: 10};
    final session = TestSession(
      sessionId: 'result-36',
      startedAt: DateTime(2026, 7),
      completedAt: DateTime(2026, 7, 1, 0, 8),
      mode: TestMode.fullDiagnostic,
      questions: questions,
      generatedQuestions: questions,
      selectedAnswers: selectedAnswers,
      elapsedSeconds: elapsed,
      estimatedIQ: 118,
      percentile: 88,
    );

    final result = const TestResultBuilder().build(
      session: session,
      profileId: 'profile-1',
    );
    final payload = TestResultPayload.fromResult(result);
    final integrity = const ResultIntegrityValidator().validate(result);
    final pdf = const PdfExportService().buildProfessionalReport(result);

    expect(integrity.isValid, isTrue);
    expect(result.questionCount, 36);
    expect(payload.totalQuestions, 36);
    expect(payload.answeredQuestions, 36);
    expect(payload.correctCount, 20);
    expect(payload.totalElapsedSeconds, 360);
    expect(pdf, contains('결과 ID: result-36'));
    expect(pdf, contains('문항 수: 36'));
    expect(pdf, contains('정답: 20'));
  });
}

TestQuestion _question(String id, {required int answerIndex}) {
  return TestQuestion(
    id: id,
    domain: IntelligenceDomain.numerical,
    typeCode: 'NR01',
    level: 1,
    prompt: '2, 4, 6, ?',
    choices: const ['6', '8', '10', '12'],
    answerIndex: answerIndex,
    explanation: '2씩 증가합니다.',
    difficulty: QuestionDifficulty.normal,
    itemId: id,
  );
}
