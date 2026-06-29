# HexaIQ Codex Build Instructions

이 문서는 Codex 또는 개발자가 HexaIQ를 구현할 때 따라야 할 작업 지시서다.

## 1. 기본 방향

Flutter 앱과 FastAPI 백엔드를 분리해 개발한다. 앱은 Android/iOS와 Phone/Tablet을 단일 코드베이스에서 지원한다. 서버는 인증 검증, 프로필 제한, 문제 생성, 채점, 광고/결제 검증, 리포트 생성, 성장 기록을 담당한다.

## 2. 권장 저장소 구조

```text
hexaiq/
  apps/
    mobile/
      lib/
        core/
        features/
          auth/
          profile/
          test/
          report/
          growth/
          training/
          store/
          settings/
        shared/
    admin/
  services/
    api/
      app/
        api/
        core/
        models/
        schemas/
        services/
        repositories/
        question_engine/
        cat/
        report/
        admin/
      tests/
  docs/
```

## 3. Flutter 구현 규칙

- Material 3 사용
- Phone은 bottom navigation 사용
- Tablet은 navigation rail 또는 sidebar 사용
- LayoutBuilder로 600dp, 840dp 기준 분기
- feature-first 구조 유지
- 상태관리는 Riverpod 또는 Bloc 중 하나로 통일
- API 모델은 서버 OpenAPI에서 생성하거나 수동 모델을 공통 규칙으로 관리
- 검사 화면은 네트워크 오류와 앱 백그라운드 전환을 견딜 수 있어야 함

필수 테스트:

- 프로필 생성/수정 widget test
- 검사 진행 navigation test
- 문제 선택/제출 widget test
- 리포트 화면 snapshot 또는 golden test
- offline/retry handling test

## 4. Backend 구현 규칙

- FastAPI + PostgreSQL + Redis
- Alembic migration 필수
- 모든 API는 `/api/v1` prefix 사용
- Pydantic schema로 요청/응답 검증
- Repository Pattern 사용
- 광고/결제 결과는 서버에서 검증
- 문제 생성 seed와 응답 로그는 반드시 저장

필수 테스트:

- API unit test
- DB migration test
- question generation test
- CAT level adjustment test
- duplicate seed prevention test
- payment validation test
- ad reward validation test

## 5. 초기 API 작업 순서

1. `GET /api/v1/health`
2. `POST /api/v1/auth/login`
3. `GET /api/v1/auth/me`
4. `GET /api/v1/profiles`
5. `POST /api/v1/profiles`
6. `PUT /api/v1/profiles/{profile_id}`
7. `DELETE /api/v1/profiles/{profile_id}`
8. `POST /api/v1/tests/start`
9. `GET /api/v1/tests/{test_id}/next-question`
10. `POST /api/v1/tests/{test_id}/submit`
11. `POST /api/v1/tests/{test_id}/complete`
12. `GET /api/v1/reports/{test_id}`
13. `GET /api/v1/profiles/{profile_id}/growth`

## 6. DB 우선 테이블

1. users
2. profiles
3. tests
4. test_domain_scores
5. question_templates
6. generated_questions
7. responses
8. growth_history
9. ad_rewards
10. purchases
11. recommendations

## 7. 문제 엔진 MVP

처음부터 6영역 x 20유형 전체를 만들지 말고, 앱 흐름 검증용으로 영역당 3~5개 유형을 먼저 구현한다. 단, 구조는 최종적으로 영역당 20개 이상으로 확장 가능해야 한다.

공통 출력:

```json
{
  "question_id": "uuid",
  "domain": "numerical",
  "type_code": "NR01",
  "level": 5,
  "question_text": "다음 수열의 빈칸에 들어갈 수는?",
  "choices": ["12", "14", "16", "18"],
  "answer": "16",
  "explanation": "각 항이 2씩 증가합니다.",
  "seed": 123456
}
```

중복 방지:

- `profile_id + type_code + seed` 저장
- 최근 90일 내 동일 조합 재사용 금지

## 8. 리포트 문구 금지 사항

금지:

- "IQ가 낮습니다"
- "지능이 부족합니다"
- "또래보다 뒤처집니다"
- "진단 결과"
- "확정 판정"

권장:

- "이번 검사에서는 이런 경향이 보입니다"
- "학습 참고 지표로 활용할 수 있습니다"
- "이 영역은 짧고 반복적인 훈련이 도움이 될 수 있습니다"
- "동일 연령대 기준 참고 백분위입니다"

## 9. Phone/Tablet 구현 체크리스트

Phone:

- 하단 탭
- 단일 컬럼
- 엄지 조작 가능한 주요 버튼 위치
- 문제 화면에서 보기 버튼 충분한 높이

Tablet:

- 사이드 내비게이션
- 2열 대시보드
- 리포트 그래프와 상세 패널 동시 표시
- 성장 그래프와 타임라인 동시 표시
- 가로/세로 회전 대응

공통:

- SafeArea 적용
- 텍스트 겹침 없음
- 큰 글자 접근성 대응
- 광고/결제 화면에서 뒤로가기 처리

## 10. 출시 전 검수

Android:

- Google Play Internal Testing
- AdMob 테스트 광고와 실제 광고 분리
- Google Play Billing sandbox 검증

iOS:

- TestFlight
- StoreKit sandbox 검증
- iPad screenshot 준비

공통:

- 개인정보 처리방침
- 이용약관
- 데이터 삭제 요청 경로
- 아동/청소년 대상 표현 검수
- Crashlytics
- Analytics 이벤트 검수

## 11. Codex 작업 원칙

- 기능 단위로 작은 PR을 만든다.
- 기존 구조를 임의로 바꾸지 않는다.
- 문제를 하드코딩하지 않는다.
- 광고/결제는 클라이언트만 신뢰하지 않는다.
- 테스트 없이 핵심 로직을 완료 처리하지 않는다.
- 문서와 OpenAPI를 구현과 함께 갱신한다.
