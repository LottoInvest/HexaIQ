import hashlib
import random
from dataclasses import dataclass

from .schemas import ChoiceDto, MetadataDto, QuestionDto


@dataclass(frozen=True)
class AgeBand:
    code: str
    min_level: int
    max_level: int
    number_max: int


AGE_BANDS = {
    "kindergarten": AgeBand("kindergarten", 1, 2, 20),
    "grade1_2": AgeBand("grade1_2", 2, 3, 50),
    "grade3_4": AgeBand("grade3_4", 3, 5, 200),
    "grade5_6": AgeBand("grade5_6", 5, 6, 1000),
    "middle": AgeBand("middle", 6, 8, 5000),
    "high": AgeBand("high", 7, 9, 10000),
    "adult": AgeBand("adult", 8, 10, 20000),
}


class QuestionEngine:
    def __init__(self) -> None:
        self.used: set[str] = set()

    def generate(
        self,
        *,
        profile_id: str,
        domain: str,
        type_code: str,
        age_group: str,
        level: int,
        seed: int | None = None,
        index: int = 0,
    ) -> QuestionDto:
        if domain != "numerical":
            return self._stub(domain, type_code, age_group, level, seed or 0)
        age = AGE_BANDS.get(age_group, AGE_BANDS["grade5_6"])
        level = max(age.min_level, min(age.max_level, level))
        seed = seed if seed is not None else self._seed(profile_id, type_code, index)
        rng = random.Random(seed + self._stable_hash(type_code))
        rule = getattr(self, f"_rule_{type_code.lower()}", self._rule_nr01)
        question, choices, answer, explanation, factors = rule(rng, level, age)
        return self._dto(
            domain="numerical",
            type_code=type_code,
            age_group=age.code,
            level=level,
            seed=seed,
            question=question,
            choices=choices,
            answer=answer,
            explanation=explanation,
            factors=factors,
        )

    def generate_batch(
        self,
        *,
        profile_id: str,
        domain: str,
        age_group: str,
        level: int,
        count: int,
    ) -> list[QuestionDto]:
        type_codes = [f"NR{i:02d}" for i in range(1, 21)]
        return [
            self.generate(
                profile_id=profile_id,
                domain=domain,
                type_code=type_codes[i % 20],
                age_group=age_group,
                level=level,
                index=i,
            )
            for i in range(count)
        ]

    def _dto(self, *, domain: str, type_code: str, age_group: str, level: int, seed: int,
             question: str, choices: list[str], answer: str, explanation: str,
             factors: list[str]) -> QuestionDto:
        keys = ["A", "B", "C", "D"]
        choice_dtos = [ChoiceDto(key=keys[i], text=choices[i]) for i in range(4)]
        answer_key = choice_dtos[choices.index(answer)].key
        return QuestionDto(
            id=hashlib.sha1(f"{domain}:{type_code}:{seed}:{question}".encode()).hexdigest(),
            domain=domain, typeCode=type_code, level=level, ageGroup=age_group,
            questionText=question, choices=choice_dtos, answerKey=answer_key,
            explanation=explanation, seed=seed, estimatedTimeSec=12 + level * 4,
            metadata=MetadataDto(rule=type_code, difficultyFactors=factors),
        )

    def _stub(self, domain: str, type_code: str, age_group: str, level: int, seed: int) -> QuestionDto:
        return self._dto(
            domain=domain, type_code=type_code, age_group=age_group, level=max(1, min(10, level)),
            seed=seed, question=f"{domain} 영역은 준비 중입니다.",
            choices=["준비 중", "보기 A", "보기 B", "보기 C"], answer="준비 중",
            explanation=f"{domain} 영역은 Stub 상태입니다.", factors=["stub", "coming_soon"],
        )

    def _choices(self, answer: int, candidates: list[int], rng: random.Random) -> list[str]:
        values = [answer]
        for value in candidates:
            if value >= 0 and value not in values:
                values.append(value)
        delta = 1
        while len(values) < 4:
            for value in (answer - delta, answer + delta):
                if value >= 0 and value not in values:
                    values.append(value)
                if len(values) == 4:
                    break
            delta += 1
        selected = [str(v) for v in values[:4]]
        rng.shuffle(selected)
        return selected

    def _seed(self, profile_id: str, type_code: str, index: int) -> int:
        raw = f"{profile_id}:{type_code}:{index}"
        seed = int(hashlib.sha256(raw.encode()).hexdigest()[:10], 16)
        key = f"{profile_id}:{type_code}:{seed}"
        retry = 0
        while key in self.used:
            retry += 1
            seed = int(hashlib.sha256(f"{raw}:{retry}".encode()).hexdigest()[:10], 16)
            key = f"{profile_id}:{type_code}:{seed}"
        self.used.add(key)
        return seed

    def _stable_hash(self, value: str) -> int:
        return int(hashlib.sha1(value.encode()).hexdigest()[:8], 16)

    def _rule_nr01(self, rng, level, age):
        d = rng.randint(1, level + 3); s = rng.randint(1, 10 + level)
        terms = [s + d * i for i in range(4)]; a = s + d * 4
        return f"다음 수열의 빈칸은? {', '.join(map(str, terms))}, ?", self._choices(a, [a+d, a-d, a+1], rng), str(a), f"{d}씩 증가합니다.", ["arithmetic_sequence"]

    def _rule_nr02(self, rng, level, age):
        r = rng.randint(2, 3 + level // 4); s = rng.randint(1, 5)
        terms = [s * (r ** i) for i in range(4)]; a = terms[-1] * r
        return f"다음 등비수열의 빈칸은? {', '.join(map(str, terms))}, ?", self._choices(a, [a+r, terms[-1]+r, a//r], rng), str(a), f"앞 항에 {r}을 곱합니다.", ["geometric_sequence"]

    def _rule_nr03(self, rng, level, age):
        s = rng.randint(1, 10); d = rng.randint(1, 4); step = rng.randint(1, 3)
        terms = [s]; diffs = []
        for i in range(4):
            diff = d + step * i; diffs.append(diff); terms.append(terms[-1] + diff)
        a = terms[-1] + d + step * 4
        return f"증가량이 변합니다. {', '.join(map(str, terms))}, ?", self._choices(a, [terms[-1]+diffs[-1], a+step, a-step], rng), str(a), "증가량이 일정하게 커집니다.", ["changing_increase"]

    def _rule_nr04(self, rng, level, age):
        s = rng.randint(40, 80); d = rng.randint(1, 5); step = rng.randint(1, 3)
        terms = [s]
        for i in range(4): terms.append(terms[-1] - (d + step * i))
        a = terms[-1] - (d + step * 4)
        return f"감소량이 변합니다. {', '.join(map(str, terms))}, ?", self._choices(a, [a+step, terms[-1]-d, a-1], rng), str(a), "감소량이 단계적으로 변합니다.", ["changing_decrease"]

    def _rule_nr05(self, rng, level, age):
        a, b, da, db = rng.randint(1, 9), rng.randint(10, 19), rng.randint(2, 5), rng.randint(2, 5)
        terms = [a, b, a+da, b+db, a+2*da, b+2*db]; ans = a+3*da
        return f"교차수열입니다. {', '.join(map(str, terms))}, ?", self._choices(ans, [b+3*db, ans+da, ans-1], rng), str(ans), "홀수 번째와 짝수 번째가 따로 변합니다.", ["alternating_sequence"]

    def _rule_nr06(self, rng, level, age):
        start = rng.randint(1, 10); odd_d = rng.randint(2, 5); even_d = rng.randint(3, 6)
        terms = [start, start+10, start+odd_d, start+10+even_d, start+2*odd_d, start+10+2*even_d]; ans = start+3*odd_d
        return f"홀짝 위치를 나누어 보세요. {', '.join(map(str, terms))}, ?", self._choices(ans, [ans+even_d, ans-odd_d, terms[-1]+even_d], rng), str(ans), "홀수 위치의 수만 따로 보면 규칙이 보입니다.", ["odd_even_split"]

    def _rule_nr07(self, rng, level, age):
        a, b = rng.randint(1, 4), rng.randint(1, 4); terms = [a, b]
        for _ in range(4): terms.append(terms[-1] + terms[-2])
        ans = terms[-1] + terms[-2]
        return f"피보나치형 수열입니다. {', '.join(map(str, terms))}, ?", self._choices(ans, [terms[-1]*2, ans+1, ans-terms[-2]], rng), str(ans), "앞의 두 수를 더해 다음 수를 만듭니다.", ["fibonacci_like"]

    def _rule_nr08(self, rng, level, age):
        n = rng.randint(2, 6); terms = [i*i for i in range(n, n+4)]; ans = (n+4)*(n+4)
        return f"제곱수 규칙입니다. {', '.join(map(str, terms))}, ?", self._choices(ans, [ans+1, (n+5)**2, ans-(n+4)], rng), str(ans), "연속된 자연수의 제곱입니다.", ["squares"]

    def _rule_nr09(self, rng, level, age):
        n = rng.randint(1, 4); terms = [i**3 for i in range(n, n+4)]; ans = (n+4)**3
        return f"세제곱수 규칙입니다. {', '.join(map(str, terms))}, ?", self._choices(ans, [ans+1, (n+5)**3, ans-(n+4)], rng), str(ans), "연속된 자연수의 세제곱입니다.", ["cubes"]

    def _rule_nr10(self, rng, level, age):
        primes = [2,3,5,7,11,13,17,19,23,29,31]; i = rng.randint(0, 5); terms = primes[i:i+4]; ans = primes[i+4]
        return f"소수 규칙입니다. {', '.join(map(str, terms))}, ?", self._choices(ans, [ans+2, ans-2, ans+4], rng), str(ans), "1과 자기 자신으로만 나누어지는 소수의 순서입니다.", ["prime_sequence"]

    def _rule_nr11(self, rng, level, age):
        m = rng.randint(2, 9); k = rng.randint(2, 5); terms = [m*(k+i) for i in range(4)]; ans = m*(k+4)
        return f"{m}의 배수 규칙입니다. {', '.join(map(str, terms))}, ?", self._choices(ans, [ans+m, ans-1, ans+m+1], rng), str(ans), f"{m}의 배수가 이어집니다.", ["multiple_rule"]

    def _rule_nr12(self, rng, level, age):
        n = rng.choice([12,18,24,30,36]); divisors = [d for d in range(1, n+1) if n % d == 0]; ans = divisors[-2]
        return f"{n}의 약수 중 두 번째로 큰 수는?", self._choices(ans, [n, divisors[1], ans-1], rng), str(ans), f"{n}의 약수를 모두 찾은 뒤 비교합니다.", ["divisor_rule"]

    def _rule_nr13(self, rng, level, age):
        mod = rng.randint(3, 9); n = rng.randint(20, 80); ans = n % mod
        return f"{n}을 {mod}로 나눈 나머지는?", self._choices(ans, [mod-ans, ans+1, mod], rng), str(ans), "나눗셈의 나머지를 계산합니다.", ["remainder_rule"]

    def _rule_nr14(self, rng, level, age):
        a,b,c = rng.randint(2,9), rng.randint(2,9), rng.randint(1,9); ans = a*b+c
        return f"{a} × {b} + {c} = ?", self._choices(ans, [a*(b+c), a+b+c, ans-c], rng), str(ans), "곱셈을 먼저 하고 덧셈을 합니다.", ["operation_order"]

    def _rule_nr15(self, rng, level, age):
        a,b,c = rng.randint(1,9), rng.randint(1,9), rng.randint(1,9); ans = a+b+c
        return f"2x2 행렬: [{a}, {b}; {c}, ?] 에서 ?가 세 수의 합이면?", self._choices(ans, [a+b, b+c, ans+1], rng), str(ans), "나머지 세 칸의 합을 구합니다.", ["matrix_2x2"]

    def _rule_nr16(self, rng, level, age):
        row = [rng.randint(1,9) for _ in range(3)]; ans = sum(row)
        return f"3x3 행렬의 한 행이 {row[0]}, {row[1]}, {row[2]}일 때 행 합은?", self._choices(ans, [ans+row[0], ans-1, row[0]*row[1]], rng), str(ans), "행의 세 수를 모두 더합니다.", ["matrix_3x3"]

    def _rule_nr17(self, rng, level, age):
        target = rng.randint(12, 24); a,b = rng.randint(1,9), rng.randint(1,9); ans = target-a-b
        return f"마방진 한 줄의 합이 {target}입니다. {a}, {b}, ? 에서 ?는?", self._choices(ans, [target-a, target-b, ans+1], rng), str(ans), "한 줄의 합이 같아야 하므로 빠진 값을 계산합니다.", ["magic_square"]

    def _rule_nr18(self, rng, level, age):
        x = rng.randint(2, 20); a = rng.randint(2, 5); b = rng.randint(1, 9); result = a*x+b
        return f"{a}x + {b} = {result}일 때 x는?", self._choices(x, [result//a, x+b, a+b], rng), str(x), "먼저 더한 값을 빼고 계수로 나눕니다.", ["conditional_equation"]

    def _rule_nr19(self, rng, level, age):
        a,b,k = rng.randint(2,5), rng.randint(6,12), rng.randint(2,6); ans = b*k
        return f"{a}:{b} = {a*k}:? 일 때 ?는?", self._choices(ans, [a*k+b, ans-k, ans+b], rng), str(ans), "같은 비율을 유지하도록 같은 배수를 곱합니다.", ["ratio_reasoning"]

    def _rule_nr20(self, rng, level, age):
        a,b,c = rng.randint(2,9), rng.randint(2,5), rng.randint(3,12); ans = a*b+c
        return f"숫자 퍼즐: 시작 수 {a}, 규칙은 ×{b} 후 +{c}입니다. 결과는?", self._choices(ans, [a+b+c, a*(b+c), ans-c], rng), str(ans), "규칙을 순서대로 적용합니다.", ["number_puzzle"]
