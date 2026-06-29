class ExplanationBuilder {
  const ExplanationBuilder();

  String sequence(String rule, Object answer) {
    return '$rule 따라서 정답은 $answer입니다.';
  }

  String equation(String steps, Object answer) {
    return '$steps 계산하면 정답은 $answer입니다.';
  }

  String generic(String message) => message;
}
