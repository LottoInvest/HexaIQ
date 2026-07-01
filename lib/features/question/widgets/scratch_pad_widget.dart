import 'package:flutter/material.dart';

enum ScratchPadMode { text, drawing }

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
  const ScratchPadWidget({
    super.key,
    required this.resetToken,
    this.compact = false,
    this.mode = ScratchPadMode.text,
  });

  final Object resetToken;
  final bool compact;
  final ScratchPadMode mode;

  @override
  State<ScratchPadWidget> createState() => _ScratchPadWidgetState();
}

class _ScratchPadWidgetState extends State<ScratchPadWidget> {
  late final TextEditingController _controller;
  late ScratchPadMode _mode;
  final List<List<Offset>> _strokes = [];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _mode = widget.mode;
  }

  @override
  void didUpdateWidget(covariant ScratchPadWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.resetToken != widget.resetToken) {
      _clearAll();
      _mode = widget.mode;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _clearAll() {
    _controller.clear();
    _strokes.clear();
  }

  void _clearAndRebuild() {
    setState(_clearAll);
  }

  Future<void> _confirmClear() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('풀이 메모를 지울까요?'),
          content: const Text('작성한 메모와 그림은 되돌릴 수 없습니다.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('지우기'),
            ),
          ],
        );
      },
    );
    if (confirmed == true && mounted) {
      _clearAndRebuild();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final padding = widget.compact ? 8.0 : 14.0;
    return Card(
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '풀이 메모',
                    style:
                        (widget.compact
                                ? theme.textTheme.labelMedium
                                : theme.textTheme.titleMedium)
                            ?.copyWith(
                              fontSize: widget.compact ? 14 : 16,
                              fontWeight: FontWeight.w700,
                            ),
                  ),
                ),
                _ModeButton(
                  label: '글',
                  selected: _mode == ScratchPadMode.text,
                  compact: widget.compact,
                  onPressed: () => setState(() => _mode = ScratchPadMode.text),
                ),
                _ModeButton(
                  label: '그림',
                  selected: _mode == ScratchPadMode.drawing,
                  compact: widget.compact,
                  onPressed: () =>
                      setState(() => _mode = ScratchPadMode.drawing),
                ),
                IconButton(
                  tooltip: '지우기',
                  iconSize: widget.compact ? 18 : 22,
                  visualDensity: widget.compact
                      ? VisualDensity.compact
                      : VisualDensity.standard,
                  padding: EdgeInsets.all(widget.compact ? 4 : 8),
                  constraints: BoxConstraints.tightFor(
                    width: widget.compact ? 32 : 40,
                    height: widget.compact ? 32 : 40,
                  ),
                  onPressed: _confirmClear,
                  icon: const Icon(Icons.clear),
                ),
              ],
            ),
            SizedBox(height: widget.compact ? 6 : 10),
            Expanded(
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 96),
                child: _mode == ScratchPadMode.text
                    ? TextField(
                        controller: _controller,
                        expands: true,
                        minLines: null,
                        maxLines: null,
                        textAlignVertical: TextAlignVertical.top,
                        style: widget.compact
                            ? theme.textTheme.bodySmall?.copyWith(fontSize: 13)
                            : null,
                        decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          contentPadding: EdgeInsets.all(
                            widget.compact ? 8 : 12,
                          ),
                        ),
                      )
                    : _DrawingPad(
                        strokes: _strokes,
                        onStart: (point) {
                          setState(() => _strokes.add([point]));
                        },
                        onAppend: (point) {
                          if (_strokes.isEmpty) {
                            setState(() => _strokes.add([point]));
                            return;
                          }
                          setState(() => _strokes.last.add(point));
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.label,
    required this.selected,
    required this.compact,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final bool compact;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return TextButton(
      style: TextButton.styleFrom(
        visualDensity: compact ? VisualDensity.compact : VisualDensity.standard,
        minimumSize: Size(compact ? 40 : 48, compact ? 32 : 40),
        padding: EdgeInsets.symmetric(horizontal: compact ? 6 : 10),
        foregroundColor: selected ? colorScheme.primary : colorScheme.onSurface,
        textStyle: TextStyle(
          fontSize: compact ? 12 : 14,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
      onPressed: onPressed,
      child: Text(label),
    );
  }
}

class _DrawingPad extends StatelessWidget {
  const _DrawingPad({
    required this.strokes,
    required this.onStart,
    required this.onAppend,
  });

  final List<List<Offset>> strokes;
  final ValueChanged<Offset> onStart;
  final ValueChanged<Offset> onAppend;

  @override
  Widget build(BuildContext context) {
    final borderColor = Theme.of(context).colorScheme.outline;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (event) => onStart(event.localPosition),
        onPointerMove: (event) => onAppend(event.localPosition),
        child: CustomPaint(
          painter: _ScratchPainter(
            strokes: strokes,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _ScratchPainter extends CustomPainter {
  const _ScratchPainter({required this.strokes, required this.color});

  final List<List<Offset>> strokes;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    for (final stroke in strokes) {
      if (stroke.length < 2) {
        if (stroke.isNotEmpty) {
          canvas.drawCircle(stroke.first, 1.25, paint);
        }
        continue;
      }
      final path = Path()..moveTo(stroke.first.dx, stroke.first.dy);
      for (final point in stroke.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ScratchPainter oldDelegate) {
    return oldDelegate.strokes != strokes || oldDelegate.color != color;
  }
}
