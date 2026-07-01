import 'dart:math';

import '../../../core/domain/intelligence_domain.dart';
import 'domain_template_generator.dart';

class MemoryGenerator extends TemplateQuestionGenerator {
  MemoryGenerator()
    : super(
        domain: IntelligenceDomain.memory,
        typeCodes: codes,
        builders: _builders,
      );

  static const List<String> codes = [
    'MR01',
    'MR02',
    'MR03',
    'MR04',
    'MR05',
    'MR06',
    'MR07',
    'MR08',
    'MR09',
    'MR10',
  ];

  static final Map<String, DomainTemplateBuilder> _builders = {
    'MR01': _digitMemory,
    'MR02': _orderMemory,
    'MR03': _positionMemory,
    'MR04': _letterMemory,
    'MR05': _patternMemory,
    'MR06': _shortTermMemory,
    'MR07': _reverseMemory,
    'MR08': _groupMemory,
    'MR09': _sequenceMemory,
    'MR10': _mixedMemory,
  };
}

DomainQuestionTemplate _memoryTemplate({
  required String prompt,
  required String question,
  required String answer,
  required List<String> distractors,
  required String ruleName,
  required String explanation,
  required List<String> factors,
}) {
  return DomainQuestionTemplate(
    questionText: question,
    answer: answer,
    distractors: distractors,
    ruleName: ruleName,
    hint: '처음 제시된 항목의 순서와 위치를 떠올려 보세요.',
    explanation: explanation,
    variables: {'memoryPrompt': prompt, 'memoryDurationMs': 3000},
    stimulus: prompt,
    stimulusDuration: const Duration(seconds: 3),
    requiresMemoryPhase: true,
    factors: factors,
  );
}

DomainQuestionTemplate _digitMemory(Random rng, int variant, int level) {
  final digits = [2 + variant % 7, 5, 8, 1 + variant % 8].join(' ');
  final answer = digits.split(' ')[2];
  return _memoryTemplate(
    prompt: digits,
    question: '방금 본 숫자열에서 세 번째 숫자는?',
    answer: answer,
    distractors: ['${int.parse(answer) + 1}', '${int.parse(answer) - 1}', '0'],
    ruleName: '숫자 기억',
    explanation: '제시된 숫자열은 $digits였고, 세 번째 숫자는 $answer입니다.',
    factors: const ['digit_memory'],
  );
}

DomainQuestionTemplate _orderMemory(Random rng, int variant, int level) {
  const items = [
    (['빨강', '파랑', '초록'], '파랑'),
    (['컵', '책', '열쇠'], '책'),
    (['해', '달', '별'], '달'),
    (['가', '다', '나'], '다'),
  ];
  final item = items[variant % items.length];
  return _memoryTemplate(
    prompt: item.$1.join(' -> '),
    question: '두 번째로 나온 항목은?',
    answer: item.$2,
    distractors: item.$1.where((value) => value != item.$2).toList()..add('없음'),
    ruleName: '순서 기억',
    explanation: '${item.$1.join(', ')} 중 두 번째 항목은 ${item.$2}입니다.',
    factors: const ['order_memory'],
  );
}

DomainQuestionTemplate _positionMemory(Random rng, int variant, int level) {
  const rows = ['가 나 다', '라 마 바', '사 아 자'];
  final center = variant.isEven;
  final answer = center ? '마' : '자';
  return _memoryTemplate(
    prompt: rows.join('\n'),
    question: center ? '가운데 칸에 있던 글자는?' : '오른쪽 아래 칸에 있던 글자는?',
    answer: answer,
    distractors: const ['가', '나', '라'],
    ruleName: '위치 기억',
    explanation: '제시된 3x3 배열에서 해당 위치의 글자는 $answer입니다.',
    factors: const ['position_memory'],
  );
}

DomainQuestionTemplate _letterMemory(Random rng, int variant, int level) {
  const strings = [
    ('ㅋ ㅁ ㄹ ㅌ', 'ㄹ'),
    ('ㅂ ㅍ ㄹ ㅋ', 'ㄹ'),
    ('ㅅ ㅇ ㄴ ㅔ', 'ㄴ'),
    ('ㅍ ㅂ ㅊ ㄷ', 'ㅊ'),
  ];
  final item = strings[variant % strings.length];
  return _memoryTemplate(
    prompt: item.$1,
    question: '세 번째로 나온 글자는?',
    answer: item.$2,
    distractors: const ['ㅇ', 'ㅂ', 'ㅌ'],
    ruleName: '문자 기억',
    explanation: '${item.$1}에서 세 번째 글자는 ${item.$2}입니다.',
    factors: const ['letter_memory'],
  );
}

