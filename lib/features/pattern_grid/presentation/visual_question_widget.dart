import 'package:flutter/material.dart';

import '../domain/visual_question.dart';
import 'pattern_question_widget.dart';

class VisualQuestionWidget extends StatelessWidget {
  const VisualQuestionWidget({
    super.key,
    required this.question,
    this.compact = false,
    this.showChoices = true,
  });

  final VisualQuestion question;
  final bool compact;
  final bool showChoices;

  @override
  Widget build(BuildContext context) {
    return PatternQuestionWidget(
      pattern: question.asPatternQuestion(),
      compact: compact,
      showChoices: showChoices,
    );
  }
}
