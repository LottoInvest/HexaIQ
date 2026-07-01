import 'dart:math';

import '../../../core/domain/intelligence_domain.dart';
import 'domain_template_generator.dart';

class VerbalGenerator extends TemplateQuestionGenerator {
  VerbalGenerator()
    : super(
        domain: IntelligenceDomain.verbal,
        typeCodes: codes,
        builders: _builders,
      );

  static const List<String> codes = [
    'LR01',
    'LR02',
    'LR03',
    'LR04',
    'LR05',
    'LR06',
    'LR07',
    'LR08',
    'LR09',
    'LR10',
  ];

  static final Map<String, DomainTemplateBuilder> _builders = {
    'LR01': _synonym,
    'LR02': _antonym,
    'LR03': _relation,
    'LR04': _analogy,
    'LR05': _sentenceCompletion,
    'LR06': _classification,
    'LR07': _proverb,
    'LR08': _vocabulary,
    'LR09': _context,
    'LR10': _wordOrder,
  };
}

DomainQuestionTemplate _synonym(Random rng, int variant, int level) {
  const items = [
    ('빠르다', '신속하다', ['느리다', '조용하다', '무겁다']),
    ('정확하다', '틀림없다', ['흐릿하다', '임의롭다', '넓다']),
    ('온화하다', '부드럽다', ['거칠다', '날카롭다', '시끄럽다']),
    ('분명하다', '뚜렷하다', ['숨겨지다', '복잡하다', '멀다']),
  ];
  final item = items[variant % items.length];
  return DomainQuestionTemplate(
    questionText: "다음 중 '${item.$1}'와 가장 가까운 뜻을 가진 단어는?",
    answer: item.$2,
    distractors: item.$3,
    ruleName: '유의어',
    hint: '문장 속에 넣었을 때 뜻이 가장 비슷한 단어를 찾아보세요.',
    explanation: "'${item.$1}'와 '${item.$2}'는 뜻이 비슷합니다.",
    factors: const ['synonym'],
  );
}

DomainQuestionTemplate _antonym(Random rng, int variant, int level) {
  const items = [
    ('넓다', '좁다', ['크다', '깊다', '길다']),
    ('겸손하다', '거만하다', ['차분하다', '친절하다', '조용하다']),
    ('부족하다', '충분하다', ['드물다', '작다', '얇다']),
    ('낡다', '새롭다', ['오래되다', '이르다', '익숙하다']),
  ];
  final item = items[variant % items.length];
  return DomainQuestionTemplate(
    questionText: "다음 중 '${item.$1}'와 반대 뜻을 가진 단어는?",
    answer: item.$2,
    distractors: item.$3,
    ruleName: '반의어',
    hint: '뜻의 방향이 반대로 바뀌는 단어를 찾아보세요.',
    explanation: "'${item.$2}'는 '${item.$1}'의 반대 뜻입니다.",
    factors: const ['antonym'],
  );
}

DomainQuestionTemplate _relation(Random rng, int variant, int level) {
  const items = [
    ('책', '읽다', '칼', '자르다', ['쓰다', '접다', '칠하다']),
    ('씨앗', '식물', '알', '새', ['돌', '구름', '강']),
    ('의사', '병원', '교사', '학교', ['시장', '공항', '은행']),
    ('화가', '붓', '작가', '펜', ['자', '모자', '숟가락']),
  ];
  final item = items[variant % items.length];
  return DomainQuestionTemplate(
    questionText: '${item.$1} : ${item.$2} = ${item.$3} : ?',
    answer: item.$4,
    distractors: item.$5,
    ruleName: '단어 관계',
    hint: '첫 번째 짝이 행동, 장소, 결과, 도구 중 어떤 관계인지 살펴보세요.',
    explanation: '${item.$1}:${item.$2}와 ${item.$3}:${item.$4}는 같은 관계입니다.',
    factors: const ['relation'],
  );
}

