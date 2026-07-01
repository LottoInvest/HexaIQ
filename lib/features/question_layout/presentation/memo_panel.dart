import 'package:flutter/material.dart';

class MemoPanel extends StatelessWidget {
  const MemoPanel({super.key, this.initiallyExpanded = false});

  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      initiallyExpanded: initiallyExpanded,
      tilePadding: EdgeInsets.zero,
      title: const Text('풀이 메모'),
      children: [
        TextField(
          minLines: 2,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: '필요하면 계산 과정이나 규칙을 메모하세요.',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }
}
