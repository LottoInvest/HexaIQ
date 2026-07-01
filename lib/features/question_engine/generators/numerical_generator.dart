import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../../core/domain/question_difficulty.dart';
import '../../item_bank/domain/item.dart';
import '../core/distractor_generator.dart';
import '../core/question_generator.dart';
import '../domain/question_engine_models.dart';

typedef _RuleBuilder =
    GeneratedQuestionDto Function(GenerateQuestionRequest request, Random rng);

class NumericalGenerator implements QuestionGenerator {
  NumericalGenerator({DistractorGenerator? distractorGenerator})
    : _distractors = distractorGenerator ?? const DistractorGenerator();

  static final List<String> typeCodes = [
    for (var i = 1; i <= 20; i++) 'NR${i.toString().padLeft(2, '0')}',
  ];

  final DistractorGenerator _distractors;

  late final Map<String, _RuleBuilder> _rules = {
    'NR01': _nr01,
    'NR02': _nr02,
    'NR03': _nr03,
    'NR04': _nr04,
    'NR05': _nr05,
    'NR06': _nr06,
    'NR07': _nr07,
    'NR08': _nr08,
    'NR09': _nr09,
    'NR10': _nr10,
    'NR11': _nr11,
    'NR12': _nr12,
    'NR13': _nr13,
    'NR14': _nr14,
    'NR15': _nr15,
    'NR16': _nr16,
    'NR17': _nr17,
    'NR18': _nr18,
    'NR19': _nr19,
    'NR20': _nr20,
  };

  @override
  QuestionDomain get domain => QuestionDomain.numerical;

  @override
  Set<String> get supportedTypeCodes => typeCodes.toSet();

  @override
  GeneratedQuestionDto generate(GenerateQuestionRequest request) {
    final typeCode = request.typeCode ?? typeCodes[request.index % 20];
    final rule = _rules[typeCode];
    if (rule == null) {
      throw ArgumentError('Unsupported numerical typeCode: $typeCode');
    }
    final rng = Random((request.seed ?? request.index) + typeCode.hashCode);
    return rule(request, rng);
  }

  @override
  Item generateItem(GenerateQuestionRequest request) {
    return Item.fromGeneratedQuestion(generate(request));
  }

  @override
  GeneratedQuestionDto generateFallback(GenerateQuestionRequest request) {
    return generate(request.copyWith(typeCode: 'NR01'));
  }

  GeneratedQuestionDto _question({
    required GenerateQuestionRequest request,
    required String typeCode,
    required String questionText,
    required List<String> choices,
    required String answer,
    required String explanation,
    required List<String> factors,
    String? hint,
    String? ruleName,
    String? solution,
    String? solutionExplanation,
    Map<String, Object?> variables = const {},
  }) {
    final level = request.level ?? 1;
    final resolvedRuleName = ruleName ?? _ruleNameFor(typeCode);
    final resolvedHint = hint ?? _hintFor(typeCode, resolvedRuleName);
    final resolvedSolution = solution ?? answer;
    final resolvedSolutionExplanation = solutionExplanation ?? explanation;
    debugPrint('[Hint] Rule=$resolvedRuleName Hint=$resolvedHint');
    return GeneratedQuestionDto.fromLegacyChoices(
      id: '${request.testId}-$typeCode-${request.seed}-${request.index}',
      domain: QuestionDomain.numerical,
      typeCode: typeCode,
      level: level,
      ageGroup: request.ageGroup,
      seed: request.seed ?? request.index,
      questionText: questionText,
      choices: choices,
      answer: answer,
      explanation: explanation,
      estimatedTimeSec: 12 + level * 4,
      difficulty: request.difficulty,
      hint: resolvedHint,
      ruleName: resolvedRuleName,
      solution: resolvedSolution,
      solutionExplanation: resolvedSolutionExplanation,
      metadata: QuestionMetadataDto(
        rule: typeCode,
        ruleName: resolvedRuleName,
        difficultyFactors: [
          'level_$level',
          'difficulty_${request.difficulty.name}',
          ...factors,
        ],
      ),
      variables: {
        ...variables,
        'ruleName': resolvedRuleName,
        'solution': resolvedSolution,
        'solutionExplanation': resolvedSolutionExplanation,
      },
    );
  }

