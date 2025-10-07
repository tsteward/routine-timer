# Agent Playbook: Routine Timer (Flutter + Dart)

This project includes MCP integrations and conventions so you can run, test, and debug autonomously. Follow this playbook end-to-end without human input.

## Project Overview
- Framework: Flutter (Dart)
- Entry point: `lib/main.dart`
- Routes: `lib/src/router/app_router.dart`
- Theme: `lib/src/app_theme.dart`
- Placeholder screens: `lib/src/screens/*`
- Tests: `test/`
 - Plan directory: `plan/` — see `plan/Plan.md` and `plan/Routine Timer.md` for a high-level overview and roadmap.

## 0) Environment Assumptions
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
- Run local tests and ensure they all pass (include edge cases):
```powershell
flutter test
```
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
**CRITICAL**: Every change must be covered by tests. **NEVER** ship new functionality, bug fixes, or refactorings without corresponding test coverage.

- **Always add tests for new functionality**: Every new feature, method, class, or behavior MUST have accompanying tests before the change is considered complete
- **Write comprehensive tests** that cover:
  - Success paths (happy path scenarios)
  - Error handling and edge cases
  - Boundary conditions and invalid inputs
  - Integration points and interactions with other components
- **Update existing tests** when modifying functionality to reflect the new behavior
- **Run tests locally** and ensure 100% of executed tests pass:
```powershell
flutter test
```
- **Avoid flakiness**: use proper async/waits, pumps, and deterministic inputs
- **Test location**: Place tests in the `test/` directory, mirroring the structure of `lib/`

### 13.1) Test File Structure
**MANDATORY**: Test file structure MUST mirror the `lib/` directory structure exactly.

#### File Naming and Organization
- **One-to-one mapping**: For every file in `lib/`, there MUST be a corresponding test file in `test/`
- **Mirror directory structure**: The directory hierarchy in `test/` must exactly match `lib/`
- **Naming convention**: Test files should have the same name as their corresponding lib file with `_test.dart` suffix

#### Examples
```
lib/main.dart                              → test/main_test.dart
lib/src/models/routine.dart                → test/src/models/routine_test.dart
lib/src/services/timer_service.dart        → test/src/services/timer_service_test.dart
lib/src/screens/home_screen.dart           → test/src/screens/home_screen_test.dart
lib/src/widgets/routine_card.dart          → test/src/widgets/routine_card_test.dart
```

#### Requirements
- **Complete coverage**: Every `.dart` file in `lib/` must have a corresponding `_test.dart` file in `test/`
- **Create test files immediately**: When creating a new file in `lib/`, create its test file at the same time
- **Maintain structure**: When moving or renaming files in `lib/`, move or rename their test files accordingly
- **No orphaned tests**: Test files should not exist without corresponding lib files

#### Verification
Before completing any change that adds or modifies lib files:
```powershell
# Verify test file exists for each lib file
# (Manual check or use a script to validate structure alignment)
```

### 13.2) Verifying Test Coverage
**MANDATORY**: Always verify that your new code is covered by tests. Do not consider a change complete without coverage verification.

#### Generate Coverage Report
Run tests with coverage collection enabled:
```powershell
flutter test --coverage
```
This generates a `coverage/lcov.info` file containing line-by-line coverage data.

#### View Coverage Report (HTML)
To generate a human-readable HTML report:
```powershell
# Install lcov if not already available (Linux/WSL)
# sudo apt-get install lcov

# Generate HTML report from lcov.info
genhtml coverage/lcov.info -o coverage/html

# Open the report in your browser
# Windows:
start coverage/html/index.html
# Linux:
xdg-open coverage/html/index.html
```

#### View Coverage Summary (Command Line)
For a quick summary without generating HTML:
```powershell
# Linux/WSL with lcov installed:
lcov --summary coverage/lcov.info

# Or use Flutter's built-in summary (if available):
flutter test --coverage --reporter=compact
```

#### Inspect Specific File Coverage
To check coverage for specific files you modified:
```powershell
# View coverage for a specific file
lcov --list coverage/lcov.info | grep "your_file.dart"
```

#### Coverage Requirements
- **100% coverage of new code**: All new lines, branches, and functions you add MUST be covered by tests
- **Verify before committing**: Always check coverage reports to ensure your new code is tested
- **No untested code paths**: Every conditional branch, error handler, and edge case must have a corresponding test
- **Review the HTML report**: Visually inspect the coverage report to identify any untested lines (highlighted in red)

#### Workflow for Coverage Verification
1. **Make your code changes** in `lib/`
2. **Write tests** in `test/` that exercise the new code
3. **Generate coverage**: `flutter test --coverage`
4. **Review the report**: Check the HTML report or lcov summary
5. **Identify gaps**: Look for red/uncovered lines in your new code
6. **Add missing tests**: Write additional tests to cover any gaps
7. **Repeat steps 3-6** until all new code is covered

**IMPORTANT**: Do not proceed to the quality gate (Section 14) until you have verified 100% coverage of your new code.

## 14) Pre-Commit Quality Gate
Before considering a change complete, verify all of the following are green:

1. **Test coverage added**: All new functionality has accompanying tests (see Section 13)
2. **Test file structure aligned**: Test files mirror lib file structure exactly (see Section 13.1)
3. **Coverage verified**: Run `flutter test --coverage` and confirm 100% coverage of new code (see Section 13.2)
4. Tests pass locally (including edge cases):
   ```powershell
   flutter test
   ```
5. Static analysis clean (0 issues):
   ```powershell
   dart analyze
   ```
6. Tests pass via MCP (if using MCP workflow)
7. Code formatted:
   ```powershell
   dart format .
   ```
