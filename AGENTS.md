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

## 1) Install Dependencies
From project root:
```bash
flutter pub get
```

## 2) List Devices and Select Target
```bash
flutter devices
```
Choose the physical Android device (e.g., `356120352015875`).

## 3) Run the App
Launch the app on your selected device:
```bash
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
mcp_dart_add_roots: [{ "uri": "file:///<project_root>", "name": "routine_timer" }]
```
2) Run tests:
```json
mcp_dart_run_tests: { "roots": [{ "root": "file:///<project_root>" }], "testRunnerArgs": { "reporter": "compact" } }
```
Expected: all tests pass.

## 7) Editing & Verifying Changes
- Make edits with apply_patch/edit_file tools only
- If `pubspec.yaml` changed → run `flutter pub get`
- Run local tests and ensure they all pass (include edge cases):
```bash
flutter test
```
- Run static analysis and fix all errors and warnings (treat warnings as errors). Do not proceed until 0 issues:
```bash
dart analyze
```
- Optionally run analyzer in Flutter context as well:
```bash
flutter analyze
```
- Format code before finishing (no unformatted files allowed):
```bash
dart format .
```
- If app is running, trigger `hot_reload`

## 8) DTD Troubleshooting (Optional)
- Version error: update Cursor to latest and restart; re-run step 3 for a fresh URI
- URI expired: re-run with `--print-dtd` to print a new URI

## 9) Privacy
- Never commit or share printed DTD URIs; they’re local and ephemeral.

## 10) One-Command Recap
```bash
flutter run -d <deviceId> --target=lib/main.dart
# Optional: add --print-dtd and connect to DTD if needed
```

## 11) Code Formatting
Always run the formatter before finishing any change. Never commit unformatted code.
```bash
dart format .
```

## 12) Static Analysis & Linting
All changes must pass static analysis and lints with 0 errors and 0 warnings.

- **Analyze the codebase**:
```bash
dart analyze
```
- **Optional Flutter-context analysis** (may catch additional issues):
```bash
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
```bash
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
```bash
# Verify test file exists for each lib file
# (Manual check or use a script to validate structure alignment)
```

### 13.2) Verifying Test Coverage
**MANDATORY**: Always verify that your new code is covered by tests. Do not consider a change complete without coverage verification.

#### Generate Coverage Report
Run tests with coverage collection enabled:
```bash
flutter test --coverage
```
This generates a `coverage/lcov.info` file containing line-by-line coverage data.

#### View Coverage Report (HTML)
To generate a human-readable HTML report:
```bash
# Install lcov if not already available (Linux/WSL)
# sudo apt-get install lcov

# Generate HTML report from lcov.info
genhtml coverage/lcov.info -o coverage/html

# Open the report in your browser
xdg-open coverage/html/index.html
```

#### View Coverage Summary (Command Line)
For a quick summary without generating HTML:
```bash
# Linux/WSL with lcov installed:
lcov --summary coverage/lcov.info

# Or use Flutter's built-in summary (if available):
flutter test --coverage --reporter=compact
```

