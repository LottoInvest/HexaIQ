import 'package:flutter/material.dart';

class QuestionScreenLayout extends StatelessWidget {
  const QuestionScreenLayout({
    super.key,
    required this.progressHeader,
    required this.domainChipBar,
    required this.scrollArea,
    required this.bottomActionArea,
  });

  final Widget progressHeader;
  final Widget domainChipBar;
  final Widget scrollArea;
  final Widget bottomActionArea;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [progressHeader, domainChipBar, scrollArea, bottomActionArea],
    );
  }
}
