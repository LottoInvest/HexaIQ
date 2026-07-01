import 'package:flutter/material.dart';

import '../domain/pattern_cell.dart';
import '../domain/pattern_theme.dart';
import 'pattern_renderer.dart';

class PatternGridView extends StatelessWidget {
  const PatternGridView({
    super.key,
    required this.grid,
    this.compact = false,
    this.animate = true,
    this.label,
    this.patternTheme = const PatternTheme(),
  });

  final PatternGrid grid;
  final bool compact;
  final bool animate;
  final String? label;
  final PatternTheme patternTheme;

  @override
  Widget build(BuildContext context) {
    final maxWidth = compact ? 220.0 : 320.0;
    final gap = compact ? 4.0 : patternTheme.cellGap;
    return Semantics(
      label: label ?? '패턴 격자',
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: AspectRatio(
          aspectRatio: grid.columns / grid.rows,
          child: Card(
            margin: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Padding(
              padding: EdgeInsets.all(compact ? 6 : 10),
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: grid.columns,
                  mainAxisSpacing: gap,
                  crossAxisSpacing: gap,
                ),
                itemCount: grid.size,
                itemBuilder: (context, index) {
                  return PatternRenderer(
                    cell: grid.cells[index],
                    patternTheme: patternTheme,
                    compact: compact,
                    animate: animate,
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
