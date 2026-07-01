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
      IntelligenceDomain.numerical => '\uC218\uB9AC\uB17C\uB9AC',
      IntelligenceDomain.verbal => '\uC5B8\uC5B4\uCD94\uB860',
      IntelligenceDomain.spatial => '\uACF5\uAC04\uC9C0\uAC01',
      IntelligenceDomain.memory => '\uAE30\uC5B5',
      IntelligenceDomain.logic => '\uB17C\uB9AC\uCD94\uB860',
      IntelligenceDomain.processing => '\uCC98\uB9AC\uC18D\uB3C4',
    };
  }

  String get shortLabel {
    return switch (this) {
      IntelligenceDomain.numerical => '\uC218\uB9AC',
      IntelligenceDomain.verbal => '\uC5B8\uC5B4',
      IntelligenceDomain.spatial => '\uACF5\uAC04',
      IntelligenceDomain.memory => '\uAE30\uC5B5',
      IntelligenceDomain.logic => '\uB17C\uB9AC',
      IntelligenceDomain.processing => '\uC18D\uB3C4',
    };
  }

  String get generatorPrefix {
    return switch (this) {
      IntelligenceDomain.numerical => 'NR',
      IntelligenceDomain.verbal => 'LR',
      IntelligenceDomain.spatial => 'SR',
      IntelligenceDomain.memory => 'MR',
      IntelligenceDomain.logic => 'LG',
      IntelligenceDomain.processing => 'PS',
    };
  }

  bool get isAvailable => true;
}
