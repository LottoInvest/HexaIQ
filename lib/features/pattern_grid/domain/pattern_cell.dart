// ignore_for_file: prefer_initializing_formals

import 'pattern_element.dart';

export 'pattern_element.dart';

enum PatternColor { primary, secondary, success, warning, error, neutral }

class PatternCell {
  const PatternCell({
    PatternElement? element,
    this.shape = PatternShape.square,
    required this.color,
    this.filled = true,
    this.rotation = 0,
    this.scale = 1,
    this.highlighted = false,
    this.opacity = 1,
    this.showBorder = true,
  }) : _element = element;

  final PatternElement? _element;
  final PatternShape shape;
  final PatternColor color;
  final bool filled;
  final double rotation;
  final double scale;
  final bool highlighted;
  final double opacity;
  final bool showBorder;

  PatternElement get element => _element ?? ShapeElement(shape);

  PatternCell copyWith({
    PatternElement? element,
    PatternShape? shape,
    PatternColor? color,
    bool? filled,
    double? rotation,
    double? scale,
    bool? highlighted,
    double? opacity,
    bool? showBorder,
  }) {
    return PatternCell(
      element: element ?? _element,
      shape: shape ?? this.shape,
      color: color ?? this.color,
      filled: filled ?? this.filled,
      rotation: rotation ?? this.rotation,
      scale: scale ?? this.scale,
      highlighted: highlighted ?? this.highlighted,
      opacity: opacity ?? this.opacity,
      showBorder: showBorder ?? this.showBorder,
    );
  }
}

class PatternGrid {
  const PatternGrid({
    required this.rows,
    required this.columns,
    required this.cells,
  }) : assert(rows >= 2 && rows <= 5),
       assert(columns >= 2 && columns <= 5),
       assert(cells.length == rows * columns);

  factory PatternGrid.square({
    required int size,
    required List<PatternCell> cells,
  }) {
    return PatternGrid(rows: size, columns: size, cells: cells);
  }

  final int rows;
  final int columns;
  final List<PatternCell> cells;

  int get size => rows * columns;

  PatternCell cellAt(int row, int column) => cells[row * columns + column];

  PatternGrid rotateCells(double degrees) {
    return PatternGrid(
      rows: rows,
      columns: columns,
      cells: [
        for (final cell in cells)
          cell.copyWith(rotation: (cell.rotation + degrees) % 360),
      ],
    );
  }
}
