import 'package:flutter/material.dart';

class MemoryInteraction extends StatelessWidget {
  const MemoryInteraction({
    super.key,
    required this.stimulus,
    required this.remainingSeconds,
    required this.isPreview,
  });

  final String stimulus;
  final int remainingSeconds;
  final bool isPreview;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: isPreview
            ? colorScheme.tertiaryContainer.withValues(alpha: 0.35)
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              isPreview ? '$remainingSeconds초 동안 기억하세요.' : '기억한 내용을 바탕으로 답하세요.',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 10),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: Text(
                isPreview ? stimulus : '제시 항목이 숨겨졌습니다.',
                key: ValueKey(isPreview),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
