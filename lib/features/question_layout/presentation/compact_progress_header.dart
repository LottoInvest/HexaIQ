import 'package:flutter/material.dart';

class CompactProgressHeader extends StatelessWidget {
  const CompactProgressHeader({
    super.key,
    required this.questionNumber,
    required this.totalQuestions,
    required this.progressPercent,
    required this.elapsedText,
    required this.difficultyLabel,
  });

  final int questionNumber;
  final int totalQuestions;
  final int progressPercent;
  final String elapsedText;
  final String difficultyLabel;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelMedium;
    return SizedBox(
      height: 48,
      child: Row(
        children: [
          Expanded(
            child: Text(
              '문제 $questionNumber / $totalQuestions',
              style: style,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Flexible(
            child: Text(
              '$progressPercent% · $elapsedText · $difficultyLabel',
              style: style,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
