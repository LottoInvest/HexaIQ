# Question Engine Master Specification v1.0

작성일: 2026-06-29  
대상 프로젝트: HexaIQ  
관계 문서: `HexaIQ_Master_Design_Spec_v1.0.md`를 대체하지 않고 보완한다.  
적용 범위: FastAPI backend question engine, Flutter client question consumption, admin template management.

---

## 1. Purpose

이 문서는 HexaIQ의 Domain 기반 범용 QuestionEngine을 정의한다.

핵심 목표:

- 6개 인지 영역별 문제 생성기를 공통 인터페이스로 관리한다.
- Numerical 영역은 MVP에서 실제 구현 가능한 수준으로 상세 설계한다.
- Spatial, Logical, Verbal, Memory, Pattern 영역은 동일 인터페이스와 Stub 구현 규칙을 정의한다.
- Numerical type code `NR01`~`NR20`의 생성 규칙, 오답 생성, 해설, 난이도, 연령 매핑을 명확히 한다.
- CAT 알고리즘과 seed 기반 중복 방지 전략을 FastAPI에서 바로 구현할 수 있게 정의한다.
- Flutter가 소비할 수 있는 안정적인 데이터 구조와 JSON schema를 정의한다.

비목표:

- 이 문서는 임상 진단 또는 공인 IQ 산출 알고리즘을 정의하지 않는다.
- 초기 MVP 점수는 학습 참고 지표이며, 표준화 검사 결과로 표현하지 않는다.
- Spatial/Logical/Verbal/Memory/Pattern의 전체 20개 유형 상세 규칙은 별도 후속 문서에서 확장한다.

---

## 2. Domain Model

### 2.1 Supported Domains

| Domain code | Label | Generator status | MVP behavior |
| --- | --- | --- | --- |
| `numerical` | 수리 추론 | 실제 구현 | `NumericalGenerator` 사용 |
| `spatial` | 공간 지각 | Stub | 고정 템플릿 또는 placeholder generator |
| `logical` | 논리 추론 | Stub | 고정 템플릿 또는 placeholder generator |
| `verbal` | 언어 추론 | Stub | 고정 템플릿 또는 placeholder generator |
| `memory` | 작업 기억 | Stub | 고정 템플릿 또는 placeholder generator |
| `pattern` | 추상 패턴 | Stub | 고정 템플릿 또는 placeholder generator |

### 2.2 Test Product Mapping

| Test type | Total items | Per domain | Engine mode |
| --- | ---: | ---: | --- |
| `basic` | 30 | 5 | age-based starting level + light CAT |
| `advanced` | 120 | 20 | domain-balanced CAT |
| `professional` | 240 | 40 | full CAT + richer report metadata |

---

## 3. QuestionEngine Architecture

### 3.1 Core Flow

```text
Start Test
  -> resolve profile age group
  -> initialize domain states
  -> choose next domain
  -> choose type code
  -> choose target level by CAT
  -> generate deterministic seed
  -> check duplicate prevention store
  -> generate question
  -> persist generated_question
  -> return Flutter-safe payload
  -> receive answer
  -> score response
  -> update domain CAT state
  -> continue or complete test
```

### 3.2 Required Backend Modules

```text
services/api/app/
  question_engine/
    engine.py
    registry.py
    schemas.py
    seed.py
    cat.py
    duplicate_guard.py
    generators/
      base.py
      numerical.py
      spatial_stub.py
      logical_stub.py
      verbal_stub.py
      memory_stub.py
      pattern_stub.py
```

### 3.3 Generator Interface

Python interface:

```python
from abc import ABC, abstractmethod
from dataclasses import dataclass
from typing import Any, Literal

DomainCode = Literal[
    "numerical",
    "spatial",
    "logical",
    "verbal",
    "memory",
    "pattern",
]

@dataclass(frozen=True)
class GenerationContext:
    profile_id: str
    age_group: str
    grade: str | None
    test_id: str
    test_type: str
    domain: DomainCode
    type_code: str
    target_level: int
    seed: int
    locale: str = "ko-KR"

@dataclass(frozen=True)
class GeneratedQuestion:
    question_id: str
    test_id: str
    domain: DomainCode
    type_code: str
    level: int
    age_group: str
    seed: int
    prompt: str
    choices: list[str]
    answer_index: int
    answer_value: str
    explanation: str
    variables: dict[str, Any]
    metadata: dict[str, Any]

class QuestionGenerator(ABC):
    domain: DomainCode
    supported_type_codes: set[str]

    @abstractmethod
    def generate(self, context: GenerationContext) -> GeneratedQuestion:
        pass
```

### 3.4 Stub Generator Contract

Stub generators must:

- implement `QuestionGenerator`.
- return valid `GeneratedQuestion`.
- never crash for valid `GenerationContext`.
- set `metadata.generator_status` to `"stub"`.
- set `metadata.requires_validation` to `true`.
- use deterministic output from `seed`.
- provide at least 3 choices and exactly 1 correct answer.

Stub domains are allowed to use simple hand-authored templates until full type specs are written.

---

## 4. NumericalGenerator Implementation Design

### 4.1 Generator Overview

`NumericalGenerator` generates deterministic numerical reasoning questions from:

```text
type_code + target_level + age_group + seed
```

It must not rely on global random state. All randomness must be created from a local seeded RNG.

Python skeleton:

