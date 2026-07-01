import 'package:flutter/material.dart';

import '../../pattern_grid/domain/pattern_cell.dart';
import '../../pattern_grid/presentation/pattern_grid_view.dart';
import 'layout_tokens.dart';

class VisualChoiceGrid extends StatelessWidget {
  const VisualChoiceGrid({
    super.key,
    required this.choices,
    required this.selectedIndex,
    required this.onSelect,
    this.compact = false,
  });

  final List<PatternGrid> choices;
  final int? selectedIndex;
  final ValueChanged<int> onSelect;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final crossAxisCount = width < 380 ? 1 : 2;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: choices.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: LayoutTokens.choiceGap,
        mainAxisSpacing: LayoutTokens.choiceGap,
        childAspectRatio: crossAxisCount == 1 ? 2.2 : 1.05,
      ),
      itemBuilder: (context, index) {
        final selected = selectedIndex == index;
        final scheme = Theme.of(context).colorScheme;
        final label = '보기 ${index + 1}';
        return InkWell(
          borderRadius: BorderRadius.circular(LayoutTokens.cardRadius),
          onTap: () => onSelect(index),
          child: Card(
            color: selected ? scheme.primaryContainer : scheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(LayoutTokens.cardRadius),
              side: BorderSide(
                color: selected ? scheme.primary : scheme.outlineVariant,
                width: selected ? 2 : 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  Text(label, style: Theme.of(context).textTheme.labelMedium),
                  const SizedBox(height: 4),
                  Expanded(
                    child: FittedBox(
                      child: PatternGridView(
                        grid: choices[index],
                        compact: true,
                        animate: false,
                        label: label,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
