import 'package:flutter/material.dart';

import 'layout_tokens.dart';

class QuestionScrollArea extends StatelessWidget {
  const QuestionScrollArea({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(
          left: LayoutTokens.screenHorizontalPadding,
          right: LayoutTokens.screenHorizontalPadding,
          bottom: LayoutTokens.bottomActionHeight + 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var index = 0; index < children.length; index++) ...[
              if (index > 0) const SizedBox(height: LayoutTokens.sectionGap),
              children[index],
            ],
          ],
        ),
      ),
    );
  }
}
