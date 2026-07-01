enum PatternDifficulty { easy, normal, hard, expert }

PatternDifficulty patternDifficultyFromName(String? name) {
  return PatternDifficulty.values.firstWhere(
    (difficulty) => difficulty.name == name,
    orElse: () => PatternDifficulty.normal,
  );
}
