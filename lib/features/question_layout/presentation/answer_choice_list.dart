import 'package:flutter/material.dart';

import 'layout_tokens.dart';

class AnswerChoiceList extends StatelessWidget {
  const AnswerChoiceList({
    super.key,
    required this.choices,
    required this.selectedIndex,
    required this.onSelect,
  });

  final List<String> choices;
  final int? selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < choices.length; index++)
          Padding(
            padding: EdgeInsets.only(
              bottom: index == choices.length - 1 ? 0 : LayoutTokens.choiceGap,
            ),
            child: SizedBox(
              width: double.infinity,
              height: LayoutTokens.choiceButtonHeight,
              child: OutlinedButton(
                onPressed: () => onSelect(index),
                style: OutlinedButton.styleFrom(
                  backgroundColor: selectedIndex == index
                      ? Theme.of(context).colorScheme.primaryContainer
                      : null,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      LayoutTokens.cardRadius,
                    ),
                  ),
                ),
                child: Text(
                  choices[index],
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
