import 'package:flutter/material.dart';

import '../../pattern_grid/domain/visual_question.dart';
import 'question_card.dart';
import 'visual_reference_grid.dart';

class VisualQuestionCard extends StatelessWidget {
  const VisualQuestionCard({super.key, required this.question});

  final VisualQuestion question;

  @override
  Widget build(BuildContext context) {
    return QuestionCard(
      prompt: question.prompt,
      instruction: question.explanation.isEmpty ? null : question.explanation,
      reference: VisualReferenceGrid(grid: question.grid),
    );
  }
}
