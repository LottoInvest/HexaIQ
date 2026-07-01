import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexaiq_app/core/domain/question_difficulty.dart';
import 'package:hexaiq_app/features/hexaiq/domain/hexaiq_models.dart';
import 'package:hexaiq_app/features/hexaiq/domain/hexaiq_repository.dart';
import 'package:hexaiq_app/features/hexaiq/presentation/state/hexaiq_app_state.dart';
import 'package:hexaiq_app/features/history/presentation/history_screen.dart';
import 'package:hexaiq_app/features/payment/domain/purchase_status.dart';
import 'package:hexaiq_app/features/result/domain/test_result_payload.dart';
import 'package:hexaiq_app/features/test/domain/models/test_mode.dart';
import 'package:hexaiq_app/features/test/domain/models/test_session.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('history card shows persisted question, correct, IQ, and time', (
    tester,
  ) async {
    final result = _result();
    final state = HexaIQAppState(
      repository: _WidgetRepository(results: [result]),
    );

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: state,
        child: const MaterialApp(home: HistoryScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('history-result-history-36')),
      findsOneWidget,
    );
    expect(find.textContaining('정답 14 / 36'), findsOneWidget);
    expect(find.textContaining('정답률 39%'), findsOneWidget);
    expect(find.textContaining('풀이 시간 6분'), findsOneWidget);
    expect(find.text('IQ 96'), findsOneWidget);
    expect(find.text('상위 비율 42%'), findsOneWidget);
  });

  testWidgets('history hides invalid saved results', (tester) async {
    final invalid = _result(
      id: 'invalid',
      totalQuestions: 0,
      correctCount: 1,
      percentile: 0,
    );
    final state = HexaIQAppState(
      repository: _WidgetRepository(results: [invalid]),
    );

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: state,
        child: const MaterialApp(home: HistoryScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('검사 결과를 불러올 수 없습니다. 다시 검사해 주세요.'), findsOneWidget);
    expect(find.byKey(const ValueKey('history-result-invalid')), findsNothing);
  });
}

class _WidgetRepository extends HexaIQRepository {
  _WidgetRepository({required this.results});

  final List<TestResultSummary> results;
  final _profile = const UserProfile(
    id: 'profile-1',
    name: '테스트',
    ageGroup: 'adult',
    grade: '성인',
    avatar: '🙂',
  );

  @override
  Future<List<UserProfile>> loadProfiles() async => [_profile];

  @override
  Future<List<TestResultSummary>> loadTestHistory(String profileId) async {
    return results.where((result) => result.profileId == profileId).toList();
  }

  @override
  Future<List<GrowthPoint>> loadGrowth(UserProfile profile) async => [
    for (var i = 0; i < results.length; i++)
      GrowthPoint(month: 'T${i + 1}', score: results[i].estimatedIQ),
  ];

  @override
  Future<PurchaseStatus> loadPurchaseStatus() async => PurchaseStatus.free;

  @override
  Future<List<TestQuestion>> loadQuestions(
    TestType testType, {
    UserProfile? profile,
  }) async => const [];

  @override
  Future<ReportSummary> buildReport(List<QuestionResponse> responses) async {
    return const ReportSummary(
      overallScore: 0,
      summary: '',
      domainScores: [],
      recommendations: [],
    );
  }

  @override
  Future<TestSession?> loadActiveTestSession(String profileId) async => null;

  @override
  Future<bool> verifyRewardAd({
    required TestType testType,
    required int index,
  }) async => true;

  @override
  Future<bool> verifyPayment({required TestType testType}) async => true;
}

TestResultSummary _result({
  String id = 'history-36',
  int totalQuestions = 36,
  int correctCount = 14,
  int percentile = 42,
}) {
  final payload = TestResultPayload(
    resultId: id,
    profileId: 'profile-1',
    testMode: TestMode.quickIq,
    totalQuestions: totalQuestions,
    answeredQuestions: totalQuestions,
    correctCount: correctCount,
    accuracy: totalQuestions == 0 ? 0 : correctCount / totalQuestions,
    totalElapsedSeconds: 360,
    averageElapsedSeconds: 10,
    questionIds: List.generate(totalQuestions, (index) => 'q-$index'),
    domainScores: const {},
  );
  return TestResultSummary(
    id: id,
    profileId: 'profile-1',
    startedAt: DateTime(2026, 7),
    completedAt: DateTime(2026, 7, 1, 0, 6),
    theta: -0.2,
    standardError: 0.6,
    estimatedIQ: 96,
    percentile: percentile,
    abilityLevel: '평균',
    averageDifficulty: QuestionDifficulty.normal,
    averageElapsedSeconds: 10,
    questionCount: totalQuestions,
    payloadJson: payload.encode(),
  );
}
