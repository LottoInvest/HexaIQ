# TODO

Checkpoint baseline: `v0.2.0_Question_Engine_Core_Checkpoint`

## Next Recommended Steps

1. Add Git initialization or copy this checkpoint into the target repository.
2. Replace mock repository calls with API client boundaries.
3. Define backend contracts for profiles, tests, questions, submissions, reports, growth, ads, and purchases.
4. Add persistent local storage for selected profile and unfinished tests.
5. Expand widget tests for profile creation, test flow, ad gate, report rendering, and tablet layout.
6. Add integration tests for the full Basic test flow.
7. Add backend persistence for generated question history and 90-day seed reuse prevention.
8. Add psychometric calibration data for Numerical domain difficulty tuning.
9. Add real rewarded ad integration with server-side verification.
10. Add real in-app purchase flow with receipt validation and restore purchase.
11. Add analytics events:
    - `app_open`
    - `profile_created`
    - `test_started`
    - `question_answered`
    - `test_completed`
    - `report_viewed`
    - `ad_started`
    - `ad_completed`
    - `ad_failed`
12. Add privacy policy, terms, account deletion, and data deletion paths before release.
13. Review all Korean UX copy before public testing.
14. Prepare app icon, splash assets, Play Store metadata, and TestFlight metadata.
15. Decide whether web support should remain a supported MVP target or only serve as a local smoke-run target.

## Code Areas To Improve

- `lib/features/hexaiq/data/mock_hexaiq_repository.dart`: Replace with repository backed by generated or typed API client.
- `lib/features/hexaiq/presentation/state/hexaiq_app_state.dart`: Split when backend, auth, and persistence are added.
- `lib/features/report/presentation`: Add richer domain-specific explanations and safer non-diagnostic language.
- `test/widget_test.dart`: Expand beyond startup smoke tests.

## Do Not Forget

- Keep report wording as a learning reference, not a diagnosis.
- Keep ad and payment verification server-side when real integrations begin.
- Preserve phone/tablet responsive behavior as screens become richer.
