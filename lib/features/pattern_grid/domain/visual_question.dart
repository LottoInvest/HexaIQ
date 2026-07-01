import 'pattern_cell.dart';
import 'pattern_difficulty.dart';
import 'pattern_generator.dart';

enum QuestionLayout { grid, matrix, sequence, comparison }

class VisualQuestion {
  const VisualQuestion({
    required this.id,
    required this.type,
    required this.layout,
    required this.rule,
    required this.grid,
    required this.choices,
    required this.answerIndex,
    this.prompt = '',
    this.packId = 'basic',
    this.domain = 'visual_reasoning',
    this.difficulty,
    this.explanation = '',
    this.tags = const [],
    this.estimatedTime = 30,
    this.premiumOnly = false,
    this.version = '1.0.0',
  });

  final String id;
  final String type;
  final QuestionLayout layout;
  final PatternRule rule;
  final PatternGrid grid;
  final List<PatternGrid> choices;
  final int answerIndex;
  final String prompt;
  final String packId;
  final String domain;
  final PatternDifficulty? difficulty;
  final String explanation;
  final List<String> tags;
  final int estimatedTime;
  final bool premiumOnly;
  final String version;

  PatternQuestionPattern asPatternQuestion() {
    return PatternQuestionPattern(
      rule: rule,
      prompt: prompt.isEmpty
          ? const PatternGenerator().promptFor(rule)
          : prompt,
      grid: grid,
      choices: choices,
      answerIndex: answerIndex,
    );
  }
}
