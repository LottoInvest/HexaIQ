import 'dart:math';

import '../../../core/domain/intelligence_domain.dart';
import 'domain_template_generator.dart';

class LogicalGenerator extends TemplateQuestionGenerator {
  LogicalGenerator()
    : super(
        domain: IntelligenceDomain.logic,
        typeCodes: codes,
        builders: _builders,
      );

  static const List<String> codes = [
    'LG01',
    'LG02',
    'LG03',
    'LG04',
    'LG05',
    'LG06',
    'LG07',
    'LG08',
    'LG09',
    'LG10',
  ];

  static final Map<String, DomainTemplateBuilder> _builders = {
    'LG01': _proposition,
    'LG02': _condition,
    'LG03': _order,
    'LG04': _inclusion,
    'LG05': _set,
    'LG06': _argument,
    'LG07': _induction,
    'LG08': _deduction,
    'LG09': _cases,
    'LG10': _rule,
  };
}

typedef LogicGenerator = LogicalGenerator;

DomainQuestionTemplate _proposition(Random rng, int variant, int level) {
  const items = [
    ('모든 정사각형은 네 변을 가진다. 이 도형은 정사각형이다.', '이 도형은 네 변을 가진다'),
    ('어떤 새도 물고기가 아니다. 참새는 새이다.', '참새는 물고기가 아니다'),
    ('모든 짝수는 2로 나누어진다. 8은 짝수이다.', '8은 2로 나누어진다'),
    ('빨간 토큰은 1점을 얻는다. 이 토큰은 빨간색이다.', '이 토큰은 1점을 얻는다'),
  ];
  final item = items[variant % items.length];
  return _logicTemplate(
    question: '${item.$1} 반드시 참인 것은?',
    answer: item.$2,
    distractors: const ['반대가 반드시 참이다', '아무 결론도 없다', '가끔만 참이다'],
    ruleName: '명제',
    explanation: '주어진 두 문장을 함께 적용하면 ${item.$2}가 결론입니다.',
    factors: const ['proposition'],
  );
}

DomainQuestionTemplate _condition(Random rng, int variant, int level) {
  const items = [
    ('비가 오면 경기가 연기된다. 비가 온다.', '경기가 연기된다'),
    ('카드가 파란색이면 2점이다. 이 카드는 파란색이다.', '이 카드는 2점이다'),
    ('스위치가 켜지면 전등이 켜진다. 스위치가 켜졌다.', '전등이 켜진다'),
    ('민아가 공부하면 필기를 한다. 민아가 공부한다.', '민아는 필기를 한다'),
  ];
  final item = items[variant % items.length];
  return _logicTemplate(
    question: '${item.$1} 따라오는 결론은?',
    answer: item.$2,
    distractors: const ['조건이 거짓이다', '결과는 일어날 수 없다', '다른 규칙이 적용된다'],
    ruleName: '조건',
    explanation: '조건이 충족되었으므로 결과인 ${item.$2}가 따라옵니다.',
    factors: const ['condition'],
  );
}

DomainQuestionTemplate _order(Random rng, int variant, int level) {
  const items = [
    ('철수는 영희보다 키가 크다. 영희는 민수보다 크다.', '철수', ['영희', '민수', '알 수 없음']),
    ('A는 B보다 앞에 있다. B는 C보다 앞에 있다.', 'A B C', ['C B A', 'B A C', 'A C B']),
    (
      '빨강은 파랑의 왼쪽에 있다. 초록은 파랑의 오른쪽에 있다.',
      '빨강 파랑 초록',
      ['초록 파랑 빨강', '파랑 빨강 초록', '빨강 초록 파랑'],
    ),
    ('민수는 지수보다 빠르다. 지수는 현우보다 빠르다.', '민수', ['지수', '현우', '알 수 없음']),
  ];
  final item = items[variant % items.length];
  return _logicTemplate(
    question: '순서 관계를 종합하세요: ${item.$1}',
    answer: item.$2,
    distractors: item.$3,
    ruleName: '순서',
    explanation: '두 관계를 연결하면 ${item.$2}가 가장 알맞습니다.',
    factors: const ['order'],
  );
}

DomainQuestionTemplate _inclusion(Random rng, int variant, int level) {
  const items = [
    ('모든 장미는 꽃이다. 어떤 꽃은 노란색이다.', '장미는 꽃에 속한다'),
    ('모든 고양이는 동물이다. 어떤 동물도 돌이 아니다.', '고양이는 돌이 아니다'),
    ('모든 정육면체는 입체이다. 어떤 입체는 무겁다.', '정육면체는 입체이다'),
    ('모든 연필은 도구이다. 어떤 도구는 빨간색이다.', '연필은 도구에 속한다'),
  ];
  final item = items[variant % items.length];
  return _logicTemplate(
    question: '다음 포함 관계에서 논리적으로 맞는 말은? ${item.$1}',
    answer: item.$2,
    distractors: const ['두 집합은 완전히 같다', '두 번째 집합은 모두 첫 번째 집합이다', '항상 결론이 없다'],
    ruleName: '포함 관계',
    explanation: '집합의 포함 관계를 따르면 ${item.$2}가 맞습니다.',
    factors: const ['inclusion'],
  );
}