DomainQuestionTemplate _analogy(Random rng, int variant, int level) {
  const items = [
    ('손', '장갑', '발', '신발', ['모자', '반지', '외투']),
    ('새', '둥지', '벌', '벌집', ['호수', '책상', '길']),
    ('요리사', '주방', '조종사', '조종석', ['정원', '도서관', '화실']),
    ('연필', '쓰다', '가위', '자르다', ['듣다', '자다', '들다']),
  ];
  final item = items[variant % items.length];
  return DomainQuestionTemplate(
    questionText: '${item.$1} : ${item.$2} = ${item.$3} : ?',
    answer: item.$4,
    distractors: item.$5,
    ruleName: '비유',
    hint: '앞의 두 단어 관계를 짧은 문장으로 바꾼 뒤 그대로 적용해 보세요.',
    explanation: '${item.$1}은 ${item.$2}와 관련되고, ${item.$3}은 ${item.$4}와 관련됩니다.',
    factors: const ['analogy'],
  );
}

DomainQuestionTemplate _sentenceCompletion(Random rng, int variant, int level) {
  const items = [
    ('방이 어두워서 민아는 __을 켰다.', '전등', ['강', '신발', '구름']),
    ('길이 미끄러워서 운전자는 __ 움직였다.', '천천히', ['크게', '매주', '달콤하게']),
    ('문제는 어려웠지만 준호는 __로 풀어냈다.', '끈기', ['소음', '날씨', '색깔']),
    ('긴 달리기 후에 선수들은 __이 필요했다.', '휴식', ['페인트', '금속', '종이']),
  ];
  final item = items[variant % items.length];
  return DomainQuestionTemplate(
    questionText: '문맥에 맞게 빈칸을 채우세요: ${item.$1}',
    answer: item.$2,
    distractors: item.$3,
    ruleName: '문장 완성',
    hint: '빈칸 앞뒤의 상황을 함께 읽어 보세요.',
    explanation: "문장 흐름상 '${item.$2}'가 가장 자연스럽습니다.",
    factors: const ['sentence'],
  );
}

DomainQuestionTemplate _classification(Random rng, int variant, int level) {
  const items = [
    (['소나무', '참나무', '단풍나무'], '나무', ['물고기', '도구', '계절']),
    (['원', '사각형', '삼각형'], '도형', ['과일', '소리', '직업']),
    (['바이올린', '피아노', '북'], '악기', ['행성', '음료', '천']),
    (['빨강', '파랑', '초록'], '색', ['동물', '도시', '숫자']),
  ];
  final item = items[variant % items.length];
  return DomainQuestionTemplate(
    questionText: '다음 단어들이 공통으로 속하는 범주는? ${item.$1.join(', ')}',
    answer: item.$2,
    distractors: item.$3,
    ruleName: '분류',
    hint: '세 단어를 모두 포함하는 가장 넓은 이름을 찾아보세요.',
    explanation: '${item.$1.join(', ')}은 모두 ${item.$2}에 속합니다.',
    factors: const ['classification'],
  );
}

DomainQuestionTemplate _proverb(Random rng, int variant, int level) {
  const items = [
    (
      '가는 말이 고와야 오는 말이 곱다.',
      '상대에게 좋게 말해야 좋은 말을 듣는다',
      ['운이 전부다', '빠를수록 좋다', '침묵은 동의다'],
    ),
    (
      '돌다리도 두들겨 보고 건너라.',
      '조심해서 확인한 뒤 행동하라',
      ['높이 뛰어라', '위험을 모두 피하라', '모든 제안을 믿어라'],
    ),
    (
      '호미로 막을 것을 가래로 막는다.',
      '작은 문제를 일찍 해결해야 한다',
      ['수를 세어라', '천천히 꿰매라', '도움을 기다려라'],
    ),
    ('백지장도 맞들면 낫다.', '함께하면 일이 쉬워진다', ['종이는 무겁다', '혼자 일하라', '도구를 줄여라']),
  ];
  final item = items[variant % items.length];
  return DomainQuestionTemplate(
    questionText: "속담 '${item.$1}'의 뜻으로 알맞은 것은?",
    answer: item.$2,
    distractors: item.$3,
    ruleName: '속담',
    hint: '표현 그대로보다 속담이 주는 교훈을 생각해 보세요.',
    explanation: "이 속담은 '${item.$2}'라는 뜻입니다.",
    factors: const ['proverb'],
  );
}

