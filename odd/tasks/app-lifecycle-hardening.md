# App Lifecycle Hardening

## Objective

Make startup, local storage, authentication/routing, app-resume restoration, and supported Web code paths reliable without losing existing user data or changing the app's remote-sync policy.

## Problem and rationale

The read-only map confirmed that `main()` runs the app even when `initStorage()` catches initialization errors; Hive opening paths disagree about encryption and include delete-and-recreate fallbacks; registered auth/establishment providers are not consumed while login calls the service directly and routes have no auth guard; no resume lifecycle flow exists; and routed import/edit screens use `dart:io` despite `GUIDE.md` listing Web as a supported platform. These gaps can leave the UI running against unavailable storage, risk user data, split session state, fail to refresh local state after resume, or prevent Web compilation.

## Authorized scope

- Repair the confirmed app-map findings above and add regression tests.
- On app resume, restore/re-read local persisted state only. DIGEMID synchronization remains a deliberate **manual user action**; resume must not initiate remote calls.
- Keep existing user data and current credential/product behavior. Do not broaden this work into a new login, account creation, or credential policy.
- Web is in scope: `GUIDE.md` lists Windows, Android, and Web, and app-routed code includes direct `dart:io` references.
- The planning-only restriction above applied to the initial planning phase and is now historical: the user selected `stacked-to-main` and authorized ALH-01 and ALH-02. ALH-01 is recorded in commit `5a73874`; ALH-02 is recorded in commit `2d6ca52`. The user has now authorized ALH-03 as the next task; ALH-04 and ALH-05 follow in order. The current uncommitted `analysis_options.yaml` and `pubspec.lock` changes are user-owned and must be preserved and excluded from future commits. Push, PR creation, and merge remain separate user decisions.

## Constraints and unresolved decisions

- Never delete/recreate Hive boxes as an error recovery strategy, reset storage, or guess an encryption migration. If an existing box cannot safely be opened, preserve it and fail safely. Any migration for legacy or mixed-cipher boxes remains an explicit owner decision; implementation must not infer one.
- Preserve established DIGEMID operation behavior; no automatic/background remote synchronization on resume.
- Do not change credential semantics or determine a new signed-in landing experience beyond what the existing stored-session behavior supports. If implementation requires a product choice, stop and surface it rather than inventing behavior.

## Delivery mode

- **TDD:** test-first, as previously selected. Add the focused regression test(s), run them to demonstrate the relevant failure, implement the smallest safe fix, then rerun focused tests and the full suite.
- **Test runner:** `flutter test`.
- **Baseline:** clean worktree on `feature/app-lifecycle-hardening`, HEAD `81d48f901270a59e93fc06f8dc248e8833cb273e`.
- **Skill resolution:** `paths-injected` (`work-unit-commits` loaded; no other project skills matched).

## Delivery strategy

- **Chain strategy:** **Apiladas a main** (`stacked-to-main`), as selected by the user.
- **Execution order update:** per the user's latest direction, perform ALH-03, then ALH-04, then ALH-05. The earlier deferral of ALH-03 is superseded by the user's explicit re-authorization.
- Implement the proposed slices as ordered work units. If PR creation and merging are separately authorized, stack them and merge each to `main` in the order listed below before merging the next one.
- The chain strategy records the intended order only; it does **not** authorize push, PR creation, or merge. Push, PR creation, and merge remain user decisions. No PR will be created or merged here.
- Create local work-unit commits on the current feature branch as authorized ODD behavior; this does not authorize pushing those commits.
- **Delivery strategy:** retain the ODD default, **ask-on-risk**. Surface material risks or decisions that cannot be resolved within the stated constraints; do not pause for routine implementation choices.

## Tasks

