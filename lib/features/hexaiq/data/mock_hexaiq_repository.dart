import 'package:sqflite/sqflite.dart';

import '../../../core/domain/domain_result.dart';
import '../../../core/domain/intelligence_domain.dart';
import '../../../core/domain/question_difficulty.dart';
import '../../../core/persistence/hexa_iq_database.dart';
import '../../question_engine/data/mock_question_api.dart';
import '../../question_engine/domain/question_engine_models.dart';
import '../domain/hexaiq_models.dart';
import '../domain/hexaiq_repository.dart';

class MockHexaIQRepository implements HexaIQRepository {
  MockHexaIQRepository({MockQuestionApi? questionApi, this.database})
    : _questionApi = questionApi ?? MockQuestionApi();

  final MockQuestionApi _questionApi;
  final HexaIQDatabase? database;

  @override
  Future<List<UserProfile>> loadProfiles() async {
    final database = this.database;
    if (database != null) {
      final db = await database.open();
      final rows = await db.query('profiles', orderBy: 'id ASC');
      if (rows.isNotEmpty) {
        return rows.map(UserProfile.fromMap).toList(growable: false);
      }
      final defaults = await MockHexaIQRepository().loadProfiles();
      await saveProfiles(defaults);
      return defaults;
    }
    return const [
      UserProfile(
        id: 'profile-1',
        name: '민아',
        ageGroup: 'grade5_6',
        grade: '초5',
        avatar: '민',
      ),
      UserProfile(
        id: 'profile-2',
        name: '서연',
        ageGroup: 'grade3_4',
        grade: '초3',
        avatar: '서',
      ),
    ];
  }