  GeneratedQuestionDto _nr01(GenerateQuestionRequest request, Random rng) {
    final level = request.level ?? 1;
    final diff = _intFor(request, rng, 1, level + 3);
    final start = _intFor(request, rng, 1, 10 + level);
    final terms = [for (var i = 0; i < 4; i++) start + diff * i];
    final answer = start + diff * 4;
    return _question(
      request: request,
      typeCode: 'NR01',
      questionText: '다음 등차수열의 빈칸에 들어갈 수는? ${terms.join(', ')}, ?',
      choices: _choices(answer, [
        answer + diff,
        answer - diff,
        answer + 1,
      ], rng),
      answer: '$answer',
      explanation: '각 항이 $diff씩 증가하므로 다음 값은 $answer입니다.',
      factors: const ['arithmetic_sequence'],
      hint: '등차수열입니다. 앞뒤 숫자의 차이가 일정한지 확인해보세요.',
      variables: {'terms': terms, 'diff': diff},
    );
  }

  GeneratedQuestionDto _nr02(GenerateQuestionRequest request, Random rng) {
    final level = request.level ?? 1;
    final ratio = _intFor(request, rng, 2, min(5, 2 + level ~/ 2));
    final start = _intFor(request, rng, 1, 5);
    final terms = [for (var i = 0; i < 4; i++) start * pow(ratio, i).toInt()];
    final answer = terms.last * ratio;
    return _question(
      request: request,
      typeCode: 'NR02',
      questionText: '다음 등비수열의 빈칸에 들어갈 수는? ${terms.join(', ')}, ?',
      choices: _choices(answer, [
        answer ~/ ratio,
        terms.last + ratio,
        answer + ratio,
      ], rng),
      answer: '$answer',
      explanation: '앞 항에 $ratio를 곱하는 규칙입니다.',
      factors: const ['geometric_sequence'],
      hint: '등비수열입니다. 앞 숫자에 같은 수를 곱하는 규칙인지 확인해보세요.',
      variables: {'terms': terms, 'ratio': ratio},
    );
  }

  GeneratedQuestionDto _nr03(GenerateQuestionRequest request, Random rng) {
    final firstDiff = _intFor(request, rng, 1, 4);
    final step = _intFor(request, rng, 1, 3);
    final terms = <int>[_intFor(request, rng, 1, 10)];
    final diffs = <int>[];
    for (var i = 0; i < 4; i++) {
      final diff = firstDiff + step * i;
      diffs.add(diff);
      terms.add(terms.last + diff);
    }
    final answer = terms.last + firstDiff + step * 4;
    return _question(
      request: request,
      typeCode: 'NR03',
      questionText: '증가량이 변합니다. ${terms.join(', ')}, ?',
      choices: _choices(answer, [
        terms.last + diffs.last,
        answer + step,
        answer - step,
      ], rng),
      answer: '$answer',
      explanation: '증가량이 ${diffs.join(', ')}처럼 $step씩 커집니다.',
      factors: const ['changing_increase'],
      variables: {'terms': terms, 'diffs': diffs},
    );
  }