```python
import random
from uuid import uuid5, NAMESPACE_URL

class NumericalGenerator(QuestionGenerator):
    domain = "numerical"
    supported_type_codes = {f"NR{i:02d}" for i in range(1, 21)}

    def generate(self, context: GenerationContext) -> GeneratedQuestion:
        rng = random.Random(context.seed)
        rule = NUMERICAL_RULES[context.type_code]
        variables = rule.generator(context, rng)
        answer = rule.answer(variables)
        choices = rule.distractors(variables, answer, context, rng)
        answer_index = choices.index(str(answer))
        question_id = str(uuid5(
            NAMESPACE_URL,
            f"{context.test_id}:{context.profile_id}:{context.type_code}:{context.seed}",
        ))
        return GeneratedQuestion(
            question_id=question_id,
            test_id=context.test_id,
            domain="numerical",
            type_code=context.type_code,
            level=context.target_level,
            age_group=context.age_group,
            seed=context.seed,
            prompt=rule.prompt(variables),
            choices=choices,
            answer_index=answer_index,
            answer_value=str(answer),
            explanation=rule.explanation(variables),
            variables=variables,
            metadata={
                "generator_status": "implemented",
                "rule_version": rule.version,
                "difficulty_band": rule.difficulty_band(context.target_level),
            },
        )
```

### 4.2 Determinism Rule

Same input must produce same question:

```text
profile_id does not influence variables directly.
test_id does not influence variables directly.
seed controls variables.
type_code controls generator.
target_level controls value range and operation complexity.
age_group controls allowed wording and numeric bounds.
```

`profile_id` and `test_id` are used for identity, audit, and duplicate prevention, not for random behavior.

---

## 5. Age Group and Level Mapping

### 5.1 Age Groups

| Age group | Code | Starting level | Numeric range bias |
| --- | --- | ---: | --- |
| 유치부 | `kinder` | 1 | 1~20 |
| 초등 1-2 | `elementary_1_2` | 2 | 1~50 |
| 초등 3-4 | `elementary_3_4` | 4 | 1~200 |
| 초등 5-6 | `elementary_5_6` | 6 | 1~1000 |
| 중학생 | `middle_school` | 7 | 1~5000 |
| 고등학생 | `high_school` | 8 | 1~10000 |
| 성인 | `adult` | 8 | 1~20000 |

### 5.2 Difficulty Levels

Levels are integer values from 1 to 10.

| Level | Band | Meaning |
| ---: | --- | --- |
| 1 | very_easy | single-step, small numbers |
| 2 | easy | one operation, direct pattern |
| 3 | easy_plus | one operation with mild distractors |
| 4 | medium_low | two-step pattern or operation |
| 5 | medium | mixed operations, moderate range |
| 6 | medium_high | multi-step pattern, larger numbers |
| 7 | hard_low | ratio, reverse, or hidden rule |
| 8 | hard | compound rules |
| 9 | very_hard | abstraction plus calculation |
| 10 | expert | dense compound rule with close distractors |

### 5.3 Allowed Level By Age

| Age code | Min level | Default level | Max level |
| --- | ---: | ---: | ---: |
| `kinder` | 1 | 1 | 3 |
| `elementary_1_2` | 1 | 2 | 5 |
| `elementary_3_4` | 2 | 4 | 7 |
| `elementary_5_6` | 3 | 6 | 8 |
| `middle_school` | 4 | 7 | 9 |
| `high_school` | 5 | 8 | 10 |
| `adult` | 5 | 8 | 10 |

The CAT algorithm may move within min/max bounds only.

---

## 6. Numerical Type Codes NR01~NR20

Each type definition contains:

- Generator: variable generation rule.
- Distractor: wrong choice strategy.
- Explanation: deterministic explanation template.
- Difficulty: level scaling rule.
- Age Mapping: where the type is allowed and preferred.

### NR01 - Arithmetic Progression

Purpose: identify constant additive difference.

- Generator:
  - choose `start` from age/level range.
  - choose `diff` from `level + 1` scaled range.
  - build 4 visible terms and 1 missing next term.
  - answer = `start + diff * 4`.
- Distractor:
  - answer `+ diff`
  - answer `- diff`
  - answer `+ 1` or `- 1`
  - one near value from visible terms.
- Explanation:
  - "각 항이 {diff}씩 증가하므로 다음 값은 {answer}입니다."
- Difficulty:
  - Level 1~3: positive diff, small numbers.
  - Level 4~6: larger diff or negative start.
  - Level 7~10: negative diff or hidden middle blank variant.
- Age Mapping:
  - all ages allowed.
  - preferred for `kinder` through `elementary_3_4`.

### NR02 - Geometric Progression

Purpose: identify multiplication ratio.

- Generator:
  - choose `start`.
  - choose integer ratio `2`, `3`, or level-based value.
  - build 4 visible terms and next answer.
- Distractor:
  - arithmetic continuation.
  - answer divided by ratio.
  - answer plus ratio.
  - common multiplication slip.
- Explanation:
  - "앞 항에 {ratio}를 곱하는 규칙입니다."
- Difficulty:
  - Level 2~4: ratio 2.
  - Level 5~7: ratio 3 or 4.
  - Level 8~10: fractional-looking but integer-safe sequence.
- Age Mapping:
  - starts at `elementary_1_2`.
  - preferred from `elementary_3_4`.