DomainQuestionTemplate _patternMemory(Random rng, int variant, int level) {
  const items = [
    ('가 나 가 다', '가 나 가 다'),
    ('■ □ ■', '■ □ ■'),
    ('위 오른 아래', '위 오른 아래'),
    ('검정 하양 검정', '검정 하양 검정'),
  ];
  final item = items[variant % items.length];
  return _memoryTemplate(
    prompt: item.$1,
    question: '숨겨진 패턴과 정확히 같은 것은?',
    answer: item.$2,
    distractors: [
      '${item.$2} 가',
      '가 ${item.$2}',
      item.$2.split(' ').reversed.join(' '),
    ],
    ruleName: '패턴 기억',
    explanation: '숨겨진 패턴은 ${item.$2}였습니다.',
    factors: const ['pattern_memory'],
  );
}

DomainQuestionTemplate _shortTermMemory(Random rng, int variant, int level) {
  const items = [
    ('강 - 전등 - 동전', '동전'),
    ('책상 - 사과 - 기차', '기차'),
    ('돌 - 종이 - 음악', '음악'),
    ('초록 - 의자 - 연필', '연필'),
  ];
  final item = items[variant % items.length];
  return _memoryTemplate(
    prompt: item.$1,
    question: '마지막 항목은 무엇이었나요?',
    answer: item.$2,
    distractors: const ['강', '책상', '돌'],
    ruleName: '단기 기억',
    explanation: '목록의 마지막 항목은 ${item.$2}입니다.',
    factors: const ['short_term'],
  );
}

DomainQuestionTemplate _reverseMemory(Random rng, int variant, int level) {
  const items = [
    ('2 7 4', '4 7 2'),
    ('가 다 바', '바 다 가'),
    ('9 1 5', '5 1 9'),
    ('ㅋ ㅍ ㅁ', 'ㅁ ㅍ ㅋ'),
  ];
  final item = items[variant % items.length];
  return _memoryTemplate(
    prompt: item.$1,
    question: '제시된 순서를 거꾸로 배열한 것은?',
    answer: item.$2,
    distractors: [
      item.$1,
      '${item.$2} X',
      item.$2.split(' ').take(2).join(' '),
    ],
    ruleName: '역순 기억',
    explanation: '${item.$1}을 거꾸로 쓰면 ${item.$2}입니다.',
    factors: const ['reverse_memory'],
  );
}

DomainQuestionTemplate _groupMemory(Random rng, int variant, int level) {
  const items = [
    ('고양이 강아지 | 빨강 파랑', '동물 2개와 색 2개'),
    ('연필 책 | 차 우유', '물건 2개와 음료 2개'),
    ('가 나 | 3 4', '글자 2개와 숫자 2개'),
    ('해 달 | 동 서', '하늘 단어 2개와 방향 2개'),
  ];
  final item = items[variant % items.length];
  return _memoryTemplate(
    prompt: item.$1,
    question: '숨겨진 항목의 묶음으로 알맞은 것은?',
    answer: item.$2,
    distractors: const ['숫자 4개', '색 3개와 동물 1개', '모두 방향'],
    ruleName: '묶음 기억',
    explanation: '숨겨진 묶음은 ${item.$2}였습니다.',
    factors: const ['group_memory'],
  );
}

DomainQuestionTemplate _sequenceMemory(Random rng, int variant, int level) {
  const items = [
    ('1 3 5 7', '7'),
    ('가 다 마 사', '사'),
    ('2 4 8 16', '16'),
    ('가 나 라 사', '사'),
  ];
  final item = items[variant % items.length];
  return _memoryTemplate(
    prompt: item.$1,
    question: '숨겨진 순서의 마지막 항목은?',
    answer: item.$2,
    distractors: const ['1', '3', '5'],
    ruleName: '시퀀스 기억',
    explanation: '제시된 순서의 마지막 항목은 ${item.$2}입니다.',
    factors: const ['sequence_memory'],
  );
}

DomainQuestionTemplate _mixedMemory(Random rng, int variant, int level) {
  const items = [
    ('가 7 파랑', '7'),
    ('마 4 별', '별'),
    ('초록 9 카', '초록'),
    ('2 구름 라', '라'),
  ];
  final item = items[variant % items.length];
  return _memoryTemplate(
    prompt: item.$1,
    question: '요청한 숨겨진 항목과 일치하는 것은?',
    answer: item.$2,
    distractors: const ['가', '파랑', '구름'],
    ruleName: '혼합 기억',
    explanation: '${item.$1}에서 목표 항목은 ${item.$2}였습니다.',
    factors: const ['mixed_memory'],
  );
}
