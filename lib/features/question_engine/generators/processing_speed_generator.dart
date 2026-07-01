import 'dart:math';

import '../../../core/domain/intelligence_domain.dart';
import 'domain_template_generator.dart';

class ProcessingSpeedGenerator extends TemplateQuestionGenerator {
  ProcessingSpeedGenerator()
    : super(
        domain: IntelligenceDomain.processing,
        typeCodes: codes,
        builders: _builders,
      );

  static const List<String> codes = [
    'PS01',
    'PS02',
    'PS03',
    'PS04',
    'PS05',
    'PS06',
    'PS07',
    'PS08',
    'PS09',
    'PS10',
  ];

  static final Map<String, DomainTemplateBuilder> _builders = {
    'PS01': _symbolSearch,
    'PS02': _numberSearch,
    'PS03': _letterSearch,
    'PS04': _quickCompare,
    'PS05': _visualSearch,
    'PS06': _speedMatch,
    'PS07': _speedJudgment,
    'PS08': _concentration,
    'PS09': _classification,
    'PS10': _selection,
  };
}

typedef ProcessingGenerator = ProcessingSpeedGenerator;

DomainQuestionTemplate _speedTemplate({
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
    hint: '왼쪽에서 오른쪽으로 빠르게 훑으며 조건에 맞는 항목만 확인하세요.',
    explanation: explanation,
    timeLimit: const Duration(seconds: 12),
    reactionScore: 1,
    estimatedTimeSec: 12,
    factors: factors,
  );
}

DomainQuestionTemplate _symbolSearch(Random rng, int variant, int level) {
  const rows = ['▲ # ■ # ◆', '@ ▲ ■ ◆ @', '◇ □ ◇ ◇', '○ * △ ▽ *'];
  final row = rows[variant % rows.length];
  final target = variant.isEven ? '#' : '@';
  final answer = '${target.allMatches(row).length}';
  return _speedTemplate(
    question: '다음 줄에서 "$target" 기호는 몇 개인가요? $row',
    answer: answer,
    distractors: const ['0', '1', '3'],
    ruleName: '기호 찾기',
    explanation: '목표 기호 "$target"는 $answer번 나타납니다.',
    factors: const ['symbol_search'],
  );
}

DomainQuestionTemplate _numberSearch(Random rng, int variant, int level) {
  const items = [
    ('44 44 45 44', '45'),
    ('92 92 92 29', '29'),
    ('13 31 13 13', '31'),
    ('80 80 08 80', '08'),
  ];
  final item = items[variant % items.length];
  return _speedTemplate(
    question: '다음 숫자 중 다른 하나를 가능한 빨리 찾으세요: ${item.$1}',
    answer: item.$2,
    distractors: const ['44', '92', '13'],
    ruleName: '숫자 찾기',
    explanation: '${item.$2}만 반복되는 숫자와 다릅니다.',
    factors: const ['number_search'],
  );
}

DomainQuestionTemplate _letterSearch(Random rng, int variant, int level) {
  const rows = ['가 나 다 라 나', '마 바 마 사 아', '카 타 파 카 하', '라 다 나 다 가'];
  final row = rows[variant % rows.length];
  final target = variant.isEven ? '나' : '다';
  final answer = '${target.allMatches(row).length}';
  return _speedTemplate(
    question: '다음 줄에서 "$target" 글자는 몇 개인가요? $row',
    answer: answer,
    distractors: const ['0', '1', '3'],
    ruleName: '문자 찾기',
    explanation: '"$target"는 $answer번 나타납니다.',
    factors: const ['letter_search'],
  );
}

DomainQuestionTemplate _quickCompare(Random rng, int variant, int level) {
  const items = [
    ('7429', '7429', '같음'),
    ('631', '613', '다름'),
    ('가나다', '가나다', '같음'),
    ('마바사', '마사바', '다름'),
  ];
  final item = items[variant % items.length];
  return _speedTemplate(
    question: '두 항목을 빠르게 비교하세요: ${item.$1} / ${item.$2}',
    answer: item.$3,
    distractors: const ['비슷함', '알 수 없음', '거꾸로'],
    ruleName: '빠른 비교',
    explanation: '두 항목은 ${item.$3}입니다.',
    factors: const ['compare'],
  );
}