### NR03 - Alternating Add/Subtract Sequence

Purpose: recognize alternating operation.

- Generator:
  - choose `start`, `a`, `b`.
  - sequence alternates `+a`, `-b`.
  - missing term can be next or internal depending on level.
- Distractor:
  - continuing with same previous operation.
  - reversed alternation.
  - arithmetic progression answer.
  - off-by-one.
- Explanation:
  - "연산이 +{a}, -{b} 순서로 번갈아 적용됩니다."
- Difficulty:
  - Level 3~5: next term only.
  - Level 6~8: internal blank.
  - Level 9~10: larger values and negative intermediate allowed.
- Age Mapping:
  - starts at `elementary_3_4`.

### NR04 - Two-Step Repeating Pattern

Purpose: handle repeated pair of operations.

- Generator:
  - choose operation pair, e.g. `*2`, `+3`.
  - generate 5 terms.
  - answer is next term.
- Distractor:
  - apply only first operation.
  - apply only second operation.
  - reverse operation order.
  - close numeric value.
- Explanation:
  - "두 연산이 한 묶음으로 반복됩니다: {op1}, {op2}."
- Difficulty:
  - Level 4~6: addition/multiplication.
  - Level 7~10: subtraction/division when integer-safe.
- Age Mapping:
  - starts at `elementary_3_4`.

### NR05 - Difference Sequence

Purpose: infer sequence from changing differences.

- Generator:
  - choose base sequence where differences are arithmetic progression.
  - example differences: `2, 4, 6, 8`.
  - answer = last term + next difference.
- Distractor:
  - use previous difference again.
  - skip one difference.
  - add constant average.
  - off-by-difference.
- Explanation:
  - "항 사이의 차이가 {diff_sequence}처럼 변합니다."
- Difficulty:
  - Level 4~6: increasing positive differences.
  - Level 7~10: decreasing or mixed differences.
- Age Mapping:
  - preferred for `elementary_5_6` and above.

### NR06 - Missing Middle Term

Purpose: solve an internal blank, not only next term.

- Generator:
  - choose a base rule from NR01, NR02, or NR05.
  - hide index 1, 2, or 3.
  - answer is hidden term.
- Distractor:
  - next-term answer.
  - previous-term answer.
  - arithmetic mean.
  - close value.
- Explanation:
  - "전체 규칙을 먼저 찾고 빈칸 위치의 값을 계산합니다."
- Difficulty:
  - Level 3~5: arithmetic progression.
  - Level 6~8: geometric progression.
  - Level 9~10: difference sequence.
- Age Mapping:
  - starts at `elementary_3_4`.

### NR07 - Basic Equation

Purpose: one-variable equation solving.

- Generator:
  - choose `x`.
  - choose operation form: `x + a = b`, `x * a = b`, `x - a = b`.
  - ensure integer answer.
- Distractor:
  - inverse operation mistake.
  - use `a` as answer.
  - use `b` as answer.
  - close answer.
- Explanation:
  - "양쪽에 같은 역연산을 적용하면 x = {x}입니다."
- Difficulty:
  - Level 2~4: addition/subtraction.
  - Level 5~7: multiplication/division.
  - Level 8~10: two-step equation.
- Age Mapping:
  - starts at `elementary_1_2`.

### NR08 - Two-Step Equation

Purpose: solve equations requiring two inverse operations.

- Generator:
  - choose `x`, `a`, `b`.
  - produce `a*x + b = c`.
- Distractor:
  - subtract after divide mistake.
  - divide after wrong side.
  - answer plus/minus 1.
  - use intermediate value.
- Explanation:
  - "먼저 {b}를 옮기고, 그 다음 {a}로 나눕니다."
- Difficulty:
  - Level 5~7: positive coefficients.
  - Level 8~10: negative constants or larger coefficients.
- Age Mapping:
  - preferred from `elementary_5_6`.

### NR09 - Ratio

Purpose: understand proportional relationship.

- Generator:
  - choose pair `a:b`.
  - choose multiplier `k`.
  - ask for corresponding value.
- Distractor:
  - add difference instead of multiply.
  - invert ratio.
  - multiply by wrong side.
  - close value.
- Explanation:
  - "비율 {a}:{b}가 유지되도록 같은 배수를 적용합니다."
- Difficulty:
  - Level 4~6: simple integer multiplier.
  - Level 7~10: missing first or second quantity with larger numbers.
- Age Mapping:
  - starts at `elementary_3_4`.

### NR10 - Percent

Purpose: basic percentage calculation.

- Generator:
  - choose base number divisible by 10 or 20 for lower levels.
  - choose percent from `10, 20, 25, 50, 75`.
  - answer = base * percent / 100.
- Distractor:
  - percent as raw value.
  - base minus percent.
  - decimal shift error.
  - close rounded value.
- Explanation:
  - "{percent}%는 {percent}/100이므로 {base}에 곱합니다."
- Difficulty:
  - Level 5~6: 50%, 10%, 20%.
  - Level 7~8: 25%, 75%.
  - Level 9~10: increase/decrease percent wording.
- Age Mapping:
  - starts at `elementary_5_6`.

### NR11 - Average

Purpose: compute mean or missing value from mean.

- Generator:
  - lower level: ask average of 3~5 numbers.
  - higher level: given average and all but one value, ask missing value.
