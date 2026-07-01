enum AbilityLevel {
  veryLow('매우 낮음'),
  low('낮음'),
  belowAverage('평균 이하'),
  average('평균'),
  aboveAverage('평균 이상'),
  superior('우수'),
  verySuperior('매우 우수');

  const AbilityLevel(this.labelKo);

  final String labelKo;

  static AbilityLevel fromIQ(int iq) {
    if (iq <= 69) {
      return AbilityLevel.veryLow;
    }
    if (iq <= 79) {
      return AbilityLevel.low;
    }
    if (iq <= 89) {
      return AbilityLevel.belowAverage;
    }
    if (iq <= 109) {
      return AbilityLevel.average;
    }
    if (iq <= 119) {
      return AbilityLevel.aboveAverage;
    }
    if (iq <= 129) {
      return AbilityLevel.superior;
    }
    return AbilityLevel.verySuperior;
  }
}
