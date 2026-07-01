import 'package:flutter/material.dart';

import 'layout_tokens.dart';

class QuestionCard extends StatelessWidget {
  const QuestionCard({
    super.key,
    required this.prompt,
    this.instruction,
    this.reference,
  });

  final String prompt;
  final String? instruction;
  final Widget? reference;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: LayoutTokens.cardHorizontalPadding,
          vertical: LayoutTokens.cardVerticalPadding,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(prompt, style: Theme.of(context).textTheme.titleLarge),
            if (instruction != null && instruction!.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(instruction!, style: Theme.of(context).textTheme.bodyMedium),
            ],
            if (reference != null) ...[
              const SizedBox(height: LayoutTokens.sectionGap),
              reference!,
            ],
          ],
        ),
      ),
    );
  }
}