  GeneratedQuestionDto _nr04(GenerateQuestionRequest request, Random rng) {
    final firstDiff = _intFor(request, rng, 1, 4);
    final step = _intFor(request, rng, 1, 3);
    final terms = <int>[_intFor(request, rng, 50, 90)];
    final diffs = <int>[];
    for (var i = 0; i < 4; i++) {
      final diff = firstDiff + step * i;
      diffs.add(diff);
      terms.add(terms.last - diff);
    }
    final answer = terms.last - (firstDiff + step * 4);
    return _question(
      request: request,
      typeCode: 'NR04',
      questionText: '감소량이 변합니다. ${terms.join(', ')}, ?',
      choices: _choices(answer, [
        terms.last - diffs.last,
        answer + step,
        answer - 1,
      ], rng),
      answer: '$answer',
      explanation: '감소량이 ${diffs.join(', ')}처럼 $step씩 커집니다.',
      factors: const ['changing_decrease'],
      variables: {'terms': terms, 'diffs': diffs},
    );
  }

  GeneratedQuestionDto _nr05(GenerateQuestionRequest request, Random rng) {
    final a = _intFor(request, rng, 1, 9);
    final b = _intFor(request, rng, 10, 19);
    final da = _intFor(request, rng, 2, 5);
    final db = _intFor(request, rng, 2, 5);
    final terms = [a, b, a + da, b + db, a + da * 2, b + db * 2];
    final answer = a + da * 3;
    return _question(
      request: request,
      typeCode: 'NR05',
      questionText: '교차수열입니다. ${terms.join(', ')}, ?',
      choices: _choices(answer, [b + db * 3, answer + da, answer - 1], rng),
      answer: '$answer',
      explanation: '홀수 번째와 짝수 번째 수열을 따로 보면 규칙이 보입니다.',
      factors: const ['alternating_sequence'],
      variables: {'terms': terms, 'oddDiff': da, 'evenDiff': db},
    );
  }

  GeneratedQuestionDto _nr06(GenerateQuestionRequest request, Random rng) {
    final start = _intFor(request, rng, 1, 10);
    final oddDiff = _intFor(request, rng, 2, 5);
    final evenDiff = _intFor(request, rng, 3, 6);
    final terms = [
      start,
      start + 10,
      start + oddDiff,
      start + 10 + evenDiff,
      start + oddDiff * 2,
      start + 10 + evenDiff * 2,
    ];
    final answer = start + oddDiff * 3;
    return _question(
      request: request,
      typeCode: 'NR06',
      questionText: '홀짝 위치를 나누어 보세요. ${terms.join(', ')}, ?',
      choices: _choices(answer, [
        answer + evenDiff,
        answer - oddDiff,
        terms.last + evenDiff,
      ], rng),
      answer: '$answer',
      explanation: '홀수 위치끼리, 짝수 위치끼리 각각 다른 규칙이 적용됩니다.',
      factors: const ['odd_even_split'],
      variables: {'terms': terms, 'oddDiff': oddDiff, 'evenDiff': evenDiff},
    );
  }

  GeneratedQuestionDto _nr07(GenerateQuestionRequest request, Random rng) {
    final a = _intFor(request, rng, 1, 4);
    final b = _intFor(request, rng, 1, 4);
    final terms = <int>[a, b];
    for (var i = 0; i < 4; i++) {
      terms.add(terms[terms.length - 1] + terms[terms.length - 2]);
    }
    final answer = terms.last + terms[terms.length - 2];
    return _question(
      request: request,
      typeCode: 'NR07',
      questionText: '피보나치형 수열입니다. ${terms.join(', ')}, ?',
      choices: _choices(answer, [
        terms.last * 2,
        answer + 1,
        answer - terms[terms.length - 2],
      ], rng),
      answer: '$answer',
      explanation: '앞의 두 수를 더해 다음 수를 만듭니다.',
      factors: const ['fibonacci_like'],
      variables: {'terms': terms},
    );
  }