- Distractor:
  - sum instead of average.
  - divide by wrong count.
  - omit one value.
  - close value.
- Explanation:
  - "평균은 전체 합을 개수로 나눈 값입니다."
- Difficulty:
  - Level 3~5: direct average.
  - Level 6~10: missing value from target average.
- Age Mapping:
  - starts at `elementary_3_4`.

### NR12 - Remainder / Modular Pattern

Purpose: cyclic numeric reasoning.

- Generator:
  - choose cycle length.
  - choose nth position.
  - ask value at position n.
- Distractor:
  - use quotient instead of remainder.
  - off-by-one position.
  - previous cycle value.
  - next cycle value.
- Explanation:
  - "반복 길이가 {cycle_length}이므로 {n}을 나눈 나머지로 위치를 찾습니다."
- Difficulty:
  - Level 4~6: visible cycle.
  - Level 7~10: longer index or hidden cycle.
- Age Mapping:
  - starts at `elementary_5_6`.

### NR13 - Unit Conversion

Purpose: transform units and compare quantities.

- Generator:
  - choose unit pair: cm/m, g/kg, min/hour.
  - choose value that converts cleanly.
  - ask converted value or comparison.
- Distractor:
  - multiply instead of divide.
  - factor of 10 error.
  - unchanged value.
  - close converted value.
- Explanation:
  - "단위 사이의 변환 비율은 {factor}입니다."
- Difficulty:
  - Level 2~4: direct conversion.
  - Level 5~8: two values compare after conversion.
  - Level 9~10: two-step conversion.
- Age Mapping:
  - starts at `elementary_1_2`.

### NR14 - Time Calculation

Purpose: elapsed time and schedule reasoning.

- Generator:
  - choose start time.
  - choose duration.
  - ask end time or elapsed time.
- Distractor:
  - hour carry mistake.
  - minute carry mistake.
  - add instead of subtract.
  - 12-hour wrap error.
- Explanation:
  - "분을 먼저 계산하고 60분이 넘으면 시간으로 올립니다."
- Difficulty:
  - Level 2~4: same-hour minutes.
  - Level 5~7: cross-hour.
  - Level 8~10: multi-duration schedule.
- Age Mapping:
  - all school-age groups.

### NR15 - Money / Price Reasoning

Purpose: arithmetic in price context.

- Generator:
  - choose item price and quantity.
  - ask total, change, or discount amount.
- Distractor:
  - single item price.
  - quantity plus price.
  - wrong change.
  - close rounded value.
- Explanation:
  - "단가와 수량을 곱하고, 필요하면 지불 금액에서 뺍니다."
- Difficulty:
  - Level 1~3: total price.
  - Level 4~6: change.
  - Level 7~10: discount or multi-item basket.
- Age Mapping:
  - all ages, wording adjusted for age.

### NR16 - Comparison / Ordering

Purpose: compare fractions, decimals, or large numbers.

- Generator:
  - choose 3~5 values.
  - ask greatest, smallest, or ordered position.
- Distractor:
  - lexical ordering mistake.
  - numerator-only fraction comparison.
  - decimal digit count mistake.
  - adjacent value.
- Explanation:
  - "값을 같은 형태로 맞춘 뒤 크기를 비교합니다."
- Difficulty:
  - Level 2~4: whole numbers.
  - Level 5~7: decimals.
  - Level 8~10: fractions and mixed values.
- Age Mapping:
  - whole number variant starts at `elementary_1_2`.
  - fraction variant starts at `elementary_5_6`.

### NR17 - Number Classification

Purpose: identify odd/even, prime, multiple, factor.

- Generator:
  - choose classification rule.
  - provide 4 choices.
  - ask which value matches or does not match.
- Distractor:
  - composite mistaken as prime.
  - multiple/factor reversal.
  - odd/even near value.
  - all-but-one trap.
- Explanation:
  - "조건을 각 선택지에 하나씩 적용해 확인합니다."
- Difficulty:
  - Level 1~3: odd/even.
  - Level 4~6: multiples/factors.
  - Level 7~10: prime/composite.
- Age Mapping:
  - odd/even all ages.
  - prime starts at `elementary_5_6`.

### NR18 - Word Problem

Purpose: convert short text into arithmetic expression.

- Generator:
  - choose scenario: sharing, grouping, remaining, total.
  - choose 2~3 numeric facts.
  - ask final quantity.
- Distractor:
  - use only one sentence.
  - wrong operation.
  - skip remainder.
  - close value.
- Explanation:
  - "문장에서 필요한 수를 찾고, 상황에 맞는 연산 순서로 계산합니다."
- Difficulty:
  - Level 2~4: one operation.
  - Level 5~7: two operations.
  - Level 8~10: irrelevant number included.
- Age Mapping:
  - all ages with vocabulary control.

### NR19 - Table / Chart Reading

Purpose: extract and calculate from structured data.

- Generator:
  - generate small table with categories and values.
  - ask total, difference, max/min, or ratio.
- Distractor:
  - select category value instead of computed value.
  - row/column confusion.
  - wrong difference direction.
  - close computed value.
- Explanation:
  - "표에서 필요한 값을 찾은 뒤 질문이 요구하는 계산을 적용합니다."
- Difficulty:
  - Level 3~5: direct lookup.
  - Level 6~8: difference or total.
  - Level 9~10: ratio or multi-row comparison.
