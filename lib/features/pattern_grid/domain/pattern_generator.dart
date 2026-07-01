import 'dart:math';

import 'pattern_cell.dart';

enum PatternRule { rotation, symmetry, missingBlock, movement, color, shape }

class PatternQuestionPattern {
  const PatternQuestionPattern({
    required this.rule,
    required this.prompt,
    required this.grid,
    required this.choices,
    required this.answerIndex,
  });

  final PatternRule rule;
  final String prompt;
  final PatternGrid grid;
  final List<PatternGrid> choices;
  final int answerIndex;
}

class PatternGenerator {
  const PatternGenerator();

  PatternGrid generate({
    required int seed,
    int size = 3,
    PatternRule rule = PatternRule.rotation,
  }) {
    final safeSize = size.clamp(2, 5);
    final random = Random(seed);
    final shapes = PatternShape.values;
    final colors = PatternColor.values;
    final cells = <PatternCell>[];

    for (var index = 0; index < safeSize * safeSize; index++) {
      final shapeOffset = switch (rule) {
        PatternRule.shape => index,
        PatternRule.symmetry => index % safeSize,
        _ => random.nextInt(shapes.length),
      };
      final colorOffset = switch (rule) {
        PatternRule.color => index,
        PatternRule.movement => index ~/ safeSize,
        _ => random.nextInt(colors.length),
      };
      cells.add(
        PatternCell(
          shape: shapes[(seed + shapeOffset) % shapes.length],
          color: colors[(seed + colorOffset) % colors.length],
          filled: random.nextBool(),
          rotation: ((index + random.nextInt(4)) % 4) * 90,
        ),
      );
    }

    return PatternGrid.square(size: safeSize, cells: cells);
  }

  PatternQuestionPattern question({
    required int seed,
    required PatternRule rule,
    int size = 3,
  }) {
    final grid = generate(seed: seed, size: size, rule: rule);
    final answer = _answerGrid(seed: seed, grid: grid, rule: rule);
    final distractors = [
      _answerGrid(seed: seed + 1, grid: grid, rule: rule),
      _answerGrid(seed: seed + 2, grid: grid, rule: rule),
      _answerGrid(seed: seed + 3, grid: grid, rule: rule),
    ];
    final answerIndex = seed.abs() % 4;
    final choices = [...distractors]..insert(answerIndex, answer);
    return PatternQuestionPattern(
      rule: rule,
      prompt: promptFor(rule),
      grid: grid,
      choices: choices.take(4).toList(growable: false),
      answerIndex: answerIndex,
    );
  }

  String promptFor(PatternRule rule) {
    return switch (rule) {
      PatternRule.rotation => '회전 규칙을 적용했을 때 알맞은 패턴을 고르세요.',
      PatternRule.symmetry => '대칭 관계를 만족하는 패턴을 고르세요.',
      PatternRule.missingBlock => '빈칸에 들어갈 블록을 고르세요.',
      PatternRule.movement => '블록 이동 규칙에 따라 다음 패턴을 고르세요.',
      PatternRule.color => '색상 규칙이 이어지는 패턴을 고르세요.',
      PatternRule.shape => '도형 규칙이 이어지는 패턴을 고르세요.',
    };
  }

  PatternGrid _answerGrid({
    required int seed,
    required PatternGrid grid,
    required PatternRule rule,
  }) {
    return switch (rule) {
      PatternRule.rotation => grid.rotateCells(90),
      PatternRule.symmetry => _mirror(grid),
      PatternRule.missingBlock => _replaceOne(grid, seed),
      PatternRule.movement => _shift(grid),
      PatternRule.color => _cycleColor(grid),
      PatternRule.shape => _cycleShape(grid),
    };
  }

  PatternGrid _mirror(PatternGrid grid) {
    final cells = <PatternCell>[];
    for (var row = 0; row < grid.rows; row++) {
      for (var column = grid.columns - 1; column >= 0; column--) {
        cells.add(grid.cellAt(row, column));
      }
    }
    return PatternGrid(rows: grid.rows, columns: grid.columns, cells: cells);
  }

  PatternGrid _replaceOne(PatternGrid grid, int seed) {
    final cells = [...grid.cells];
    final index = seed.abs() % cells.length;
    cells[index] = cells[index].copyWith(
      filled: !cells[index].filled,
      rotation: (cells[index].rotation + 180) % 360,
    );
    return PatternGrid(rows: grid.rows, columns: grid.columns, cells: cells);
  }

  PatternGrid _shift(PatternGrid grid) {
    return PatternGrid(
      rows: grid.rows,
      columns: grid.columns,
      cells: [grid.cells.last, ...grid.cells.take(grid.cells.length - 1)],
    );
  }

  PatternGrid _cycleColor(PatternGrid grid) {
    final colors = PatternColor.values;
    return PatternGrid(
      rows: grid.rows,
      columns: grid.columns,
      cells: [
        for (final cell in grid.cells)
          cell.copyWith(color: colors[(cell.color.index + 1) % colors.length]),
      ],
    );
  }

  PatternGrid _cycleShape(PatternGrid grid) {
    final shapes = PatternShape.values;
    return PatternGrid(
      rows: grid.rows,
      columns: grid.columns,
      cells: [
        for (final cell in grid.cells)
          cell.copyWith(shape: shapes[(cell.shape.index + 1) % shapes.length]),
      ],
    );
  }
}