  GeneratedQuestionDto _nr08(GenerateQuestionRequest request, Random rng) {
    final n = _intFor(request, rng, 2, 6);
    final terms = [for (var i = n; i < n + 4; i++) i * i];
    final answer = (n + 4) * (n + 4);
    return _question(
      request: request,
      typeCode: 'NR08',
      questionText: '제곱수 규칙입니다. ${terms.join(', ')}, ?',
      choices: _choices(answer, [
        answer + 1,
        (n + 5) * (n + 5),
        answer - (n + 4),
      ], rng),
      answer: '$answer',
      explanation: '연속된 자연수의 제곱입니다.',
      factors: const ['squares'],
      hint: '2², 3², 4²처럼 제곱수 규칙을 찾아보세요.',
      variables: {'start': n},
    );
  }

  GeneratedQuestionDto _nr09(GenerateQuestionRequest request, Random rng) {
    final n = _intFor(request, rng, 1, 4);
    final terms = [for (var i = n; i < n + 4; i++) i * i * i];
    final answer = (n + 4) * (n + 4) * (n + 4);
    return _question(
      request: request,
      typeCode: 'NR09',
      questionText: '세제곱수 규칙입니다. ${terms.join(', ')}, ?',
      choices: _choices(answer, [
        answer + 1,
        pow(n + 5, 3).toInt(),
        answer - (n + 4),
      ], rng),
      answer: '$answer',
      explanation: '연속된 자연수의 세제곱입니다.',
      factors: const ['cubes'],
      hint: '2³, 3³, 4³처럼 세제곱 규칙을 찾아보세요.',
      solutionExplanation:
          '${terms[0]}=$n³\n'
          '${terms[1]}=${n + 1}³\n'
          '${terms[2]}=${n + 2}³\n'
          '${terms[3]}=${n + 3}³\n'
          '다음은 ${n + 4}³입니다.',
      variables: {'start': n},
    );
  }

  GeneratedQuestionDto _nr10(GenerateQuestionRequest request, Random rng) {
    const primes = [2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31];
    final start = _intFor(request, rng, 0, 5);
    final terms = primes.sublist(start, start + 4);
    final answer = primes[start + 4];
    return _question(
      request: request,
      typeCode: 'NR10',
      questionText: '소수 규칙입니다. ${terms.join(', ')}, ?',
      choices: _choices(answer, [
        primes[start + 5],
        answer + 2,
        answer - 1,
      ], rng),
      answer: '$answer',
      explanation: '1과 자기 자신으로만 나누어지는 소수의 순서입니다.',
      factors: const ['prime_sequence'],
      variables: {'terms': terms},
    );
  }

  GeneratedQuestionDto _nr11(GenerateQuestionRequest request, Random rng) {
    final multiple = _intFor(request, rng, 2, 9);
    final start = _intFor(request, rng, 2, 5);
    final terms = [for (var i = 0; i < 4; i++) multiple * (start + i)];
    final answer = multiple * (start + 4);
    return _question(
      request: request,
      typeCode: 'NR11',
      questionText: '$multiple의 배수 규칙입니다. ${terms.join(', ')}, ?',
      choices: _choices(answer, [
        answer + multiple,
        answer - 1,
        answer + multiple + 1,
      ], rng),
      answer: '$answer',
      explanation: '$multiple의 배수가 이어집니다.',
      factors: const ['multiple_rule'],
      variables: {'multiple': multiple, 'terms': terms},
    );
  }

  GeneratedQuestionDto _nr12(GenerateQuestionRequest request, Random rng) {
    final number = [12, 18, 24, 30, 36][rng.nextInt(5)];
    final divisors = [
      for (var i = 1; i <= number; i++)
        if (number % i == 0) i,
    ];
    final answer = divisors[divisors.length - 2];
    return _question(
      request: request,
      typeCode: 'NR12',
      questionText: '$number의 약수 중 두 번째로 큰 수는?',
      choices: _choices(answer, [number, divisors[1], answer - 1], rng),
      answer: '$answer',
      explanation: '$number의 약수를 모두 찾은 뒤 크기순으로 비교합니다.',
      factors: const ['divisor_rule'],
      variables: {'number': number, 'divisors': divisors},
    );
  }

