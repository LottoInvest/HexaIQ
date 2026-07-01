import 'package:flutter/material.dart';

import '../../pattern_grid/domain/pattern_cell.dart';
import 'answer_choice_list.dart';
import 'visual_choice_grid.dart';

class AnswerChoiceArea extends StatelessWidget {
  const AnswerChoiceArea.text({
    super.key,
    required List<String> choices,
    required this.selectedIndex,
    required this.onSelect,
  }) : textChoices = choices,
       visualChoices = null;

  const AnswerChoiceArea.visual({
    super.key,
    required List<PatternGrid> choices,
    required this.selectedIndex,
    required this.onSelect,
  }) : visualChoices = choices,
       textChoices = null;

  final List<String>? textChoices;
  final List<PatternGrid>? visualChoices;
  final int? selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final visual = visualChoices;
    if (visual != null) {
      return VisualChoiceGrid(
        choices: visual,
        selectedIndex: selectedIndex,
        onSelect: onSelect,
      );
    }
    return AnswerChoiceList(
      choices: textChoices ?? const [],
      selectedIndex: selectedIndex,
      onSelect: onSelect,
    );
  }
}