- Age Mapping:
  - starts at `elementary_3_4`.

### NR20 - Mixed Rule Challenge

Purpose: capstone item combining multiple numerical skills.

- Generator:
  - choose two primitive rule families from NR01~NR19.
  - generate a compact item with one final answer.
  - ensure all intermediate results are integer-safe.
- Distractor:
  - answer from primitive rule A only.
  - answer from primitive rule B only.
  - wrong order of operations.
  - close value.
- Explanation:
  - "먼저 {first_rule}을 적용하고, 그 결과에 {second_rule}을 적용합니다."
- Difficulty:
  - Level 7~10 only.
  - must not appear in Basic for younger groups unless CAT level allows.
- Age Mapping:
  - `middle_school`, `high_school`, `adult` preferred.
  - `elementary_5_6` allowed only at level 8 and below.

---

## 7. Numerical Rule Registry

FastAPI registry record:

```json
{
  "domain": "numerical",
  "type_code": "NR01",
  "title": "Arithmetic Progression",
  "version": "1.0.0",
  "implemented": true,
  "min_level": 1,
  "max_level": 10,
  "allowed_age_groups": [
    "kinder",
    "elementary_1_2",
    "elementary_3_4",
    "elementary_5_6",
    "middle_school",
    "high_school",
    "adult"
  ],
  "requires_assets": false,
  "answer_type": "integer",
  "choice_count": 4
}
```

The backend should store rule registry in code first for MVP, then mirror it in `question_templates` for admin visibility.

---

## 8. Distractor Strategy

### 8.1 General Requirements

Distractors must:

- be unique.
- never equal the correct answer.
- be plausible for the target level.
- have same display format as the answer.
- avoid embarrassing or trick-only wording.
- be deterministic under seed.

### 8.2 Numeric Distractor Builder

Algorithm:

```python
def build_numeric_choices(answer: int, candidates: list[int], rng: random.Random) -> list[str]:
    unique = []
    for value in candidates:
        if value != answer and value not in unique:
            unique.append(value)
    delta = 1
    while len(unique) < 3:
        for value in (answer - delta, answer + delta):
            if value != answer and value not in unique:
                unique.append(value)
            if len(unique) == 3:
                break
        delta += 1
    choices = [answer, *unique[:3]]
    rng.shuffle(choices)
    return [str(value) for value in choices]
```

---

## 9. Explanation Strategy

Each generated question must include:

- short explanation for Basic.
- structured explanation steps for Advanced and Professional.
- non-diagnostic wording.

Recommended FastAPI payload fields:

```json
{
  "explanation": "각 항이 3씩 증가하므로 다음 값은 15입니다.",
  "explanation_steps": [
    "항 사이의 차이를 확인합니다.",
    "3, 6, 9, 12는 3씩 증가합니다.",
    "12에 3을 더하면 15입니다."
  ]
}
```

Flutter may show only `explanation` in MVP and reserve `explanation_steps` for report/detail screens.

---

## 10. CAT Algorithm

### 10.1 State Per Domain

```json
{
  "domain": "numerical",
  "current_level": 6,
  "min_level": 3,
  "max_level": 8,
  "answered_count": 0,
  "correct_count": 0,
  "incorrect_count": 0,
  "consecutive_correct": 0,
  "consecutive_incorrect": 0,
  "average_response_ms": null,
  "confidence": 0.0
}
```

### 10.2 Initial Level

Initial level = age group default level, clamped by product:

| Test type | Adjustment |
| --- | --- |
| `basic` | age default |
| `advanced` | age default + 1, clamp to max |
| `professional` | age default + 1, then CAT stabilizes |

### 10.3 Response Scoring

Backend receives:

```json
{
  "selected_index": 2,
  "response_ms": 8200
}
```

Internal score:

```text
correct = selected_index == answer_index
fast = response_ms <= expected_ms(level, age_group) * 0.65
slow = response_ms >= expected_ms(level, age_group) * 1.75
```

Expected response time:

```text
base_ms = 12000
level_bonus_ms = level * 1800
age_modifier:
  kinder: +8000
  elementary_1_2: +6000
  elementary_3_4: +4000
  elementary_5_6: +2500
  middle_school: +1200
  high_school: 0
  adult: 0
```

### 10.4 Level Update Rule

```python
def next_level(state, correct: bool, response_ms: int, expected_ms: int) -> int:
    level = state.current_level
    fast = response_ms <= expected_ms * 0.65
    slow = response_ms >= expected_ms * 1.75

    if correct and fast and state.consecutive_correct >= 1:
        level += 1
    elif correct:
        level += 0
    elif not correct and slow:
        level -= 2
    else:
        level -= 1

    return clamp(level, state.min_level, state.max_level)
```

### 10.5 Type Selection Strategy

For each domain:

1. Exclude type codes already overused in current test.
2. Prefer type codes allowed for age group and current level.
3. Prefer lower exposure count for the profile.
4. For Basic, ensure coverage breadth over precision.
5. For Professional, optimize CAT information gain.

Numerical Basic type rotation:

```text
NR01, NR02, NR07, NR11, NR18
```

Numerical Advanced should sample all NR01~NR20 once before repeating.

Professional can repeat type families but not exact `profile_id + type_code + seed` within duplicate window.

### 10.6 Domain Selection Strategy

Basic:

```text
round-robin by domain, 5 items each
```

