import 'item_generator.dart';
import '../models/test_item.dart';

class VerbalItemGenerator extends ItemGenerator {
  const VerbalItemGenerator();

  static const _types = [
    '어휘 관계',
    '문장 추론',
    '글 핵심 파악',
    '유의어',
    '반의어',
    '비유',
    '분류',
    '속담',
    '문맥',
    '배열',
  ];

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
    final type = _types[index % _types.length];
    final data = switch (index % 5) {
      0 => (
        question: "'빠르다'와 가장 가까운 뜻을 가진 단어는?",
        choices: ['신속하다', '느리다', '무겁다', '조용하다'],
        answer: 0,
        explanation: "'빠르다'는 시간이 적게 걸린다는 뜻이므로 '신속하다'가 가장 가깝습니다.",
      ),
      1 => (
        question: "'높다'와 반대되는 뜻을 가진 단어는?",
        choices: ['깊다', '낮다', '넓다', '길다'],
        answer: 1,
        explanation: "'높다'의 반대 의미는 '낮다'입니다.",
      ),
      2 => (
        question: '의사 : 병원 = 교사 : ?',
        choices: ['학교', '시장', '공항', '공장'],
        answer: 0,
        explanation: '의사가 병원에서 일하듯 교사는 학교에서 일합니다.',
      ),
      3 => (
        question: '문장에 가장 알맞은 단어를 고르세요. 그는 약속을 ___ 지켰다.',
        choices: ['성실히', '흐리게', '낮게', '멀리'],
        answer: 0,
        explanation: '약속을 지키는 태도에는 성실히가 가장 자연스럽습니다.',
      ),
      _ => (
        question: '다음 중 나머지와 성격이 다른 것은?',
        choices: ['사과', '배', '바나나', '의자'],
        answer: 3,
        explanation: '사과, 배, 바나나는 과일이고 의자는 물건입니다.',
      ),
    };
    return TestItem(
      id: 'LR-GEN-${(index + 1).toString().padLeft(3, '0')}',
      domain: 'verbal',
      type: type,
      question: data.question,
      choices: data.choices,
      answerIndex: data.answer,
      difficulty: difficulty,
      discrimination: discriminationFor(difficulty),
      guessing: 0.25,
      estimatedTime: estimatedSecondsFor(difficulty),
      explanation: data.explanation,
    );
  }
}
