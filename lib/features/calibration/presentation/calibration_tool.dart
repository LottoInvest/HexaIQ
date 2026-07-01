import 'package:flutter/material.dart';

import '../../item_bank/domain/exposure_status.dart';
import '../../item_bank/domain/item.dart';
import '../domain/calibration_profile.dart';

class CalibrationTool extends StatelessWidget {
  const CalibrationTool({
    super.key,
    required this.showDebugMetrics,
    this.items = const [],
    this.exposures = const [],
    this.profiles = const [],
  });

  final bool showDebugMetrics;
  final List<Item> items;
  final List<ExposureStatus> exposures;
  final List<CalibrationProfile> profiles;

  @override
  Widget build(BuildContext context) {
    if (!showDebugMetrics) {
      return const SizedBox.shrink();
    }
    final exposureById = {
      for (final status in exposures) status.itemId: status,
    };
    return ExpansionTile(
      title: const Text('Calibration Mode'),
      subtitle: Text('items ${items.length} / calibration ${profiles.length}'),
      children: [
        for (final item in items.take(8))
          ListTile(
            dense: true,
            title: Text(item.id),
            subtitle: Text(
              'difficulty=${item.difficultyIndex.toStringAsFixed(2)} '
              'a=${item.discrimination.toStringAsFixed(2)} '
              'c=${item.guessing.toStringAsFixed(2)} '
              'usage=${exposureById[item.id]?.exposureCount ?? item.usageCount}',
            ),
          ),
      ],
    );
  }
}