Advanced:

```text
round-robin by domain, 20 items each, with domain CAT state
```

Professional:

```text
round-robin first 12 items, then adaptive domain allocation:
  weak domains: +20% item allocation
  unstable confidence domains: +10% item allocation
  strong stable domains: -10% item allocation
```

---

## 11. Seed Strategy and Duplicate Prevention

### 11.1 Seed Generation

Seed should be server-generated.

Inputs:

```text
test_id
profile_id
domain
type_code
attempt_index
server_secret_salt
timestamp_bucket
retry_counter
```

Recommended algorithm:

```python
import hashlib

def make_seed(
    test_id: str,
    profile_id: str,
    domain: str,
    type_code: str,
    attempt_index: int,
    salt: str,
    retry_counter: int = 0,
) -> int:
    raw = f"{test_id}:{profile_id}:{domain}:{type_code}:{attempt_index}:{retry_counter}:{salt}"
    digest = hashlib.sha256(raw.encode("utf-8")).hexdigest()
    return int(digest[:12], 16)
```

### 11.2 Duplicate Key

Hard duplicate key:

```text
profile_id + type_code + seed
```

Recommended DB unique index:

```sql
CREATE UNIQUE INDEX uq_generated_question_profile_type_seed
ON generated_questions(profile_id, type_code, seed);
```

### 11.3 90-Day Reuse Guard

Even if old records remain, the engine must reject recent duplicates:

```sql
SELECT 1
FROM generated_questions
WHERE profile_id = :profile_id
  AND type_code = :type_code
  AND seed = :seed
  AND created_at >= NOW() - INTERVAL '90 days'
LIMIT 1;
```

### 11.4 Retry Strategy

If duplicate:

```text
retry_counter += 1
generate new seed
try again
max retry = 10
if still duplicate, choose next eligible type_code
if all fail, return 409 QUESTION_GENERATION_EXHAUSTED
```

### 11.5 Variable-Level Duplicate Guard

Some different seeds may produce same visible question. Store a question signature:

```python
signature = sha256(f"{domain}:{type_code}:{prompt}:{answer_value}".encode()).hexdigest()
```

Soft duplicate key:

```text
profile_id + question_signature within 90 days
```

Soft duplicates should be retried for Basic/Advanced and forbidden for Professional.

---

## 12. FastAPI JSON Schemas

### 12.1 Start Test Request

```json
{
  "profile_id": "profile_123",
  "test_type": "basic",
  "locale": "ko-KR"
}
```

JSON schema:

```json
{
  "type": "object",
  "required": ["profile_id", "test_type"],
  "properties": {
    "profile_id": { "type": "string", "minLength": 1 },
    "test_type": {
      "type": "string",
      "enum": ["basic", "advanced", "professional"]
    },
    "locale": {
      "type": "string",
      "default": "ko-KR"
    }
  }
}
```

### 12.2 Next Question Response

```json
{
  "test_id": "test_123",
  "question": {
    "question_id": "87f6d3b5-4e8c-5e82-b06e-2abf59a25a8b",
    "domain": "numerical",
    "type_code": "NR01",
    "level": 4,
    "age_group": "elementary_5_6",
    "seed": 192837465,
    "prompt": "다음 수열의 빈칸에 들어갈 수는? 3, 6, 9, 12, ?",
    "choices": ["13", "14", "15", "18"],
    "answer_format": "single_choice",
    "display": {
      "kind": "text",
      "assets": []
    },
    "estimated_time_ms": 19200,
    "progress": {
      "answered": 0,
      "total": 30,
      "domain_answered": 0,
      "domain_total": 5
    }
  }
}
```

Public response must not include `answer_index`, `answer_value`, or internal variables.

### 12.3 Internal Generated Question Record

```json
{
  "question_id": "87f6d3b5-4e8c-5e82-b06e-2abf59a25a8b",
  "test_id": "test_123",
  "profile_id": "profile_123",
  "domain": "numerical",
  "type_code": "NR01",
  "level": 4,
  "age_group": "elementary_5_6",
  "seed": 192837465,
  "prompt": "다음 수열의 빈칸에 들어갈 수는? 3, 6, 9, 12, ?",
  "choices": ["13", "14", "15", "18"],
  "answer_index": 2,
  "answer_value": "15",
  "explanation": "각 항이 3씩 증가하므로 다음 값은 15입니다.",
  "explanation_steps": [
    "항 사이의 차이를 확인합니다.",
    "3, 6, 9, 12는 3씩 증가합니다.",
    "12에 3을 더하면 15입니다."
  ],
  "variables": {
    "start": 3,
    "diff": 3,
    "terms": [3, 6, 9, 12],
    "answer": 15
  },
  "question_signature": "sha256...",
  "metadata": {
    "generator_status": "implemented",
    "rule_version": "1.0.0",
    "difficulty_band": "medium_low"
  }
}
```

### 12.4 Submit Answer Request

```json
{
  "question_id": "87f6d3b5-4e8c-5e82-b06e-2abf59a25a8b",
  "selected_index": 2,
  "response_ms": 8200,
  "client_event_id": "evt_123"
}
```

Schema:

```json
{
  "type": "object",
  "required": ["question_id", "selected_index", "response_ms"],
  "properties": {
    "question_id": { "type": "string", "format": "uuid" },
    "selected_index": { "type": "integer", "minimum": 0, "maximum": 9 },
    "response_ms": { "type": "integer", "minimum": 0 },
    "client_event_id": { "type": "string" }
  }
}
```

