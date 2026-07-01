enum AgeGroup {
  elementary56,
  middle,
  high,
  adult;

  String get code {
    return switch (this) {
      AgeGroup.elementary56 => 'elementary56',
      AgeGroup.middle => 'middle',
      AgeGroup.high => 'high',
      AgeGroup.adult => 'adult',
    };
  }

  String get labelKo {
    return switch (this) {
      AgeGroup.elementary56 => '초등 5-6',
      AgeGroup.middle => '중학생',
      AgeGroup.high => '고등학생',
      AgeGroup.adult => '성인',
    };
  }

  static AgeGroup parse(String value) {
    final normalized = value.toLowerCase().replaceAll(RegExp(r'[\s_-]'), '');
    if (normalized.contains('middle') || normalized.contains('중')) {
      return AgeGroup.middle;
    }
    if (normalized.contains('high') || normalized.contains('고')) {
      return AgeGroup.high;
    }
    if (normalized.contains('adult') || normalized.contains('성인')) {
      return AgeGroup.adult;
    }
    return AgeGroup.elementary56;
  }
}

class NormProfile {
  const NormProfile({
    required this.id,
    required this.ageGroup,
    this.meanTheta = 0.0,
    this.sdTheta = 1.0,
    this.meanIQ = 100,
    this.sdIQ = 15,
  });

  factory NormProfile.forAgeGroup(AgeGroup ageGroup) {
    return NormProfile(id: ageGroup.code, ageGroup: ageGroup.code);
  }

  static const defaultProfile = NormProfile(
    id: 'default-elementary56',
    ageGroup: 'elementary56',
  );

  final String id;
  final String ageGroup;
  final double meanTheta;
  final double sdTheta;
  final int meanIQ;
  final int sdIQ;

  AgeGroup get resolvedAgeGroup => AgeGroup.parse(ageGroup);

  double get safeSdTheta {
    return sdTheta.isFinite && sdTheta > 0 ? sdTheta : 1.0;
  }
}
