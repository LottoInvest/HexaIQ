import '../models/test_item.dart';

abstract class ItemGenerator {
  const ItemGenerator();

  List<TestItem> generate({
    required int count,
    required double targetDifficulty,
  });
}

double normalizedDifficulty(double value) {
  if (!value.isFinite) {
    return 0.5;
  }
  return value.clamp(0.2, 1.0).toDouble();
}

double discriminationFor(double difficulty) {
  final normalized = normalizedDifficulty(difficulty);
  return (0.9 + normalized * 0.7).clamp(0.8, 1.8).toDouble();
}

int estimatedSecondsFor(double difficulty, {int base = 18}) {
  return (base + normalizedDifficulty(difficulty) * 24).round();
}
