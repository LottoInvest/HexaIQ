import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../pattern_grid/domain/visual_question.dart';

class QuestionErrorBoundary extends StatelessWidget {
  const QuestionErrorBoundary({
    super.key,
    required this.child,
    required this.question,
    this.message = '문제를 불러오는 중 오류가 발생했습니다.\n다음 문제로 이동해 주세요.',
  });

  final Widget child;
  final VisualQuestion question;
  final String message;

  @override
  Widget build(BuildContext context) {
    final debugMessage = _validate(question);
    if (debugMessage == null) {
      return child;
    }
    return _QuestionFallback(message: message, debugMessage: debugMessage);
  }

  String? _validate(VisualQuestion question) {
    if (question.choices.isEmpty) {
      return 'choices is empty';
    }
    if (question.answerIndex < 0 ||
        question.answerIndex >= question.choices.length) {
      return 'answerIndex out of range';
    }
    if (question.grid.cells.length !=
        question.grid.rows * question.grid.columns) {
      return 'reference grid cell count mismatch';
    }
    for (final choice in question.choices) {
      if (choice.cells.length != choice.rows * choice.columns) {
        return 'choice grid cell count mismatch';
      }
    }
    return null;
  }
}

class _QuestionFallback extends StatelessWidget {
  const _QuestionFallback({required this.message, required this.debugMessage});

  final String message;
  final String debugMessage;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              if (kDebugMode) ...[
                const SizedBox(height: 12),
                Text(
                  debugMessage,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
