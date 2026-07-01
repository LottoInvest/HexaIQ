import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../../../core/domain/intelligence_domain.dart';
import '../../../core/domain/question_difficulty.dart';
import '../../../core/persistence/hexa_iq_database.dart';
import '../../question_engine/data/mock_question_api.dart';
import '../../question_engine/domain/question_engine_models.dart';
import '../../payment/domain/purchase_status.dart';
import '../../report/domain/domain_score_calculator.dart';
import '../../report/domain/report_localization.dart';
import '../../test/domain/models/test_item.dart';
import '../../test/domain/models/test_mode.dart';
import '../../test/domain/models/test_response.dart';
import '../../test/domain/models/test_session.dart';
import '../../training/domain/training_result.dart';
import '../domain/hexaiq_models.dart';
import '../domain/hexaiq_repository.dart';

class MockHexaIQRepository implements HexaIQRepository {
  MockHexaIQRepository({MockQuestionApi? questionApi, this.database})
    : _questionApi = questionApi ?? MockQuestionApi();

  final MockQuestionApi _questionApi;
  final HexaIQDatabase? database;
  final Map<String, TestSession> _activeSessions = {};
  final Map<String, List<TrainingResult>> _trainingHistory = {};

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
    if (profiles.isEmpty) {
      batch.delete('profiles');
    } else {
      batch.delete(
        'profiles',
        where: 'id NOT IN (${List.filled(profiles.length, '?').join(', ')})',
        whereArgs: profiles.map((profile) => profile.id).toList(),
      );
    }
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
  Future<void> saveTrainingResult(TrainingResult result) async {
    final existing = _trainingHistory[result.profileId] ?? const [];
    _trainingHistory[result.profileId] = [
      result,
      ...existing.where((item) => item.id != result.id),
    ]..sort((a, b) => b.completedAt.compareTo(a.completedAt));

    final database = this.database;
    if (database == null) {
      return;
    }
    final db = await database.open();
    await db.insert(
      'training_results',
      result.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<List<TrainingResult>> loadTrainingHistory(String profileId) async {
    final cached = _trainingHistory[profileId];
    if (cached != null) {
      return cached;
    }
    final database = this.database;
    if (database == null) {
      return const [];
    }
    final db = await database.open();
    final rows = await db.query(
      'training_results',
      where: 'profile_id = ?',
      whereArgs: [profileId],
      orderBy: 'completed_at DESC',
    );
    final history = rows.map(TrainingResult.fromMap).toList(growable: false);
    _trainingHistory[profileId] = history;
    return history;
  }

  @override
  Future<void> saveActiveTestSession({
    required String profileId,
    required TestSession session,
  }) async {
    _activeSessions[profileId] = session;
    final database = this.database;
    if (database == null) {
      return;
    }
    final db = await database.open();
    await db.insert('active_test_sessions', {
      'profile_id': profileId,
      'session_id': session.sessionId,
      'payload_json': jsonEncode(_sessionToJson(session)),
      'updated_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<TestSession?> loadActiveTestSession(String profileId) async {
    final cached = _activeSessions[profileId];
    if (cached != null && !cached.isComplete) {
      return cached;
    }
    final database = this.database;
    if (database == null) {
      return null;
    }
    final db = await database.open();
    final rows = await db.query(
      'active_test_sessions',
      where: 'profile_id = ?',
      whereArgs: [profileId],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    final payload = rows.first['payload_json'] as String? ?? '{}';
    final decoded = jsonDecode(payload) as Map<String, Object?>;
    final session = _sessionFromJson(decoded);
    if (session.isComplete) {
      return null;
    }
    _activeSessions[profileId] = session;
    return session;
  }

  @override
  Future<void> clearActiveTestSession(String profileId) async {
    _activeSessions.remove(profileId);
    final database = this.database;
    if (database == null) {
      return;
    }
    final db = await database.open();
    await db.delete(
      'active_test_sessions',
      where: 'profile_id = ?',
      whereArgs: [profileId],
    );
  }

  @override
  Future<PurchaseStatus> loadPurchaseStatus() async {
    final database = this.database;
    if (database == null) {
      return PurchaseStatus.free;
    }
    final db = await database.open();
    final rows = await db.query(
      'settings',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: ['purchase_status'],
      limit: 1,
    );
    if (rows.isEmpty) {
      return PurchaseStatus.free;
    }
    return PurchaseStatus.values.byName(
      rows.single['value'] as String? ?? PurchaseStatus.free.name,
    );
  }

  @override
  Future<void> savePurchaseStatus(PurchaseStatus status) async {
    final database = this.database;
    if (database == null) {
      return;
    }
    final db = await database.open();
    await db.insert('settings', {
      'key': 'purchase_status',
      'value': status.name,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<List<TestQuestion>> loadQuestions(
    TestType testType, {
    UserProfile? profile,
  }) async {
    final resolvedProfile = profile ?? (await loadProfiles()).first;
    final generated = await _questionApi.generateTestQuestions(
      profile: resolvedProfile,
      testType: testType,
    );
    return generated.map(_toTestQuestion).toList(growable: false);
  }

  @override
  Future<ReportSummary> buildReport(List<QuestionResponse> responses) async {
    const calculator = DomainScoreCalculator();
    final domainResults = {
      for (final info in domainCatalog)
        info.domain: calculator.calculateFromResponses(
          domain: info.domain,
          responses: responses,
        ),
    };
    final scores = calculator.scoresFromResults(domainResults);
    final activeScores = scores.where((score) => score.score > 0).toList();
    final overall = activeScores.isEmpty
        ? 0
        : (activeScores.map((score) => score.score).reduce((a, b) => a + b) /
                  activeScores.length)
              .round();

    return ReportSummary(
      overallScore: overall,
      summary: ReportLocalization.summary,
      domainScores: scores,
      recommendations: ReportLocalization.trainingRecommendations(
        domainResults,
      ),
      domainResults: domainResults,
      averageDifficulty: _averageDifficulty(responses),
    );
  }

  @override
  Future<List<GrowthPoint>> loadGrowth(UserProfile profile) async {
    final history = await loadTestHistory(profile.id);
    if (history.isEmpty) {
      return const [];
    }
    final chronological = history
        .take(6)
        .toList(growable: false)
        .reversed
        .toList(growable: false);
    return [
      for (var i = 0; i < chronological.length; i++)
        GrowthPoint(month: 'T${i + 1}', score: chronological[i].estimatedIQ),
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

  Map<String, Object?> _sessionToJson(TestSession session) {
    return {
      'sessionId': session.sessionId,
      'startedAt': session.startedAt.toIso8601String(),
      'completedAt': session.completedAt?.toIso8601String(),
      'mode': session.mode.name,
      'domain': session.domain.name,
      'currentQuestionIndex': session.currentQuestionIndex,
      'targetQuestionCount': session.targetQuestionCount,
      'questions': [
        for (final question in session.activeQuestions)
          _questionToJson(question),
      ],
      'items': [for (final item in session.items) item.toJson()],
      'responses': [
        for (final response in session.responses) response.toJson(),
      ],
      'selectedAnswers': session.selectedAnswers,
      'elapsedSeconds': session.elapsedSeconds,
      'totalElapsedSeconds': session.totalElapsedSeconds,
      'difficultyByQuestionId': {
        for (final entry in session.difficultyByQuestionId.entries)
          entry.key: entry.value.name,
      },
      'usedItemIds': session.usedItemIds.toList(growable: false),
      'baseSeed': session.baseSeed,
    };
  }

  TestSession _sessionFromJson(Map<String, Object?> json) {
    final questions = ((json['questions'] as List?) ?? const [])
        .cast<Map>()
        .map((item) => _questionFromJson(item.cast<String, Object?>()))
        .toList(growable: false);
    final selectedAnswers = ((json['selectedAnswers'] as Map?) ?? const {}).map(
      (key, value) => MapEntry(key as String, (value as num).toInt()),
    );
    final elapsedSeconds = ((json['elapsedSeconds'] as Map?) ?? const {}).map(
      (key, value) => MapEntry(key as String, (value as num).toInt()),
    );
    final difficultyByQuestionId =
        ((json['difficultyByQuestionId'] as Map?) ?? const {}).map(
          (key, value) => MapEntry(
            key as String,
            QuestionDifficulty.values.byName(value as String),
          ),
        );
    return TestSession(
      sessionId: json['sessionId'] as String,
      startedAt: DateTime.parse(json['startedAt'] as String),
      completedAt: DateTime.tryParse(json['completedAt'] as String? ?? ''),
      mode: TestMode.values.byName(json['mode'] as String? ?? 'quickIq'),
      domain: IntelligenceDomain.values.byName(
        json['domain'] as String? ?? 'numerical',
      ),
      currentQuestionIndex:
          (json['currentQuestionIndex'] as num?)?.toInt() ?? 0,
      questions: questions,
      generatedQuestions: questions,
      items: ((json['items'] as List?) ?? const [])
          .cast<Map>()
          .map((item) => TestItem.fromJson(item.cast<String, Object?>()))
          .toList(growable: false),
      responses: ((json['responses'] as List?) ?? const [])
          .cast<Map>()
          .map((item) => TestResponse.fromJson(item.cast<String, Object?>()))
          .toList(growable: false),
      targetQuestionCount: (json['targetQuestionCount'] as num?)?.toInt() ?? 5,
      selectedAnswers: selectedAnswers,
      elapsedSeconds: elapsedSeconds,
      difficultyByQuestionId: difficultyByQuestionId,
      usedItemIds: ((json['usedItemIds'] as List?) ?? const [])
          .cast<String>()
          .toSet(),
      totalElapsedSeconds: (json['totalElapsedSeconds'] as num?)?.toInt() ?? 0,
      baseSeed: (json['baseSeed'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, Object?> _questionToJson(TestQuestion question) {
    return {
      'id': question.id,
      'domain': question.domain.name,
      'typeCode': question.typeCode,
      'level': question.level,
      'prompt': question.prompt,
      'choices': question.choices,
      'answerIndex': question.answerIndex,
      'explanation': question.explanation,
      'difficulty': question.difficulty.name,
      'seed': question.seed,
      'difficultyIndex': question.difficultyIndex,
      'discrimination': question.discrimination,
      'guessing': question.guessing,
      'upperAsymptote': question.upperAsymptote,
      'expectedSolveTimeMs': question.expectedSolveTime.inMilliseconds,
      'itemId': question.itemId,
      'hint': question.hint,
      'ruleName': question.ruleName,
      'solution': question.solution,
      'solutionExplanation': question.solutionExplanation,
      'stimulus': question.stimulus,
      'stimulusDurationMs': question.stimulusDuration?.inMilliseconds,
      'requiresMemoryPhase': question.requiresMemoryPhase,
      'timeLimitMs': question.timeLimit?.inMilliseconds,
      'reactionScore': question.reactionScore,
    };
  }

  TestQuestion _questionFromJson(Map<String, Object?> json) {
    return TestQuestion(
      id: json['id'] as String,
      domain: IntelligenceDomain.values.byName(json['domain'] as String),
      typeCode: json['typeCode'] as String,
      level: (json['level'] as num).toInt(),
      prompt: json['prompt'] as String,
      choices: (json['choices'] as List).cast<String>(),
      answerIndex: (json['answerIndex'] as num).toInt(),
      explanation: json['explanation'] as String,
      difficulty: QuestionDifficulty.values.byName(
        json['difficulty'] as String,
      ),
      seed: (json['seed'] as num?)?.toInt() ?? 0,
      difficultyIndex: (json['difficultyIndex'] as num?)?.toDouble() ?? 0,
      discrimination: (json['discrimination'] as num?)?.toDouble() ?? 1,
      guessing: (json['guessing'] as num?)?.toDouble() ?? 0.25,
      upperAsymptote: (json['upperAsymptote'] as num?)?.toDouble() ?? 1,
      expectedSolveTime: Duration(
        milliseconds: (json['expectedSolveTimeMs'] as num?)?.toInt() ?? 0,
      ),
      itemId: json['itemId'] as String?,
      hint: json['hint'] as String?,
      ruleName: json['ruleName'] as String?,
      solution: json['solution'] as String?,
      solutionExplanation: json['solutionExplanation'] as String?,
      stimulus: json['stimulus'] as String?,
      stimulusDuration: json['stimulusDurationMs'] == null
          ? null
          : Duration(milliseconds: (json['stimulusDurationMs'] as num).toInt()),
      requiresMemoryPhase: json['requiresMemoryPhase'] as bool? ?? false,
      timeLimit: json['timeLimitMs'] == null
          ? null
          : Duration(milliseconds: (json['timeLimitMs'] as num).toInt()),
      reactionScore: (json['reactionScore'] as num?)?.toDouble(),
    );
  }
}
