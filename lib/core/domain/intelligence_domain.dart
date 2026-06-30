enum IntelligenceDomain {
  numerical,
  verbal,
  spatial,
  memory,
  logic,
  processing,
}

extension IntelligenceDomainInfo on IntelligenceDomain {
  String get label {
    return switch (this) {
      IntelligenceDomain.numerical => '수리논리',
      IntelligenceDomain.verbal => '언어추론',
      IntelligenceDomain.spatial => '공간지각',
      IntelligenceDomain.memory => '기억력',
      IntelligenceDomain.logic => '논리추론',
      IntelligenceDomain.processing => '처리속도',
    };
  }

  String get shortLabel {
    return switch (this) {
      IntelligenceDomain.numerical => '수리',
      IntelligenceDomain.verbal => '언어',
      IntelligenceDomain.spatial => '공간',
      IntelligenceDomain.memory => '기억',
      IntelligenceDomain.logic => '논리',
      IntelligenceDomain.processing => '속도',
    };
  }

  String get generatorPrefix {
    return switch (this) {
      IntelligenceDomain.numerical => 'NR',
      IntelligenceDomain.verbal => 'VB',
      IntelligenceDomain.spatial => 'SP',
      IntelligenceDomain.memory => 'MR',
      IntelligenceDomain.logic => 'LR',
      IntelligenceDomain.processing => 'PR',
    };
  }

  bool get isAvailable => this == IntelligenceDomain.numerical;
}