DomainQuestionTemplate _vocabulary(Random rng, int variant, int level) {
  const items = [
    ('단서를 보고 답을 추론했다.', '미루어 생각했다', ['지웠다', '늦췄다', '꾸몄다']),
    ('새로운 사실이 나와 계획을 수정했다.', '고쳤다', ['숨겼다', '칭찬했다', '무시했다']),
    ('대답이 모호해서 다시 물었다.', '분명하지 않았다', ['정확했다', '빨랐다', '용감했다']),
    ('유리컵이 연약해서 쉽게 금이 갔다.', '깨지기 쉬웠다', ['무거웠다', '비어 있었다', '평범했다']),
  ];
  final item = items[variant % items.length];
  return DomainQuestionTemplate(
    questionText: '문장 속 밑줄 친 말의 뜻으로 알맞은 것은? ${item.$1}',
    answer: item.$2,
    distractors: item.$3,
    ruleName: '어휘 추론',
    hint: '앞뒤 단어가 어떤 상황을 설명하는지 살펴보세요.',
    explanation: "문맥상 해당 표현은 '${item.$2}'라는 뜻입니다.",
    factors: const ['vocabulary'],
  );
}

DomainQuestionTemplate _context(Random rng, int variant, int level) {
  const items = [
    (
      '하늘이 어두워지고 사람들이 우산을 펼쳤다.',
      '비가 올 가능성이 높다',
      ['방이 덥다', '경기가 끝났다', '기차가 도착했다'],
    ),
    (
      '지수는 지도를 두 번 확인하고 배낭끈을 조였다.',
      '이동을 준비하고 있다',
      ['요리하고 있다', '잠을 자고 있다', '그림을 그리고 있다'],
    ),
    ('막이 내려가자 관객들이 박수를 쳤다.', '공연이 끝났다', ['수업이 시작됐다', '폭풍이 시작됐다', '식사가 나왔다']),
    (
      '아기가 자고 있어서 아이는 작은 목소리로 말했다.',
      '조용히 하려 했다',
      ['화가 났다', '아기가 노래했다', '방이 비어 있었다'],
    ),
  ];
  final item = items[variant % items.length];
  return DomainQuestionTemplate(
    questionText: '다음 상황에서 추론할 수 있는 것은? ${item.$1}',
    answer: item.$2,
    distractors: item.$3,
    ruleName: '문맥 이해',
    hint: '문장 속 단서로 뒷받침되는 내용만 고르세요.',
    explanation: '제시된 단서들은 ${item.$2}는 해석을 뒷받침합니다.',
    factors: const ['context'],
  );
}

DomainQuestionTemplate _wordOrder(Random rng, int variant, int level) {
  const items = [
    (
      '민아 / 매일 / 걷는다 / 아침에',
      '민아는 매일 아침에 걷는다',
      ['매일 걷는다 민아 아침에', '아침에 민아 매일 걷는다', '걷는다 아침에 매일 민아'],
    ),
    (
      '도서관에서 / 조용히 / 읽는다 / 준호가',
      '준호가 도서관에서 조용히 읽는다',
      ['조용히 도서관에서 준호가 읽는다', '읽는다 준호가 도서관에서 조용히', '도서관에서 읽는다 조용히 준호가'],
    ),
    (
      '새로운 / 규칙을 / 찾았다 / 팀이',
      '팀이 새로운 규칙을 찾았다',
      ['새로운 찾았다 팀이 규칙을', '규칙을 팀이 새로운 찾았다', '찾았다 새로운 팀이 규칙을'],
    ),
    (
      '점심 후에 / 풀었다 / 퍼즐을 / 그들이',
      '그들이 점심 후에 퍼즐을 풀었다',
      ['점심 후에 풀었다 그들이 퍼즐을', '퍼즐을 그들이 점심 풀었다', '풀었다 점심 후에 퍼즐을 그들이'],
    ),
  ];
  final item = items[variant % items.length];
  return DomainQuestionTemplate(
    questionText: '다음 낱말을 자연스러운 문장으로 배열하세요: ${item.$1}',
    answer: item.$2,
    distractors: item.$3,
    ruleName: '단어 배열',
    hint: '주어, 시간/장소, 목적어, 서술어의 흐름을 생각해 보세요.',
    explanation: "자연스러운 문장은 '${item.$2}'입니다.",
    factors: const ['word_order'],
  );
}
