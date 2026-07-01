import 'pattern_difficulty_resolver.dart';
import 'pattern_element.dart';
import 'validation_result.dart';
import 'visual_question.dart';

class PatternQuestionValidator {
  const PatternQuestionValidator({
    this.difficultyResolver = const PatternDifficultyResolver(),
  });

  final PatternDifficultyResolver difficultyResolver;

  ValidationResult validate(VisualQuestion question) {
    final errors = <String>[];
    final warnings = <String>[];

    if (question.id.trim().isEmpty) {
      errors.add('question id is required');
    }
    if (!RegExp(r'^[a-z]+_[a-z]+_[a-z]+_\d{3}$').hasMatch(question.id)) {
      warnings.add('question id does not follow pack_type_rule_number format');
    }
    if (question.type.trim().isEmpty) {
      errors.add('type is required');
    }
    if (question.grid.rows < 2 ||
        question.grid.rows > 5 ||
        question.grid.columns < 2 ||
        question.grid.columns > 5) {
      errors.add('grid must be between 2x2 and 5x5');
    }
    if (question.grid.cells.length !=
        question.grid.rows * question.grid.columns) {
      errors.add('cell count does not match grid size');
    }
    if (question.choices.length < 2) {
      errors.add('at least two choices are required');
    }
    if (question.answerIndex < 0 ||
        question.answerIndex >= question.choices.length) {
      errors.add('answer index out of range');
    }
    for (final cell in question.grid.cells) {
      _validateCell(cell.element, errors, warnings);
      if (!cell.rotation.isFinite) {
        errors.add('rotation must be finite');
      }
      if (cell.scale <= 0 || !cell.scale.isFinite) {
        errors.add('scale must be greater than zero');
      }
      if (cell.opacity < 0 || cell.opacity > 1 || !cell.opacity.isFinite) {
        errors.add('opacity must be between 0 and 1');
      }
    }
    final resolution = difficultyResolver.resolveDetailed(question);
    if (resolution.warning != null) {
      warnings.add(resolution.warning!);
    }
    if (question.explanation.trim().isEmpty) {
      warnings.add('explanation is empty');
    }

    return ValidationResult(
      questionId: question.id,
      packId: question.packId,
      errors: errors,
      warnings: warnings,
      canAutoFix: errors.every(
        (error) => error.contains('id') || error.contains('explanation'),
      ),
    );
  }

  void _validateCell(
    PatternElement element,
    List<String> errors,
    List<String> warnings,
  ) {
    switch (element) {
      case SvgElement(:final assetPath):
      case ImageElement(:final assetPath):
        if (assetPath.trim().isEmpty || !assetPath.startsWith('assets/')) {
          errors.add('asset path must start with assets/');
        }
      case EmojiElement(:final emoji):
        if (emoji.trim().isEmpty) {
          warnings.add('empty emoji fallback will be used');
        }
      case IconElement(:final name):
        if (name.trim().isEmpty) {
          warnings.add('empty icon name fallback will be used');
        }
      case ShapeElement():
        break;
      default:
        warnings.add('unknown element type fallback will be used');
    }
  }
}
