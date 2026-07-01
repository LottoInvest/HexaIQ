import '../../../core/domain/difficulty_profile.dart';
import '../../../core/domain/intelligence_domain.dart';
import '../../../core/domain/question_difficulty.dart';
import '../../cat/domain/theta_estimate.dart';

typedef QuestionDomain = IntelligenceDomain;

class GenerateQuestionRequest {
  const GenerateQuestionRequest({
    required this.profileId,
    required this.testId,
    required this.domain,
    required this.ageGroup,
    required this.index,
    this.typeCode,
    this.level,
    this.seed,
    this.difficulty = QuestionDifficulty.normal,
    this.difficultyProfile,
    this.usedItemIds = const {},
    this.thetaEstimate,
  });

  final String profileId;
  final String testId;
  final IntelligenceDomain domain;
  final String ageGroup;
  final int index;
  final String? typeCode;
  final int? level;
  final int? seed;
  final QuestionDifficulty difficulty;
  final DifficultyProfile? difficultyProfile;
  final Set<String> usedItemIds;
  final ThetaEstimate? thetaEstimate;

  GenerateQuestionRequest copyWith({
    String? profileId,
    String? testId,
    IntelligenceDomain? domain,
    String? ageGroup,
    int? index,
    String? typeCode,
    int? level,
    int? seed,
    QuestionDifficulty? difficulty,
    DifficultyProfile? difficultyProfile,
    Set<String>? usedItemIds,
    ThetaEstimate? thetaEstimate,
  }) {
    return GenerateQuestionRequest(
      profileId: profileId ?? this.profileId,
      testId: testId ?? this.testId,
      domain: domain ?? this.domain,
      ageGroup: ageGroup ?? this.ageGroup,
      index: index ?? this.index,
      typeCode: typeCode ?? this.typeCode,
      level: level ?? this.level,
      seed: seed ?? this.seed,
      difficulty: difficulty ?? this.difficulty,
      difficultyProfile: difficultyProfile ?? this.difficultyProfile,
      usedItemIds: usedItemIds ?? this.usedItemIds,
      thetaEstimate: thetaEstimate ?? this.thetaEstimate,
    );
  }
}

class QuestionChoiceDto {
  const QuestionChoiceDto({required this.key, required this.text});

  final String key;
  final String text;

  Map<String, Object?> toJson() {
    return {'key': key, 'text': text};
  }
}

class QuestionMetadataDto {
  const QuestionMetadataDto({
    required this.rule,
    required this.difficultyFactors,
    this.ruleName,
    this.version = 'v0.1.0',
    this.status,
    this.message,
  });

  final String rule;
  final String? ruleName;
  final List<String> difficultyFactors;
  final String version;
  final String? status;
  final String? message;

  Map<String, Object?> toJson() {
    return {
      'rule': rule,
      if (ruleName != null) 'ruleName': ruleName,
      'difficultyFactors': difficultyFactors,
      'version': version,
      if (status != null) 'status': status,
      if (message != null) 'message': message,
    };
  }
}

class GeneratedQuestionDto {
  GeneratedQuestionDto({
    required this.id,
    required this.domain,
    required this.typeCode,
    required this.level,
    required this.ageGroup,
    required this.seed,
    required this.questionText,
    required this.choiceDtos,
    required this.answerKey,
    required this.explanation,
    required this.estimatedTimeSec,
    required this.metadata,
    this.difficulty = QuestionDifficulty.normal,
    this.difficultyIndex = 0,
    this.discrimination = 1,
    this.guessing = 0.25,
    this.upperAsymptote = 1,
    Duration? expectedSolveTime,
    this.itemId,
    this.selectionScore = 1,
    this.itemInformation = 0,
    this.catSelectionScore = 0,
    this.hint,
    String? ruleName,
    String? solution,
    String? solutionExplanation,
    this.variables = const {},
    this.isStub = false,
  }) : expectedSolveTime =
           expectedSolveTime ?? Duration(seconds: estimatedTimeSec),
       ruleName = ruleName ?? metadata.ruleName ?? metadata.rule,
       solution =
           solution ??
           choiceDtos.firstWhere((choice) => choice.key == answerKey).text,
       solutionExplanation = solutionExplanation ?? explanation;

