import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexaiq_app/core/domain/question_difficulty.dart';
import 'package:hexaiq_app/features/hexaiq/domain/hexaiq_models.dart';
import 'package:hexaiq_app/features/hexaiq/domain/hexaiq_repository.dart';
import 'package:hexaiq_app/features/hexaiq/presentation/state/hexaiq_app_state.dart';
import 'package:hexaiq_app/features/question_engine/question_engine.dart';
import 'package:hexaiq_app/features/report/presentation/report_summary_screen.dart';
import 'package:hexaiq_app/features/test/application/test_session_controller.dart';
import 'package:hexaiq_app/features/test/domain/models/question_record.dart';
import 'package:hexaiq_app/features/test/domain/models/test_session.dart';
import 'package:provider/provider.dart';

void main() {
  test('ThetaEstimate initial and copyWith work', () {
    final updatedAt = DateTime(2026);
    final initial = ThetaEstimate.initial(updatedAt: updatedAt);

    expect(initial.theta, 0);
    expect(initial.standardError, 1);
    expect(initial.answeredCount, 0);
    expect(initial.updatedAt, updatedAt);

    final copied = initial.copyWith(theta: 0.4, answeredCount: 2);
    expect(copied.theta, 0.4);
    expect(copied.standardError, 1);
    expect(copied.answeredCount, 2);
  });

  test('ItemInformation calculates 2PL approximation and stays finite', () {
    final information = itemInformation(
      theta: 0,
      difficultyIndex: 0,
      discrimination: 1,
    );

    expect(information, closeTo(0.25, 0.0001));
    expect(
      itemInformation(
        theta: double.infinity,
        difficultyIndex: 0,
        discrimination: 1,
      ),
      0,
    );
    expect(
      itemInformation(theta: 0, difficultyIndex: double.nan, discrimination: 1),
      0,
    );
    expect(
      itemInformation(
        theta: -10000,
        difficultyIndex: 10000,
        discrimination: 2,
      ).isFinite,
      isTrue,
    );
  });

  test('CATSelectionScore calculates weighted totalScore', () {
    const score = CATSelectionScore(
      informationScore: 0.8,
      difficultyMatchScore: 0.5,
      exposureScore: 0.25,
    );

    expect(score.totalScore, closeTo(0.6, 0.0001));
  });

  test('ThetaUpdater raises, lowers, clamps, and reduces standardError', () {
    const updater = ThetaUpdater();
    final initial = ThetaEstimate.initial(updatedAt: DateTime(2026));

    final correct = updater.update(
      current: initial,
      difficulty: QuestionDifficulty.normal,
      isCorrect: true,
      updatedAt: DateTime(2026, 1, 2),
    );
    final wrong = updater.update(
      current: initial,
      difficulty: QuestionDifficulty.normal,
      isCorrect: false,
    );

    expect(correct.theta, greaterThan(initial.theta));
    expect(wrong.theta, lessThan(initial.theta));
    expect(correct.standardError, lessThan(initial.standardError));

    final upper = updater.update(
      current: initial.copyWith(theta: 2.95),
      difficulty: QuestionDifficulty.veryHard,
      isCorrect: true,
    );
    final lower = updater.update(
      current: initial.copyWith(theta: -2.95),
      difficulty: QuestionDifficulty.veryHard,
      isCorrect: false,
    );
    expect(upper.theta, 3);
    expect(lower.theta, -3);
  });

  test('LikelihoodCalculator calculates finite 2PL probability', () {
    const calculator = LikelihoodCalculator();

    final probability = calculator.probability(
      theta: 0,
      difficultyIndex: 0,
      discrimination: 1,
    );
    final lowerAbility = calculator.probability(
      theta: -1,
      difficultyIndex: 1,
      discrimination: 1.2,
    );
    final higherAbility = calculator.probability(
      theta: 2,
      difficultyIndex: 1,
      discrimination: 1.2,
    );

    expect(probability, closeTo(0.5, 0.0001));
    expect(higherAbility, greaterThan(lowerAbility));
    expect(
      calculator.probability(
        theta: double.infinity,
        difficultyIndex: 0,
        discrimination: 1,
      ),
      0.5,
    );
    expect(
      calculator
          .probability(theta: 10000, difficultyIndex: -10000, discrimination: 2)
          .isFinite,
      isTrue,
    );
  });

  test('ThetaEstimator raises and lowers theta from response history', () {
    const estimator = ThetaEstimator();
    final initial = ThetaEstimate.initial(updatedAt: DateTime(2026));

    final correct = estimator.estimate(
      history: [
        _record(correct: true, difficultyIndex: 0, discrimination: 1),
        _record(correct: true, difficultyIndex: 0.5, discrimination: 1),
      ],
      current: initial,
      updatedAt: DateTime(2026, 1, 2),
    );
    final wrong = estimator.estimate(
      history: [
        _record(correct: false, difficultyIndex: 0, discrimination: 1),
        _record(correct: false, difficultyIndex: -0.5, discrimination: 1),
      ],
      current: initial,
    );

    expect(correct.theta, greaterThan(initial.theta));
    expect(wrong.theta, lessThan(initial.theta));
    expect(correct.answeredCount, 2);
  });

  test('ThetaEstimator clamps theta and prevents NaN or Infinity', () {
    const estimator = ThetaEstimator();
    final initial = ThetaEstimate.initial(updatedAt: DateTime(2026));

    final upper = estimator.estimate(
      history: List.generate(
        8,
        (_) => _record(correct: true, difficultyIndex: 3, discrimination: 2),
      ),
      current: initial,
    );
    final lower = estimator.estimate(
      history: List.generate(
        8,
        (_) => _record(correct: false, difficultyIndex: -3, discrimination: 2),
      ),
      current: initial,
    );
    final failed = estimator.estimate(
      history: [_record(correct: true, difficultyIndex: double.nan)],
      current: initial.copyWith(theta: 0.4, standardError: 0.9),
    );

    expect(upper.theta, 3);
    expect(lower.theta, -3);
    expect(upper.standardError.isFinite, isTrue);
    expect(lower.standardError.isFinite, isTrue);
    expect(upper.standardError, lessThanOrEqualTo(1));
    expect(lower.standardError, lessThanOrEqualTo(1));
    expect(failed.theta, 0.4);
    expect(failed.standardError, 0.9);
  });

  test('ThetaEstimator standardError uses total information', () {
    const estimator = ThetaEstimator();
    final initial = ThetaEstimate.initial(updatedAt: DateTime(2026));

    final estimate = estimator.estimate(
      history: [
        _record(correct: true, difficultyIndex: 0, discrimination: 2),
        _record(correct: true, difficultyIndex: 0, discrimination: 2),
        _record(correct: false, difficultyIndex: 0, discrimination: 2),
        _record(correct: false, difficultyIndex: 0, discrimination: 2),
      ],
      current: initial,
    );

    expect(estimate.theta, closeTo(0, 0.0001));
    expect(estimate.standardError, lessThan(initial.standardError));
    expect(estimate.standardError, greaterThanOrEqualTo(0.25));
  });

  test(
    'CATItemSelectionStrategy excludes used ids and prefers information',
    () {
      const strategy = CATItemSelectionStrategy();
      final lowInfo = _item(
        id: 'NR-low',
        difficultyIndex: 0,
        discrimination: 0.5,
      );
      final highInfo = _item(
        id: 'NR-high',
        difficultyIndex: 0,
        discrimination: 2,
      );

      final selected = strategy.selectNext(
        candidates: [lowInfo, highInfo],
        domain: IntelligenceDomain.numerical,
        targetDifficulty: QuestionDifficulty.normal,
        usedItemIds: const {},
        seed: 7,
        thetaEstimate: ThetaEstimate.initial(updatedAt: DateTime(2026)),
      );
      final afterUsed = strategy.selectNext(
        candidates: [lowInfo, highInfo],
        domain: IntelligenceDomain.numerical,
        targetDifficulty: QuestionDifficulty.normal,
        usedItemIds: {highInfo.id},
        seed: 7,
        thetaEstimate: ThetaEstimate.initial(updatedAt: DateTime(2026)),
      );

      expect(selected.id, highInfo.id);
      expect(afterUsed.id, lowInfo.id);
    },
  );

  test('CATItemSelectionStrategy reflects exposure and deterministic seed', () {
    const strategy = CATItemSelectionStrategy();
    final first = _item(id: 'NR-a');
    final second = _item(id: 'NR-b');

    final selected = strategy.selectNext(
      candidates: [first, second],
      domain: IntelligenceDomain.numerical,
      targetDifficulty: QuestionDifficulty.normal,
      usedItemIds: const {},
      seed: 11,
      exposureStatuses: {
        first.id: ExposureStatus(itemId: first.id, exposureCount: 5),
        second.id: ExposureStatus(itemId: second.id),
      },
      thetaEstimate: ThetaEstimate.initial(updatedAt: DateTime(2026)),
    );
    final repeated = strategy.selectNext(
      candidates: [first, second],
      domain: IntelligenceDomain.numerical,
      targetDifficulty: QuestionDifficulty.normal,
      usedItemIds: const {},
      seed: 11,
      thetaEstimate: ThetaEstimate.initial(updatedAt: DateTime(2026)),
    );

    expect(selected.id, second.id);
    expect(
      repeated.id,
      strategy
          .selectNext(
            candidates: [first, second],
            domain: IntelligenceDomain.numerical,
            targetDifficulty: QuestionDifficulty.normal,
            usedItemIds: const {},
            seed: 11,
            thetaEstimate: ThetaEstimate.initial(updatedAt: DateTime(2026)),
          )
          .id,
    );
  });

  test('QuestionRecord stores theta and CAT fields', () {
    final question = _question(itemInformation: 0.23, catSelectionScore: 0.71);
    final record = QuestionRecord.fromQuestion(
      question: question,
      correct: true,
      elapsedSeconds: 12,
      thetaBefore: 0,
      thetaAfter: 0.15,
    );

    expect(record.thetaBefore, 0);
    expect(record.thetaAfter, 0.15);
    expect(record.itemInformation, 0.23);
    expect(record.catSelectionScore, 0.71);
    expect(record.expectedProbability, 0.5);
    expect(record.likelihood, 1);
    expect(record.residual, 0);
    expect(record.totalInformation, 0);
  });

  test('TestSessionController stores theta history and psychometrics', () {
    final question = _question(discrimination: 1.5);
    final controller = TestSessionController(
      TestSession(
        sessionId: 'session-theta',
        startedAt: DateTime(2026),
        questions: [question],
        generatedQuestions: [question],
      ),
    )..selectAnswer(question.answerIndex);

    final session = controller.submit(completedAt: DateTime(2026, 1, 2));

    expect(session.thetaHistory, hasLength(1));
    expect(session.thetaEstimate.theta, greaterThan(0));
    expect(session.questionHistory.single.expectedProbability, greaterThan(0));
    expect(session.questionHistory.single.likelihood, greaterThan(0));
    expect(session.questionHistory.single.totalInformation, greaterThan(0));
  });

  testWidgets('Report question history is localized for users', (tester) async {
    final question = _question(itemInformation: 0.23, catSelectionScore: 0.71);
    final session = TestSession(
      sessionId: 'session-cat',
      startedAt: DateTime(2026),
      questions: [question],
      generatedQuestions: [question],
      questionHistory: [
        QuestionRecord.fromQuestion(
          question: question,
          correct: true,
          elapsedSeconds: 10,
          thetaBefore: 0,
          thetaAfter: 0.15,
        ),
      ],
      thetaEstimate: ThetaEstimate.initial(
        updatedAt: DateTime(2026),
      ).copyWith(theta: 0.15, standardError: 0.7, answeredCount: 1),
    );
    final state = HexaIQAppState(repository: _FakeRepository())
      ..testSessionController = TestSessionController(session)
      ..report = const ReportSummary(
        overallScore: 80,
        summary: '검사 결과 요약',
        domainScores: [
          DomainScore(
            domain: IntelligenceDomain.numerical,
            score: 80,
            percentile: 70,
            growth: 1,
            comment: 'OK',
          ),
        ],
        recommendations: [],
      );

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: state,
        child: const MaterialApp(home: ReportSummaryScreen()),
      ),
    );

    await tester.scrollUntilVisible(
      find.text('문항 기록'),
      300,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text('문항 기록'), findsOneWidget);
    expect(find.textContaining('1번 문항'), findsOneWidget);
    expect(find.textContaining('수리논리'), findsWidgets);
    expect(find.textContaining('정답'), findsWidgets);
    expect(find.textContaining('10초'), findsWidgets);
    expect(find.text('능력 추정값'), findsOneWidget);
    expect(find.text('추정 안정도'), findsOneWidget);
    expect(find.text('평균 정보량'), findsOneWidget);
    expect(find.textContaining('NR-'), findsNothing);
    expect(find.textContaining('numerical'), findsNothing);
    expect(find.textContaining('theta'), findsNothing);
    expect(find.textContaining('CAT'), findsNothing);
    expect(find.textContaining('info='), findsNothing);
  });
}

