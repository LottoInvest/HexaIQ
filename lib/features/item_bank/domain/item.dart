import '../../../../core/domain/intelligence_domain.dart';
import '../../../../core/domain/question_difficulty.dart';
import '../../question_engine/domain/question_engine_models.dart';

class Item {
  const Item({
    required this.id,
    required this.domain,
    required this.difficulty,
    required this.difficultyIndex,
    required this.discrimination,
    required this.guessing,
    required this.expectedSolveTime,
    required this.question,
    required this.choices,
    required this.answer,
    required this.explanation,
    required this.tags,
    required this.version,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Item.fromGeneratedQuestion(
    GeneratedQuestionDto question, {
    String? id,
    String version = 'v0.6.0',
    DateTime? now,
  }) {
    final timestamp = now ?? DateTime.now();
    return Item(
      id: id ?? question.id,
      domain: question.domain,
      difficulty: question.difficulty,
      difficultyIndex: question.difficultyIndex,
      discrimination: question.discrimination,
      guessing: question.guessing,
      expectedSolveTime: question.expectedSolveTime,
      question: question.questionText,
      choices: question.choices,
      answer: question.answer,
      explanation: question.explanation,
      tags: [
        question.domain.name,
        question.typeCode,
        'type:${question.typeCode}',
        'difficulty:${question.difficulty.name}',
        ...question.metadata.difficultyFactors,
      ],
      version: version,
      createdAt: timestamp,
      updatedAt: timestamp,
    );
  }

  final String id;
  final IntelligenceDomain domain;
  final QuestionDifficulty difficulty;
  final double difficultyIndex;
  final double discrimination;
  final double guessing;
  final Duration expectedSolveTime;
  final String question;
  final List<String> choices;
  final String answer;
  final String explanation;
  final List<String> tags;
  final String version;
  final DateTime createdAt;
  final DateTime updatedAt;

  String get typeCode {
    for (final tag in tags) {
      if (tag.startsWith('type:')) {
        return tag.substring('type:'.length);
      }
    }
    return '${domain.generatorPrefix}${(1).toString().padLeft(2, '0')}';
  }

  bool hasTag(String tag) => tags.contains(tag);

  Item copyWith({
    String? id,
    IntelligenceDomain? domain,
    QuestionDifficulty? difficulty,
    double? difficultyIndex,
    double? discrimination,
    double? guessing,
    Duration? expectedSolveTime,
    String? question,
    List<String>? choices,
    String? answer,
    String? explanation,
    List<String>? tags,
    String? version,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Item(
      id: id ?? this.id,
      domain: domain ?? this.domain,
      difficulty: difficulty ?? this.difficulty,
      difficultyIndex: difficultyIndex ?? this.difficultyIndex,
      discrimination: discrimination ?? this.discrimination,
      guessing: guessing ?? this.guessing,
      expectedSolveTime: expectedSolveTime ?? this.expectedSolveTime,
      question: question ?? this.question,
      choices: choices ?? this.choices,
      answer: answer ?? this.answer,
      explanation: explanation ?? this.explanation,
      tags: tags ?? this.tags,
      version: version ?? this.version,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
