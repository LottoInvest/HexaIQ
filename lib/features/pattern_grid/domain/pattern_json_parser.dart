import 'dart:convert';

import 'pattern_cell.dart';
import 'pattern_difficulty.dart';
import 'pattern_generator.dart';
import 'visual_question.dart';

class PatternJsonParser {
  const PatternJsonParser();

  VisualQuestion parse(String source, {String id = 'json-pattern'}) {
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, Object?>) {
      throw const FormatException('Pattern JSON must be an object.');
    }
    return parseMap(decoded, id: id);
  }

  VisualQuestion parseMap(
    Map<String, Object?> map, {
    String id = 'json-pattern',
  }) {
    final (rows, columns) = _gridSize(map['grid']);
    final rule = _ruleFromValue(map['rule']);
    final grid = PatternGrid(
      rows: rows,
      columns: columns,
      cells: _cellsFor(map, rows, columns),
    );
    final pattern = const PatternGenerator().question(
      seed: map.hashCode,
      rule: rule,
      size: rows.clamp(2, 5),
    );
    return VisualQuestion(
      id: map['id'] as String? ?? id,
      type: map['type'] as String? ?? 'matrix',
      layout: _layoutFromName(map['type'] as String? ?? 'matrix'),
      rule: rule,
      grid: grid,
      choices: pattern.choices,
      answerIndex: map['answer'] as int? ?? pattern.answerIndex,
      prompt:
          map['prompt'] as String? ?? const PatternGenerator().promptFor(rule),
      packId: map['packId'] as String? ?? map['pack'] as String? ?? 'basic',
      domain: map['domain'] as String? ?? 'visual_reasoning',
      difficulty: patternDifficultyFromName(map['difficulty'] as String?),
      explanation: map['explanation'] as String? ?? '',
      tags: [
        for (final tag in map['tags'] as List<Object?>? ?? const [])
          tag.toString(),
      ],
      estimatedTime: map['estimatedTime'] as int? ?? 30,
      premiumOnly: map['premiumOnly'] as bool? ?? false,
      version: map['version'] as String? ?? '1.0.0',
    );
  }

  (int, int) _gridSize(Object? value) {
    if (value is Map<String, Object?>) {
      return (
        (value['rows'] as int? ?? 3).clamp(2, 5),
        (value['cols'] as int? ?? value['columns'] as int? ?? 3).clamp(2, 5),
      );
    }
    final gridText = value as String? ?? '3x3';
    final parts = gridText.toLowerCase().split('x');
    final rows = (int.tryParse(parts.first) ?? 3).clamp(2, 5);
    final columns = (parts.length > 1 ? int.tryParse(parts[1]) ?? rows : rows)
        .clamp(2, 5);
    return (rows, columns);
  }

  List<PatternCell> _cellsFor(Map<String, Object?> map, int rows, int columns) {
    final rawCells = map['cells'] as List<Object?>?;
    if (rawCells != null && rawCells.isNotEmpty) {
      final parsed = [
        for (final raw in rawCells)
          if (raw is Map<String, Object?>) _cellFromMap(raw),
      ];
      if (parsed.isNotEmpty) {
        return [
          for (var index = 0; index < rows * columns; index++)
            parsed[index % parsed.length],
        ];
      }
    }
    final elements = (map['elements'] as List<Object?>? ?? const ['square'])
        .map(patternElementFromJson)
        .toList(growable: false);
    final color = _colorFromName(map['color'] as String? ?? 'primary');
    return [
      for (var index = 0; index < rows * columns; index++)
        PatternCell(
          element: elements[index % elements.length],
          color: color,
          rotation: ((map['rotation'] as num?)?.toDouble() ?? 0) + index * 15,
          scale: ((map['scale'] as num?)?.toDouble() ?? 1).clamp(0.4, 1.8),
          highlighted: index == map['highlightedIndex'],
        ),
    ];
  }

  PatternCell _cellFromMap(Map<String, Object?> map) {
    return PatternCell(
      element: patternElementFromJson(map['element']),
      color: _colorFromName(map['color'] as String? ?? 'primary'),
      rotation: (map['rotation'] as num?)?.toDouble() ?? 0,
      scale: ((map['scale'] as num?)?.toDouble() ?? 1).clamp(0.2, 2.0),
      filled: map['filled'] as bool? ?? true,
      opacity: ((map['opacity'] as num?)?.toDouble() ?? 1).clamp(0, 1),
      showBorder: map['border'] as bool? ?? true,
      highlighted: map['highlighted'] as bool? ?? false,
    );
  }

  PatternRule _ruleFromValue(Object? value) {
    if (value is Map<String, Object?>) {
      return _ruleFromName(value['type'] as String? ?? 'rotation');
    }
    return _ruleFromName(value as String? ?? 'rotation');
  }

  PatternRule _ruleFromName(String name) {
    return PatternRule.values.firstWhere(
      (rule) => rule.name == name,
      orElse: () => PatternRule.rotation,
    );
  }

  QuestionLayout _layoutFromName(String name) {
    return switch (name) {
      'sequence' => QuestionLayout.sequence,
      'comparison' => QuestionLayout.comparison,
      'grid' => QuestionLayout.grid,
      _ => QuestionLayout.matrix,
    };
  }

  PatternColor _colorFromName(String name) {
    return PatternColor.values.firstWhere(
      (color) => color.name == name,
      orElse: () => PatternColor.primary,
    );
  }
}
