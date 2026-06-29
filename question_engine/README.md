# HexaIQ Question Engine Shared Contract

This folder stores shared Question Engine contracts that both Flutter and FastAPI should follow.

- `question_dto_schema.json`: canonical JSON DTO schema.
- Flutter implementation: `lib/features/question_engine`.
- FastAPI mock implementation: `backend_fastapi/app/question_engine`.

MVP status:

- Numerical domain: implemented.
- Spatial, Logical, Verbal, Memory, Pattern: stub only.