DomainQuestionTemplate _set(Random rng, int variant, int level) {
  const items = [
    ('A={1,2,3}, B={3,4}', '3'),
    ('A={빨강,파랑}, B={파랑,초록}', '파랑'),
    ('A={고양이,강아지}, B={강아지,새}', '강아지'),
    ('A={2,4,6}, B={1,4,7}', '4'),
  ];
  final item = items[variant % items.length];
  return _logicTemplate(
    question: '두 집합에 공통으로 들어 있는 것은? ${item.$1}',
    answer: item.$2,
    distractors: const ['없음', '모두', '첫 항목만'],
    ruleName: '집합',
    explanation: '${item.$2}는 두 집합에 모두 들어 있습니다.',
    factors: const ['set'],
  );
}

DomainQuestionTemplate _argument(Random rng, int variant, int level) {
  const items = [
    ('다리가 젖은 이유는 비가 왔기 때문이다. 그런데 스프링클러도 켜져 있었다.', '다른 원인이 가능하다'),
    ('모든 샘플이 통과했다. 그래서 오늘 기계는 정상이다.', '증거가 주장을 뒷받침한다'),
    ('그는 키가 크다. 그래서 반드시 농구 선수다.', '결론이 지나치게 강하다'),
    ('건전지가 다 되어서 시계가 멈췄다.', '원인과 결과가 자연스럽다'),
  ];
  final item = items[variant % items.length];
  return _logicTemplate(
    question: '다음 논증을 평가하세요: ${item.$1}',
    answer: item.$2,
    distractors: const ['반대를 증명한다', '주장이 없다', '정의만 말한다'],
    ruleName: '논증',
    explanation: item.$2,
    factors: const ['argument'],
  );
}

DomainQuestionTemplate _induction(Random rng, int variant, int level) {
  const items = [
    ('2, 4, 6, 8', '짝수가 2씩 증가한다'),
    ('가, 다, 마, 사', '글자가 하나씩 건너뛴다'),
    ('1, 4, 9, 16', '제곱수이다'),
    ('3, 6, 12, 24', '두 배씩 증가한다'),
  ];
  final item = items[variant % items.length];
  return _logicTemplate(
    question: '예시를 가장 잘 설명하는 규칙은? ${item.$1}',
    answer: item.$2,
    distractors: const ['무작위이다', '감소한다', '항목이 매번 반복된다'],
    ruleName: '귀납',
    explanation: '제시된 예시는 ${item.$2}는 규칙으로 설명됩니다.',
    factors: const ['induction'],
  );
}

DomainQuestionTemplate _deduction(Random rng, int variant, int level) {
  const items = [
    ('모든 A는 B이다. 모든 B는 C이다.', '모든 A는 C이다'),
    ('모든 학생은 명찰을 단다. 지수는 학생이다.', '지수는 명찰을 단다'),
    ('금속은 전기를 통한다. 구리는 금속이다.', '구리는 전기를 통한다'),
    ('포유류는 새끼에게 젖을 먹인다. 고래는 포유류이다.', '고래는 새끼에게 젖을 먹인다'),
  ];
  final item = items[variant % items.length];
  return _logicTemplate(
    question: '주어진 전제에서 연역적으로 따라오는 결론은? ${item.$1}',
    answer: item.$2,
    distractors: const ['모든 C는 A이다', 'A와 C는 관계없다', '전제가 항상 거짓이다'],
    ruleName: '연역',
    explanation: '상위 관계를 차례로 적용하면 ${item.$2}가 됩니다.',
    factors: const ['deduction'],
  );
}

DomainQuestionTemplate _cases(Random rng, int variant, int level) {
  final shirts = 2 + variant % 2;
  final pants = 3;
  final answer = shirts * pants;
  return _logicTemplate(
    question: '상의 $shirts벌과 하의 $pants벌을 조합하면 몇 가지 옷차림이 가능한가요?',
    answer: '$answer',
    distractors: ['${answer + 1}', '${shirts + pants}', '${answer - 1}'],
    ruleName: '경우의 수',
    explanation: '$shirts가지와 $pants가지를 곱하면 $answer가지입니다.',
    factors: const ['cases'],
  );
}

DomainQuestionTemplate _rule(Random rng, int variant, int level) {
  final x = 2 + variant % 5;
  final answer = x * 2 + 1;
  return _logicTemplate(
    question: '규칙: 출력 = 입력 x 2 + 1. 입력이 $x이면 출력은?',
    answer: '$answer',
    distractors: ['${x * 2}', '${answer + 2}', '${answer - 2}'],
    ruleName: '규칙 적용',
    explanation: '$x x 2 + 1 = $answer입니다.',
    factors: const ['rule'],
  );
}

DomainQuestionTemplate _logicTemplate({
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
    hint: '문장을 간단한 규칙이나 관계로 바꾸어 생각해 보세요.',
    explanation: explanation,
    factors: factors,
  );
}
