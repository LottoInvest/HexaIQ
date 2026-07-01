import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexaiq_app/core/domain/domain_result.dart';
import 'package:hexaiq_app/core/domain/intelligence_domain.dart';
import 'package:hexaiq_app/core/domain/question_difficulty.dart';
import 'package:hexaiq_app/core/theme/app_theme.dart';
import 'package:hexaiq_app/features/cat/domain/theta_estimate.dart';
import 'package:hexaiq_app/features/hexaiq/data/mock_hexaiq_repository.dart';
import 'package:hexaiq_app/features/hexaiq/domain/hexaiq_models.dart';
import 'package:hexaiq_app/features/hexaiq/presentation/state/hexaiq_app_state.dart';
import 'package:hexaiq_app/features/report/domain/domain_score_calculator.dart';
import 'package:hexaiq_app/features/report/domain/iq_calculator.dart';
import 'package:hexaiq_app/features/report/domain/report_localization.dart';
import 'package:hexaiq_app/features/report/presentation/report_summary_screen.dart';
import 'package:hexaiq_app/features/test/application/test_session_controller.dart';
import 'package:hexaiq_app/features/test/domain/models/question_record.dart';
import 'package:hexaiq_app/features/test/domain/models/test_session.dart';
import 'package:provider/provider.dart';

void main() {
  test('v1.0.1 IQ recalibration keeps zero and perfect scores plausible', () {
    const calculator = IQCalculator();

    expect(
      calculator.estimatedIQ(theta: -3, accuracy: 0),
      inInclusiveRange(55, 65),
    );
    expect(
      calculator.estimatedIQ(theta: 0, accuracy: 0.25),
      inInclusiveRange(70, 80),
    );
    expect(
      calculator.estimatedIQ(theta: 0, accuracy: 0.5),
      inInclusiveRange(90, 100),
    );
    expect(
      calculator.estimatedIQ(theta: 0, accuracy: 0.75),
      inInclusiveRange(110, 120),
    );
    expect(
      calculator.estimatedIQ(theta: 3, accuracy: 1),
      inInclusiveRange(130, 145),
    );
  });

  test('Domain score is direct accuracy and keeps zero correct at center', () {
    const calculator = DomainScoreCalculator();

    expect(
      calculator.domainScore(
        accuracy: 0,
        theta: -3,
        difficultyLevel: QuestionDifficulty.normal.level.toDouble(),
      ),
      0,
    );
    expect(
      calculator.domainScore(
        accuracy: 0.5,
        theta: 3,
        difficultyLevel: QuestionDifficulty.veryHard.level.toDouble(),
      ),
      50,
    );
    expect(
      calculator.domainScore(
        accuracy: 1,
        theta: 3,
        difficultyLevel: QuestionDifficulty.veryHard.level.toDouble(),
      ),
      100,
    );
  });

  testWidgets('Report uses stable Korean labels and hides debug by default', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final state = HexaIQAppState(repository: MockHexaIQRepository())
      ..testSessionController = TestSessionController(_session())
      ..report = _report();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: state,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const ReportSummaryScreen(),
        ),
      ),
    );

    final grids = tester.widgetList<GridView>(find.byType(GridView)).toList();
    final metricDelegate =
        grids.first.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
    final domainDelegate =
        grids.last.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;

    expect(metricDelegate.crossAxisCount, 4);
    expect(domainDelegate.crossAxisCount, 3);
    expect(find.text('검사 리포트'), findsOneWidget);
    expect(find.text('추정 IQ'), findsOneWidget);
    expect(find.text('상위 비율'), findsOneWidget);
    expect(find.text('영역별 결과'), findsOneWidget);
    expect(find.text('다음 추천 훈련'), findsOneWidget);
    expect(find.textContaining('Quick IQ 영역 결과'), findsWidgets);
    expect(find.textContaining('데이터 없음'), findsNothing);
    expect(find.textContaining('Results are calculated'), findsNothing);
    expect(find.textContaining('Use Quick IQ'), findsNothing);
    expect(find.textContaining('Next training'), findsNothing);
    expect(find.textContaining('theta'), findsNothing);
    expect(find.textContaining('CAT'), findsNothing);
  });
}

ReportSummary _report() {
  final results = {
    for (final domain in IntelligenceDomain.values)
      domain: domain == IntelligenceDomain.numerical
          ? const DomainResult(
              domain: IntelligenceDomain.numerical,
              correctCount: 0,
              totalCount: 3,
              accuracy: 0,
              elapsedSeconds: 54,
              theta: -3,
              difficulty: 1,
              domainScore: 0,
            )
          : DomainResult(domain: domain),
  };
  const calculator = DomainScoreCalculator();
  return ReportSummary(
    overallScore: 0,
    summary: ReportLocalization.summary,
    domainScores: calculator.scoresFromResults(results),
    recommendations: ReportLocalization.trainingRecommendations(results),
    domainResults: results,
  );
}

TestSession _session() {
  final question = _question();
  return TestSession(
    sessionId: 'v101',
    startedAt: DateTime(2026),
    questions: [question],
    generatedQuestions: [question],
    questionHistory: [
      QuestionRecord.fromQuestion(
        question: question,
        correct: false,
        elapsedSeconds: 18,
        thetaBefore: 0,
        thetaAfter: -3,
      ),
    ],
    thetaEstimate: ThetaEstimate.initial().copyWith(theta: -3),
    domainResults: {
      IntelligenceDomain.numerical: const DomainResult(
        domain: IntelligenceDomain.numerical,
        correctCount: 0,
        totalCount: 3,
        accuracy: 0,
        elapsedSeconds: 54,
        theta: -3,
        difficulty: 1,
        domainScore: 0,
      ),
    },
    estimatedIQ: 55,
    percentile: 99,
  );
}

TestQuestion _question() {
  return const TestQuestion(
    id: 'nr-v101',
    domain: IntelligenceDomain.numerical,
    typeCode: 'NR01',
    level: 5,
    prompt: '다음 수는?',
    choices: ['1', '2', '3', '4'],
    answerIndex: 0,
    explanation: '규칙을 확인합니다.',
    difficulty: QuestionDifficulty.normal,
  );
}