- [x] **ALH-01 — Make storage initialization a real startup gate.**
  - **Implementation route:** `delegated`.
  - **Task routing trigger:** multi-file, non-trivial writer; preparation requires reading across 4+ files.
  - **Route:** `lib/main.dart`, `lib/src/services/storage_service.dart`; startup/storage tests under `test/`.
  - **Trigger evidence:** `main()` awaits `initStorage()` before `runApp()`, but `initStorage()` catches and logs failures (including Hive init/key/box failures) and returns normally.
  - **Done when:** tests prove startup cannot present the normal app as ready after required storage initialization fails; the failure is observable through a safe startup/error path and does not silently continue with partially initialized storage.
  - **Outcome:** `initStorage()` now propagates failures; `main()` launches either the normal app after successful initialization or a standalone visible startup-failure screen. The storage service's startup box opener no longer deletes/recreates a box after an open failure, so unsafe or incompatible data remains blocked and the error propagates. Other independent Hive-opening paths remain in ALH-02 scope.
  - **Changed files:** `lib/main.dart`, `lib/src/services/storage_service.dart`, `test/storage_startup_test.dart`.
  - **TDD evidence:** RED — `flutter test test/storage_startup_test.dart` failed as expected because `initStorage()` swallowed the injected path-provider `PlatformException`. GREEN — `flutter test --no-pub test/storage_startup_test.dart` passed (2 tests); `flutter test --no-pub` passed (8 tests).
  - **Additional checks:** `flutter analyze --no-pub` — no issues; `dart format lib/main.dart lib/src/services/storage_service.dart test/storage_startup_test.dart` — final run formatted 0 files.
  - **Runtime harness:** widget test in `test/storage_startup_test.dart` exercised the failed-startup UI and verified the login route was absent; no device/app launch was run.
  - **Authored change count:** +97 / -29 lines (126 authored changed lines for ALH-01 implementation and regression tests).
  - **Commit identity:** `5a73874` — `fix(storage): fail safely during app startup`.
  - **Commit stats:** +209 / -29 = 238 authored changed lines.
  - **RDD assessment:** mode on; native assessment against base `81d48f901270a59e93fc06f8dc248e8833cb273e` returned risk `medium`, `review_due: false`, reason `under_budget`, and `changed_lines: 238` (commit assessment includes the task document).
  - **Boundary status:** the per-commit assessment was under budget and did not make review due; the later cumulative review resolution is recorded below.

