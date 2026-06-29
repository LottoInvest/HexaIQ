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
    final generated = await _questionApi.generateTestQuestions(
      profile: resolvedProfile,
      testType: testType,
    );
    return generated.map(_toTestQuestion).toList();
  }

  @override
  Future<ReportSummary> buildReport(List<QuestionResponse> responses) async {
    final scores = domainCatalog.map((info) {
      final domainResponses = responses
          .where((response) => response.question.domain == info.domain)
          .toList();
      final correct = domainResponses
          .where((response) => response.isCorrect)
          .length;
      final ratio = domainResponses.isEmpty
          ? 0.0
          : correct / domainResponses.length;
      final base = 52 + domainCatalog.indexOf(info) * 3;
      final score = (base + ratio * 35).round().clamp(0, 100);
      return DomainScore(
        domain: info.domain,
        score: score,
        percentile: (score * 0.9).round().clamp(1, 99),
        growth: 2.5 + domainCatalog.indexOf(info) * 0.7,
        comment:
            '${info.label}은 ${info.description}과 관련된 참고 지표입니다. 반복 검사로 변화 추이를 확인하세요.',
      );
    }).toList();

    final overall =
        (scores.map((score) => score.score).reduce((a, b) => a + b) /
                scores.length)
            .round();

    return ReportSummary(
      overallScore: overall,
      summary:
          '이번 mock 검사에서는 규칙을 찾고 단계적으로 해결하는 과제에서 안정적인 흐름을 보였습니다. 이 점수는 학습 참고 지표이며, 반복 훈련과 재검사를 통해 변화 추이를 보는 것이 좋습니다.',
      domainScores: scores,
      recommendations: const [
        '하루 10분씩 가장 낮은 영역부터 짧게 반복해 보세요.',
        '2주 뒤 Basic 재검사로 변화 추이를 확인하세요.',
        '강한 영역은 심화 문항으로 사고 시간을 조금씩 늘려도 좋습니다.',
      ],
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
      domain: _toCognitiveDomain(dto.domain),
      typeCode: dto.typeCode,
      level: dto.level,
      prompt: dto.question,
      choices: dto.choices,
      answerIndex: dto.answerIndex,
      explanation: dto.explanation,
    );
  }

  CognitiveDomain _toCognitiveDomain(QuestionDomain domain) {
    return CognitiveDomain.values.firstWhere(
      (item) => item.name == domain.name,
    );
  }
}
