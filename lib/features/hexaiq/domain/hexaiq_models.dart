enum CognitiveDomain { numerical, spatial, logical, verbal, memory, pattern }

enum TestType { basic, advanced, professional }

class DomainInfo {
  const DomainInfo({
    required this.domain,
    required this.label,
    required this.shortLabel,
    required this.description,
  });

  final CognitiveDomain domain;
  final String label;
  final String shortLabel;
  final String description;
}

const domainCatalog = [
  DomainInfo(
    domain: CognitiveDomain.numerical,
    label: '수리논리',
    shortLabel: '수리',
    description: '수열, 계산 규칙, 비율을 빠르게 파악하는 힘',
  ),
  DomainInfo(
    domain: CognitiveDomain.spatial,
    label: '공간지각',
    shortLabel: '공간',
    description: '도형의 회전, 위치, 관계를 머릿속에서 다루는 힘',
  ),
  DomainInfo(
    domain: CognitiveDomain.logical,
    label: '논리추론',
    shortLabel: '논리',
    description: '조건과 규칙을 차분하게 연결해 결론을 찾는 힘',
  ),
  DomainInfo(
    domain: CognitiveDomain.verbal,
    label: '언어유추',
    shortLabel: '언어',
    description: '단어 관계와 문맥의 의미를 이해하는 힘',
  ),
  DomainInfo(
    domain: CognitiveDomain.memory,
    label: '작업기억',
    shortLabel: '기억',
    description: '짧은 정보를 유지하고 다시 처리하는 힘',
  ),
  DomainInfo(
    domain: CognitiveDomain.pattern,
    label: '추상패턴',
    shortLabel: '패턴',
    description: '기호와 형태 안의 반복 규칙을 발견하는 힘',
  ),
];

String domainLabel(CognitiveDomain domain) {
  return domainCatalog.firstWhere((item) => item.domain == domain).label;
}

String domainShortLabel(CognitiveDomain domain) {
  return domainCatalog.firstWhere((item) => item.domain == domain).shortLabel;
}

String testTypeLabel(TestType type) {
  return switch (type) {
    TestType.basic => 'Basic',
    TestType.advanced => 'Advanced',
    TestType.professional => 'Professional',
  };
}

String testTypeDescription(TestType type) {
  return switch (type) {
    TestType.basic => '6개 영역을 빠르게 훑는 무료 기본 검사',
    TestType.advanced => '문항 수를 늘려 영역별 경향을 더 자세히 보는 검사',
    TestType.professional => '광고 없이 긴 문항과 상세 리포트를 제공하는 검사',
  };
}

class UserProfile {
  const UserProfile({
    required this.id,
    required this.name,
    required this.ageGroup,
    required this.grade,
    required this.avatar,
  });

  final String id;
  final String name;
  final String ageGroup;
  final String grade;
  final String avatar;
}

class TestQuestion {
  const TestQuestion({
    required this.id,
    required this.domain,
    required this.typeCode,
    required this.level,
    required this.prompt,
    required this.choices,
    required this.answerIndex,
    required this.explanation,
  });

  final String id;
  final CognitiveDomain domain;
  final String typeCode;
  final int level;
  final String prompt;
  final List<String> choices;
  final int answerIndex;
  final String explanation;
}

class QuestionResponse {
  const QuestionResponse({required this.question, required this.selectedIndex});

  final TestQuestion question;
  final int selectedIndex;

  bool get isCorrect => selectedIndex == question.answerIndex;
}

class DomainScore {
  const DomainScore({
    required this.domain,
    required this.score,
    required this.percentile,
    required this.growth,
    required this.comment,
  });

  final CognitiveDomain domain;
  final int score;
  final int percentile;
  final double growth;
  final String comment;
}

class ReportSummary {
  const ReportSummary({
    required this.overallScore,
    required this.summary,
    required this.domainScores,
    required this.recommendations,
  });

  final int overallScore;
  final String summary;
  final List<DomainScore> domainScores;
  final List<String> recommendations;
}

class GrowthPoint {
  const GrowthPoint({required this.month, required this.score});

  final String month;
  final int score;
}
