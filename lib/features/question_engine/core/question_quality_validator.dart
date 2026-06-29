import '../domain/question_engine_models.dart';
import 'age_mapper.dart';
import 'difficulty_manager.dart';

class QuestionQualityValidator {
  const QuestionQualityValidator({
    required this.ageMapper,
    required this.difficultyManager,
  });

  final AgeMapper ageMapper;
  final DifficultyManager difficultyManager;

  void validate(GeneratedQuestionDto question) {
    _validateEstimatedTime(question);
    _validateAgeNumberRange(question);
    _validateNumericChoiceDistance(question);
  }

  void _validateEstimatedTime(GeneratedQuestionDto question) {
    final expected = difficultyManager.estimatedTimeSec(question.level);
    if ((question.estimatedTimeSec - expected).abs() > 20) {
      throw StateError('estimatedTimeSec is not aligned with difficulty.');
    }
  }

  void _validateAgeNumberRange(GeneratedQuestionDto question) {
    final age = ageMapper.resolve(question.ageGroup);
    final values = _numbers(
      question.questionText,
    ).followedBy(question.choices.expand(_numbers));
    final maxAllowed = age.largeNumberMax * 50;
    for (final value in values) {
      if (value.abs() > maxAllowed) {
        throw StateError(
          'Question number $value is too large for ${age.code}.',
        );
      }
    }
  }

  void _validateNumericChoiceDistance(GeneratedQuestionDto question) {
    final choiceNumbers = question.choices
        .map(int.tryParse)
        .whereType<int>()
        .toList(growable: false);
    final answer = int.tryParse(question.answer);
    if (answer == null || choiceNumbers.length != question.choices.length) {
      return;
    }
    for (final value in choiceNumbers) {
      if (value != answer &&
          (value - answer).abs() > answer.abs() * 20 + 10000) {
        throw StateError('Distractor $value is too far from answer $answer.');
      }
    }
  }

  Iterable<int> _numbers(String value) sync* {
    final matches = RegExp(r'-?\d+').allMatches(value);
    for (final match in matches) {
      final parsed = int.tryParse(match.group(0)!);
      if (parsed != null) {
        yield parsed;
      }
    }
  }
}
