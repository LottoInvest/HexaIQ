import '../../../core/domain/domain_result.dart';
import '../../../core/domain/intelligence_domain.dart';
import '../../../core/domain/question_difficulty.dart';

typedef CognitiveDomain = IntelligenceDomain;

enum TestType { basic, advanced, professional }

class DomainInfo {
  const DomainInfo({
    required this.domain,
    required this.label,
    required this.shortLabel,
    required this.description,
  });

  final IntelligenceDomain domain;
  final String label;
  final String shortLabel;
  final String description;
}

final domainCatalog = [
  DomainInfo(
    domain: IntelligenceDomain.numerical,
    label: IntelligenceDomain.numerical.label,
    shortLabel: IntelligenceDomain.numerical.shortLabel,
    description: '수열, 계산 규칙, 비율을 빠르게 파악하는 힘',
  ),
  DomainInfo(
    domain: IntelligenceDomain.verbal,
    label: IntelligenceDomain.verbal.label,
    shortLabel: IntelligenceDomain.verbal.shortLabel,
    description: '단어 관계와 문장의 의미를 이해하고 추론하는 힘',
  ),
  DomainInfo(
    domain: IntelligenceDomain.spatial,
    label: IntelligenceDomain.spatial.label,
    shortLabel: IntelligenceDomain.spatial.shortLabel,
    description: '도형의 회전, 위치, 관계를 머릿속에서 다루는 힘',
  ),
  DomainInfo(
    domain: IntelligenceDomain.memory,
    label: IntelligenceDomain.memory.label,
    shortLabel: IntelligenceDomain.memory.shortLabel,
    description: '정보를 잠시 유지하고 다시 처리하는 힘',
  ),
  DomainInfo(
    domain: IntelligenceDomain.logic,
    label: IntelligenceDomain.logic.label,
    shortLabel: IntelligenceDomain.logic.shortLabel,
    description: '조건과 규칙을 차분하게 연결해 결론을 찾는 힘',
  ),
  DomainInfo(
    domain: IntelligenceDomain.processing,
    label: IntelligenceDomain.processing.label,
    shortLabel: IntelligenceDomain.processing.shortLabel,
    description: '간단한 판단을 빠르고 안정적으로 처리하는 힘',
  ),
];

String domainLabel(IntelligenceDomain domain) {
  return domainCatalog.firstWhere((item) => item.domain == domain).label;
}

String domainShortLabel(IntelligenceDomain domain) {
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
    this.age = 0,
    this.recentIQ = 100,
    this.recentPercentile = 50,
    this.recentAbilityLevel = '평균',
    this.lastTestAt,
    this.testCount = 0,
  });

  final String id;
  final String name;
  final String ageGroup;
  final String grade;
  final String avatar;
  final int age;
  final int recentIQ;
  final int recentPercentile;
  final String recentAbilityLevel;
  final DateTime? lastTestAt;
  final int testCount;

  UserProfile copyWith({
    String? id,
    String? name,
    String? ageGroup,
    String? grade,
    String? avatar,
    int? age,
    int? recentIQ,
    int? recentPercentile,
    String? recentAbilityLevel,
    DateTime? lastTestAt,
    bool clearLastTestAt = false,
    int? testCount,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      ageGroup: ageGroup ?? this.ageGroup,
      grade: grade ?? this.grade,
      avatar: avatar ?? this.avatar,
      age: age ?? this.age,
      recentIQ: recentIQ ?? this.recentIQ,
      recentPercentile: recentPercentile ?? this.recentPercentile,
      recentAbilityLevel: recentAbilityLevel ?? this.recentAbilityLevel,
      lastTestAt: clearLastTestAt ? null : lastTestAt ?? this.lastTestAt,
      testCount: testCount ?? this.testCount,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'age_group': ageGroup,
      'grade': grade,
      'avatar': avatar,
      'age': age,
      'recent_iq': recentIQ,
      'recent_percentile': recentPercentile,
      'recent_ability_level': recentAbilityLevel,
      'last_test_at': lastTestAt?.toIso8601String(),
      'test_count': testCount,
    };
  }

  factory UserProfile.fromMap(Map<String, Object?> map) {
    return UserProfile(
      id: map['id'] as String,
      name: map['name'] as String,
      ageGroup: map['age_group'] as String,
      grade: map['grade'] as String,
      avatar: map['avatar'] as String,
      age: map['age'] as int? ?? 0,
      recentIQ: map['recent_iq'] as int? ?? 100,
      recentPercentile: map['recent_percentile'] as int? ?? 50,
      recentAbilityLevel: map['recent_ability_level'] as String? ?? '평균',
      lastTestAt: DateTime.tryParse(map['last_test_at'] as String? ?? ''),
      testCount: map['test_count'] as int? ?? 0,
    );
  }
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
    this.difficulty = QuestionDifficulty.normal,
    this.seed = 0,
    this.difficultyIndex = 0,
    this.discrimination = 1,
    this.guessing = 0.25,
    this.upperAsymptote = 1,
    this.expectedSolveTime = Duration.zero,
    this.itemId,
    this.selectionScore = 1,
    this.itemInformation = 0,
    this.catSelectionScore = 0,
    this.hint,
    this.ruleName,
    this.solution,
    this.solutionExplanation,
  });

  final IntelligenceDomain domain;
  final String id;
  final String typeCode;
  final int level;
  final String prompt;
  final List<String> choices;
  final int answerIndex;
  final String explanation;
  final QuestionDifficulty difficulty;
  final int seed;
  final double difficultyIndex;
  final double discrimination;
  final double guessing;
  final double upperAsymptote;
  final Duration expectedSolveTime;
  final String? itemId;
  final double selectionScore;
  final double itemInformation;
  final double catSelectionScore;
  final String? hint;
  final String? ruleName;
  final String? solution;
  final String? solutionExplanation;

  TestQuestion copyWith({
    QuestionDifficulty? difficulty,
    int? seed,
    double? difficultyIndex,
    double? discrimination,
    double? guessing,
    double? upperAsymptote,
    Duration? expectedSolveTime,
    String? itemId,
    double? selectionScore,
    double? itemInformation,
    double? catSelectionScore,
    String? hint,
    String? ruleName,
    String? solution,
    String? solutionExplanation,
  }) {
    return TestQuestion(
      id: id,
      domain: domain,
      typeCode: typeCode,
      level: level,
      prompt: prompt,
      choices: choices,
      answerIndex: answerIndex,
      explanation: explanation,
      difficulty: difficulty ?? this.difficulty,
      seed: seed ?? this.seed,
      difficultyIndex: difficultyIndex ?? this.difficultyIndex,
      discrimination: discrimination ?? this.discrimination,
      guessing: guessing ?? this.guessing,
      upperAsymptote: upperAsymptote ?? this.upperAsymptote,
      expectedSolveTime: expectedSolveTime ?? this.expectedSolveTime,
      itemId: itemId ?? this.itemId,
      selectionScore: selectionScore ?? this.selectionScore,
      itemInformation: itemInformation ?? this.itemInformation,
      catSelectionScore: catSelectionScore ?? this.catSelectionScore,
      hint: hint ?? this.hint,
      ruleName: ruleName ?? this.ruleName,
      solution: solution ?? this.solution,
      solutionExplanation: solutionExplanation ?? this.solutionExplanation,
    );
  }
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
    this.isComingSoon = false,
  });

  final IntelligenceDomain domain;
  final int score;
  final int percentile;
  final double growth;
  final String comment;
  final bool isComingSoon;
}