- [x] **ALH-02 — Unify Hive access and make recovery non-destructive.**
  - **Implementation route:** `delegated`.
  - **Task routing trigger:** multi-file, non-trivial writer; preparation requires reading across 4+ files.
  - **Route:** `lib/src/services/storage_service.dart`, `lib/src/services/hive_helper.dart`, plus direct Hive-opening call sites in `lib/src/screens/{import_catalog_screen.dart,import_report_screen.dart,export_csv_screen.dart,sync_screen.dart,edit_screen.dart}`; storage tests under `test/`.
  - **Trigger evidence:** ALH-01 changed the storage-service opener to propagate failures without deleting boxes; `hive_helper.dart` and routed screens previously opened boxes without the shared AES cipher, and fallback paths could use unscoped plaintext boxes.
  - **Done when:** app box access follows one explicit, tested policy; failure never deletes/recreates a user's box; tests establish that incompatible existing data remains untouched and the failure is surfaced. No encryption migration is performed without an explicit approved policy.
  - **Outcome:** `openStorageBox` is the sole app opener and applies the persisted AES key, with crash recovery disabled so a cipher/checksum mismatch cannot truncate existing files. `HiveHelper` delegates all opens to it; screen, widget, and utility accesses use the helper, and unscoped plaintext fallbacks and delete/recreate recovery were removed. If a key is missing while the active user's boxes already exist, initialization fails before generating a replacement key. No legacy data is migrated or deleted.
  - **Changed files:** `lib/src/services/storage_service.dart`, `lib/src/services/hive_helper.dart`, `lib/src/screens/{edit_screen.dart,export_csv_screen.dart,import_catalog_screen.dart,import_report_screen.dart,sync_screen.dart}`, `lib/src/widgets/catalog_search_dialog.dart`, `lib/src/utils/price_utils.dart`, `test/storage_box_policy_test.dart`.
  - **TDD evidence:** RED — `flutter test --no-pub test/storage_box_policy_test.dart` initially showed helper opens used plaintext (returned a box where encrypted open should fail) and missing keys were generated despite existing data. GREEN — `flutter test --no-pub test/storage_box_policy_test.dart` passed (3 tests), proving encrypted persistence/idempotent open, unchanged bytes after cipher mismatch, and no replacement key/data loss when a key is missing.
  - **Additional checks:** `flutter test --no-pub` — all 11 tests passed; `flutter analyze --no-pub` — no issues; `dart format lib/src/services/storage_service.dart lib/src/services/hive_helper.dart lib/src/screens/import_catalog_screen.dart lib/src/screens/import_report_screen.dart lib/src/screens/export_csv_screen.dart lib/src/screens/sync_screen.dart lib/src/screens/edit_screen.dart lib/src/widgets/catalog_search_dialog.dart lib/src/utils/price_utils.dart test/storage_box_policy_test.dart` — final run formatted 0 files.
  - **Runtime harness:** Hive storage tests use temporary directories and mocked secure storage; no app/device launch or DIGEMID sync was run.
  - **Commit identity:** `2d6ca52` — `fix(storage): unify encrypted Hive access`.
  - **Commit stats:** +438 / -280 = 718 authored changed lines.
  - **Cumulative RDD assessment:** mode on; assessment of the committed range from base `81d48f901270a59e93fc06f8dc248e8833cb273e` returned risk `medium`, `review_due: true`, reason `slice_budget_reached`, and native `changed_lines: 926`. This native metric is distinct from the authored add/delete total.
  - **Native review resolution:** `gentle-ai.review-acknowledged/v1`; action `acknowledged`; authority `burned`; lineage `review-73a014fbf928928b`; target `sha256:484e9595ea588af6e6976a94029c06c995ccc10a87b117ff503778b085cafdf5`. The final admitted `review-reliability` capture had no findings; review is terminal. This records no delivery authority.
  - **Public follow-up:** one sanitized occurrence comment was posted to canonical open issue [#5094](https://github.com/Gentleman-Programming/gentle-ai/issues/5094#issuecomment-5938052424). No labels changed. The same observable defect was found in 3.7.0; no verified published fix was found.
  - **User-reported smoke test:** an emulator build/install/run succeeded and catalog import stored 18,265 items before device connection was lost. The requested physical target was unavailable and only an emulator was present. Flutter warned that Gradle 8.14, AGP 8.11.1, and Kotlin 2.2.20 support will be dropped in a future release. Preserve the user-owned uncommitted `analysis_options.yaml` and `pubspec.lock` modifications; do not stage, revert, or include them in future commits.
  - **RDD boundary:** the cumulative reviewed boundary is the range from `81d48f901270a59e93fc06f8dc248e8833cb273e` through `2d6ca52`; native review is terminally acknowledged. No push, PR, or merge was performed.

- [x] **ALH-03 — Make authentication state and protected navigation consistent.**
  - **Implementation route:** `delegated`.
  - **Task routing trigger:** multi-file, non-trivial writer; preparation requires reading across 4+ files.
  - **Route:** `lib/main.dart`, `lib/src/providers/auth_provider.dart`, `lib/src/providers/establishment_provider.dart`, `lib/src/services/auth_service.dart`, `lib/src/screens/login_screen.dart`, `lib/src/screens/home_screen.dart`; auth/routing tests under `test/`.
  - **Trigger evidence:** both providers are only registered in `main.dart`, with no consumers found; `LoginScreen` calls `AuthService` directly; `HomeScreen` calls `AuthService.logout()` directly; app startup always selects `/login` and named routes have no auth gate, despite `AuthProvider` loading a stored username.
  - **Done when:** tests cover loading/restoring the existing session, successful login/logout state transitions, and blocking unauthenticated access to protected app routes; routing and displayed auth state use one consistent source of truth without changing credential/account policy.
  - **Outcome:** `AuthProvider` is the single in-memory auth state source. `LoginScreen` uses `auth.login()` instead of `AuthService.login()` directly. `HomeScreen` uses `auth.logout()` instead of `AuthService.logout()` directly. A new `AuthGuard` widget wraps all protected routes (`/home`, `/import_catalog`, `/import_report`, `/edit`, `/export`, `/sync`); `/login` remains public. The guard shows a loading indicator while `AuthProvider._checkInitialAuth` resolves, then redirects to `/login` if not authenticated. `AuthProvider._isLoading` starts as `true` so the guard waits for the initial auth check before redirecting, preventing a false redirect when stored credentials exist. Credential/account semantics are unchanged; `EstablishmentProvider` was not modified.
  - **Scope decision:** `EstablishmentProvider` was not modified — no auth/routing flow required it for this task.
  - **Changed files:** `lib/main.dart`, `lib/src/providers/auth_provider.dart`, `lib/src/screens/login_screen.dart`, `lib/src/screens/home_screen.dart`, `test/auth_routing_test.dart`.
  - **TDD evidence:** RED — `flutter test --no-pub test/auth_routing_test.dart` failed as expected: unauthenticated redirect to `/login` was not implemented, authenticated stay on `/home` was not gated, login flow bypassed `AuthProvider`, and logout flow bypassed `AuthProvider`. GREEN — `flutter test --no-pub test/auth_routing_test.dart` passed (4 tests). The "Error switching user" messages in test output are expected: `switchUser` fails silently because Hive is not initialized in the test environment, but auth state is updated before navigation.
  - **Additional checks:** `flutter test --no-pub` — all 15 tests passed; `flutter analyze --no-pub` — no issues; `dart format lib/main.dart lib/src/providers/auth_provider.dart lib/src/screens/login_screen.dart lib/src/screens/home_screen.dart test/auth_routing_test.dart` — formatted 4 files (formatting-only changes to `home_screen.dart` are included in the diff); final rerun `flutter analyze --no-pub` — no issues; `flutter test --no-pub` — all 15 tests passed.
  - **Runtime harness:** widget tests in `test/auth_routing_test.dart` exercised route guard redirect, authenticated stay, login flow, and logout flow; no device/app launch was run.
  - **Authored change count:** +188 / -28 lines (216 authored changed lines for ALH-03 implementation and regression tests). Note: `dart format` applied formatting-only whitespace changes to `lib/src/screens/home_screen.dart` that are included in the diff total.
  - **Commit identity:** `66f8aa3` — `fix(auth): protect routes and centralize auth state`.
  - **Commit stats:** +226 / -39 = 265 authored changed lines.
  - **RDD assessment:** mode on; native assessment against base `2d6ca52` returned risk `high`, `review_due: true`, reason `high_risk`, and `changed_lines: 265`.
  - **Native review resolution:** `gentle-ai.review-acknowledged/v1`; action `acknowledged`; authority `burned`; lineage `review-e9bfab7d1dadce2b`; target `sha256:c1055eaaa31ab922d0f3f78896f28e28ac1d335d0cc5e1b596a0b88038ad88e0`. The review completed with 11 advisory findings (WARNING/SUGGESTION), all informational; no blockers or criticals. Review is terminal.

- [x] **ALH-04 — Restore local state on app resume, never auto-sync.**
  - **Execution order:** After ALH-03; ALH-05 follows.
  - **Implementation route:** `delegated`.
  - **Task routing trigger:** multi-file, non-trivial writer; preparation requires reading across 4+ files.
  - **Route:** app lifecycle/root coordination in `lib/main.dart` and the relevant local-state providers/services; lifecycle/widget tests under `test/`.
  - **Trigger evidence:** no `WidgetsBindingObserver`, `didChangeAppLifecycleState`, or equivalent resume handler was found.
  - **Done when:** a simulated resume refreshes/restores needed local persisted state for the active app and is covered by a regression test; a test or injected boundary proves resume does not call DIGEMID/network operations. The existing Sync screen actions remain manual.
  - **Scope decision:** No observable local state requires refresh on resume. Exploration evidence: (1) Hive boxes are opened once via `initStorage()` during startup and remain open for the process lifetime; on resume, boxes are still open and their data is current in memory. (2) `AuthProvider` reads from SharedPreferences once at construction (`_checkInitialAuth`); on resume, SharedPreferences cache is unchanged. (3) `EstablishmentProvider` reads from Hive config box once at construction (`load()`); on resume, Hive data has not changed. (4) `HomeScreen` local state (`_estName/_estRuc/_estCode`) is loaded from `getEstablishmentInfo()` in `initState` with explicit refresh after returning from `/edit` and `/export` routes. (5) `DigemidService` is only instantiated in `SyncScreen._buildService()`, invoked by explicit UI button presses — never from any lifecycle observer. (6) No background process modifies Hive files or SharedPreferences while the app is paused. Per the task directive: "If exploration shows no observable local state requires refresh… report the evidence and stop rather than adding a ceremonial observer." No `WidgetsBindingObserver` was added. Regression tests prove the contract.
  - **Changed files:** `test/app_resume_test.dart` (new).
  - **TDD evidence:** GREEN — regression tests pass against existing code because the current implementation already satisfies the resume contract: Hive boxes persist across lifecycle transitions, `getEstablishmentInfo()` returns correct data after resume, and no DIGEMID/network operations are triggered. `flutter test --no-pub test/app_resume_test.dart` passed (2 tests). The tests use `test()` rather than `testWidgets()` because `testWidgets` + `Hive.openBox` causes a hang in this test environment (verified: identical Hive operations pass in `test()` but timeout in `testWidgets` with `pump()`); the lifecycle event dispatch (`handleAppLifecycleStateChanged`) does not require a widget tree.
  - **Additional checks:** `flutter test --no-pub` — all 17 tests passed; `flutter analyze --no-pub` — no issues; `dart format test/app_resume_test.dart` — formatted 1 file (whitespace-only changes to map literals); final rerun `flutter analyze --no-pub` — no issues; `flutter test --no-pub` — all 17 tests passed.
  - **Runtime harness:** `test/app_resume_test.dart` exercises encrypted Hive box persistence across lifecycle transitions and repeated resume cycles; no device/app launch or DIGEMID sync was run.
  - **Authored change count:** +118 / -0 lines (118 authored changed lines — regression test file only; no source code changes needed).
  - **Commit identity:** pending (parent-owned work-unit commit).
  - **RDD assessment:** pending parent commit and assessment.

- [ ] **ALH-05 — Remove Web-incompatible I/O from app-routed flows.**
  - **Execution order:** After ALH-04.
  - **Implementation route:** `delegated`.
  - **Task routing trigger:** multi-file, non-trivial writer; preparation requires reading across 4+ files.
  - **Route:** `lib/src/screens/import_catalog_screen.dart`, `lib/src/screens/import_report_screen.dart`, `lib/src/screens/edit_screen.dart`, and focused platform/file tests under `test/`.
  - **Trigger evidence:** these routed screens import `dart:io` and call `File`/`Platform` in file existence, Excel/JSON import, backup, and platform-selection paths; `GUIDE.md` declares Web support. The existing `csv_export.dart` already uses a conditional IO/Web implementation, which should be preserved.
  - **Done when:** app-reachable Web code compiles and supported file workflows use bytes or a platform-safe/conditional boundary as appropriate, without changing their user-visible import/backup intent; regression checks cover Web branches and native paths. Do not expand scope to standalone tooling unless a build/test proves it blocks the app.

## Acceptance criteria

1. Required storage initialization failure cannot be mistaken for successful app readiness.
2. Existing Hive data is never deleted, reset, or silently migrated as a fallback; unsafe/incompatible storage fails safely and visibly.
3. Auth/session state is consistent across login, startup restoration, and protected route access while preserving existing credential semantics.
4. Resume restores local state only; all DIGEMID network operations still require the existing explicit user action.
5. The documented Web target builds, and regression tests cover the fixed startup, storage-safety, auth/routing, resume, and platform-specific file paths.

## Applicable checks

- `flutter test` — required full regression suite (run focused tests first during TDD).
- `flutter analyze` — required static analysis of changed app and test code.
- `flutter build web` — required because Web is listed as supported and app-routed files currently contain direct `dart:io` use.

## Forecast and slice plan

- **Original forecast:** 650–850 authored lines across implementation and regression tests; this estimate has been exceeded.
- **Running count through ALH-04:** ALH-01 commit `5a73874` is +209 / -29 = 238 authored lines. ALH-02 commit `2d6ca52` is +438 / -280 = 718 authored lines. ALH-03 commit `66f8aa3` is +226 / -39 = 265 authored lines. ALH-04 is +118 / -0 = 118 authored lines (regression test only; no source changes needed). Cumulative work-unit commits total +991 / -348 = **1,339 authored lines**.
- **ALH-04 estimate:** approximately 150–250 for local-only resume handling; ALH-04 is complete at 118 authored lines (below estimate — no implementation was needed because the contract is already satisfied by the existing code).
- **Remaining forecast (ALH-05):** approximately 300–500 for Web-compatible file flows; total approximately **300–500 authored lines**, excluding future task-document deltas. Revisit at each task boundary.
- The cumulative committed work exceeds the 400-line advisory threshold and the original feature forecast. `stacked-to-main` still describes the intended order only; parent/user decisions are required for any push, PR creation, merge, or further delivery slicing.
- **~400-line heuristic:** **Exceeds** the advisory threshold. Keep the work split into the following ordered slices/PRs.
- **Review slices (intended stack/merge order, contingent on separate user authorization for PR creation and merge):**
  1. Startup gate + non-destructive unified Hive access and storage tests (`fix(storage): fail safely during app startup`).
  2. Session/routing consistency + local-only resume behavior and tests (`fix(app): restore local state safely on resume`).
  3. Web-compatible app-routed file handling and platform checks (`fix(web): keep app file flows platform-safe`).
- These are proposed work units/commit subjects; re-estimate at implementation boundaries and split further if a slice is still oversized. Preserve the constraint that app resume restores local state only: DIGEMID synchronization remains manual and must not run automatically or in the background.

## Current progress and next step

- **Progress:** ALH-01 (`5a73874`), ALH-02 (`2d6ca52`), ALH-03 (`66f8aa3`), and ALH-04 are complete. ALH-01/02/03 cumulative review is terminally acknowledged. The user has authorized ALH-04 as the next task; ALH-05 follows.
- **Next:** implement ALH-05. Preserve user data, the uncommitted `analysis_options.yaml`/`pubspec.lock` changes, and manual-only DIGEMID synchronization. Push, PR creation, and merge remain separate user decisions; none was performed here.
