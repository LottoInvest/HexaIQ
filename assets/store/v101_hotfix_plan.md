# v1.0.1 Launch Hotfix + Production Monitoring Plan

v1.0.1은 새 기능 추가 버전이 아니라 출시 직후 안정화 버전입니다.

## 우선순위

- P0: 앱 실행 불가, 검사 시작 불가, 결과 화면 진입 불가, 결제 후 전문 검사 접근 불가
- P1: 광고 실패 후 진행 중단, PDF 생성 실패, 특정 문항 렌더링 실패, 작은 화면 overflow
- P2: 문구 개선, 스크린샷 개선, 리뷰 응답 템플릿 보완

## 모니터링 대상

- Play Console Android vitals
- 사용자 리뷰
- 사용자 문의
- 광고 실패 로그
- 결제 취소/실패/복원 흐름
- PDF 생성 실패
- Pattern Pack validator 실패

## Hotfix 금지 범위

- 신규 검사 유형
- 점수 계산식 대규모 변경
- 문제 포맷 변경
- 광고 위치 변경
- 결제 상품 구조 변경
- 리포트 전면 개편
