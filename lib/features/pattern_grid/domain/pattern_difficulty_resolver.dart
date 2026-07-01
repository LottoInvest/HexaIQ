import 'pattern_difficulty.dart';
import 'pattern_element.dart';
import 'pattern_generator.dart';
import 'visual_question.dart';

class PatternDifficultyResolution {
  const PatternDifficultyResolution({required this.difficulty, this.warning});

  final PatternDifficulty difficulty;
  final String? warning;
}

class PatternDifficultyResolver {
  const PatternDifficultyResolver();

  PatternDifficulty resolve(VisualQuestion question) {
    return resolveDetailed(question).difficulty;
  }

  PatternDifficultyResolution resolveDetailed(VisualQuestion question) {
    final computed = _compute(question);
    final declared = question.difficulty;
    if (declared == null) {
      return PatternDifficultyResolution(difficulty: computed);
    }
    final distance = (declared.index - computed.index).abs();
    return PatternDifficultyResolution(
      difficulty: declared,
      warning: distance >= 2
          ? 'declared difficulty ${declared.name} differs from computed ${computed.name}'
          : null,
    );
  }

  PatternDifficulty _compute(VisualQuestion question) {
    var score = 0;
    if (question.grid.rows >= 4 || question.grid.columns >= 4) {
      score += 2;
    } else if (question.grid.rows == 3 || question.grid.columns == 3) {
      score += 1;
    }
    if (question.choices.length >= 5) {
      score += 1;
    }
    score += switch (question.rule) {
      PatternRule.rotation || PatternRule.color => 0,
      PatternRule.symmetry || PatternRule.shape => 1,
      PatternRule.missingBlock || PatternRule.movement => 2,
    };
    final elementTypes = question.grid.cells
        .map((cell) => cell.element.type)
        .toSet();
    if (elementTypes.length >= 3) {
      score += 1;
    }
    if (question.grid.cells.any(
      (cell) => cell.element is SvgElement || cell.element is ImageElement,
    )) {
      score += 1;
    }
    if (question.tags.contains('compound')) {
      score += 1;
    }
    if (score <= 1) {
      return PatternDifficulty.easy;
    }
    if (score <= 3) {
      return PatternDifficulty.normal;
    }
    if (score <= 5) {
      return PatternDifficulty.hard;
    }
    return PatternDifficulty.expert;
  }
}
