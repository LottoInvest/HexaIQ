import 'dart:math';

import '../../../core/domain/intelligence_domain.dart';
import 'domain_template_generator.dart';

abstract class QuestionData {
  const QuestionData({required this.kind});

  final String kind;

  Map<String, Object?> toJson();
}

class SpatialData extends QuestionData {
  const SpatialData({
    required this.task,
    required this.elements,
    this.canvasInstructions = const [],
  }) : super(kind: 'spatial');

  final String task;
  final List<String> elements;
  final List<String> canvasInstructions;

  @override
  Map<String, Object?> toJson() {
    return {
      'kind': kind,
      'task': task,
      'elements': elements,
      'canvasInstructions': canvasInstructions,
      'renderTarget': 'canvas',
    };
  }
}

class SpatialGenerator extends TemplateQuestionGenerator {
  SpatialGenerator()
    : super(
        domain: IntelligenceDomain.spatial,
        typeCodes: codes,
        builders: _builders,
      );

  static const List<String> codes = [
    'SR01',
    'SR02',
    'SR03',
    'SR04',
    'SR05',
    'SR06',
    'SR07',
    'SR08',
    'SR09',
    'SR10',
  ];

  static final Map<String, DomainTemplateBuilder> _builders = {
    'SR01': _rotation,
    'SR02': _symmetry,
    'SR03': _pattern,
    'SR04': _coordinate,
    'SR05': _direction,
    'SR06': _blocks,
    'SR07': _array,
    'SR08': _shapeRelation,
    'SR09': _rule,
    'SR10': _puzzle,
  };
}

const _arrows = ['▲', '▶', '▼', '◀'];
const _shapeSides = {'▲': '3', '■': '4', '◆': '4', '●': '0'};

Map<String, Object?> _spatialVariables(String task, List<String> elements) {
  return {
    'questionDataType': 'SpatialData',
    'spatialData': SpatialData(
      task: task,
      elements: elements,
      canvasInstructions: const ['draw_text_grid', 'preserve_symbol_layout'],
    ).toJson(),
  };
}

DomainQuestionTemplate _rotation(Random rng, int variant, int level) {
  final start = variant % _arrows.length;
  final turns = variant.isEven ? 1 : 2;
  final answer = _arrows[(start + turns) % _arrows.length];
  return DomainQuestionTemplate(
    questionText:
        '${_arrows[start]}를 시계 방향으로 ${turns == 1 ? '90도' : '180도'} 돌리면 어떤 모양이 되나요?',
    answer: answer,
    distractors: _arrows.where((item) => item != answer).toList(),
    ruleName: '회전',
    hint: '회전 방향을 먼저 확인한 뒤 한 칸씩 돌려 보세요.',
    explanation: '시계 방향으로 돌리면 ${_arrows[start]}는 $answer가 됩니다.',
    variables: _spatialVariables('rotation', [_arrows[start], answer]),
    factors: const ['rotation'],
  );
}

DomainQuestionTemplate _symmetry(Random rng, int variant, int level) {
  const items = [
    ('◀ |', '| ▶', ['| ◀', '▶ |', '◀ ▶']),
    ('◢ |', '| ◣', ['| ◢', '◣ |', '◢ ◣']),
    ('ㄴ |', '| ㄱ', ['| ㄴ', 'ㄱ |', 'ㅜ |']),
    ('◆ |', '| ◆', ['| ◇', '◇ |', '◆ ◇']),
  ];
  final item = items[variant % items.length];
  return DomainQuestionTemplate(
    questionText: '세로선 | 을 기준으로 왼쪽 모양을 대칭하면?',
    answer: item.$2,
    distractors: item.$3,
    ruleName: '대칭',
    hint: '대칭선의 양쪽이 서로 마주 보도록 생각해 보세요.',
    explanation: '${item.$1}를 세로선 기준으로 뒤집으면 ${item.$2}입니다.',
    variables: _spatialVariables('symmetry', [item.$1, item.$2]),
    factors: const ['symmetry'],
  );
}

