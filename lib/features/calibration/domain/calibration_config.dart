class CalibrationConfig {
  const CalibrationConfig({
    this.minResponsesForStable = 30,
    this.learningRate = 0.08,
    this.minDiscrimination = 0.35,
    this.maxDiscrimination = 2.5,
    this.minGuessing = 0.0,
    this.maxGuessing = 0.35,
    this.minDifficulty = -3.0,
    this.maxDifficulty = 3.0,
  });

  final int minResponsesForStable;
  final double learningRate;
  final double minDiscrimination;
  final double maxDiscrimination;
  final double minGuessing;
  final double maxGuessing;
  final double minDifficulty;
  final double maxDifficulty;
}
