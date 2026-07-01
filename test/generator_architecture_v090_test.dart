import 'package:flutter_test/flutter_test.dart';
import 'package:hexaiq_app/features/question_engine/question_engine.dart';
import 'package:hexaiq_app/features/test/domain/models/test_session.dart';

void main() {
  final generatorByDomain = <IntelligenceDomain, QuestionGenerator>{
    IntelligenceDomain.verbal: VerbalGenerator(),
    IntelligenceDomain.spatial: SpatialGenerator(),
    IntelligenceDomain.memory: MemoryGenerator(),
    IntelligenceDomain.logic: LogicalGenerator(),
    IntelligenceDomain.processing: ProcessingSpeedGenerator(),
  };

  test('QuestionGenerator exposes QuestionRequest and QuestionDto aliases', () {
    final QuestionGenerator generator = VerbalGenerator();
    const QuestionRequest request = GenerateQuestionRequest(
      profileId: 'p',
      testId: 't',
      domain: IntelligenceDomain.verbal,
      ageGroup: 'grade5_6',
      index: 0,
      seed: 90,
    );

    final QuestionDto dto = generator.generate(request);

    expect(dto.domain, IntelligenceDomain.verbal);
    expect(dto.typeCode, startsWith('LR'));
  });

  test('Memory DTO carries explicit two-phase fields', () {
    final dto = MemoryGenerator().generate(
      const GenerateQuestionRequest(
        profileId: 'p',
        testId: 't',
        domain: IntelligenceDomain.memory,
        ageGroup: 'grade5_6',
        index: 0,
        seed: 91,
      ),
    );

    expect(dto.requiresMemoryPhase, isTrue);
    expect(dto.stimulus, isNotEmpty);
    expect(dto.stimulusDuration, const Duration(seconds: 3));
    expect(dto.toJson()['requiresMemoryPhase'], isTrue);
  });

  test('Processing DTO carries speed fields', () {
    final dto = ProcessingSpeedGenerator().generate(
      const GenerateQuestionRequest(
        profileId: 'p',
        testId: 't',
        domain: IntelligenceDomain.processing,
        ageGroup: 'grade5_6',
        index: 0,
        seed: 92,
      ),
    );

    expect(dto.timeLimit, const Duration(seconds: 12));
    expect(dto.reactionScore, 1);
    expect(dto.toJson()['timeLimitMs'], 12000);
  });

  test('Spatial DTO includes canvas-ready SpatialData metadata', () {
    final dto = SpatialGenerator().generate(
      const GenerateQuestionRequest(
        profileId: 'p',
        testId: 't',
        domain: IntelligenceDomain.spatial,
        ageGroup: 'grade5_6',
        index: 0,
        seed: 93,
      ),
    );

    final spatialData = dto.variables['spatialData'] as Map<String, Object?>;
    expect(dto.variables['questionDataType'], 'SpatialData');
    expect(spatialData['kind'], 'spatial');
    expect(spatialData['renderTarget'], 'canvas');
  });

  test('TestSession exposes compact domain theta aliases', () {
    final session = TestSession(sessionId: 's', startedAt: DateTime(2026));

    expect(session.thetaNR.theta, session.thetaNumerical.theta);
    expect(session.thetaLR.theta, session.thetaVerbal.theta);
    expect(session.thetaSR.theta, session.thetaSpatial.theta);
    expect(session.thetaMR.theta, session.thetaMemory.theta);
    expect(session.thetaLG.theta, session.thetaLogical.theta);
    expect(session.thetaPS.theta, session.thetaProcessing.theta);
  });

  for (final entry in generatorByDomain.entries) {
    for (final typeCode in entry.value.supportedTypeCodes) {
      test('${entry.key.name} $typeCode is deterministic for same seed', () {
        final request = GenerateQuestionRequest(
          profileId: 'p',
          testId: 't',
          domain: entry.key,
          ageGroup: 'grade5_6',
          index: 0,
          typeCode: typeCode,
          seed: 100,
        );

        final first = entry.value.generate(request);
        final second = entry.value.generate(request);

        expect(second.id, first.id);
        expect(second.questionText, first.questionText);
        expect(second.choices, first.choices);
        expect(second.answer, first.answer);
      });

      test('${entry.key.name} $typeCode changes across seeds', () {
        final first = entry.value.generate(
          GenerateQuestionRequest(
            profileId: 'p',
            testId: 't',
            domain: entry.key,
            ageGroup: 'grade5_6',
            index: 0,
            typeCode: typeCode,
            seed: 101,
          ),
        );
        final second = entry.value.generate(
          GenerateQuestionRequest(
            profileId: 'p',
            testId: 't',
            domain: entry.key,
            ageGroup: 'grade5_6',
            index: 0,
            typeCode: typeCode,
            seed: 102,
          ),
        );

        expect(second.id, isNot(first.id));
        expect(second.toJson(), isNot(first.toJson()));
      });
    }
  }
}
