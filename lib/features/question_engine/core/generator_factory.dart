import '../../../core/domain/intelligence_domain.dart';
import '../generators/logical_generator.dart';
import '../generators/memory_generator.dart';
import '../generators/numerical_generator.dart';
import '../generators/processing_speed_generator.dart';
import '../generators/spatial_generator.dart';
import '../generators/verbal_generator.dart';
import 'question_generator.dart';

class GeneratorFactory {
  GeneratorFactory({
    NumericalGenerator? numericalGenerator,
    SpatialGenerator? spatialGenerator,
    VerbalGenerator? verbalGenerator,
    MemoryGenerator? memoryGenerator,
    LogicalGenerator? logicalGenerator,
    ProcessingSpeedGenerator? processingGenerator,
  }) : _generators = {
         IntelligenceDomain.numerical:
             numericalGenerator ?? NumericalGenerator(),
         IntelligenceDomain.verbal: verbalGenerator ?? VerbalGenerator(),
         IntelligenceDomain.spatial: spatialGenerator ?? SpatialGenerator(),
         IntelligenceDomain.memory: memoryGenerator ?? MemoryGenerator(),
         IntelligenceDomain.logic: logicalGenerator ?? LogicalGenerator(),
         IntelligenceDomain.processing:
             processingGenerator ?? ProcessingSpeedGenerator(),
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