  GeneratedQuestionDto _nr13(GenerateQuestionRequest request, Random rng) {
    final divisor = _intFor(request, rng, 3, 9);
    final number = _intFor(request, rng, 20, 80);
    final answer = number % divisor;
    return _question(
      request: request,
      typeCode: 'NR13',
      questionText: '$number를 $divisor로 나눈 나머지는?',
      choices: _choices(answer, [divisor - answer, answer + 1, divisor], rng),
      answer: '$answer',
      explanation: '$number = $divisor × ${number ~/ divisor} + $answer입니다.',
      factors: const ['remainder_rule'],
      variables: {'number': number, 'divisor': divisor},
    );
  }

  GeneratedQuestionDto _nr14(GenerateQuestionRequest request, Random rng) {
    final a = _intFor(request, rng, 2, 9);
    final b = _intFor(request, rng, 2, 9);
    final c = _intFor(request, rng, 1, 9);
    final answer = a * b + c;
    return _question(
      request: request,
      typeCode: 'NR14',
      questionText: '$a × $b + $c = ?',
      choices: _choices(answer, [a * (b + c), a + b + c, answer - c], rng),
      answer: '$answer',
      explanation: '곱셈을 먼저 계산한 뒤 덧셈을 합니다.',
      factors: const ['operation_order'],
      variables: {'a': a, 'b': b, 'c': c},
    );
  }

  GeneratedQuestionDto _nr15(GenerateQuestionRequest request, Random rng) {
    final left = _intFor(request, rng, 3, 12);
    final topRight = _intFor(request, rng, 8, 18);
    final bottomLeft = _intFor(request, rng, 8, 18);
    final diff = topRight - left;
    final answer = bottomLeft + diff;
    return _question(
      request: request,
      typeCode: 'NR15',
      questionText:
          '2x2 수 행렬입니다. 왼쪽에서 오른쪽으로 같은 차이가 적용됩니다.\n[ $left, $topRight ; $bottomLeft, ? ]',
      choices: _choices(answer, [
        bottomLeft - diff,
        topRight + bottomLeft - left,
        answer + 1,
      ], rng),
      answer: '$answer',
      explanation:
          '윗줄은 $left에서 $topRight로 ${diff >= 0 ? '+' : ''}$diff만큼 변합니다. 아랫줄에도 같은 차이를 적용하면 $answer입니다.',
      factors: const ['matrix_2x2'],
      hint: '행렬 문제입니다. 같은 행이나 같은 열에 반복되는 차이를 찾아보세요.',
      variables: {
        'left': left,
        'topRight': topRight,
        'bottomLeft': bottomLeft,
        'diff': diff,
      },
    );
  }

  GeneratedQuestionDto _nr16(GenerateQuestionRequest request, Random rng) {
    final row1 = [_intFor(request, rng, 2, 8), _intFor(request, rng, 2, 8)];
    final row2 = [_intFor(request, rng, 3, 9), _intFor(request, rng, 3, 9)];
    final row3 = [_intFor(request, rng, 4, 10), _intFor(request, rng, 4, 10)];
    final firstSum = row1[0] + row1[1];
    final secondSum = row2[0] + row2[1];
    final answer = row3[0] + row3[1];
    return _question(
      request: request,
      typeCode: 'NR16',
      questionText:
          '각 행의 오른쪽 수는 왼쪽 두 수의 합입니다.\n[ ${row1[0]}, ${row1[1]}, $firstSum ]\n[ ${row2[0]}, ${row2[1]}, $secondSum ]\n[ ${row3[0]}, ${row3[1]}, ? ]',
      choices: _choices(answer, [
        answer + 1,
        answer - 1,
        row3[0] * row3[1],
      ], rng),
      answer: '$answer',
      explanation:
          '각 행에서 첫 번째 수와 두 번째 수를 더하면 오른쪽 수가 됩니다. ${row3[0]} + ${row3[1]} = $answer입니다.',
      factors: const ['matrix_3x3'],
      hint: '행 합 규칙입니다. 각 행의 오른쪽 수가 왼쪽 두 수의 합인지 확인해보세요.',
      variables: {'row1': row1, 'row2': row2, 'row3': row3},
    );
  }