### 12.5 Submit Answer Response

```json
{
  "correct": true,
  "domain": "numerical",
  "type_code": "NR01",
  "level_before": 4,
  "level_after": 5,
  "explanation": "각 항이 3씩 증가하므로 다음 값은 15입니다.",
  "next_action": "next_question"
}
```

`next_action` enum:

```text
next_question
domain_complete
test_complete
ad_gate
payment_required
report_ready
```

---

## 13. FastAPI Pydantic Models

```python
from typing import Any, Literal
from pydantic import BaseModel, Field

DomainCode = Literal[
    "numerical",
    "spatial",
    "logical",
    "verbal",
    "memory",
    "pattern",
]

TestType = Literal["basic", "advanced", "professional"]
AnswerFormat = Literal["single_choice"]
DisplayKind = Literal["text", "image", "text_image", "interactive"]

class QuestionDisplay(BaseModel):
    kind: DisplayKind = "text"
    assets: list[dict[str, Any]] = Field(default_factory=list)

class QuestionProgress(BaseModel):
    answered: int
    total: int
    domain_answered: int
    domain_total: int

class PublicQuestion(BaseModel):
    question_id: str
    domain: DomainCode
    type_code: str
    level: int = Field(ge=1, le=10)
    age_group: str
    seed: int
    prompt: str
    choices: list[str] = Field(min_length=2, max_length=10)
    answer_format: AnswerFormat = "single_choice"
    display: QuestionDisplay
    estimated_time_ms: int
    progress: QuestionProgress

class NextQuestionResponse(BaseModel):
    test_id: str
    question: PublicQuestion | None
    next_action: str = "next_question"

class SubmitAnswerRequest(BaseModel):
    question_id: str
    selected_index: int = Field(ge=0, le=9)
    response_ms: int = Field(ge=0)
    client_event_id: str | None = None

class SubmitAnswerResponse(BaseModel):
    correct: bool
    domain: DomainCode
    type_code: str
    level_before: int
    level_after: int
    explanation: str
    next_action: str
```

---

## 14. Flutter Data Structures

Flutter should treat question payload as immutable UI data.

```dart
enum CognitiveDomain {
  numerical,
  spatial,
  logical,
  verbal,
  memory,
  pattern,
}

enum AnswerFormat { singleChoice }

class QuestionProgress {
  const QuestionProgress({
    required this.answered,
    required this.total,
    required this.domainAnswered,
    required this.domainTotal,
  });

  final int answered;
  final int total;
  final int domainAnswered;
  final int domainTotal;

  factory QuestionProgress.fromJson(Map<String, dynamic> json) {
    return QuestionProgress(
      answered: json['answered'] as int,
      total: json['total'] as int,
      domainAnswered: json['domain_answered'] as int,
      domainTotal: json['domain_total'] as int,
    );
  }
}

class QuestionDisplay {
  const QuestionDisplay({
    required this.kind,
    required this.assets,
  });

  final String kind;
  final List<Map<String, dynamic>> assets;

  factory QuestionDisplay.fromJson(Map<String, dynamic> json) {
    return QuestionDisplay(
      kind: json['kind'] as String,
      assets: (json['assets'] as List<dynamic>? ?? const [])
          .cast<Map<String, dynamic>>(),
    );
  }
}

class TestQuestionDto {
  const TestQuestionDto({
    required this.questionId,
    required this.domain,
    required this.typeCode,
    required this.level,
    required this.ageGroup,
    required this.seed,
    required this.prompt,
    required this.choices,
    required this.answerFormat,
    required this.display,
    required this.estimatedTimeMs,
    required this.progress,
  });

  final String questionId;
  final CognitiveDomain domain;
  final String typeCode;
  final int level;
  final String ageGroup;
  final int seed;
  final String prompt;
  final List<String> choices;
  final AnswerFormat answerFormat;
  final QuestionDisplay display;
  final int estimatedTimeMs;
  final QuestionProgress progress;

  factory TestQuestionDto.fromJson(Map<String, dynamic> json) {
    return TestQuestionDto(
      questionId: json['question_id'] as String,
      domain: _domainFromJson(json['domain'] as String),
      typeCode: json['type_code'] as String,
      level: json['level'] as int,
      ageGroup: json['age_group'] as String,
      seed: json['seed'] as int,
      prompt: json['prompt'] as String,
      choices: (json['choices'] as List<dynamic>).cast<String>(),
      answerFormat: AnswerFormat.singleChoice,
      display: QuestionDisplay.fromJson(json['display'] as Map<String, dynamic>),
      estimatedTimeMs: json['estimated_time_ms'] as int,
      progress: QuestionProgress.fromJson(json['progress'] as Map<String, dynamic>),
    );
  }
}

CognitiveDomain _domainFromJson(String value) {
  return CognitiveDomain.values.firstWhere((domain) => domain.name == value);
}
```

Submit request:

```dart
class SubmitAnswerRequestDto {
  const SubmitAnswerRequestDto({
    required this.questionId,
    required this.selectedIndex,
    required this.responseMs,
    this.clientEventId,
  });

  final String questionId;
  final int selectedIndex;
  final int responseMs;
  final String? clientEventId;

  Map<String, dynamic> toJson() {
    return {
      'question_id': questionId,
      'selected_index': selectedIndex,
      'response_ms': responseMs,
      if (clientEventId != null) 'client_event_id': clientEventId,
    };
  }
}
```

