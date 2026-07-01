import 'item_generator.dart';
import '../models/test_item.dart';

class MathLogicItemGenerator extends ItemGenerator {
  const MathLogicItemGenerator();

  static const _types = ['수열', '비례식', '간단한 방정식', '규칙 찾기'];

  @override
  List<TestItem> generate({
    required int count,
    required double targetDifficulty,
  }) {
    final difficulty = normalizedDifficulty(targetDifficulty);
    return [
      for (var index = 0; index < count; index++)
        _item(index: index, difficulty: difficulty),
    ];
  }

  TestItem _item({required int index, required double difficulty}) {
    final step = 2 + (index % 5);
    final start = 3 + index;
    final answer = start + step * 4;
    final choices = [
      answer,
      answer + step,
      answer - step,
      answer + step * 2,
    ].map((value) => '$value').toList(growable: false);
    return TestItem(
      id: 'NR-GEN-${(index + 1).toString().padLeft(3, '0')}',
      domain: 'numerical',
      type: _types[index % _types.length],
      question:
          '$start, ${start + step}, ${start + step * 2}, ${start + step * 3}, ?',
      choices: choices,
      answerIndex: 0,
      difficulty: difficulty,
      discrimination: discriminationFor(difficulty),
      guessing: 0.25,
      estimatedTime: estimatedSecondsFor(difficulty, base: 20),
      explanation: '인접한 수가 $step씩 증가하므로 다음 수는 $answer입니다.',
    );
  }
}