  GeneratedQuestionDto _nr17(GenerateQuestionRequest request, Random rng) {
    final target = _intFor(request, rng, 12, 24);
    final a = _intFor(request, rng, 1, 9);
    final b = _intFor(request, rng, 1, min(9, target - a - 1));
    final answer = target - a - b;
    return _question(
      request: request,
      typeCode: 'NR17',
      questionText: '마방진 한 줄의 합이 $target입니다. $a, $b, ?에서 ?는?',
      choices: _choices(answer, [target - a, target - b, answer + 1], rng),
      answer: '$answer',
      explanation: '한 줄의 합이 $target이 되도록 빠진 값을 계산합니다.',
      factors: const ['magic_square'],
      hint: '숫자퍼즐입니다. 행, 열, 대각선 중 반복되는 합계를 찾아보세요.',
      variables: {'target': target, 'a': a, 'b': b},
    );
  }

  GeneratedQuestionDto _nr18(GenerateQuestionRequest request, Random rng) {
    final x = _intFor(request, rng, 2, 20);
    final a = _intFor(request, rng, 2, 5);
    final b = _intFor(request, rng, 1, 9);
    final result = a * x + b;
    return _question(
      request: request,
      typeCode: 'NR18',
      questionText: '${a}x + $b = $result일 때 x는?',
      choices: _choices(x, [result ~/ a, x + b, a + b], rng),
      answer: '$x',
      explanation: '먼저 $b를 빼고, 그 결과를 $a로 나눕니다.',
      factors: const ['conditional_equation'],
      hint: '방정식 문제입니다. 양쪽에서 같은 수를 빼거나 나누어 x를 구해보세요.',
      variables: {'x': x, 'a': a, 'b': b, 'result': result},
    );
  }

  GeneratedQuestionDto _nr19(GenerateQuestionRequest request, Random rng) {
    final a = _intFor(request, rng, 2, 5);
    final b = _intFor(request, rng, 6, 12);
    final k = _intFor(request, rng, 2, 6);
    final answer = b * k;
    return _question(
      request: request,
      typeCode: 'NR19',
      questionText: '$a:$b = ${a * k}:? 일 때 ?는?',
      choices: _choices(answer, [a * k + b, answer - k, answer + b], rng),
      answer: '$answer',
      explanation: '같은 비율을 유지하도록 양쪽에 같은 배수를 곱합니다.',
      factors: const ['ratio_reasoning'],
      variables: {'a': a, 'b': b, 'k': k},
    );
  }

  GeneratedQuestionDto _nr20(GenerateQuestionRequest request, Random rng) {
    final start = _intFor(request, rng, 2, 9);
    final multiplier = _intFor(request, rng, 2, 5);
    final add = _intFor(request, rng, 3, 12);
    final answer = start * multiplier + add;
    return _question(
      request: request,
      typeCode: 'NR20',
      questionText: '숫자 퍼즐: 시작 수 $start, 규칙은 ×$multiplier 후 +$add입니다. 결과는?',
      choices: _choices(answer, [
        answer - add,
        answer + add,
        answer + multiplier,
      ], rng),
      answer: '$answer',
      explanation:
          '$start × $multiplier = ${start * multiplier}, 여기에 $add를 더합니다.',
      factors: const ['number_puzzle'],
      hint: '숫자퍼즐입니다. 곱하기와 더하기가 어떤 순서로 적용되는지 확인해보세요.',
      variables: {'start': start, 'multiplier': multiplier, 'add': add},
    );
  }

