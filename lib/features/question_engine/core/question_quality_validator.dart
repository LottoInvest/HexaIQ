import 'package:flutter/foundation.dart';

import '../domain/question_engine_models.dart';
import 'age_mapper.dart';
import 'difficulty_manager.dart';

class ValidationResult {
  const ValidationResult._({required this.isValid, this.reason, this.warning});

  final bool isValid;
  final String? reason;
  final String? warning;

  const ValidationResult.valid({String? warning})
    : this._(isValid: true, warning: warning);

  const ValidationResult.invalid(String reason, {String? warning})
    : this._(isValid: false, reason: reason, warning: warning);
}

class QuestionQualityValidator {
  const QuestionQualityValidator({
    required this.ageMapper,
    required this.difficultyManager,
  });

  final AgeMapper ageMapper;
  final DifficultyManager difficultyManager;

  ValidationResult validate(GeneratedQuestionDto question) {
    try {
      _validateEstimatedTime(question);
      _validateAgeNumberRange(question);
      _validateNumericChoiceDistance(question);
      return const ValidationResult.valid();
    } on Object catch (error, stackTrace) {
      debugPrint(
        '[Validator] invalid '
        'type=${question.typeCode} '
        'id=${question.id} '
        'seed=${question.seed} '
        'reason=$error',
      );
      debugPrint('[Validator] stackTrace=$stackTrace');
      return ValidationResult.invalid(error.toString());
    }
  }

  void _validateEstimatedTime(GeneratedQuestionDto question) {
    final expected = difficultyManager.estimatedTimeSec(question.level);
    final diff = (question.estimatedTimeSec - expected).abs();
    if (diff > 20) {
      throw StateError(
        'estimatedTimeSec mismatch: '
        'actual=${question.estimatedTimeSec}, '
        'expected=$expected, '
        'diff=$diff, '
        'level=${question.level}.',
      );
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
          'number range exceeded: '
          'value=$value, '
          'maxAllowed=$maxAllowed, '
          'ageGroup=${question.ageGroup}, '
          'resolvedAge=${age.code}.',
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
        throw StateError(
          'numeric choice distance too large: '
          'choice=$value, '
          'answer=$answer, '
          'distance=${(value - answer).abs()}, '
          'allowed=${answer.abs() * 20 + 10000}.',
        );
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
