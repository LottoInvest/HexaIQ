import 'package:flutter_test/flutter_test.dart';
import 'package:hexaiq_app/features/hexaiq/domain/hexaiq_models.dart'
    show TestType;
import 'package:hexaiq_app/features/pattern_grid/domain/pattern_difficulty.dart';
import 'package:hexaiq_app/features/pattern_grid/domain/result_metadata.dart';
import 'package:hexaiq_app/features/scoring/domain/cognitive_domain.dart';
import 'package:hexaiq_app/features/scoring/domain/difficulty_weight_resolver.dart';
import 'package:hexaiq_app/features/scoring/domain/response_time_analyzer.dart';
import 'package:hexaiq_app/features/scoring/domain/scoring_reliability_engine.dart';
import 'package:hexaiq_app/features/scoring/domain/scoring_response.dart';
import 'package:hexaiq_app/features/scoring/domain/test_score_policy.dart';

void main() {
  group('v0.9.8 Scoring Reliability Engine', () {
    test('all wrong responses produce minimum IQ and near-center hexagon', () {
      final report = const ScoringReliabilityEngine().calculate(
        responses: _responses(
          correct: false,
          difficulty: PatternDifficulty.normal,
        ),
        testType: TestType.basic,
      );

      expect(report.iqScore, TestScorePolicy.forTestType(TestType.basic).minIq);
      expect(
        report.hexagonScores.values.where((value) => value == 0).length,
        CognitiveDomain.values.length,
      );
    });

    test('all correct quick IQ responses reach quick policy ceiling', () {
      final report = const ScoringReliabilityEngine().calculate(
        responses: _responses(
          correct: true,
          difficulty: PatternDifficulty.hard,
          testType: TestType.quickIq,
        ),
      );

      expect(
        report.iqScore,
        TestScorePolicy.forTestType(TestType.quickIq).maxIq,
      );
      expect(report.hexagonScores.values.every((value) => value >= 0.95), true);
    });

    test('unanswered domains are excluded from overall score', () {
      final responses = [
        for (var i = 0; i < 3; i++)
          _response(
            id: 'verbal_$i',
            domain: CognitiveDomain.verbal,
            isCorrect: true,
          ),
      ];

      final report = const ScoringReliabilityEngine().calculate(
        responses: responses,
      );

      expect(
        report.domainScores
            .singleWhere((score) => score.domain == CognitiveDomain.verbal)
            .totalCount,
        3,
      );
      expect(report.hexagonScores[CognitiveDomain.numerical.name], 0);
      expect(report.iqScore, TestScorePolicy.forTestType(TestType.basic).maxIq);
    });

    test('difficulty weights are capped by test policy', () {
      const resolver = DifficultyWeightResolver();

      expect(
        resolver.weightFor(PatternDifficulty.expert, TestType.quickIq),
        TestScorePolicy.forTestType(TestType.quickIq).maxDifficultyWeight,
      );
      expect(
        resolver.weightFor(PatternDifficulty.expert, TestType.professional),
        1.8,
      );
    });

    test('response time is auxiliary and constrained', () {
      const analyzer = ResponseTimeAnalyzer();

      final fast = analyzer.analyze(
        isCorrect: true,
        responseTime: const Duration(milliseconds: 300),
        estimatedTime: const Duration(seconds: 30),
      );
      final expected = analyzer.analyze(
        isCorrect: true,
        responseTime: const Duration(seconds: 20),
        estimatedTime: const Duration(seconds: 30),
      );

      expect(fast.category, ResponseTimeCategory.tooFast);
      expect(fast.multiplier, lessThanOrEqualTo(1));
      expect(expected.multiplier, lessThanOrEqualTo(1.03));
    });

    test('report text is Korean and strength/weakness is resolved', () {
      final report = const ScoringReliabilityEngine().calculate(
        responses: [
          for (var i = 0; i < 3; i++)
            _response(
              id: 'pattern_$i',
              domain: CognitiveDomain.pattern,
              isCorrect: true,
              difficulty: PatternDifficulty.hard,
            ),
          for (var i = 0; i < 3; i++)
            _response(
              id: 'speed_$i',
              domain: CognitiveDomain.speed,
              isCorrect: false,
            ),
        ],
      );

      expect(report.overallDescription, contains('이번 결과'));
      expect(
        report.domainDescriptions[CognitiveDomain.pattern.name],
        contains('패턴 인식'),
      );
      expect(
        report.strengthWeakness.strengths.first.domain,
        CognitiveDomain.pattern,
      );
      expect(
        report.strengthWeakness.weaknesses.first.domain,
        CognitiveDomain.speed,
      );
    });

    test('result metadata stores scoring fields and timestamp', () {
      final metadata = PatternResultMetadata(
        questionId: 'q1',
        packId: 'basic_pack',
        testType: 'basic',
        domain: 'pattern',
        difficulty: 'hard',
        ruleType: 'rotation',
        elementType: 'shape',
        isCorrect: true,
        responseTime: const Duration(seconds: 12),
        selectedAnswer: 1,
        correctAnswer: 1,
        rawScore: 100,
        weightedScore: 92.5,
        domainScore: 93,
        timestamp: DateTime.utc(2026, 7, 1),
      );

      final json = metadata.toJson();

      expect(json['rawScore'], 100);
      expect(json['weightedScore'], 92.5);
      expect(json['domainScore'], 93);
      expect(json['timestamp'], '2026-07-01T00:00:00.000Z');
    });
  });
}

List<ScoringResponse> _responses({
  required bool correct,
  PatternDifficulty difficulty = PatternDifficulty.normal,
  TestType testType = TestType.basic,
}) {
  return [
    for (final domain in CognitiveDomain.values)
      for (var index = 0; index < 3; index++)
        _response(
          id: '${domain.name}_$index',
          domain: domain,
          isCorrect: correct,
          difficulty: difficulty,
          testType: testType,
        ),
  ];
}

ScoringResponse _response({
  required String id,
  required CognitiveDomain domain,
  required bool isCorrect,
  PatternDifficulty difficulty = PatternDifficulty.normal,
  TestType testType = TestType.basic,
}) {
  return ScoringResponse(
    questionId: id,
    packId: 'test_pack',
    testType: testType,
    domain: domain,
    difficulty: difficulty,
    ruleType: 'rotation',
    elementType: 'shape',
    isCorrect: isCorrect,
    responseTime: const Duration(seconds: 20),
    selectedAnswer: isCorrect ? 1 : 0,
    correctAnswer: 1,
  );
}