  @override
  Future<void> saveProfiles(List<UserProfile> profiles) async {
    final database = this.database;
    if (database == null) {
      return;
    }
    final db = await database.open();
    final batch = db.batch();
    for (final profile in profiles) {
      batch.insert(
        'profiles',
        profile.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  @override
  Future<void> saveTestResult(TestResultSummary result) async {
    final database = this.database;
    if (database == null) {
      return;
    }
    final db = await database.open();
    await db.insert(
      'test_results',
      result.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<List<TestResultSummary>> loadTestHistory(String profileId) async {
    final database = this.database;
    if (database == null) {
      return const [];
    }
    final db = await database.open();
    final rows = await db.query(
      'test_results',
      where: 'profile_id = ?',
      whereArgs: [profileId],
      orderBy: 'completed_at DESC',
    );
    return rows.map(TestResultSummary.fromMap).toList(growable: false);
  }

  @override
  Future<List<TestQuestion>> loadQuestions(
    TestType testType, {
    UserProfile? profile,
  }) async {
    final resolvedProfile = profile ?? (await loadProfiles()).first;
    final generated = testType == TestType.quickIq
        ? await _questionApi.generateTestQuestions(
            profile: resolvedProfile,
            testType: testType,
          )
        : await _questionApi.generateQuestions(
            profile: resolvedProfile,
            domain: IntelligenceDomain.numerical,
            count: 5,
            testType: testType,
          );
    return generated.map(_toTestQuestion).toList(growable: false);
  }

  @override
  Future<ReportSummary> buildReport(List<QuestionResponse> responses) async {
    final domainResults = {
      for (final info in domainCatalog)
        info.domain: _buildDomainResult(responses, info.domain),
    };

    final scores = domainCatalog
        .map((info) {
          final result = domainResults[info.domain] ?? const DomainResult();
          final hasData = result.total > 0;
          final base = 52 + domainCatalog.indexOf(info) * 3;
          final score = hasData
              ? (base + result.accuracy * 35).round().clamp(0, 100)
              : 0;
          return DomainScore(
            domain: info.domain,
            score: score,
            percentile: hasData ? (score * 0.9).round().clamp(1, 99) : 0,
            growth: hasData ? 2.5 + domainCatalog.indexOf(info) * 0.7 : 0,
            comment: hasData
                ? '${info.label}: ${info.description}'
                : '${info.label}: 응답이 쌓이면 영역 결과가 표시됩니다.',
            isComingSoon: false,
          );
        })
        .toList(growable: false);

    final activeScores = scores.where((score) => score.score > 0).toList();
    final overall = activeScores.isEmpty
        ? 0
        : (activeScores.map((score) => score.score).reduce((a, b) => a + b) /
                  activeScores.length)
              .round();

    return ReportSummary(
      overallScore: overall,
      summary: '응답이 기록된 영역을 기준으로 결과를 계산했습니다.',
      domainScores: scores,
      recommendations: const [
        '빠른 IQ로 6개 영역을 짧게 반복 점검해 보세요.',
        '점수가 낮은 영역은 같은 유형을 다시 풀어 안정도를 높여 보세요.',
        '처리속도 영역은 정답률과 풀이 시간을 함께 확인해 보세요.',
      ],
      domainResults: domainResults,
      averageDifficulty: _averageDifficulty(responses),
    );
  }

  @override
  Future<List<GrowthPoint>> loadGrowth(UserProfile profile) async {
    final history = await loadTestHistory(profile.id);
    if (history.isNotEmpty) {
      final recent = history.take(6).toList(growable: false);
      return [
        for (var i = 0; i < recent.length; i++)
          GrowthPoint(
            month: 'T${recent.length - i}',
            score: recent[i].estimatedIQ,
          ),
      ].reversed.toList(growable: false);
    }
    return const [
      GrowthPoint(month: 'T1', score: 61),
      GrowthPoint(month: 'T2', score: 64),
      GrowthPoint(month: 'T3', score: 68),
      GrowthPoint(month: 'T4', score: 72),
    ];
  }

  @override
  Future<bool> verifyRewardAd({
    required TestType testType,
    required int index,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return true;
  }

  @override
  Future<bool> verifyPayment({required TestType testType}) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return testType == TestType.professional;
  }

  TestQuestion _toTestQuestion(GeneratedQuestionDto dto) {
    return TestQuestion(
      id: dto.id,
      domain: dto.domain,
      typeCode: dto.typeCode,
      level: dto.level,
      prompt: dto.question,
      choices: dto.choices,
      answerIndex: dto.answerIndex,
      explanation: dto.explanation,
      difficulty: dto.difficulty,
      seed: dto.seed,
      difficultyIndex: dto.difficultyIndex,
      discrimination: dto.discrimination,
      guessing: dto.guessing,
      upperAsymptote: dto.upperAsymptote,
      expectedSolveTime: dto.expectedSolveTime,
      itemId: dto.itemId,
      selectionScore: dto.selectionScore,
      itemInformation: dto.itemInformation,
      catSelectionScore: dto.catSelectionScore,
      hint: dto.hint,
      ruleName: dto.ruleName,
      solution: dto.solution,
      solutionExplanation: dto.solutionExplanation,
      variables: dto.variables,
      stimulus: dto.stimulus,
      stimulusDuration: dto.stimulusDuration,
      requiresMemoryPhase: dto.requiresMemoryPhase,
      timeLimit: dto.timeLimit,
      reactionScore: dto.reactionScore,
    );
  }

  QuestionDifficulty _averageDifficulty(List<QuestionResponse> responses) {
    if (responses.isEmpty) {
      return QuestionDifficulty.normal;
    }
    final average =
        responses
            .map((response) => response.question.difficulty.level)
            .reduce((a, b) => a + b) /
        responses.length;
    return QuestionDifficulty.values.reduce((nearest, difficulty) {
      final nearestDistance = (nearest.level - average).abs();
      final currentDistance = (difficulty.level - average).abs();
      return currentDistance < nearestDistance ? difficulty : nearest;
    });
  }

  DomainResult _buildDomainResult(
    List<QuestionResponse> responses,
    IntelligenceDomain domain,
  ) {
    final domainResponses = responses
        .where((response) => response.question.domain == domain)
        .toList(growable: false);
    if (domainResponses.isEmpty) {
      return const DomainResult();
    }
    final correct = domainResponses
        .where((response) => response.isCorrect)
        .length;
    final wrong = domainResponses.length - correct;
    return DomainResult(
      correct: correct,
      wrong: wrong,
      accuracy: correct / domainResponses.length,
    );
  }
}
