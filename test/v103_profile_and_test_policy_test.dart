import 'package:flutter_test/flutter_test.dart';
import 'package:hexaiq_app/core/domain/domain_result.dart';
import 'package:hexaiq_app/core/domain/intelligence_domain.dart';
import 'package:hexaiq_app/core/domain/question_difficulty.dart';
import 'package:hexaiq_app/core/persistence/hexa_iq_database.dart';
import 'package:hexaiq_app/features/hexaiq/data/mock_hexaiq_repository.dart';
import 'package:hexaiq_app/features/hexaiq/domain/hexaiq_models.dart';
import 'package:hexaiq_app/features/hexaiq/presentation/state/hexaiq_app_state.dart';
import 'package:hexaiq_app/features/question_engine/data/mock_question_api.dart';
import 'package:hexaiq_app/features/test/application/test_flow_controller.dart';
import 'package:hexaiq_app/features/test/domain/models/test_mode.dart';
import 'package:hexaiq_app/features/training/domain/training_result.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
  });

  test(
    'profile switch clears profile scoped report and active test state',
    () async {
      final state = HexaIQAppState(repository: MockHexaIQRepository());
      await state.loadInitialData();
      await state.startTest();

      state.report = const ReportSummary(
        overallScore: 80,
        summary: 'cached report',
        domainScores: [],
        recommendations: [],
        domainResults: {
          IntelligenceDomain.numerical: DomainResult(totalCount: 1),
        },
      );
      expect(state.testSession, isNotNull);
      expect(state.report, isNotNull);

      await state.selectProfile(state.profiles.last);

      expect(state.selectedProfile?.id, state.profiles.last.id);
      expect(state.testSession, isNull);
      expect(state.report, isNull);
      expect(state.responses, isEmpty);
      expect(state.totalQuestionCount, 0);
      expect(state.growth, isEmpty);
    },
  );

  test('test mode policy uses v1.0.3 counts and equal domains', () async {
    const flow = TestFlowController();

    expect(flow.targetQuestionCount(TestType.basic), 30);
    expect(flow.questionsPerDomain(TestType.basic), 5);
    expect(flow.targetQuestionCount(TestType.quickIq), 60);
    expect(flow.questionsPerDomain(TestType.quickIq), 10);
    expect(flow.targetQuestionCount(TestType.advanced), 90);
    expect(flow.questionsPerDomain(TestType.advanced), 15);

    final api = MockQuestionApi();
    for (final entry in const {
      TestType.basic: 5,
      TestType.quickIq: 10,
      TestType.advanced: 15,
    }.entries) {
      final questions = await api.generateTestQuestions(
        profile: _profile,
        testType: entry.key,
      );
      expect(questions.length, entry.value * IntelligenceDomain.values.length);
      for (final domain in IntelligenceDomain.values) {
        expect(
          questions.where((question) => question.domain == domain).length,
          entry.value,
        );
      }
    }
  });

  test('Basic IQ starts as diagnostic test, not training mode', () async {
    final state = HexaIQAppState(repository: MockHexaIQRepository());
    await state.loadInitialData();
    state.selectTestType(TestType.basic);
    await state.startTest();

    expect(state.testSession?.mode, TestMode.fullDiagnostic);
    expect(state.totalQuestionCount, 30);
    expect(state.requiredAds, 0);
    expect(state.activeDomainSequence, IntelligenceDomain.values);
  });

  test(
    'training result is profile scoped and never saved as test history',
    () async {
      final database = HexaIQDatabase(
        factory: databaseFactoryFfi,
        databasePath: inMemoryDatabasePath,
      );
      final repository = MockHexaIQRepository(database: database);
      final completedAt = DateTime(2026, 7, 1, 21);

      await repository.saveTrainingResult(
        TrainingResult(
          id: 'training-v103',
          profileId: 'profile-training',
          selectedDomains: const [IntelligenceDomain.numerical],
          selectedDifficulty: QuestionDifficulty.normal,
          questionCount: 10,
          correctCount: 7,
          completedAt: completedAt,
        ),
      );

      expect(await repository.loadTestHistory('profile-training'), isEmpty);
      final trainingHistory = await repository.loadTrainingHistory(
        'profile-training',
      );
      expect(trainingHistory, hasLength(1));
      expect(trainingHistory.single.profileId, 'profile-training');
      expect(await repository.loadTrainingHistory('other-profile'), isEmpty);

      await database.close();
    },
  );
}

const _profile = UserProfile(
  id: 'profile-v103',
  name: 'V103',
  ageGroup: 'grade5_6',
  grade: 'grade5',
  avatar: 'V',
);
