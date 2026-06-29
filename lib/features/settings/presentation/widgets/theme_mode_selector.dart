import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../hexaiq/presentation/state/hexaiq_app_state.dart';

class ThemeModeSelector extends StatelessWidget {
  const ThemeModeSelector({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<HexaIQAppState>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!compact) ...[
          Text('테마', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
        ],
        SegmentedButton<ThemeMode>(
          segments: const [
            ButtonSegment(
              value: ThemeMode.system,
              label: Text('시스템'),
              icon: Icon(Icons.brightness_auto_outlined),
            ),
            ButtonSegment(
              value: ThemeMode.light,
              label: Text('라이트'),
              icon: Icon(Icons.light_mode_outlined),
            ),
            ButtonSegment(
              value: ThemeMode.dark,
              label: Text('다크'),
              icon: Icon(Icons.dark_mode_outlined),
            ),
          ],
          selected: {state.themeMode},
          onSelectionChanged: (selection) {
            state.setThemeMode(selection.first);
          },
        ),
      ],
    );
  }
}
