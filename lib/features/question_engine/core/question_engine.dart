import '../domain/question_engine_models.dart';
import '../generators/numerical_generator.dart';
import 'age_mapper.dart';
import 'difficulty_manager.dart';
import 'generator_factory.dart';
import 'question_quality_validator.dart';
import 'question_validator.dart';
import 'seed_manager.dart';

class QuestionEngine {
  QuestionEngine({
    GeneratorFactory? generatorFactory,
    AgeMapper? ageMapper,
    DifficultyManager? difficultyManager,
    SeedManager? seedManager,
    QuestionValidator? validator,
    QuestionQualityValidator? qualityValidator,
  }) : ageMapper = ageMapper ?? AgeMapper(),
       seedManager = seedManager ?? SeedManager(),
       validator = validator ?? const QuestionValidator(),
       generatorFactory = generatorFactory ?? GeneratorFactory(),
       difficultyManager =
           difficultyManager ?? DifficultyManager(ageMapper ?? AgeMapper()),
       qualityValidator =
           qualityValidator ??
           QuestionQualityValidator(
             ageMapper: ageMapper ?? AgeMapper(),
             difficultyManager:
                 difficultyManager ??
                 DifficultyManager(ageMapper ?? AgeMapper()),
           );

  final GeneratorFactory generatorFactory;
  final AgeMapper ageMapper;
  final DifficultyManager difficultyManager;
  final SeedManager seedManager;
  final QuestionValidator validator;
  final QuestionQualityValidator qualityValidator;

  GeneratedQuestionDto generate(GenerateQuestionRequest request) {
    final typeCode = request.typeCode ?? _defaultTypeCode(request);
    final age = ageMapper.resolve(request.ageGroup);
    final level = difficultyManager.resolveLevel(
      ageGroup: age.code,
      requestedLevel: request.level,
    );
    final seed =
        request.seed ??
        seedManager.nextUniqueSeed(
          profileId: request.profileId,
          testId: request.testId,
          domain: request.domain,
          typeCode: typeCode,
          index: request.index,
        );
    final normalized = GenerateQuestionRequest(
      profileId: request.profileId,
      testId: request.testId,
      domain: request.domain,
      ageGroup: age.code,
      index: request.index,
      typeCode: typeCode,
      level: level,
      seed: seed,
    );
    final generator = generatorFactory.generatorFor(request.domain);
    final question = generator.generate(normalized);
    validator.validate(question);
    qualityValidator.validate(question);
    seedManager.registerSignature(
      profileId: request.profileId,
      question: question.questionText,
      answer: question.answer,
    );
    return question;
  }

  List<GeneratedQuestionDto> generateDomainBatch({
    required String profileId,
    required String testId,
    required QuestionDomain domain,
    required String ageGroup,
    required int count,
    int? level,
  }) {
    return [
      for (var index = 0; index < count; index++)
        generate(
          GenerateQuestionRequest(
            profileId: profileId,
            testId: testId,
            domain: domain,
            ageGroup: ageGroup,
            index: index,
            level: level,
          ),
        ),
    ];
  }

  String _defaultTypeCode(GenerateQuestionRequest request) {
    if (request.domain == QuestionDomain.numerical) {
      return NumericalGenerator.typeCodes[request.index %
          NumericalGenerator.typeCodes.length];
    }
    final prefix = switch (request.domain) {
      QuestionDomain.spatial => 'SP',
      QuestionDomain.logical => 'LG',
      QuestionDomain.verbal => 'VB',
      QuestionDomain.memory => 'WM',
      QuestionDomain.pattern => 'PT',
      QuestionDomain.numerical => 'NR',
    };
    return '$prefix${(request.index % 20 + 1).toString().padLeft(2, '0')}';
  }
}