#### Inspect Specific File Coverage
To check coverage for specific files you modified:
```bash
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

### 13.3) Bug Fix Testing & Regression Prevention
**MANDATORY**: When fixing a bug, you MUST add regression tests that verify the bug is fixed and prevent it from reoccurring in the future.

#### Why Regression Tests Are Critical
- **Prevent recurrence**: Bugs often reappear when code is refactored or modified later
- **Document the issue**: Tests serve as living documentation of what the bug was and how it was fixed
- **Verify the fix**: Ensures the fix actually solves the problem, not just symptoms
- **Build confidence**: Allows future changes to be made confidently without fear of breaking previously fixed issues

#### Workflow for Bug Fix Testing
When fixing any bug, follow this mandatory process:

1. **Understand and reproduce the bug**:
   - Identify the exact conditions that trigger the bug
   - Document the expected vs. actual behavior
   - Determine which component(s) are affected

2. **Write a failing test FIRST**:
   - Create a test that reproduces the bug
   - The test should FAIL before your fix is applied
   - This proves the test actually catches the bug
   - Include descriptive test names like `test('should handle null values without throwing exception')`

3. **Apply the bug fix**:
   - Make the minimal changes needed to fix the bug
   - Keep the fix focused and avoid unrelated changes

4. **Verify the test now passes**:
   - Run the test to confirm it now passes with your fix
   - If it still fails, your fix is incomplete
   - Run the full test suite to ensure no regressions elsewhere

5. **Add additional edge case tests**:
   - Consider related scenarios that might have similar issues
   - Test boundary conditions around the bug
   - Test error cases and invalid inputs that might trigger similar bugs

#### Test Documentation Requirements
Every regression test MUST include clear documentation:

```dart
test('should not crash when routine has null name (fixes #123)', () {
  // Bug: App crashed with NullPointerException when routine.name was null
  // Expected: Should handle null gracefully and show default text
  
  final routine = Routine(name: null, duration: 60);
  
  expect(() => routine.displayName, returnsNormally);
  expect(routine.displayName, equals('Unnamed Routine'));
});
```

#### Key Elements of a Good Regression Test
- **Descriptive name**: Test name should explain what bug it prevents
- **Issue reference**: Link to issue number if available (e.g., "fixes #123")
- **Bug description**: Comment explaining what the bug was
- **Expected behavior**: Comment explaining correct behavior
- **Minimal reproduction**: Test should be as simple as possible while still catching the bug
- **Clear assertions**: Verify the specific behavior that was broken

#### Examples of Bug Fix Testing Scenarios

**Example 1: Null pointer crash**
```dart
test('should handle null routine name without crashing', () {
  // Bug: App crashed when routine.name was null
  final routine = Routine(name: null);
  expect(() => routine.display(), returnsNormally);
});
```

**Example 2: Incorrect calculation**
```dart
test('should correctly calculate elapsed time across midnight', () {
  // Bug: Timer showed negative time when crossing midnight
  final startTime = DateTime(2025, 1, 1, 23, 59, 0);
  final endTime = DateTime(2025, 1, 2, 0, 1, 0);
  
  final elapsed = calculateElapsed(startTime, endTime);
  
  expect(elapsed.inMinutes, equals(2)); // Should be 2 minutes, not negative
});
```

**Example 3: State management issue**
```dart
testWidgets('should maintain timer state after app backgrounding', (tester) async {
  // Bug: Timer reset to 0 when app was backgrounded and restored
  
  await tester.pumpWidget(TimerApp());
  
  // Start timer
  await tester.tap(find.byIcon(Icons.play_arrow));
  await tester.pump(Duration(seconds: 5));
  
  // Simulate app lifecycle change
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  
  await tester.pump();
  
  // Timer should still show elapsed time, not reset to 0
  expect(find.text('00:05'), findsOneWidget);
});
```

#### Verification Checklist for Bug Fixes
Before completing a bug fix, verify:

- [ ] Regression test written that reproduces the original bug
- [ ] Test fails before the fix is applied (verified manually or in a separate commit)
- [ ] Test passes after the fix is applied
- [ ] Test includes clear documentation of what bug it prevents
- [ ] Additional edge cases around the bug are also tested
- [ ] Full test suite still passes (`flutter test`)
- [ ] Coverage includes the bug fix code (see Section 13.2)

**CRITICAL**: A bug fix without regression tests is incomplete. Do not consider the bug fix done until all tests are in place and passing.

## 14) Pre-Commit Quality Gate
Before considering a change complete, verify all of the following are green:

1. **Test coverage added**: All new functionality has accompanying tests (see Section 13)
2. **Test file structure aligned**: Test files mirror lib file structure exactly (see Section 13.1)
3. **Coverage verified**: Run `flutter test --coverage` and confirm 100% coverage of new code (see Section 13.2)
4. Tests pass locally (including edge cases):
   ```bash
   flutter test
   ```
5. Static analysis clean (0 issues):
   ```bash
   dart analyze
   ```
6. Tests pass via MCP (if using MCP workflow)
7. Code formatted:
   ```bash
   dart format .
   ```
