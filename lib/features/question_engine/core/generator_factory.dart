import '../domain/question_engine_models.dart';
import '../generators/numerical_generator.dart';
import '../generators/stub_generators.dart';
import 'question_generator.dart';

class GeneratorFactory {
  GeneratorFactory({
    NumericalGenerator? numericalGenerator,
    SpatialGenerator? spatialGenerator,
    LogicalGenerator? logicalGenerator,
    VerbalGenerator? verbalGenerator,
    MemoryGenerator? memoryGenerator,
    PatternGenerator? patternGenerator,
  }) : _generators = {
         QuestionDomain.numerical: numericalGenerator ?? NumericalGenerator(),
         QuestionDomain.spatial: spatialGenerator ?? const SpatialGenerator(),
         QuestionDomain.logical: logicalGenerator ?? const LogicalGenerator(),
         QuestionDomain.verbal: verbalGenerator ?? const VerbalGenerator(),
         QuestionDomain.memory: memoryGenerator ?? const MemoryGenerator(),
         QuestionDomain.pattern: patternGenerator ?? const PatternGenerator(),
       };

  final Map<QuestionDomain, QuestionGenerator> _generators;

  QuestionGenerator generatorFor(QuestionDomain domain) {
    final generator = _generators[domain];
    if (generator == null) {
      throw ArgumentError('No generator registered for ${domain.name}.');
    }
    return generator;
  }
}
