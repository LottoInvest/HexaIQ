# Question Engine TODO

## Next Priority

1. Replace remaining legacy Korean text in older MVP screens and generated explanations where needed.
2. Port the complete Dart Numerical rules to the FastAPI implementation if backend parity is required before API testing.
3. Add persistent duplicate tracking in PostgreSQL:
   - `profile_id + type_code + seed`
   - 90-day recent-use window
   - question signature guard
4. Expand QuestionQualityValidator with item exposure and response-time calibration.
5. Add API integration repository in Flutter:
   - `QuestionEngineRepository`
   - `MockQuestionEngineRepository`
   - `ApiQuestionEngineRepository`
6. Add golden/sample tests for each NR type at multiple age groups.
7. Implement real Spatial, Logical, Verbal, Memory, and Pattern generators after Numerical validation.

## Product Safety

- Keep all report language as "인지능력 참고 지표".
- Do not expose answers before submission in real API responses.
- Avoid "IQ 확정값" wording.
