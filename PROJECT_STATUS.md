# Project Status

Development root: `outputs/HexaIQ`

Latest checkpoint: `v0.2.0_Question_Engine_Core_Checkpoint`

Date: 2026-06-29

## Status

Safe continuation point. The project is ready for another developer to open `outputs/HexaIQ` and continue from the current Flutter MVP baseline.

## What Exists

- Flutter project scaffold with Android, iOS, and web platform folders.
- Material 3 app shell.
- Responsive phone/tablet layout support through `ResponsivePage` and `LayoutBreakpoints`.
- Provider state object: `HexaIQAppState`.
- Mock repository implementing profiles, questions, reports, growth history, rewarded ad verification, and payment verification.
- Complete mock MVP navigation path:
  - Splash
  - Onboarding
  - Profile Select
  - Profile Create
  - Home Dashboard
  - Test Type Select
  - Test Intro
  - Question
  - Domain Complete
  - Reward Ad
  - Payment
  - Analysis Loading
  - Report Summary
  - Hexagon Detail
  - Domain Detail
  - Growth Dashboard
  - Training Recommendation
  - Settings
- Reference design documents in `docs/`, including:
  - `HexaIQ_Master_Design_Spec_v1.0.md`
  - `Question_Engine_Master_Specification_v1.0.md`
  - `HexaIQ_MVP_Execution_Roadmap.md`
  - `HexaIQ_Codex_Build_Instructions.md`
- Question Engine Core implementation:
  - `QuestionEngine`
  - `QuestionGenerator`
  - `QuestionValidator`
  - `SeedManager`
  - `DifficultyManager`
  - `AgeMapper`
  - `GeneratorFactory`
  - `NumericalGenerator` with NR01~NR20
  - Stub generators for Spatial, Logical, Verbal, Memory, Pattern
  - `MockQuestionApi` connected to the Flutter question flow
- FastAPI mock implementation:
  - `backend_fastapi/app/question_engine/engine.py`
  - `backend_fastapi/app/question_engine/router.py`
  - `POST /api/v1/question-engine/generate`
  - `POST /api/v1/question-engine/generate-batch`
- Shared contract:
  - `question_engine/question_dto_schema.json`
- Generated NR01~NR20 sample output:
  - `outputs/numerical_samples_NR01_NR20.json`
- Numerical question quality review output:
  - `outputs/numerical_quality_review_report.md`

## Current Architecture

```text
lib/
  app/
    app_router.dart
    app_routes.dart
  core/
    responsive/
    theme/
    widgets/
  features/
    ads/
    growth/
    hexaiq/
      data/
      domain/
      presentation/
    payment/
    report/
    settings/
    test/
    training/
```

## Verification

The project was verified after Question Engine implementation and numerical sample quality refinement:

```text
flutter analyze: No issues found.
flutter test: All tests passed. 8 tests total.
flutter run -d chrome: Launch successful in debug mode.
python import test: QuestionEngine generate and batch generation passed.
NR01~NR20 sample validation: 400 samples, 0 DTO/choice/answer/explanation errors.
```

## Known Constraints

- Backend is not implemented in this Flutter project.
- Authentication is not connected.
- AdMob, billing, analytics, Crashlytics, and storage are mock placeholders.
- Report scoring is mock logic and must not be treated as a validated assessment result.
- Current tests are smoke tests only.
- The project folder is not a Git repository.
- Numerical question quality is rule-validated, not psychometrically calibrated.

## Handoff Rule

All future work should start from `outputs/HexaIQ` unless the user explicitly requests another base.
