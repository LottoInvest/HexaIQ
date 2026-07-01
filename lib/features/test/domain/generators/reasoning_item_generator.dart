import 'item_generator.dart';
import '../models/test_item.dart';

class ReasoningItemGenerator extends ItemGenerator {
  const ReasoningItemGenerator();

  static const _types = ['도형 규칙', '논리 조건', '관계 추론'];

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
    final names = ['철수', '영희', '민수'];
    return TestItem(
      id: 'LG-GEN-${(index + 1).toString().padLeft(3, '0')}',
      domain: 'logic',
      type: _types[index % _types.length],
      question:
          '${names[0]}는 ${names[1]}보다 키가 크고, ${names[1]}는 ${names[2]}보다 큽니다. 가장 큰 사람은?',
      choices: [names[0], names[1], names[2], '알 수 없음'],
      answerIndex: 0,
      difficulty: difficulty,
      discrimination: discriminationFor(difficulty),
      guessing: 0.25,
      estimatedTime: estimatedSecondsFor(difficulty, base: 18),
      explanation: '철수 > 영희 > 민수 순서이므로 가장 큰 사람은 철수입니다.',
    );
  }
}
