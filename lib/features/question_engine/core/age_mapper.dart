class AgeProfile {
  const AgeProfile({
    required this.code,
    required this.label,
    required this.minLevel,
    required this.defaultLevel,
    required this.maxLevel,
    required this.smallNumberMax,
    required this.mediumNumberMax,
    required this.largeNumberMax,
    required this.allowsNegative,
    required this.allowsFraction,
  });

  final String code;
  final String label;
  final int minLevel;
  final int defaultLevel;
  final int maxLevel;
  final int smallNumberMax;
  final int mediumNumberMax;
  final int largeNumberMax;
  final bool allowsNegative;
  final bool allowsFraction;
}

class AgeMapper {
  static const kindergarten = AgeProfile(
    code: 'kindergarten',
    label: '유치부',
    minLevel: 1,
    defaultLevel: 1,
    maxLevel: 2,
    smallNumberMax: 10,
    mediumNumberMax: 20,
    largeNumberMax: 30,
    allowsNegative: false,
    allowsFraction: false,
  );

  static const grade12 = AgeProfile(
    code: 'grade1_2',
    label: '초1~2',
    minLevel: 2,
    defaultLevel: 2,
    maxLevel: 3,
    smallNumberMax: 20,
    mediumNumberMax: 50,
    largeNumberMax: 100,
    allowsNegative: false,
    allowsFraction: false,
  );

  static const grade34 = AgeProfile(
    code: 'grade3_4',
    label: '초3~4',
    minLevel: 3,
    defaultLevel: 4,
    maxLevel: 5,
    smallNumberMax: 50,
    mediumNumberMax: 200,
    largeNumberMax: 500,
    allowsNegative: false,
    allowsFraction: false,
  );

  static const grade56 = AgeProfile(
    code: 'grade5_6',
    label: '초5~6',
    minLevel: 5,
    defaultLevel: 5,
    maxLevel: 6,
    smallNumberMax: 100,
    mediumNumberMax: 1000,
    largeNumberMax: 3000,
    allowsNegative: false,
    allowsFraction: true,
  );

  static const middle = AgeProfile(
    code: 'middle',
    label: '중학생',
    minLevel: 6,
    defaultLevel: 7,
    maxLevel: 8,
    smallNumberMax: 200,
    mediumNumberMax: 5000,
    largeNumberMax: 10000,
    allowsNegative: true,
    allowsFraction: true,
  );

  static const high = AgeProfile(
    code: 'high',
    label: '고등학생',
    minLevel: 7,
    defaultLevel: 8,
    maxLevel: 9,
    smallNumberMax: 500,
    mediumNumberMax: 10000,
    largeNumberMax: 20000,
    allowsNegative: true,
    allowsFraction: true,
  );

  static const adult = AgeProfile(
    code: 'adult',
    label: '성인',
    minLevel: 8,
    defaultLevel: 8,
    maxLevel: 10,
    smallNumberMax: 500,
    mediumNumberMax: 10000,
    largeNumberMax: 30000,
    allowsNegative: true,
    allowsFraction: true,
  );

  static const _profiles = [
    kindergarten,
    grade12,
    grade34,
    grade56,
    middle,
    high,
    adult,
  ];

  AgeProfile resolve(String ageGroup) {
    final normalized = ageGroup.toLowerCase().replaceAll(' ', '');
    if (normalized.contains('kindergarten') || normalized.contains('유치')) {
      return kindergarten;
    }
    if (normalized.contains('grade1_2') ||
        normalized.contains('1-2') ||
        normalized.contains('1~2') ||
        normalized.contains('초1')) {
      return grade12;
    }
    if (normalized.contains('grade3_4') ||
        normalized.contains('3-4') ||
        normalized.contains('3~4') ||
        normalized.contains('초3')) {
      return grade34;
    }
    if (normalized.contains('grade5_6') ||
        normalized.contains('5-6') ||
        normalized.contains('5~6') ||
        normalized.contains('초5')) {
      return grade56;
    }
    if (normalized.contains('middle') || normalized.contains('중')) {
      return middle;
    }
    if (normalized.contains('high') || normalized.contains('고')) {
      return high;
    }
    if (normalized.contains('adult') || normalized.contains('성인')) {
      return adult;
    }
    return grade56;
  }

  List<AgeProfile> get profiles => _profiles;
}
