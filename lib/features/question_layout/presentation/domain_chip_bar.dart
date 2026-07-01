import 'package:flutter/material.dart';

class DomainChipData {
  const DomainChipData({
    required this.index,
    required this.label,
    this.isCurrent = false,
    this.isCompleted = false,
  });

  final int index;
  final String label;
  final bool isCurrent;
  final bool isCompleted;
}

class DomainChipBar extends StatelessWidget {
  const DomainChipBar({super.key, required this.items});

  final List<DomainChipData> items;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final item = items[index];
          return Chip(
            visualDensity: VisualDensity.compact,
            avatar: item.isCompleted
                ? Icon(Icons.check_circle, size: 16, color: scheme.primary)
                : CircleAvatar(
                    radius: 9,
                    child: Text(
                      '${item.index}',
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
            label: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 64),
              child: Text(item.label, overflow: TextOverflow.ellipsis),
            ),
            backgroundColor: item.isCurrent
                ? scheme.primaryContainer
                : item.isCompleted
                ? scheme.secondaryContainer
                : scheme.surfaceContainerHighest,
          );
        },
      ),
    );
  }
}