  factory GeneratedQuestionDto.fromLegacyChoices({
    required String id,
    required IntelligenceDomain domain,
    required String typeCode,
    required int level,
    required String ageGroup,
    required int seed,
    required String questionText,
    required List<String> choices,
    required String answer,
    required String explanation,
    required int estimatedTimeSec,
    required QuestionMetadataDto metadata,
    QuestionDifficulty difficulty = QuestionDifficulty.normal,
    double? difficultyIndex,
    double discrimination = 1,
    double guessing = 0.25,
    double upperAsymptote = 1,
    Duration? expectedSolveTime,
    String? itemId,
    double selectionScore = 1,
    double itemInformation = 0,
    double? catSelectionScore,
    String? hint,
    String? ruleName,
    String? solution,
    String? solutionExplanation,
    Map<String, Object?> variables = const {},
    bool isStub = false,
  }) {
    const keys = ['A', 'B', 'C', 'D', 'E', 'F'];
    final choiceDtos = [
      for (var i = 0; i < choices.length; i++)
        QuestionChoiceDto(key: keys[i], text: choices[i]),
    ];
    final answerIndex = choices.indexOf(answer);
    return GeneratedQuestionDto(
      id: id,
      domain: domain,
      typeCode: typeCode,
      level: level,
      ageGroup: ageGroup,
      seed: seed,
      questionText: questionText,
      choiceDtos: choiceDtos,
      answerKey: choiceDtos[answerIndex].key,
      explanation: explanation,
      estimatedTimeSec: estimatedTimeSec,
      metadata: metadata,
      difficulty: difficulty,
      difficultyIndex:
          difficultyIndex ??
          (difficulty.level - QuestionDifficulty.normal.level).toDouble(),
      discrimination: discrimination,
      guessing: guessing,
      upperAsymptote: upperAsymptote,
      expectedSolveTime:
          expectedSolveTime ?? Duration(seconds: estimatedTimeSec),
      itemId: itemId,
      selectionScore: selectionScore,
      itemInformation: itemInformation,
      catSelectionScore: catSelectionScore ?? selectionScore,
      hint: hint,
      ruleName: ruleName,
      solution: solution ?? answer,
      solutionExplanation: solutionExplanation ?? explanation,
      variables: variables,
      isStub: isStub,
    );
  }

  final String id;
  final IntelligenceDomain domain;
  final String typeCode;
  final int level;
  final String ageGroup;
  final int seed;
  final String questionText;
  final List<QuestionChoiceDto> choiceDtos;
  final String answerKey;
  final String explanation;
  final int estimatedTimeSec;
  final QuestionMetadataDto metadata;
  final QuestionDifficulty difficulty;
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
  final String ruleName;
  final String solution;
  final String solutionExplanation;
  final Map<String, Object?> variables;
  final bool isStub;

  String get question => questionText;

  List<String> get choices => choiceDtos.map((choice) => choice.text).toList();

  String get answer {
    return choiceDtos.firstWhere((choice) => choice.key == answerKey).text;
  }

  int get answerIndex {
    return choiceDtos.indexWhere((choice) => choice.key == answerKey);
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'domain': domain.name,
      'typeCode': typeCode,
      'level': level,
      'difficulty': difficulty.name,
      'difficultyIndex': difficultyIndex,
      'discrimination': discrimination,
      'guessing': guessing,
      'upperAsymptote': upperAsymptote,
      'expectedSolveTimeMs': expectedSolveTime.inMilliseconds,
      if (itemId != null) 'itemId': itemId,
      'selectionScore': selectionScore,
      'itemInformation': itemInformation,
      'catSelectionScore': catSelectionScore,
      if (hint != null) 'hint': hint,
      'ruleName': ruleName,
      'solution': solution,
      'solutionExplanation': solutionExplanation,
      'ageGroup': ageGroup,
      'questionText': questionText,
      'choices': choiceDtos.map((choice) => choice.toJson()).toList(),
      'answerKey': answerKey,
      'explanation': explanation,
      'seed': seed,
      'estimatedTimeSec': estimatedTimeSec,
      'metadata': metadata.toJson(),
    };
  }

  Map<String, Object?> toPublicJson() => toJson();

  Map<String, Object?> toStubJson() {
    return {
      'domain': domain.name,
      'status': metadata.status ?? 'coming_soon',
      'message': metadata.message ?? '$domain 영역은 준비 중입니다.',
    };
  }
}
