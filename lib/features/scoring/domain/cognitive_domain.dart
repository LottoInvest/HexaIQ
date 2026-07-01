enum CognitiveDomain { verbal, numerical, spatial, pattern, memory, speed }

extension CognitiveDomainInfo on CognitiveDomain {
  String get labelKo {
    return switch (this) {
      CognitiveDomain.verbal => '언어 이해',
      CognitiveDomain.numerical => '수리 추론',
      CognitiveDomain.spatial => '공간 지각',
      CognitiveDomain.pattern => '패턴 인식',
      CognitiveDomain.memory => '작업 기억',
      CognitiveDomain.speed => '처리 속도',
    };
  }
}