DomainQuestionTemplate _visualSearch(Random rng, int variant, int level) {
  const items = [
    ('○ ○ ○ ◇ ○', '◇'),
    ('ㅣ ㅣ ㅏ ㅣ ㅣ', 'ㅏ'),
    ('5 5 S 5 5', 'S'),
    ('Z Z 2 Z Z', '2'),
  ];
  final item = items[variant % items.length];
  return _speedTemplate(
    question: '시각적으로 다른 항목을 찾으세요: ${item.$1}',
    answer: item.$2,
    distractors: const ['○', 'ㅣ', '5'],
    ruleName: '시각 탐색',
    explanation: '${item.$2}만 주변 항목과 모양이 다릅니다.',
    factors: const ['visual_search'],
  );
}

DomainQuestionTemplate _speedMatch(Random rng, int variant, int level) {
  const items = [
    ('규칙: A=1, B=2. B는?', '2'),
    ('규칙: X=빨강, Y=파랑. X는?', '빨강'),
    ('규칙: 원=○, 사각형=□. 사각형은?', '□'),
    ('규칙: 위=▲, 아래=▼. 아래는?', '▼'),
  ];
  final item = items[variant % items.length];
  return _speedTemplate(
    question: item.$1,
    answer: item.$2,
    distractors: const ['1', '파랑', '○'],
    ruleName: '속도 매칭',
    explanation: '제시된 대응 규칙을 적용하면 ${item.$2}입니다.',
    factors: const ['speed_match'],
  );
}

DomainQuestionTemplate _speedJudgment(Random rng, int variant, int level) {
  const items = [
    ('신호가 GO이면 초록을 고른다. 신호: GO', '초록'),
    ('화살표가 ◀이면 왼쪽을 고른다. 신호: ◀', '왼쪽'),
    ('두 항목이 같으면 예를 고른다. 항목: AA/AA', '예'),
    ('두 항목이 다르면 아니오를 고른다. 항목: AB/AC', '아니오'),
  ];
  final item = items[variant % items.length];
  return _speedTemplate(
    question: item.$1,
    answer: item.$2,
    distractors: const ['빨강', '오른쪽', '기다림'],
    ruleName: '속도 판단',
    explanation: '신호와 규칙이 맞는 선택은 ${item.$2}입니다.',
    factors: const ['speed_judgment'],
  );
}

DomainQuestionTemplate _concentration(Random rng, int variant, int level) {
  const items = [
    ('가 가 가 나 가 가', '나'),
    ('3 3 8 3 3 3', '8'),
    ('□ □ □ ■ □', '■'),
    ('+ + - + +', '-'),
  ];
  final item = items[variant % items.length];
  return _speedTemplate(
    question: '집중해서 한 번만 나타나는 항목을 찾으세요: ${item.$1}',
    answer: item.$2,
    distractors: const ['가', '3', '□'],
    ruleName: '집중력',
    explanation: '${item.$2}만 한 번 나타납니다.',
    factors: const ['concentration'],
  );
}

DomainQuestionTemplate _classification(Random rng, int variant, int level) {
  const items = [
    ('사과 배 포도 7', '7'),
    ('1 3 5 나', '나'),
    ('▲ ■ ◆ 책', '책'),
    ('빨강 파랑 초록 9', '9'),
  ];
  final item = items[variant % items.length];
  return _speedTemplate(
    question: '분류가 다른 하나를 빠르게 고르세요: ${item.$1}',
    answer: item.$2,
    distractors: const ['사과', '1', '▲'],
    ruleName: '빠른 분류',
    explanation: '${item.$2}만 같은 범주에 속하지 않습니다.',
    factors: const ['classification'],
  );
}

DomainQuestionTemplate _selection(Random rng, int variant, int level) {
  const items = [
    ('조건: 짝수 선택. 3 5 8 9', '8'),
    ('조건: 도형 선택. 가 나 ▲ 다', '▲'),
    ('조건: 색 선택. 책 파랑 연필 컵', '파랑'),
    ('조건: 가장 작은 수 선택. 7 2 5 9', '2'),
  ];
  final item = items[variant % items.length];
  return _speedTemplate(
    question: item.$1,
    answer: item.$2,
    distractors: const ['3', '가', '책'],
    ruleName: '선택',
    explanation: '조건에 맞는 항목은 ${item.$2}입니다.',
    factors: const ['selection'],
  );
}
