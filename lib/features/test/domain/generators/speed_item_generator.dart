import 'item_generator.dart';
import '../models/test_item.dart';

class SpeedItemGenerator extends ItemGenerator {
  const SpeedItemGenerator();

  static const _types = ['빠른 비교', '기호 탐색', '단순 판단'];

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
    final target = switch (index % 3) {
      0 => '7',
      1 => '◇',
      _ => '가',
    };
    final row = '$target $target ${index % 2 == 0 ? '9' : '◆'} $target $target';
    return TestItem(
      id: 'PS-GEN-${(index + 1).toString().padLeft(3, '0')}',
      domain: 'processing',
      type: _types[index % _types.length],
      question: '다음 항목 중 다른 하나를 가능한 빨리 찾으세요.\n$row',
      choices: ['세 번째', '첫 번째', '두 번째', '다섯 번째'],
      answerIndex: 0,
      difficulty: difficulty,
      discrimination: discriminationFor(difficulty),
      guessing: 0.25,
      estimatedTime: estimatedSecondsFor(difficulty, base: 8),
      explanation: '나머지와 다른 기호가 세 번째 위치에 있습니다.',
    );
  }
}
