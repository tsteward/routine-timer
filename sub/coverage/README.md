# Test Coverage Reports

This directory contains various coverage reports generated from the test suite.

## Files Available

### 📊 Raw Coverage Data
- **`lcov.info`** - Raw LCOV coverage data file (machine-readable)

### 📝 Text Reports
- **`summary.txt`** - Overall coverage summary showing total lines/functions covered
- **`detailed-list.txt`** - Per-file coverage breakdown with percentages and line counts
- **`pr-comment-preview.md`** - Preview of what will be posted as a PR comment

### 🌐 HTML Report
- **`html/index.html`** - Interactive HTML coverage report
  - Open in a browser to see detailed line-by-line coverage
  - Navigate through files to see which lines are covered/uncovered
  - Color-coded: green (covered), red (uncovered)

## Quick Summary

**Overall Coverage: 74.0%** (632 of 854 lines)

### Files with Perfect Coverage (100%)
- `src/bloc/routine_bloc.dart` - 130 lines
- `src/bloc/routine_state_bloc.dart` - 8 lines
- `src/screens/pre_start_screen.dart` - 13 lines

### Files with High Coverage (≥80%)
- `src/app_theme.dart` - 93.3% (15 lines)
- `src/models/routine_state.dart` - 90.0% (30 lines)
- `src/models/task.dart` - 89.3% (28 lines)
- `src/screens/main_routine_screen.dart` - 81.2% (16 lines)
- `src/router/app_router.dart` - 80.0% (10 lines)

### Files Needing Attention (<80%)
- `src/models/routine_settings.dart` - 73.7% (19 lines)
- `src/models/break.dart` - 71.4% (14 lines)
- `src/screens/task_management_screen.dart` - 68.7% (515 lines) ⚠️ **Largest file**
- `src/main.dart` - 64.3% (14 lines)
- `src/bloc/routine_events.dart` - 18.8% (32 lines) ❌
- `src/utils/simple_bloc_observer.dart` - 10.0% (10 lines) ❌

## Top Coverage Opportunities

Focus testing efforts on:
1. **`src/bloc/routine_events.dart`** - 81.2% untested (26 lines uncovered)
2. **`src/screens/task_management_screen.dart`** - 31.3% untested (161 lines uncovered) - **Biggest impact**
3. **`src/utils/simple_bloc_observer.dart`** - 90% untested (9 lines uncovered)

---
*Generated: $(date)*
