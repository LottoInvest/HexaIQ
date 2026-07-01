import 'package:flutter/material.dart';

import '../../pattern_grid/domain/visual_question.dart';
import 'hint_box.dart';
import 'memo_panel.dart';
import 'question_error_boundary.dart';
import 'question_scroll_area.dart';
import 'visual_choice_grid.dart';
import 'visual_question_card.dart';

class VisualQuestionLayout extends StatelessWidget {
  const VisualQuestionLayout({
    super.key,
    required this.question,
    required this.selectedIndex,
    required this.onSelect,
    this.hint,
  });

  final VisualQuestion question;
  final int? selectedIndex;
  final ValueChanged<int> onSelect;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return QuestionErrorBoundary(
      question: question,
      child: QuestionScrollArea(
        children: [
          VisualQuestionCard(question: question),
          VisualChoiceGrid(
            choices: question.choices,
            selectedIndex: selectedIndex,
            onSelect: onSelect,
          ),
          if (hint != null) HintBox(hint: hint!),
          const MemoPanel(),
        ],
      ),
    );
  }
}