class ReportSummary {
  const ReportSummary({
    required this.overallScore,
    required this.summary,
    required this.domainScores,
    required this.recommendations,
    this.domainResults = const {},
    this.averageDifficulty = QuestionDifficulty.normal,
  });

  final int overallScore;
  final String summary;
  final List<DomainScore> domainScores;
  final List<String> recommendations;
  final Map<IntelligenceDomain, DomainResult> domainResults;
  final QuestionDifficulty averageDifficulty;

  ReportSummary copyWith({
    int? overallScore,
    String? summary,
    List<DomainScore>? domainScores,
    List<String>? recommendations,
    Map<IntelligenceDomain, DomainResult>? domainResults,
    QuestionDifficulty? averageDifficulty,
  }) {
    return ReportSummary(
      overallScore: overallScore ?? this.overallScore,
      summary: summary ?? this.summary,
      domainScores: domainScores ?? this.domainScores,
      recommendations: recommendations ?? this.recommendations,
      domainResults: domainResults ?? this.domainResults,
      averageDifficulty: averageDifficulty ?? this.averageDifficulty,
    );
  }
}

class GrowthPoint {
  const GrowthPoint({required this.month, required this.score});

  final String month;
  final int score;
}

class TestResultSummary {
  const TestResultSummary({
    required this.id,
    required this.profileId,
    required this.startedAt,
    required this.completedAt,
    required this.theta,
    required this.standardError,
    required this.estimatedIQ,
    required this.percentile,
    required this.abilityLevel,
    required this.averageDifficulty,
    required this.averageElapsedSeconds,
    required this.questionCount,
    this.payloadJson = '{}',
  });

  final String id;
  final String profileId;
  final DateTime startedAt;
  final DateTime completedAt;
  final double theta;
  final double standardError;
  final int estimatedIQ;
  final int percentile;
  final String abilityLevel;
  final QuestionDifficulty averageDifficulty;
  final int averageElapsedSeconds;
  final int questionCount;
  final String payloadJson;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'profile_id': profileId,
      'started_at': startedAt.toIso8601String(),
      'completed_at': completedAt.toIso8601String(),
      'theta': theta,
      'standard_error': standardError,
      'estimated_iq': estimatedIQ,
      'percentile': percentile,
      'ability_level': abilityLevel,
      'average_difficulty': averageDifficulty.name,
      'average_elapsed_seconds': averageElapsedSeconds,
      'question_count': questionCount,
      'payload_json': payloadJson,
    };
  }

  factory TestResultSummary.fromMap(Map<String, Object?> map) {
    return TestResultSummary(
      id: map['id'] as String,
      profileId: map['profile_id'] as String,
      startedAt: DateTime.parse(map['started_at'] as String),
      completedAt: DateTime.parse(map['completed_at'] as String),
      theta: (map['theta'] as num).toDouble(),
      standardError: (map['standard_error'] as num).toDouble(),
      estimatedIQ: map['estimated_iq'] as int,
      percentile: map['percentile'] as int,
      abilityLevel: map['ability_level'] as String,
      averageDifficulty: QuestionDifficulty.values.byName(
        map['average_difficulty'] as String,
      ),
      averageElapsedSeconds: map['average_elapsed_seconds'] as int,
      questionCount: map['question_count'] as int,
      payloadJson: map['payload_json'] as String? ?? '{}',
    );
  }
}
