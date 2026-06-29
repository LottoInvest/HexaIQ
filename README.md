# HexaIQ Flutter MVP

Development root: `outputs/HexaIQ`

HexaIQ is a Flutter MVP scaffold for a six-domain cognitive ability app. This project folder is the active continuation point for the current MVP work and contains a working mock-only mobile/tablet/web flow.

## Current Scope

- Flutter Material 3 app for Android, iOS, web, phone, and tablet layouts.
- Provider-based app state with a mock repository.
- Profile selection and profile creation.
- Test type selection for Basic, Advanced, and Professional.
- Mock question flow across six cognitive domains.
- Domain completion, rewarded-ad gate, mock payment gate, analysis loading, report summary, domain detail, hexagon detail, growth dashboard, training recommendations, and settings.
- Widget smoke tests for splash and onboarding navigation.

## Project Root

This Flutter app lives at:

```text
outputs/HexaIQ
```

Reference design documents live at:

```text
docs/
```

## How To Run

From this directory:

```powershell
$env:PATH='C:\Windows\System32;C:\Windows;C:\Windows\System32\WindowsPowerShell\v1.0;C:\Program Files\Git\cmd;C:\Program Files\Git\bin;' + $env:PATH
& "C:\Users\madne\Documents\Codex\flutter-sdk\bin\flutter.bat" pub get
& "C:\Users\madne\Documents\Codex\flutter-sdk\bin\flutter.bat" run -d chrome
```

## Verification Commands

```powershell
$env:PATH='C:\Windows\System32;C:\Windows;C:\Windows\System32\WindowsPowerShell\v1.0;C:\Program Files\Git\cmd;C:\Program Files\Git\bin;' + $env:PATH
& "C:\Users\madne\Documents\Codex\flutter-sdk\bin\flutter.bat" analyze
& "C:\Users\madne\Documents\Codex\flutter-sdk\bin\flutter.bat" test
```

Latest verification at checkpoint creation:

- `flutter analyze`: No issues found.
- `flutter test`: 2 tests passed.
- `flutter run -d chrome`: launched successfully in debug mode.

## Important Notes For Next Developer

- This is not connected to a backend yet. All data comes from `lib/features/hexaiq/data/mock_hexaiq_repository.dart`.
- The current route map is in `lib/app/app_router.dart` and `lib/app/app_routes.dart`.
- Shared UI helpers live under `lib/core`.
- Feature screens live under `lib/features`.
- Question Engine design lives in `docs/Question_Engine_Master_Specification_v1.0.md`.
- The app directory is not currently a Git repository. Treat `outputs/HexaIQ` as the active development root going forward.
