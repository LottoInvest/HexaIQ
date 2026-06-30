import '../../../core/domain/intelligence_domain.dart';
import '../generators/numerical_generator.dart';
import '../generators/logic/logic_generator.dart';
import '../generators/memory/memory_generator.dart';
import '../generators/processing/processing_generator.dart';
import '../generators/spatial/spatial_generator.dart';
import '../generators/verbal/verbal_generator.dart';
import 'question_generator.dart';

class GeneratorFactory {
  GeneratorFactory({
    NumericalGenerator? numericalGenerator,
    SpatialGenerator? spatialGenerator,
    VerbalGenerator? verbalGenerator,
    MemoryGenerator? memoryGenerator,
    LogicGenerator? logicGenerator,
    ProcessingGenerator? processingGenerator,
  }) : _generators = {
         IntelligenceDomain.numerical:
             numericalGenerator ?? NumericalGenerator(),
         IntelligenceDomain.verbal: verbalGenerator ?? const VerbalGenerator(),
         IntelligenceDomain.spatial:
             spatialGenerator ?? const SpatialGenerator(),
         IntelligenceDomain.memory: memoryGenerator ?? const MemoryGenerator(),
         IntelligenceDomain.logic: logicGenerator ?? const LogicGenerator(),
         IntelligenceDomain.processing:
             processingGenerator ?? const ProcessingGenerator(),
       };

  final Map<IntelligenceDomain, QuestionGenerator> _generators;

  QuestionGenerator generatorFor(IntelligenceDomain domain) {
    final generator = _generators[domain];
    if (generator == null) {
      throw ArgumentError('No generator registered for ${domain.name}.');
    }
    return generator;
  }

  QuestionGenerator create(IntelligenceDomain domain) => generatorFor(domain);
}
