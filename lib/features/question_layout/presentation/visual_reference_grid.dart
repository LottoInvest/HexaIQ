import 'package:flutter/material.dart';

import '../../pattern_grid/domain/pattern_cell.dart';
import '../../pattern_grid/presentation/pattern_grid_view.dart';

class VisualReferenceGrid extends StatelessWidget {
  const VisualReferenceGrid({
    super.key,
    required this.grid,
    this.compact = false,
  });

  final PatternGrid grid;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: PatternGridView(grid: grid, compact: compact, label: '참조 패턴'),
    );
  }
}
