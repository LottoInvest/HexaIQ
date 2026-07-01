import 'package:flutter/material.dart';

import 'layout_tokens.dart';

class HintBox extends StatelessWidget {
  const HintBox({super.key, required this.hint});

  final String hint;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(LayoutTokens.cardRadius),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.28)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(hint, style: Theme.of(context).textTheme.bodySmall),
      ),
    );
  }
}
