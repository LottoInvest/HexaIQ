import 'item_generator.dart';
import '../models/test_item.dart';

class SpatialItemGenerator extends ItemGenerator {
  const SpatialItemGenerator();

  static const _types = ['도형 회전', '전개도', '패턴 매칭', '좌표', '방향', '도형 관계'];
  static const _patterns = ['▲ ▼ ▲ ▼ ?', '■ □ ■ □ ?', '◆ ◇ ◆ ◇ ?'];

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
    final pattern = _patterns[index % _patterns.length];
    final answer = switch (index % _patterns.length) {
      0 => '▲',
      1 => '■',
      _ => '◆',
    };
    return TestItem(
      id: 'SR-GEN-${(index + 1).toString().padLeft(3, '0')}',
      domain: 'spatial',
      type: _types[index % _types.length],
      question: '도형의 규칙에 맞는 다음 기호를 고르세요.\n$pattern',
      choices: [answer, '▼', '□', '◇'],
      answerIndex: 0,
      difficulty: difficulty,
      discrimination: discriminationFor(difficulty),
      guessing: 0.25,
      estimatedTime: estimatedSecondsFor(difficulty, base: 16),
      explanation: '도형이 번갈아 나타나는 패턴이므로 앞의 반복 규칙을 그대로 적용합니다.',
    );
  }
}
