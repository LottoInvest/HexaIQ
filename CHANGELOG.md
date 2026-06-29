# Changelog

## v0.2.0_Question_Engine_Core_Checkpoint - 2026-06-29

### Added

- Added shared Question DTO schema under `question_engine/`.
- Added FastAPI mock Question Engine implementation under `backend_fastapi/app/question_engine`.
- Added FastAPI mock endpoints:
  - `POST /api/v1/question-engine/generate`
  - `POST /api/v1/question-engine/generate-batch`
- Added Flutter repository preparation layer:
  - `QuestionEngineRepository`
  - `MockQuestionEngineRepository`
  - `ApiQuestionEngineRepository`
- Added Question Engine output files:
  - `outputs/numerical_samples_NR01_NR20.json`
  - `outputs/question_engine_implementation_summary.md`
  - `outputs/question_engine_todo.md`
- Added numerical question quality review report:
  - `outputs/numerical_quality_review_report.md`
- Saved checkpoint folder `v0.2.0_Question_Engine_Core_Checkpoint`.

### Changed

- Updated Question DTO to use `questionText`, keyed choices, `answerKey`, `estimatedTimeSec`, and `metadata`.
- Rewrote NumericalGenerator with clean NR01~NR20 rules matching the implementation brief.
- Improved NR10, NR15, NR16, and NR20 generation rules after sample quality review.
- Regenerated NR01~NR20 samples from 10 per type to 20 per type, 400 samples total.

### Verified

- `flutter analyze`: No issues found.
- `flutter test`: All tests passed, 8 tests total.
- Python import test: QuestionEngine single and batch generation passed.
- NR01~NR20 sample validation: 400 samples, 0 DTO/choice/answer/explanation errors.

## Question Engine Core Implementation - 2026-06-29

### Added

- Implemented Question Engine Core for the Flutter MVP codebase.
- Added JSON-oriented DTOs for generated questions.
- Added `QuestionGenerator` interface.
- Added `QuestionEngine`, `QuestionValidator`, `SeedManager`, `DifficultyManager`, `AgeMapper`, and `GeneratorFactory`.
- Implemented `NumericalGenerator` with NR01~NR20 generation rules.
- Added Stub generators for Spatial, Logical, Verbal, Memory, and Pattern domains.
- Added `MockQuestionApi` and connected it to `MockHexaIQRepository`.
- Added Question Engine tests.
- Generated `docs/question_engine_nr01_nr20_samples.json` with 10 samples per NR type.

### Verified

- `flutter analyze`: No issues found.
- `flutter test`: All tests passed, 5 tests total.

## Active HexaIQ Project Handoff - 2026-06-29

### Added

- Created `outputs/HexaIQ` as the active project folder for continuing development.
- Copied the verified Flutter MVP checkpoint into this folder.
- Added design documents under `docs/`, including the Question Engine master specification.

### Verified

- This folder should be used as the working root for future tasks.

## v0.1.0_Flutter_MVP_Checkpoint - 2026-06-29

### Added

- Saved the current project as the named Flutter MVP checkpoint.
- Added Flutter web platform files so the current checkpoint can be run on the connected Chrome target.
- Added up-to-date handoff documentation:
  - `README.md`
  - `PROJECT_STATUS.md`
  - `TODO.md`
  - `CHANGELOG.md`
- Added complete mock Flutter MVP navigation flow:
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
- Added mock six-domain question and report data.
- Added smoke widget tests for startup and onboarding navigation.

### Fixed

- Repaired broken Korean strings and invalid Dart syntax left by the interrupted generation.
- Restored route targets that were referenced by the router but missing from the file tree.
- Fixed splash timer disposal so widget tests finish safely.
- Fixed Flutter analyzer issues.

### Verified

- `flutter analyze`: No issues found.
- `flutter test`: All tests passed.
- `flutter run -d chrome`: Launch successful in debug mode.

### Notes

- This checkpoint is mock-only and has no backend integration.
- The project folder is not currently a Git repository.
