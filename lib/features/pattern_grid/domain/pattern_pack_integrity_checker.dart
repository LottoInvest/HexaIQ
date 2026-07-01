import 'asset_loader.dart';
import 'pattern_cell.dart';
import 'pattern_pack_manager.dart';
import 'pattern_question_validator.dart';
import 'visual_question.dart';

class PatternPackIntegrityReport {
  const PatternPackIntegrityReport({
    required this.packCount,
    required this.validQuestionCount,
    required this.invalidQuestionCount,
    required this.duplicateQuestionIds,
    required this.missingAssets,
    required this.errors,
    required this.warnings,
  });

  final int packCount;
  final int validQuestionCount;
  final int invalidQuestionCount;
  final List<String> duplicateQuestionIds;
  final List<String> missingAssets;
  final List<String> errors;
  final List<String> warnings;

  bool get isReadyForRelease =>
      errors.isEmpty && duplicateQuestionIds.isEmpty && missingAssets.isEmpty;

  String debugLog() {
    return [
      '[PatternPackIntegrity]',
      'packs=$packCount',
      'valid=$validQuestionCount',
      'invalid=$invalidQuestionCount',
      if (duplicateQuestionIds.isNotEmpty)
        'duplicates=${duplicateQuestionIds.join(',')}',
      if (missingAssets.isNotEmpty) 'missingAssets=${missingAssets.join(',')}',
      if (errors.isNotEmpty) 'errors=${errors.join('|')}',
      if (warnings.isNotEmpty) 'warnings=${warnings.join('|')}',
    ].join(' ');
  }
}

class PatternPackIntegrityChecker {
  const PatternPackIntegrityChecker({
    this.validator = const PatternQuestionValidator(),
    this.assetLoader,
  });

  final PatternQuestionValidator validator;
  final PatternAssetLoader? assetLoader;

  PatternPackIntegrityReport checkPacks(List<PatternPack> packs) {
    final seenQuestions = <String>{};
    final duplicates = <String>{};
    final missingAssets = <String>{};
    final errors = <String>[];
    final warnings = <String>[];
    var validCount = 0;
    var invalidCount = 0;

    for (final pack in packs) {
      if (pack.manifest.packId.trim().isEmpty) {
        errors.add('pack id is required');
      }
      if (pack.manifest.questionCount != pack.questions.length) {
        warnings.add(
          '${pack.id}: manifest questionCount ${pack.manifest.questionCount} '
          'does not match ${pack.questions.length}',
        );
      }
      for (final question in pack.questions) {
        if (!seenQuestions.add(question.id)) {
          duplicates.add(question.id);
        }
        final result = validator.validate(question);
        if (result.isValid) {
          validCount++;
        } else {
          invalidCount++;
          errors.addAll(result.errors.map((error) => '${question.id}: $error'));
        }
        warnings.addAll(
          result.warnings.map((warning) => '${question.id}: $warning'),
        );
        missingAssets.addAll(_missingAssets(question));
      }
    }

    return PatternPackIntegrityReport(
      packCount: packs.length,
      validQuestionCount: validCount,
      invalidQuestionCount: invalidCount,
      duplicateQuestionIds: duplicates.toList(growable: false)..sort(),
      missingAssets: missingAssets.toList(growable: false)..sort(),
      errors: errors,
      warnings: warnings,
    );
  }

  Iterable<String> _missingAssets(VisualQuestion question) sync* {
    final loader = assetLoader;
    if (loader == null) {
      return;
    }
    for (final assetPath in _assetPaths(question)) {
      if (loader.hasFailed(assetPath)) {
        yield assetPath;
      }
    }
  }

  Iterable<String> _assetPaths(VisualQuestion question) sync* {
    for (final cell in [
      ...question.grid.cells,
      for (final choice in question.choices) ...choice.cells,
    ]) {
      final path = _assetPathFor(cell);
      if (path != null) {
        yield path;
      }
    }
  }

  String? _assetPathFor(PatternCell cell) {
    return switch (cell.element) {
      SvgElement(:final assetPath) => assetPath,
      ImageElement(:final assetPath) => assetPath,
      _ => null,
    };
  }
}
