import '../domain/question_engine_models.dart';

class QuestionValidator {
  const QuestionValidator();

  void validate(GeneratedQuestionDto question) {
    if (question.typeCode.isEmpty) {
      throw StateError('Question typeCode is empty.');
    }
    if (question.level < 1 || question.level > 10) {
      throw StateError('Question level must be 1~10.');
    }
    if (question.question.trim().isEmpty) {
      throw StateError('Question prompt is empty.');
    }
    if (question.choices.length < 2) {
      throw StateError('Question must have at least two choices.');
    }
    if (question.choices.toSet().length != question.choices.length) {
      throw StateError('Question choices must be unique.');
    }
    if (!question.choices.contains(question.answer)) {
      throw StateError('Question choices must include answer.');
    }
    if (question.answerIndex < 0 ||
        question.answerIndex >= question.choices.length ||
        question.choices[question.answerIndex] != question.answer) {
      throw StateError('Question answerIndex does not match answer.');
    }
    if (question.explanation.trim().isEmpty) {
      throw StateError('Question explanation is empty.');
    }
  }
}
