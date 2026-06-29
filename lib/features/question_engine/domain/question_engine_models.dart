enum QuestionDomain { numerical, spatial, logical, verbal, memory, pattern }

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
  });

  final String profileId;
  final String testId;
  final QuestionDomain domain;
  final String ageGroup;
  final int index;
  final String? typeCode;
  final int? level;
  final int? seed;
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
    this.version = 'v0.1.0',
    this.status,
    this.message,
  });

  final String rule;
  final List<String> difficultyFactors;
  final String version;
  final String? status;
  final String? message;

  Map<String, Object?> toJson() {
    return {
      'rule': rule,
      'difficultyFactors': difficultyFactors,
      'version': version,
      if (status != null) 'status': status,
      if (message != null) 'message': message,
    };
  }
}

class GeneratedQuestionDto {
  const GeneratedQuestionDto({
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
    this.variables = const {},
    this.isStub = false,
  });

  factory GeneratedQuestionDto.fromLegacyChoices({
    required String id,
    required QuestionDomain domain,
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
      variables: variables,
      isStub: isStub,
    );
  }

  final String id;
  final QuestionDomain domain;
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
