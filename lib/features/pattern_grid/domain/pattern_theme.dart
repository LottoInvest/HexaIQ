import 'package:flutter/material.dart';

import 'pattern_cell.dart';

enum PatternThemeType {
  material3,
  monochrome,
  highContrast,
  kids,
  professional,
}

class PatternTheme {
  const PatternTheme({
    this.type = PatternThemeType.material3,
    this.cellRadius = 8,
    this.cellGap = 6,
    this.emphasisScale = 1.12,
  });

  final PatternThemeType type;
  final double cellRadius;
  final double cellGap;
  final double emphasisScale;

  Color resolveSurface(ColorScheme scheme) {
    return switch (type) {
      PatternThemeType.material3 => scheme.surface,
      PatternThemeType.monochrome => scheme.surface,
      PatternThemeType.highContrast => scheme.inverseSurface,
      PatternThemeType.kids => scheme.primaryContainer,
      PatternThemeType.professional => scheme.surfaceContainerHighest,
    };
  }

  Color resolveElementColor(ColorScheme scheme, PatternColor color) {
    if (type == PatternThemeType.monochrome) {
      return scheme.onSurface;
    }
    if (type == PatternThemeType.highContrast) {
      return scheme.inversePrimary;
    }
    return switch (color) {
      PatternColor.primary => scheme.primary,
      PatternColor.secondary => scheme.secondary,
      PatternColor.success => scheme.tertiary,
      PatternColor.warning => Colors.amber.shade700,
      PatternColor.error => scheme.error,
      PatternColor.neutral => scheme.onSurfaceVariant,
    };
  }
}
