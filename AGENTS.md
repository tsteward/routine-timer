# Agent Playbook: Routine Timer (Flutter + Dart MCP)

This project includes MCP integrations and conventions so you can run, test, and debug autonomously. Follow this playbook end-to-end without human input.

## Project Overview
- Framework: Flutter (Dart)
- Entry point: `lib/main.dart`
- Routes: `lib/src/router/app_router.dart`
- Theme: `lib/src/app_theme.dart`
- Placeholder screens: `lib/src/screens/*`
- Tests: `test/widget_test.dart`
 - Plan directory: `plan/` — see `plan/Plan.md` and `plan/Routine Timer.md` for a high-level overview and roadmap.

## 0) Environment Assumptions
- Shell: Windows PowerShell
- Project root: `C:\Users\tstew\projects\routine_timer`
- Flutter installed on stable; Dart ≥ 3.9.

## 1) Install Dependencies
From project root:
```powershell
flutter pub get
```

## 2) List Devices and Select Target
```powershell
flutter devices
```
Choose the physical Android device (e.g., `356120352015875`).

## 3) Run the App
Launch the app on your selected device:
```powershell
flutter run -d <deviceId> --target=lib/main.dart
```
Optional: If you plan to use MCP, add `--print-dtd` to also print a DTD URI (you will see "The Dart Tooling Daemon is available at: ws://...").

## 4) Optional: Connect to Dart MCP (DTD)
If using MCP tooling, call `connect_dart_tooling_daemon(uri)`, then `hot_reload(clearRuntimeErrors: true)` if needed. Use `get_widget_tree()` and `get_runtime_errors(clearRuntimeErrors: true)` to verify.

## 5) Common MCP Commands (Optional)
- Hot reload: `hot_reload(clearRuntimeErrors: true)`
- Runtime errors: `get_runtime_errors(clearRuntimeErrors: true)`
- Widget tree: `get_widget_tree()`
- Selected widget: `get_selected_widget()`
- Enable inspector selection: `set_widget_selection_mode(enabled: true|false)`

## 6) Running Tests via MCP (Optional)
1) Ensure root is registered:
```json
mcp_dart_add_roots: [{ "uri": "file:///C:/Users/tstew/projects/routine_timer", "name": "routine_timer" }]
```
2) Run tests:
```json
mcp_dart_run_tests: { "roots": [{ "root": "file:///C:/Users/tstew/projects/routine_timer" }], "testRunnerArgs": { "reporter": "compact" } }
```
Expected: all tests pass.

## 7) Editing & Verifying Changes
- Make edits with apply_patch/edit_file tools only
- If `pubspec.yaml` changed → run `flutter pub get`
- Run static analysis and fix all errors and warnings (treat warnings as errors). Do not proceed until 0 issues:
```powershell
dart analyze
```
- Optionally run analyzer in Flutter context as well:
```powershell
flutter analyze
```
- Format code before finishing (no unformatted files allowed):
```powershell
dart format .
```
- Re-run tests with MCP and ensure they all pass
- Run local tests and ensure they all pass (include edge cases):
```powershell
flutter test
```
- If app is running, trigger `hot_reload`

## 8) DTD Troubleshooting (Optional)
- Version error: update Cursor to latest and restart; re-run step 3 for a fresh URI
- URI expired: re-run with `--print-dtd` to print a new URI

## 9) Privacy
- Never commit or share printed DTD URIs; they’re local and ephemeral.

## 10) One-Command Recap
```powershell
flutter run -d <deviceId> --target=lib/main.dart
# Optional: add --print-dtd and connect to DTD if needed
```

## 11) Code Formatting
Always run the formatter before finishing any change. Never commit unformatted code.
```powershell
dart format .
```

## 12) Static Analysis & Linting
All changes must pass static analysis and lints with 0 errors and 0 warnings.

- **Analyze the codebase**:
```powershell
dart analyze
```
- **Optional Flutter-context analysis** (may catch additional issues):
```powershell
flutter analyze
```
- **Resolve all findings**: Treat warnings as errors; do not defer fixes. If a rule is inappropriate, prefer improving the code over disabling the lint. Only adjust rules in `analysis_options.yaml` with strong justification.

## 13) Testing Requirements
Every change must be covered by tests. Add or update tests for new functionality, bug fixes, and edge cases.

- **Write tests** that cover success paths, error handling, and edge cases
- **Run tests locally** and ensure 100% of executed tests pass:
```powershell
flutter test
```
- **Run tests via MCP** when applicable and confirm green status
- **Avoid flakiness**: use proper async/waits, pumps, and deterministic inputs

## 14) Pre-Commit Quality Gate
Before considering a change complete, verify all of the following are green:

1. Code formatted:
   ```powershell
   dart format .
   ```
2. Static analysis clean (0 issues):
   ```powershell
   dart analyze
   ```
3. Tests pass locally (including edge cases):
   ```powershell
   flutter test
   ```
4. Tests pass via MCP (if using MCP workflow)
