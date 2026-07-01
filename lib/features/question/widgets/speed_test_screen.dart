import 'package:flutter/material.dart';

class SpeedInteractionPanel extends StatelessWidget {
  const SpeedInteractionPanel({
    super.key,
    required this.elapsedSeconds,
    this.timeLimit,
  });

  final int elapsedSeconds;
  final Duration? timeLimit;

  @override
  Widget build(BuildContext context) {
    final limit = timeLimit ?? const Duration(seconds: 12);
    final progress = (elapsedSeconds / limit.inSeconds).clamp(0.0, 1.0);
    final remaining = (limit.inSeconds - elapsedSeconds).clamp(
      0,
      limit.inSeconds,
    );
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('처리속도', style: Theme.of(context).textTheme.labelLarge),
                Text('남은 시간 ${remaining}초'),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: progress),
          ],
        ),
      ),
    );
  }
}