Flutter must not require `answer_index` to render question UI.

---

## 15. Database Tables

### 15.1 question_templates

```sql
CREATE TABLE question_templates (
  id UUID PRIMARY KEY,
  domain TEXT NOT NULL,
  type_code TEXT NOT NULL,
  title TEXT NOT NULL,
  version TEXT NOT NULL,
  implemented BOOLEAN NOT NULL DEFAULT FALSE,
  min_level INT NOT NULL,
  max_level INT NOT NULL,
  allowed_age_groups JSONB NOT NULL,
  generator_rule_json JSONB NOT NULL,
  distractor_rule_json JSONB NOT NULL,
  explanation_template TEXT NOT NULL,
  active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(domain, type_code, version)
);
```

### 15.2 generated_questions

```sql
CREATE TABLE generated_questions (
  id UUID PRIMARY KEY,
  test_id UUID NOT NULL,
  profile_id UUID NOT NULL,
  domain TEXT NOT NULL,
  type_code TEXT NOT NULL,
  level INT NOT NULL,
  age_group TEXT NOT NULL,
  seed BIGINT NOT NULL,
  prompt TEXT NOT NULL,
  choices JSONB NOT NULL,
  answer_index INT NOT NULL,
  answer_value TEXT NOT NULL,
  explanation TEXT NOT NULL,
  explanation_steps JSONB NOT NULL,
  variables JSONB NOT NULL,
  metadata JSONB NOT NULL,
  question_signature TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX uq_generated_question_profile_type_seed
ON generated_questions(profile_id, type_code, seed);

CREATE INDEX ix_generated_questions_test_id
ON generated_questions(test_id);

CREATE INDEX ix_generated_questions_profile_signature_created
ON generated_questions(profile_id, question_signature, created_at);
```

### 15.3 responses

```sql
CREATE TABLE responses (
  id UUID PRIMARY KEY,
  test_id UUID NOT NULL,
  profile_id UUID NOT NULL,
  generated_question_id UUID NOT NULL,
  selected_index INT NOT NULL,
  correct BOOLEAN NOT NULL,
  response_ms INT NOT NULL,
  level_before INT NOT NULL,
  level_after INT NOT NULL,
  client_event_id TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

---

## 16. API Endpoints

### POST `/api/v1/tests/start`

Creates a test session and initializes CAT states.

### GET `/api/v1/tests/{test_id}/next-question`

Returns the next generated public question.

Backend must:

1. load test session.
2. select domain.
3. select type code.
4. generate seed.
5. check duplicate guard.
6. call generator.
7. persist internal question.
8. return public question.

### POST `/api/v1/tests/{test_id}/submit`

Scores a response, updates CAT state, and returns next action.

### POST `/api/v1/tests/{test_id}/complete`

Closes the test and computes report inputs.

---

## 17. Error Codes

| Code | HTTP | Meaning |
| --- | ---: | --- |
| `QUESTION_GENERATION_EXHAUSTED` | 409 | duplicate guard could not find valid new question |
| `UNKNOWN_TYPE_CODE` | 400 | generator registry has no matching type code |
| `TYPE_NOT_ALLOWED_FOR_AGE` | 400 | selected type is outside age constraints |
| `LEVEL_OUT_OF_RANGE` | 400 | requested level is invalid |
| `QUESTION_ALREADY_ANSWERED` | 409 | duplicate answer submission |
| `QUESTION_NOT_FOUND` | 404 | generated question not found for test |
| `TEST_ALREADY_COMPLETED` | 409 | test is closed |

---

## 18. Security and Integrity

- Client must never receive correct answer before submission.
- Client `seed` is informational and audit-friendly, not trusted.
- Server must validate every answer from persisted generated question.
- Ad and payment gates must be checked server-side before report access.
- Logs must avoid storing unnecessary child personal data.
- Admin changes to templates must be versioned and auditable.

---

## 19. Validation Checklist

For each new generator rule:

- deterministic with same seed.
- produces valid answer.
- produces unique choices.
- answer index matches answer value.
- obeys age group min/max.
- obeys level min/max.
- explanation references actual variables.
- no duplicate prompt signature within recent profile history.
- JSON serializes cleanly for Flutter.
- unit tests cover at least 20 seeds per level band.

Numerical MVP acceptance:

- NR01~NR20 registry exists.
- NR01, NR02, NR07, NR11, NR18 must be production-ready before Basic backend launch.
- all NR01~NR20 must have passing generator unit tests before Advanced launch.
- Professional launch requires item exposure statistics and CAT stability analysis.

---

## 20. Implementation Priority

Phase 1:

1. `QuestionGenerator` base interface.
2. `NumericalGenerator` with NR01, NR02, NR07, NR11, NR18.
3. Duplicate guard.
4. Public question JSON schema.
5. Flutter DTO integration.

Phase 2:

1. Complete NR03~NR20.
2. CAT state persistence.
3. Response-time-aware level adjustment.
4. Generator unit test matrix.

Phase 3:

1. Stub generators replaced with real domain specs.
2. Admin template registry.
3. Exposure balancing.
4. Professional CAT optimization.

