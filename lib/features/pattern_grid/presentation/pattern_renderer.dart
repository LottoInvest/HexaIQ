import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../domain/pattern_cell.dart';
import '../domain/pattern_theme.dart';

class PatternRenderer extends StatelessWidget {
  const PatternRenderer({
    super.key,
    required this.cell,
    this.patternTheme = const PatternTheme(),
    this.compact = false,
    this.animate = true,
  });

  final PatternCell cell;
  final PatternTheme patternTheme;
  final bool compact;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = patternTheme.resolveElementColor(scheme, cell.color);
    final safeRotation = cell.rotation.isFinite ? cell.rotation % 360 : 0.0;
    final turns = safeRotation / 360;
    final size = compact ? 22.0 : 30.0;
    final safeScale = cell.scale.isFinite ? cell.scale.clamp(0.2, 2.0) : 1.0;
    final safeOpacity = cell.opacity.isFinite
        ? cell.opacity.clamp(0.0, 1.0)
        : 1.0;
    final scaledSize = size * safeScale;
    final content = _contentFor(cell.element, color, scaledSize);
    final decorated = AnimatedContainer(
      duration: animate ? const Duration(milliseconds: 180) : Duration.zero,
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: patternTheme.resolveSurface(scheme),
        borderRadius: BorderRadius.circular(patternTheme.cellRadius),
        border: cell.showBorder
            ? Border.all(
                color: cell.highlighted
                    ? scheme.primary
                    : scheme.outlineVariant,
                width: cell.highlighted ? 2 : 1,
              )
            : null,
        boxShadow: cell.highlighted
            ? [
                BoxShadow(
                  color: scheme.primary.withValues(alpha: 0.18),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Center(
        child: Opacity(
          opacity: safeOpacity,
          child: Transform.scale(
            scale: cell.highlighted ? patternTheme.emphasisScale : 1,
            child: AnimatedRotation(
              turns: turns,
              duration: animate
                  ? const Duration(milliseconds: 180)
                  : Duration.zero,
              child: content,
            ),
          ),
        ),
      ),
    );
    return Semantics(label: '${cell.element.type} pattern', child: decorated);
  }

  Widget _contentFor(PatternElement element, Color color, double size) {
    return switch (element) {
      ShapeElement(:final shape) => Icon(
        _shapeIcon(shape, cell.filled),
        color: color,
        size: size,
      ),
      IconElement(:final name) => Icon(
        _iconByName(name),
        color: color,
        size: size,
      ),
      SvgElement(:final assetPath) => SvgPicture.asset(
        assetPath,
        width: size,
        height: size,
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
        placeholderBuilder: (_) => Icon(Icons.image, color: color, size: size),
      ),
      EmojiElement(:final emoji) => Text(
        emoji,
        style: TextStyle(fontSize: size, height: 1),
      ),
      ImageElement(:final assetPath, :final semanticLabel) => Image.asset(
        assetPath,
        width: size,
        height: size,
        semanticLabel: semanticLabel,
        errorBuilder: (_, _, _) => Icon(Icons.image, color: color, size: size),
      ),
      _ => Icon(Icons.category, color: color, size: size),
    };
  }

  IconData _shapeIcon(PatternShape shape, bool filled) {
    return switch (shape) {
      PatternShape.square => filled ? Icons.square : Icons.crop_square,
      PatternShape.circle => filled ? Icons.circle : Icons.circle_outlined,
      PatternShape.triangle => Icons.change_history,
      PatternShape.diamond => filled ? Icons.diamond : Icons.diamond_outlined,
      PatternShape.pentagon =>
        filled ? Icons.pentagon : Icons.pentagon_outlined,
      PatternShape.hexagon => filled ? Icons.hexagon : Icons.hexagon_outlined,
      PatternShape.star => filled ? Icons.star : Icons.star_border,
    };
  }

  IconData _iconByName(String name) {
    return switch (name) {
      'home' => Icons.home,
      'favorite' => Icons.favorite,
      'star' => Icons.star,
      'bolt' => Icons.bolt,
      'psychology' => Icons.psychology,
      'extension' => Icons.extension,
      'school' => Icons.school,
      'timer' => Icons.timer,
      _ => Icons.category,
    };
  }
}
