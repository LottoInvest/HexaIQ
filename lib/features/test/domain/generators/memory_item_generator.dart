import 'item_generator.dart';
import '../models/test_item.dart';

class MemoryItemGenerator extends ItemGenerator {
  const MemoryItemGenerator();

  static const _types = ['숫자 기억', '위치 기억', '순서 기억'];

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
    final length = 4 + (difficulty * 4).round();
    final digits = [
      for (var offset = 0; offset < length; offset++)
        '${(index + offset * 3) % 10}',
    ].join();
    return TestItem(
      id: 'MR-GEN-${(index + 1).toString().padLeft(3, '0')}',
      domain: 'memory',
      type: _types[index % _types.length],
      question: '3초 동안 숫자를 기억한 뒤 같은 순서를 고르세요: $digits',
      choices: [
        digits,
        '$digits${index % 10}',
        digits.split('').reversed.join(),
        digits.substring(1),
      ],
      answerIndex: 0,
      difficulty: difficulty,
      discrimination: discriminationFor(difficulty),
      guessing: 0.25,
      estimatedTime: estimatedSecondsFor(difficulty, base: 14),
      explanation: '제시된 숫자의 순서를 그대로 유지한 선택지가 정답입니다.',
    );
  }
}
