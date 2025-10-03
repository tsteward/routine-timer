# Agent Playbook: Routine Timer (Flutter + Dart MCP)

This project includes MCP integrations and conventions so you can run, test, and debug autonomously. Follow this playbook end-to-end without human input.

## Project Overview
- Framework: Flutter (Dart)
- Entry point: `lib/main.dart`
- Routes: `lib/src/router/app_router.dart`
- Theme: `lib/src/app_theme.dart`
- Placeholder screens: `lib/src/screens/*`
- Tests: `test/widget_test.dart`

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

## 3) Run the App and Print the DTD URI
Use `--print-dtd` so you can connect via MCP automatically:
```powershell
flutter run -d <deviceId> --target=lib/main.dart --print-dtd
```
Parse stdout for:
```
The Dart Tooling Daemon is available at: ws://127.0.0.1:PORT/TOKEN
```
Extract the full `ws://…` URI.

## 4) Connect to Dart MCP (DTD)
Call:
- `connect_dart_tooling_daemon(uri)`
- Optionally `hot_reload(clearRuntimeErrors: true)` to ensure active session
- `get_widget_tree()` and `get_runtime_errors(clearRuntimeErrors: true)` to verify

If you see “No active debug session”:
- Ensure the `flutter run` session from step 3 is still active
- Call `hot_reload(clearRuntimeErrors: true)` and retry

## 5) Common MCP Commands
- Hot reload: `hot_reload(clearRuntimeErrors: true)`
- Runtime errors: `get_runtime_errors(clearRuntimeErrors: true)`
- Widget tree: `get_widget_tree()`
- Selected widget: `get_selected_widget()`
- Enable inspector selection: `set_widget_selection_mode(enabled: true|false)`

## 6) Running Tests via MCP
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
- Re-run tests with MCP
- If app is running, trigger `hot_reload`

## 8) DTD Troubleshooting
- Version error: update Cursor to latest and restart; re-run step 3 for a fresh URI
- URI expired: re-run with `--print-dtd` to print a new URI

## 9) Privacy
- Never commit or share printed DTD URIs; they’re local and ephemeral.

## 10) One-Command Recap
```powershell
flutter run -d <deviceId> --target=lib/main.dart --print-dtd
# parse URI from stdout → connect_dart_tooling_daemon(uri)
# then: hot_reload → get_widget_tree → get_runtime_errors
```