DomainQuestionTemplate _pattern(Random rng, int variant, int level) {
  const items = [
    (['▲', '■', '▲', '■'], '▲', ['■', '◆', '◇']),
    (['◆', '◇', '◇', '◆', '◇'], '◇', ['◆', '■', '□']),
    (['▲', '▶', '▼', '◀'], '▲', ['▶', '▼', '◀']),
    (['■', '□', '■', '□'], '■', ['□', '◆', '◇']),
  ];
  final item = items[variant % items.length];
  return DomainQuestionTemplate(
    questionText: '도형 규칙을 이어가세요: ${item.$1.join('  ')}  ?',
    answer: item.$2,
    distractors: item.$3,
    ruleName: '도형 패턴',
    hint: '반복되는 순서와 위치를 먼저 찾아보세요.',
    explanation: '반복 순서에 따라 다음 도형은 ${item.$2}입니다.',
    variables: _spatialVariables('pattern', [...item.$1, item.$2]),
    factors: const ['pattern'],
  );
}

DomainQuestionTemplate _coordinate(Random rng, int variant, int level) {
  final x = variant % 4;
  final y = (variant ~/ 2) % 4;
  final dx = variant.isEven ? 1 : -1;
  final answer = '(${x + dx}, $y)';
  return DomainQuestionTemplate(
    questionText: '점 ($x, $y)를 ${dx > 0 ? '오른쪽' : '왼쪽'}으로 1칸 옮기면 좌표는?',
    answer: answer,
    distractors: ['($x, ${y + 1})', '(${x - dx}, $y)', '(${x + dx}, ${y + 1})'],
    ruleName: '좌표 이동',
    hint: '가로 이동에서는 x값만 변합니다.',
    explanation: 'x값이 ${dx > 0 ? '+1' : '-1'} 변하므로 새 좌표는 $answer입니다.',
    variables: _spatialVariables('coordinate', ['($x, $y)', answer]),
    factors: const ['coordinate'],
  );
}

DomainQuestionTemplate _direction(Random rng, int variant, int level) {
  const items = [
    ('북쪽', '오른쪽', '동쪽', ['서쪽', '남쪽', '북쪽']),
    ('동쪽', '오른쪽', '남쪽', ['북쪽', '서쪽', '동쪽']),
    ('남쪽', '왼쪽', '동쪽', ['서쪽', '북쪽', '남쪽']),
    ('서쪽', '왼쪽', '남쪽', ['북쪽', '동쪽', '서쪽']),
  ];
  final item = items[variant % items.length];
  return DomainQuestionTemplate(
    questionText: '${item.$1}을 보고 서서 ${item.$2}으로 돌면 어느 쪽을 보나요?',
    answer: item.$3,
    distractors: item.$4,
    ruleName: '방향',
    hint: '나침반 방향을 머릿속에 놓고 회전해 보세요.',
    explanation: '${item.$1}에서 ${item.$2}으로 돌면 ${item.$3}을 보게 됩니다.',
    variables: _spatialVariables('direction', [item.$1, item.$2, item.$3]),
    factors: const ['direction'],
  );
}

DomainQuestionTemplate _blocks(Random rng, int variant, int level) {
  final bottom = 3 + variant % 3;
  final top = 1 + variant % 2;
  final answer = bottom + top;
  return DomainQuestionTemplate(
    questionText: '아래층에 블록 $bottom개, 위층에 블록 $top개가 있습니다. 전체 블록 수는?',
    answer: '$answer',
    distractors: ['${answer + 1}', '${answer - 1}', '${bottom * top}'],
    ruleName: '블록 세기',
    hint: '층별로 보이는 블록 수를 따로 세어 보세요.',
    explanation: '$bottom개와 $top개를 더하면 $answer개입니다.',
    variables: _spatialVariables('blocks', ['$bottom', '$top', '$answer']),
    factors: const ['blocks'],
  );
}

