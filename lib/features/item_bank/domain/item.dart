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
    this.upperAsymptote = 1,
    required this.expectedSolveTime,
    required this.question,
    required this.choices,
    required this.answer,
    required this.explanation,
    required this.tags,
    required this.version,
    required this.createdAt,
    required this.updatedAt,
    this.hint,
    this.ruleName,
    this.solution,
    this.solutionExplanation,
    this.variables = const {},
    this.stimulus,
    this.stimulusDuration,
    this.requiresMemoryPhase = false,
    this.timeLimit,
    this.reactionScore,
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
      upperAsymptote: question.upperAsymptote,
      expectedSolveTime: question.expectedSolveTime,
      question: question.questionText,
      choices: question.choices,
      answer: question.answer,
      explanation: question.explanation,
      hint: question.hint,
      ruleName: question.ruleName,
      solution: question.solution,
      solutionExplanation: question.solutionExplanation,
      variables: question.variables,
      stimulus: question.stimulus,
      stimulusDuration: question.stimulusDuration,
      requiresMemoryPhase: question.requiresMemoryPhase,
      timeLimit: question.timeLimit,
      reactionScore: question.reactionScore,
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
  final double upperAsymptote;
  final Duration expectedSolveTime;
  final String question;
  final List<String> choices;
  final String answer;
  final String explanation;
  final String? hint;
  final String? ruleName;
  final String? solution;
  final String? solutionExplanation;
  final Map<String, Object?> variables;
  final String? stimulus;
  final Duration? stimulusDuration;
  final bool requiresMemoryPhase;
  final Duration? timeLimit;
  final double? reactionScore;
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
    double? upperAsymptote,
    Duration? expectedSolveTime,
    String? question,
    List<String>? choices,
    String? answer,
    String? explanation,
    String? hint,
    String? ruleName,
    String? solution,
    String? solutionExplanation,
    Map<String, Object?>? variables,
    String? stimulus,
    Duration? stimulusDuration,
    bool? requiresMemoryPhase,
    Duration? timeLimit,
    double? reactionScore,
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
      upperAsymptote: upperAsymptote ?? this.upperAsymptote,
      expectedSolveTime: expectedSolveTime ?? this.expectedSolveTime,
      question: question ?? this.question,
      choices: choices ?? this.choices,
      answer: answer ?? this.answer,
      explanation: explanation ?? this.explanation,
      hint: hint ?? this.hint,
      ruleName: ruleName ?? this.ruleName,
      solution: solution ?? this.solution,
      solutionExplanation: solutionExplanation ?? this.solutionExplanation,
      variables: variables ?? this.variables,
      stimulus: stimulus ?? this.stimulus,
      stimulusDuration: stimulusDuration ?? this.stimulusDuration,
      requiresMemoryPhase: requiresMemoryPhase ?? this.requiresMemoryPhase,
      timeLimit: timeLimit ?? this.timeLimit,
      reactionScore: reactionScore ?? this.reactionScore,
      tags: tags ?? this.tags,
      version: version ?? this.version,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
