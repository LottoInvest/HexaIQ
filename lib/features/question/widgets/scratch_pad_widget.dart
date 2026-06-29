import 'package:flutter/material.dart';

class ScratchPadConfig {
  const ScratchPadConfig({this.extraEnabledTypeCodes = const {}});

  static const defaultEnabledTypeCodes = {
    'NR01',
    'NR02',
    'NR03',
    'NR04',
    'NR05',
    'NR15',
    'NR16',
    'NR17',
    'NR18',
    'NR19',
    'NR20',
  };

  final Set<String> extraEnabledTypeCodes;

  bool isEnabledFor(String typeCode) {
    return defaultEnabledTypeCodes.contains(typeCode) ||
        extraEnabledTypeCodes.contains(typeCode);
  }
}

class ScratchPadWidget extends StatefulWidget {
  const ScratchPadWidget({super.key, required this.resetToken});

  final Object resetToken;

  @override
  State<ScratchPadWidget> createState() => _ScratchPadWidgetState();
}

class _ScratchPadWidgetState extends State<ScratchPadWidget> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void didUpdateWidget(covariant ScratchPadWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.resetToken != widget.resetToken) {
      _controller.clear();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Scratch Work', style: theme.textTheme.titleMedium),
            const SizedBox(height: 10),
            Expanded(
              child: TextField(
                controller: _controller,
                expands: true,
                minLines: null,
                maxLines: null,
                textAlignVertical: TextAlignVertical.top,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.all(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