  int _intFor(
    GenerateQuestionRequest request,
    Random rng,
    int lower,
    int upper,
  ) {
    final cap = _difficultyCap(request.difficulty);
    return _int(rng, lower, min(upper, cap));
  }

  int _difficultyCap(QuestionDifficulty difficulty) {
    return switch (difficulty) {
      QuestionDifficulty.veryEasy => 10,
      QuestionDifficulty.easy => 30,
      QuestionDifficulty.normal => 100,
      QuestionDifficulty.hard => 300,
      QuestionDifficulty.veryHard => 1000,
    };
  }

  int _int(Random rng, int min, int max) {
    if (max <= min) {
      return min;
    }
    return min + rng.nextInt(max - min + 1);
  }

  List<String> _choices(int answer, List<int> distractors, Random rng) {
    return _distractors.numericChoices(answer, distractors, rng);
  }

  String _ruleNameFor(String typeCode) {
    return switch (typeCode) {
      'NR01' => '등차수열',
      'NR02' => '등비수열',
      'NR03' => '증가량 변화',
      'NR04' => '감소량 변화',
      'NR05' => '교차수열',
      'NR06' => '홀짝 위치 규칙',
      'NR07' => '피보나치형 수열',
      'NR08' => '제곱수',
      'NR09' => '세제곱수',
      'NR10' => '소수',
      'NR11' => '배수',
      'NR12' => '약수',
      'NR13' => '나머지',
      'NR14' => '연산 순서',
      'NR15' => '행렬 규칙',
      'NR16' => '행 합 규칙',
      'NR17' => '숫자퍼즐',
      'NR18' => '방정식',
      'NR19' => '비례식',
      'NR20' => '숫자 관계',
      _ => typeCode,
    };
  }

  String _hintFor(String typeCode, String ruleName) {
    return switch (typeCode) {
      'NR01' => '앞뒤 숫자의 차이가 일정한지 확인해보세요.',
      'NR02' => '앞 숫자에 같은 수를 곱하는 규칙인지 확인해보세요.',
      'NR03' => '숫자 사이의 차이가 다시 일정하게 변하는지 살펴보세요.',
      'NR04' => '감소하는 차이가 어떤 규칙으로 커지는지 비교해보세요.',
      'NR05' => '홀수 번째와 짝수 번째 숫자를 따로 나누어 보세요.',
      'NR06' => '위치가 홀수인지 짝수인지에 따라 다른 규칙일 수 있습니다.',
      'NR07' => '앞의 두 수를 더해 다음 수가 되는지 확인해보세요.',
      'NR08' => '2², 3², 4²처럼 제곱수 규칙을 찾아보세요.',
      'NR09' => '2³, 3³, 4³처럼 세제곱 규칙을 찾아보세요.',
      'NR10' => '1과 자기 자신으로만 나누어지는 수의 순서를 떠올려보세요.',
      'NR11' => '같은 수의 배수가 이어지는지 확인해보세요.',
      'NR12' => '약수를 모두 찾은 뒤 큰 순서로 비교해보세요.',
      'NR13' => '나누어 떨어지고 남는 수를 계산해보세요.',
      'NR14' => '곱셈을 먼저 계산한 뒤 덧셈이나 뺄셈을 처리해보세요.',
      'NR15' => '같은 행이나 열에서 반복되는 차이를 찾아보세요.',
      'NR16' => '각 행의 오른쪽 수가 왼쪽 두 수의 합인지 확인해보세요.',
      'NR17' => '행, 열, 대각선 중 반복되는 합계를 찾아보세요.',
      'NR18' => '양쪽에서 같은 수를 빼거나 나누어 x를 구해보세요.',
      'NR19' => '같은 비율을 유지하려면 어떤 배수를 곱해야 하는지 보세요.',
      'NR20' => '곱하기와 더하기가 어떤 순서로 적용되는지 확인해보세요.',
      _ => '$ruleName 규칙을 찾고 보기와 하나씩 비교해보세요.',
    };
  }
}
