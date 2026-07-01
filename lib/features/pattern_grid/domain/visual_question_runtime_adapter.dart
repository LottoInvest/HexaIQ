import '../../../core/domain/intelligence_domain.dart';
import '../../../core/domain/question_difficulty.dart';
import '../../hexaiq/domain/hexaiq_models.dart';
import 'pattern_difficulty.dart';
import 'pattern_json_parser.dart';
import 'visual_question.dart';

class VisualQuestionRuntimeAdapter {
  const VisualQuestionRuntimeAdapter({this.parser = const PatternJsonParser()});

  final PatternJsonParser parser;

  TestQuestion toLegacyQuestion(VisualQuestion visualQuestion) {
    return TestQuestion(
      id: visualQuestion.id,
      domain: _domainFor(visualQuestion.domain),
      typeCode: 'PATTERN-${visualQuestion.rule.name}',
      level: _levelFor(visualQuestion.difficulty),
      prompt: visualQuestion.prompt,
      choices: [
        for (var index = 0; index < visualQuestion.choices.length; index++)
          '보기 ${index + 1}',
      ],
      answerIndex: visualQuestion.answerIndex,
      explanation: visualQuestion.explanation,
      difficulty: _difficultyFor(visualQuestion.difficulty),
      seed: visualQuestion.id.hashCode,
      expectedSolveTime: Duration(seconds: visualQuestion.estimatedTime),
      itemId: visualQuestion.id,
      ruleName: visualQuestion.rule.name,
      solutionExplanation: visualQuestion.explanation,
      variables: {
        'visualQuestionId': visualQuestion.id,
        'packId': visualQuestion.packId,
        'patternRule': visualQuestion.rule.name,
        'patternDifficulty': visualQuestion.difficulty?.name,
        'elementTypes': visualQuestion.grid.cells
            .map((cell) => cell.element.type)
            .toSet()
            .join(','),
      },
    );
  }

  VisualQuestion fromJson(Map<String, Object?> json) {
    return parser.parseMap(json);
  }

  IntelligenceDomain _domainFor(String domain) {
    return switch (domain) {
      'visual_reasoning' => IntelligenceDomain.logic,
      'spatial' || 'spatial_reasoning' => IntelligenceDomain.spatial,
      'processing' => IntelligenceDomain.processing,
      'memory' => IntelligenceDomain.memory,
      _ => IntelligenceDomain.logic,
    };
  }

  int _levelFor(PatternDifficulty? difficulty) {
    return switch (difficulty ?? PatternDifficulty.normal) {
      PatternDifficulty.easy => 1,
      PatternDifficulty.normal => 2,
      PatternDifficulty.hard => 3,
      PatternDifficulty.expert => 4,
    };
  }

  QuestionDifficulty _difficultyFor(PatternDifficulty? difficulty) {
    return switch (difficulty ?? PatternDifficulty.normal) {
      PatternDifficulty.easy => QuestionDifficulty.easy,
      PatternDifficulty.normal => QuestionDifficulty.normal,
      PatternDifficulty.hard => QuestionDifficulty.hard,
      PatternDifficulty.expert => QuestionDifficulty.veryHard,
    };
  }
}
