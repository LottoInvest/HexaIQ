import 'dart:async';

import 'package:flutter/material.dart';

class MockAdDialog extends StatefulWidget {
  const MockAdDialog({
    super.key,
    required this.title,
    required this.message,
    this.countdown = const Duration(seconds: 5),
  });

  final String title;
  final String message;
  final Duration countdown;

  @override
  State<MockAdDialog> createState() => _MockAdDialogState();
}

class _MockAdDialogState extends State<MockAdDialog> {
  Timer? _timer;
  late int _remainingSeconds;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.countdown.inSeconds.clamp(1, 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remainingSeconds <= 1) {
        _timer?.cancel();
        if (mounted) {
          Navigator.of(context).pop(true);
        }
        return;
      }
      if (mounted) {
        setState(() => _remainingSeconds -= 1);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final duration = widget.countdown.inSeconds.clamp(1, 60);
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            height: 150,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.ondemand_video, size: 44),
                const SizedBox(height: 8),
                const Text('잠시 후 검사 결과가 이어집니다.'),
                const SizedBox(height: 4),
                Text('$_remainingSeconds초'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(widget.message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          LinearProgressIndicator(value: 1 - (_remainingSeconds / duration)),
        ],
      ),
    );
  }
}
