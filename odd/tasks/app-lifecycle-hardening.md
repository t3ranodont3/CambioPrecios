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
- The planning-only restriction above applied to the initial planning phase and is now historical: the user selected `stacked-to-main` and authorized ALH-01 implementation. Source and test changes are limited to ALH-01; no configuration, other documentation, Git index, branch, or commits were changed.

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
  - **TDD evidence:** RED — `$env:PUB_OFFLINE = 'true'; flutter test test/storage_startup_test.dart; $env:PUB_OFFLINE = $null` failed as expected because `initStorage()` swallowed the injected path-provider `PlatformException`. GREEN — `flutter test --no-pub test/storage_startup_test.dart` passed (2 tests); `flutter test --no-pub` passed (8 tests).
  - **Additional checks:** `flutter analyze --no-pub` — no issues; `dart format lib/main.dart lib/src/services/storage_service.dart test/storage_startup_test.dart` — final run formatted 0 files.
  - **Runtime harness:** widget test in `test/storage_startup_test.dart` exercised the failed-startup UI and verified the login route was absent; no device/app launch was run.
  - **Authored change count:** +97 / -29 lines (126 authored changed lines for ALH-01 implementation and regression tests).
  - **Commit identity:** pending parent-owned work-unit commit; no commit created here.

- [ ] **ALH-02 — Unify Hive access and make recovery non-destructive.**
  - **Implementation route:** `delegated`.
  - **Task routing trigger:** multi-file, non-trivial writer; preparation requires reading across 4+ files.
  - **Route:** `lib/src/services/storage_service.dart`, `lib/src/services/hive_helper.dart`, plus direct Hive-opening call sites in `lib/src/screens/{import_catalog_screen.dart,import_report_screen.dart,export_csv_screen.dart,sync_screen.dart,edit_screen.dart}`; storage tests under `test/`.
  - **Trigger evidence:** ALH-01 changed the storage-service opener to propagate failures without deleting boxes; `hive_helper.dart` still opens without a cipher and deletes on failure, and several screens independently open boxes without a cipher. These remaining access paths still require the unified, non-destructive policy in ALH-02.
  - **Done when:** app box access follows one explicit, tested policy; failure never deletes/recreates a user's box; tests establish that incompatible existing data remains untouched and the failure is surfaced. No encryption migration is performed without an explicit approved policy.

- [ ] **ALH-03 — Make authentication state and protected navigation consistent.**
  - **Implementation route:** `delegated`.
  - **Task routing trigger:** multi-file, non-trivial writer; preparation requires reading across 4+ files.
  - **Route:** `lib/main.dart`, `lib/src/providers/auth_provider.dart`, `lib/src/providers/establishment_provider.dart`, `lib/src/services/auth_service.dart`, `lib/src/screens/login_screen.dart`; auth/routing tests under `test/`.
  - **Trigger evidence:** both providers are only registered in `main.dart`, with no consumers found; `LoginScreen` calls `AuthService` directly; app startup always selects `/login` and named routes have no auth gate, despite `AuthProvider` loading a stored username.
  - **Done when:** tests cover loading/restoring the existing session, successful login/logout state transitions, and blocking unauthenticated access to protected app routes; routing and displayed auth state use one consistent source of truth without changing credential/account policy.

- [ ] **ALH-04 — Restore local state on app resume, never auto-sync.**
  - **Implementation route:** `delegated`.
  - **Task routing trigger:** multi-file, non-trivial writer; preparation requires reading across 4+ files.
  - **Route:** app lifecycle/root coordination in `lib/main.dart` and the relevant local-state providers/services; lifecycle/widget tests under `test/`.
  - **Trigger evidence:** no `WidgetsBindingObserver`, `didChangeAppLifecycleState`, or equivalent resume handler was found.
  - **Done when:** a simulated resume refreshes/restores needed local persisted state for the active app and is covered by a regression test; a test or injected boundary proves resume does not call DIGEMID/network operations. The existing Sync screen actions remain manual.

- [ ] **ALH-05 — Remove Web-incompatible I/O from app-routed flows.**
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

- **Forecast:** approximately **650–850 authored lines (additions + deletions)** across implementation and regression tests. This is an estimate, not a measured diff; the platform adapters and lifecycle/auth coverage are the main uncertainty.
- **Running count after ALH-01:** 126 authored changed lines (+97 / -29). The remaining ALH-02–ALH-05 forecast is approximately 524–724 authored lines; the projected feature total remains 650–850 pending re-estimation at slice boundaries.
- **~400-line heuristic:** **Exceeds** the advisory threshold. Keep the work split into the following ordered slices/PRs.
- **Review slices (intended stack/merge order, contingent on separate user authorization for PR creation and merge):**
  1. Startup gate + non-destructive unified Hive access and storage tests (`fix(storage): fail safely during app startup`).
  2. Session/routing consistency + local-only resume behavior and tests (`fix(app): restore local state safely on resume`).
  3. Web-compatible app-routed file handling and platform checks (`fix(web): keep app file flows platform-safe`).
- These are proposed work units/commit subjects; re-estimate at implementation boundaries and split further if a slice is still oversized. Preserve the constraint that app resume restores local state only: DIGEMID synchronization remains manual and must not run automatically or in the background.

## Current progress and next step

- **Progress:** ALH-01 implementation and regression tests are complete and pass the checks recorded above. No ALH-02 or later work has started. No commit has been created; the parent owns the work-unit commit, native RDD, and delivery actions.
- **Next:** proceed with ALH-02 only. Continue the ordered task/slice plan, preserve existing user data and manual-only DIGEMID synchronization, and keep push, PR creation, and merge as separate user decisions. No PR was created or merged for ALH-01.
