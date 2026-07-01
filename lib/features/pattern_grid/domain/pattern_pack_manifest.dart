import 'pattern_difficulty.dart';
import 'pattern_element.dart';

class PatternPackManifest {
  const PatternPackManifest({
    required this.packId,
    required this.name,
    required this.version,
    required this.target,
    required this.difficultyRange,
    required this.questionCount,
    required this.supportedElements,
    this.requiresPremium = false,
    this.enabled = true,
    this.price,
    this.currency,
  });

  final String packId;
  final String name;
  final String version;
  final String target;
  final List<PatternDifficulty> difficultyRange;
  final int questionCount;
  final List<String> supportedElements;
  final bool requiresPremium;
  final bool enabled;
  final double? price;
  final String? currency;

  bool supportsElement(PatternElement element) {
    return supportedElements.contains(element.type);
  }

  factory PatternPackManifest.fromJson(Map<String, Object?> json) {
    return PatternPackManifest(
      packId: json['packId'] as String? ?? 'unknown_pack',
      name: json['name'] as String? ?? 'Unknown Pattern Pack',
      version: json['version'] as String? ?? '0.0.0',
      target: json['target'] as String? ?? 'basic',
      difficultyRange: [
        for (final value
            in json['difficultyRange'] as List<Object?>? ?? const ['normal'])
          patternDifficultyFromName(value as String?),
      ],
      questionCount: json['questionCount'] as int? ?? 0,
      supportedElements: [
        for (final value
            in json['supportedElements'] as List<Object?>? ?? const ['shape'])
          value.toString(),
      ],
      requiresPremium: json['requiresPremium'] as bool? ?? false,
      enabled: json['enabled'] as bool? ?? true,
      price: (json['price'] as num?)?.toDouble(),
      currency: json['currency'] as String?,
    );
  }
}
