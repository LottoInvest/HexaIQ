abstract class PatternElement {
  const PatternElement();

  String get type;

  Map<String, Object?> toJson();
}

enum PatternShape { square, circle, triangle, diamond, pentagon, hexagon, star }

class ShapeElement extends PatternElement {
  const ShapeElement(this.shape);

  final PatternShape shape;

  @override
  String get type => 'shape';

  @override
  Map<String, Object?> toJson() => {'type': type, 'shape': shape.name};
}

class IconElement extends PatternElement {
  const IconElement(this.name);

  final String name;

  @override
  String get type => 'icon';

  @override
  Map<String, Object?> toJson() => {'type': type, 'name': name};
}

class SvgElement extends PatternElement {
  const SvgElement(this.assetPath, {this.category = 'symbols'});

  final String assetPath;
  final String category;

  @override
  String get type => 'svg';

  @override
  Map<String, Object?> toJson() => {
    'type': type,
    'assetPath': assetPath,
    'category': category,
  };
}

class EmojiElement extends PatternElement {
  const EmojiElement(this.emoji);

  final String emoji;

  @override
  String get type => 'emoji';

  @override
  Map<String, Object?> toJson() => {'type': type, 'emoji': emoji};
}

class ImageElement extends PatternElement {
  const ImageElement(this.assetPath, {this.semanticLabel});

  final String assetPath;
  final String? semanticLabel;

  @override
  String get type => 'image';

  @override
  Map<String, Object?> toJson() => {
    'type': type,
    'assetPath': assetPath,
    if (semanticLabel != null) 'semanticLabel': semanticLabel,
  };
}

PatternElement patternElementFromJson(Object? value) {
  if (value is String) {
    return ShapeElement(_shapeFromName(value));
  }
  if (value is! Map<String, Object?>) {
    return const ShapeElement(PatternShape.square);
  }
  final type = value['type'] as String? ?? 'shape';
  return switch (type) {
    'icon' => IconElement(value['name'] as String? ?? 'star'),
    'svg' => SvgElement(
      value['assetPath'] as String? ??
          'assets/patterns/shapes/sample_shape.svg',
      category: value['category'] as String? ?? 'symbols',
    ),
    'emoji' => EmojiElement(value['emoji'] as String? ?? '😀'),
    'image' => ImageElement(
      value['assetPath'] as String? ?? 'assets/patterns/objects/sample.png',
      semanticLabel: value['semanticLabel'] as String?,
    ),
    _ => ShapeElement(_shapeFromName(value['shape'] as String? ?? 'square')),
  };
}

PatternShape _shapeFromName(String name) {
  return PatternShape.values.firstWhere(
    (shape) => shape.name == name,
    orElse: () => PatternShape.square,
  );
}
