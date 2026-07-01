import 'package:flutter/material.dart';

import '../domain/pattern_generator.dart';
import 'pattern_grid_view.dart';

class PatternQuestionWidget extends StatelessWidget {
  const PatternQuestionWidget({
    super.key,
    required this.pattern,
    this.compact = false,
    this.showChoices = false,
  });

  final PatternQuestionPattern pattern;
  final bool compact;
  final bool showChoices;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(pattern.prompt, style: textTheme.labelLarge),
        const SizedBox(height: 10),
        Center(
          child: PatternGridView(
            grid: pattern.grid,
            compact: compact,
            label: '문제 패턴',
          ),
        ),
        if (showChoices) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (var index = 0; index < pattern.choices.length; index++)
                SizedBox(
                  width: compact ? 112 : 136,
                  child: Column(
                    children: [
                      Text('${index + 1}', style: textTheme.labelMedium),
                      const SizedBox(height: 4),
                      PatternGridView(
                        grid: pattern.choices[index],
                        compact: true,
                        animate: false,
                        label: '보기 ${index + 1}',
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