Item _item({
  required String id,
  double difficultyIndex = 0,
  double discrimination = 1,
}) {
  return Item(
    id: id,
    domain: IntelligenceDomain.numerical,
    difficulty: QuestionDifficulty.normal,
    difficultyIndex: difficultyIndex,
    discrimination: discrimination,
    guessing: 0.25,
    expectedSolveTime: const Duration(seconds: 30),
    question: '1, 2, ?',
    choices: const ['2', '3', '4', '5'],
    answer: '3',
    explanation: 'Add one.',
    tags: const ['type:NR01'],
    version: 'test',
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );
}

TestQuestion _question({
  double itemInformation = 0,
  double catSelectionScore = 0,
  double difficultyIndex = 0,
  double discrimination = 1,
}) {
  return TestQuestion(
    id: 'q1',
    domain: IntelligenceDomain.numerical,
    typeCode: 'NR01',
    level: 5,
    prompt: '1, 2, ?',
    choices: const ['2', '3', '4', '5'],
    answerIndex: 1,
    explanation: 'Add one.',
    difficulty: QuestionDifficulty.normal,
    difficultyIndex: difficultyIndex,
    discrimination: discrimination,
    itemId: 'NR-001',
    selectionScore: catSelectionScore,
    itemInformation: itemInformation,
    catSelectionScore: catSelectionScore,
  );
}

QuestionRecord _record({
  required bool correct,
  double difficultyIndex = 0,
  double discrimination = 1,
}) {
  return QuestionRecord.fromQuestion(
    question: _question(
      difficultyIndex: difficultyIndex,
      discrimination: discrimination,
    ),
    correct: correct,
    elapsedSeconds: 10,
  );
}

class _FakeRepository implements HexaIQRepository {
  @override
  Future<ReportSummary> buildReport(List<QuestionResponse> responses) async {
    throw UnimplementedError();
  }

  @override
  Future<List<GrowthPoint>> loadGrowth(UserProfile profile) async => const [];

  @override
  Future<List<TestQuestion>> loadQuestions(
    TestType testType, {
    UserProfile? profile,
  }) async {
    return const [];
  }

  @override
  Future<List<UserProfile>> loadProfiles() async => const [];

  @override
  Future<bool> verifyPayment({required TestType testType}) async => true;

  @override
  Future<bool> verifyRewardAd({
    required TestType testType,
    required int index,
  }) async {
    return true;
  }
}
