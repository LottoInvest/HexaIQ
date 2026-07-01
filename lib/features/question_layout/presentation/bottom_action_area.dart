import 'package:flutter/material.dart';

class BottomActionArea extends StatelessWidget {
  const BottomActionArea({
    super.key,
    required this.onNext,
    required this.nextLabel,
    this.onPrevious,
    this.previousLabel = '이전',
  });

  final VoidCallback? onPrevious;
  final VoidCallback onNext;
  final String previousLabel;
  final String nextLabel;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            OutlinedButton.icon(
              onPressed: onPrevious,
              icon: const Icon(Icons.chevron_left),
              label: Text(previousLabel),
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: onNext,
              icon: const Icon(Icons.chevron_right),
              label: Text(nextLabel),
            ),
          ],
        ),
      ),
    );
  }
}
