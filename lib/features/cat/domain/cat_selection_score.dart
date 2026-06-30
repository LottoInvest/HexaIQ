class CATSelectionScore {
  const CATSelectionScore({
    required this.informationScore,
    required this.exposureScore,
    required this.difficultyMatchScore,
    double? totalScore,
  }) : totalScore =
           totalScore ??
           informationScore * 0.5 +
               difficultyMatchScore * 0.3 +
               exposureScore * 0.2;

  final double informationScore;
  final double exposureScore;
  final double difficultyMatchScore;
  final double totalScore;
}
