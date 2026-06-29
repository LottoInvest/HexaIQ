import 'age_mapper.dart';

class DifficultyProfile {
  const DifficultyProfile({
    required this.level,
    required this.numberMax,
    required this.operationSteps,
    required this.ruleCount,
    required this.distractorSimilarity,
    required this.allowNegative,
    required this.allowLargeNumbers,
    required this.allowCompositeRules,
    required this.estimatedTimeSec,
  });

  final int level;
  final int numberMax;
  final int operationSteps;
  final int ruleCount;
  final int distractorSimilarity;
  final bool allowNegative;
  final bool allowLargeNumbers;
  final bool allowCompositeRules;
  final int estimatedTimeSec;
}

class DifficultyManager {
  const DifficultyManager(this.ageMapper);

  final AgeMapper ageMapper;

  int resolveLevel({
    required String ageGroup,
    required int? requestedLevel,
    int testTypeOffset = 0,
  }) {
    final age = ageMapper.resolve(ageGroup);
    final raw = requestedLevel ?? age.defaultLevel + testTypeOffset;
    return clamp(raw, age.minLevel, age.maxLevel);
  }

  DifficultyProfile profile({required String ageGroup, required int level}) {
    final age = ageMapper.resolve(ageGroup);
    final clamped = clamp(level, age.minLevel, age.maxLevel);
    final numberMax = switch (clamped) {
      <= 2 => age.smallNumberMax,
      <= 6 => age.mediumNumberMax,
      _ => age.largeNumberMax,
    };
    return DifficultyProfile(
      level: clamped,
      numberMax: numberMax,
      operationSteps: clamped <= 3
          ? 1
          : clamped <= 7
          ? 2
          : 3,
      ruleCount: clamped <= 4
          ? 1
          : clamped <= 8
          ? 2
          : 3,
      distractorSimilarity: clamped <= 3
          ? 1
          : clamped <= 7
          ? 2
          : 3,
      allowNegative: age.allowsNegative && clamped >= 6,
      allowLargeNumbers: clamped >= 7,
      allowCompositeRules: clamped >= 8,
      estimatedTimeSec: estimatedTimeSec(clamped),
    );
  }

  int estimatedTimeSec(int level) => 12 + clamp(level, 1, 10) * 4;

  int clamp(int value, int min, int max) {
    if (value < min) {
      return min;
    }
    if (value > max) {
      return max;
    }
    return value;
  }

  String band(int level) {
    return switch (level) {
      <= 1 => 'very_easy',
      2 || 3 => 'easy',
      4 => 'medium_low',
      5 => 'medium',
      6 => 'medium_high',
      7 => 'hard_low',
      8 => 'hard',
      9 => 'very_hard',
      _ => 'expert',
    };
  }
}
