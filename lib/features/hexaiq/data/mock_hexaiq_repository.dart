import '../../../core/domain/domain_result.dart';
import '../../../core/domain/intelligence_domain.dart';
import '../../../core/domain/question_difficulty.dart';
import '../../question_engine/data/mock_question_api.dart';
import '../../question_engine/domain/question_engine_models.dart';
import '../domain/hexaiq_models.dart';
import '../domain/hexaiq_repository.dart';

class MockHexaIQRepository implements HexaIQRepository {
  MockHexaIQRepository({MockQuestionApi? questionApi})
    : _questionApi = questionApi ?? MockQuestionApi();

  final MockQuestionApi _questionApi;

  @override
  Future<List<UserProfile>> loadProfiles() async {
    return const [
      UserProfile(
        id: 'profile-1',
        name: '민지',
        ageGroup: '초등 5-6',
        grade: '초등 5학년',
        avatar: 'M',
      ),
      UserProfile(
        id: 'profile-2',
        name: '서연',
        ageGroup: '초등 3-4',
        grade: '초등 3학년',
        avatar: 'S',
      ),
    ];
  }

  @override
  Future<List<TestQuestion>> loadQuestions(
    TestType testType, {
    UserProfile? profile,
  }) async {
    final resolvedProfile = profile ?? (await loadProfiles()).first;
    final generated = await _questionApi.generateQuestions(
      profile: resolvedProfile,
      domain: IntelligenceDomain.numerical,
      count: 5,
      testType: testType,
    );
    return generated.map(_toTestQuestion).toList();
  }

  @override
  Future<ReportSummary> buildReport(List<QuestionResponse> responses) async {
    final domainResults = {
      for (final info in domainCatalog)
        info.domain: _buildDomainResult(responses, info.domain),
    };

    final scores = domainCatalog.map((info) {
      final result = domainResults[info.domain] ?? const DomainResult();
      final isComingSoon = info.domain != IntelligenceDomain.numerical;
      final base = 52 + domainCatalog.indexOf(info) * 3;
      final score = isComingSoon
          ? 0
          : (base + result.accuracy * 35).round().clamp(0, 100);
      return DomainScore(
        domain: info.domain,
        score: score,
        percentile: isComingSoon ? 0 : (score * 0.9).round().clamp(1, 99),
        growth: isComingSoon ? 0 : 2.5 + domainCatalog.indexOf(info) * 0.7,
        comment: isComingSoon
            ? '${info.label} 영역은 Coming Soon입니다.'
            : '${info.label}는 ${info.description}과 관련된 참고 지표입니다. 반복 검사로 변화 추이를 확인하세요.',
        isComingSoon: isComingSoon,
      );
    }).toList();

    final activeScores = scores.where((score) => !score.isComingSoon).toList();
    final overall = activeScores.isEmpty
        ? 0
        : (activeScores.map((score) => score.score).reduce((a, b) => a + b) /
                  activeScores.length)
              .round();

    return ReportSummary(
      overallScore: overall,
      summary:
          '이번 MVP 검사에서는 Numerical 결과를 실제 계산하고, 나머지 영역은 Coming Soon으로 표시합니다.',
      domainScores: scores,
      recommendations: const [
        'Numerical 영역은 Basic 재검사로 변화 추이를 확인하세요.',
        'Verbal, Spatial, Memory, Logic, Processing은 이후 실제 문항으로 확장됩니다.',
        '강한 영역은 심화 문항으로 넓히고, 약한 영역은 짧게 반복하는 훈련이 좋습니다.',
      ],
      domainResults: domainResults,
      averageDifficulty: _averageDifficulty(responses),
    );
  }

  @override
  Future<List<GrowthPoint>> loadGrowth(UserProfile profile) async {
    return const [
      GrowthPoint(month: '3월', score: 61),
      GrowthPoint(month: '4월', score: 64),
      GrowthPoint(month: '5월', score: 68),
      GrowthPoint(month: '6월', score: 72),
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
      expectedSolveTime: dto.expectedSolveTime,
      itemId: dto.itemId,
      selectionScore: dto.selectionScore,
      itemInformation: dto.itemInformation,
      catSelectionScore: dto.catSelectionScore,
      hint: dto.hint,
      ruleName: dto.ruleName,
      solution: dto.solution,
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