DomainQuestionTemplate _array(Random rng, int variant, int level) {
  const items = [
    ('[▲][■]\n[◆][?]', '◇', ['▲', '■', '◆']),
    ('[1][2]\n[3][?]', '4', ['1', '2', '5']),
    ('[□][■]\n[◇][?]', '◆', ['□', '■', '◇']),
    ('[왼][오]\n[위][?]', '아래', ['앞', '뒤', '왼']),
  ];
  final item = items[variant % items.length];
  return DomainQuestionTemplate(
    questionText: '2x2 배열의 빈칸에 들어갈 것은?\n${item.$1}',
    answer: item.$2,
    distractors: item.$3,
    ruleName: '배열',
    hint: '윗줄의 관계를 아랫줄에도 적용해 보세요.',
    explanation: '같은 배열 규칙을 적용하면 빈칸은 ${item.$2}입니다.',
    variables: _spatialVariables('array', [item.$1, item.$2]),
    factors: const ['array'],
  );
}

DomainQuestionTemplate _shapeRelation(Random rng, int variant, int level) {
  final shapes = _shapeSides.keys.toList(growable: false);
  final shape = shapes[variant % shapes.length];
  final sides = _shapeSides[shape]!;
  return DomainQuestionTemplate(
    questionText: '$shape 모양의 곧은 변은 몇 개인가요?',
    answer: sides,
    distractors: const ['1', '2', '5'],
    ruleName: '도형 관계',
    hint: '곡선은 빼고 곧은 변만 세어 보세요.',
    explanation: '$shape의 곧은 변은 $sides개입니다.',
    variables: _spatialVariables('shape_relation', [shape, sides]),
    factors: const ['shape'],
  );
}

DomainQuestionTemplate _rule(Random rng, int variant, int level) {
  const items = [
    ('▲ ■ ▲ ■', '반복', ['회전', '대칭', '크기 변화']),
    ('▲ ▶ ▼ ◀', '회전', ['반복 없음', '색 변화', '개수 변화']),
    ('■ □ ■ □', '채움 변화', ['방향 변화', '개수 변화', '위치 이동']),
    ('◆ ◇ ◆ ◇', '채움 변화', ['회전', '좌표 이동', '크기 변화']),
  ];
  final item = items[variant % items.length];
  return DomainQuestionTemplate(
    questionText: '다음 도형열의 주된 규칙은? ${item.$1}',
    answer: item.$2,
    distractors: item.$3,
    ruleName: '공간 규칙',
    hint: '모양, 방향, 채움이 어떻게 바뀌는지 비교해 보세요.',
    explanation: '${item.$1}에서는 ${item.$2} 규칙이 나타납니다.',
    variables: _spatialVariables('rule', [item.$1, item.$2]),
    factors: const ['rule'],
  );
}

DomainQuestionTemplate _puzzle(Random rng, int variant, int level) {
  const items = [
    ('▲ + □ = 3 + 4\n◆ = ?', '4', ['2', '3', '5']),
    ('왼쪽의 반대는 오른쪽\n위의 반대는 ?', '아래', ['앞', '뒤', '왼쪽']),
    ('채운 사각형 ■, 빈 사각형 □\n채운 마름모는?', '◆', ['◇', '■', '□']),
    ('시계방향: ▲ ▶ ▼\n다음은?', '◀', ['▲', '▶', '▼']),
  ];
  final item = items[variant % items.length];
  return DomainQuestionTemplate(
    questionText: '공간 퍼즐을 완성하세요:\n${item.$1}',
    answer: item.$2,
    distractors: item.$3,
    ruleName: '공간 퍼즐',
    hint: '주어진 관계를 같은 방식으로 적용해 보세요.',
    explanation: '관계를 적용하면 정답은 ${item.$2}입니다.',
    variables: _spatialVariables('puzzle', [item.$1, item.$2]),
    factors: const ['puzzle'],
  );
}
