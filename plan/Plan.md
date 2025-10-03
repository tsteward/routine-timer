# Routine Timer: Incremental Development Plan

I'll break down this Flutter application into manageable, testable increments. Each step will produce a working application that you can run and verify.

---

## **Phase 1: Foundation & Core Infrastructure**

### **Step 1: Project Setup & Basic Navigation**
**Goal:** Create the Flutter project with proper structure and navigation skeleton.

**Tasks:**
- Initialize Flutter project with proper package structure
- Set up BLoC pattern architecture (flutter_bloc dependency)
- Add Firebase dependencies (firebase_core, cloud_firestore, firebase_auth)
- Create basic app theme (colors, text styles) matching the green/red color scheme
- Implement basic navigation structure with placeholder screens:
  - Pre-Start Screen (black background)
  - Main Routine Screen (green background)
  - Task Management Screen (two-column layout placeholder)
- Add a simple FAB or button to navigate between screens for testing

**Verification:** Run the app and navigate between all three placeholder screens. Confirm theme colors are applied.

---

### **Step 2: Data Models & Local State**
**Goal:** Define all data structures and implement local state management.

**Tasks:**
- Create data models:
  - `Task` model (id, name, estimatedDuration, actualDuration, isCompleted, order)
  - `Break` model (duration, isEnabled)
  - `RoutineSettings` model (startTime, breaksEnabledByDefault, defaultBreakDuration)
  - `RoutineState` model (tasks, settings, currentTaskIndex, isRunning)
- Implement BLoC classes:
  - `RoutineBloc` with events and states for task management
  - Initial state with sample hardcoded tasks (3-4 tasks for testing)
- Add JSON serialization methods (toJson/fromJson) for all models

**Verification:** Run the app with BLoC DevTools. Verify you can see the initial state with sample tasks. Dispatch test events and observe state changes.

---

## **Phase 2: Task Management Interface**

### **Step 3: Task Management Screen - Task List (Left Column)**
**Goal:** Build the left column showing the ordered task list with drag-and-drop.

**Tasks:**
- Implement scrollable task list view
- Display each task with:
  - Expected start time (calculated from routine start time)
  - Task name
  - Estimated duration
- Add reorder functionality using `ReorderableListView`
- Implement tap-to-select functionality (highlight selected task)
- Add visual styling matching the design (cards, spacing, typography)
- Wire up to RoutineBloc to dispatch reorder events

**Verification:** Run the app, navigate to Task Management screen. Verify you can see all tasks, drag to reorder them, and see start times update. Tap tasks to select them.

---

### **Step 4: Task Management Screen - Settings Panel (Right Column)**
**Goal:** Build the right column with routine settings and task editing.

**Tasks:**
- Create Routine Settings section:
  - Time picker for "Routine Start Time"
  - Toggle switch for "Enable Breaks by Default"
  - Text field for "Break Duration"
  - "Cancel" and "Save Changes" buttons
- Create Task Details section:
  - Text field for "Task Name"
  - Text field for "Estimated Duration"
  - "Duplicate" button
  - "Delete Task" button
- Wire up all controls to RoutineBloc
- Implement functionality:
  - When task is selected in left column, populate details in right column
  - Save button updates the task/settings
  - Duplicate creates a copy of selected task
  - Delete removes selected task

**Verification:** Run the app. Select tasks and verify details appear. Edit task properties and verify changes persist. Test duplicate and delete. Change routine settings and verify they update.

---

### **Step 5: Task Management Screen - Interactive Gaps & Breaks**
**Goal:** Add break management between tasks.

**Tasks:**
- Implement gap UI between tasks in the left column:
  - Active Break state: colored card with icon and duration
  - Disabled Break state: thin placeholder with dashed border and "Add Break" text
- Make gaps clickable to toggle between states
- Update task start time calculations to include active breaks
- Wire toggle functionality to RoutineBloc
- Implement "Enable Breaks by Default" toggle behavior:
  - When enabled, all gaps show active breaks
  - When disabled, all gaps show disabled state
- Add real-time calculation updates as breaks are toggled

**Verification:** Run the app. Toggle breaks on/off in gaps and verify start times recalculate. Toggle "Enable Breaks by Default" and verify all gaps update. Verify the break duration from settings is used.

---

### **Step 6: Task Management Screen - Bottom Bar & Add Task**
**Goal:** Complete the task management screen with add functionality.

**Tasks:**
- Implement bottom bar with:
  - Display of total estimated finish time
  - Display of total time for all tasks
  - "+ Add New Task" button
- Implement add task functionality:
  - Opens a dialog or inline form
  - User enters task name and duration
  - Task is added to the end of the list
- Calculate and display estimated finish time based on start time and all tasks/breaks
- Calculate and display total time (sum of all task durations)

**Verification:** Run the app. Add new tasks and verify they appear in the list. Verify total time and estimated finish time update correctly. Add/remove tasks and breaks and verify calculations remain accurate.

---

## **Phase 3: Firebase Integration**

### **Step 7: Firebase Setup & Data Persistence**
**Goal:** Connect to Firebase and persist all routine data.

**Tasks:**
- Set up Firebase project and download configuration files
- Initialize Firebase in the app
- Create Firestore data structure:
  - Collection: `routines`
  - Documents: user-specific routine data
- Implement Firebase repository layer:
  - `saveRoutine()` method
  - `loadRoutine()` method
- Update RoutineBloc to:
  - Load data from Firebase on app start
  - Save data to Firebase whenever tasks/settings change
- Add loading states and error handling

**Verification:** Run the app, make changes to tasks/settings, force-quit the app, and restart. Verify all data persists. Test on a second device (if available) to verify cloud sync.

---

## **Phase 4: Pre-Start Screen**

### **Step 8: Pre-Start Countdown**
**Goal:** Implement the black screen with countdown to routine start.

**Tasks:**
- Create Pre-Start screen UI:
  - Solid black background
  - "Routine Starts In:" text
  - Large countdown timer display (HH:MM:SS)
- Implement countdown logic using Dart Timer:
  - Calculate difference between current time and routine start time
  - Update display every second
  - Handle case where current time is past start time
- Add automatic transition to Main Routine Screen when countdown reaches zero
- Add navigation logic to show Pre-Start screen when app opens before start time

**Verification:** Run the app. Set routine start time to 2-3 minutes in the future. Verify countdown displays correctly and counts down. Verify automatic transition to main screen when countdown reaches zero. Test with start time in the past and verify it skips to main screen.

---

## **Phase 5: Main Routine Execution**

### **Step 9: Main Screen - Current Task Display**
**Goal:** Build the core task execution interface.

**Tasks:**
- Create Main Routine Screen UI:
  - Dynamic background color (green by default)
  - Large task name display at top center
  - Massive countdown timer (MM:SS format)
  - Slim progress bar below timer
  - "Previous" and "Done" buttons below progress bar
- Implement timer logic:
  - Load first task from Firebase
  - Start countdown from task's estimated duration
  - Update display every second
  - Allow timer to go negative (show as -MM:SS)
  - Change background to red when timer goes negative
- Implement progress bar calculation:
  - Show percentage of task completed
  - Update in real-time with timer
- Wire up Done button:
  - Mark current task as complete with actual time taken
  - Advance to next task
  - Reset timer and progress bar
- Wire up Previous button:
  - Go back to previous task
  - Restore its timer state

**Verification:** Run the app, navigate to main screen. Verify timer counts down correctly. Let timer go negative and verify background turns red. Test Done button advances to next task. Test Previous button goes back. Verify progress bar updates smoothly.

---

### **Step 10: Main Screen - Header & Schedule Tracking**
**Goal:** Add header with schedule status and settings access.

**Tasks:**
- Implement header UI:
  - Left side: Schedule status card ("Ahead by X min", "Behind by Y min", "On track")
  - Below status: "Est. Completion: HH:MM AM/PM"
  - Right side: Settings gear icon
- Implement schedule tracking logic:
  - Calculate expected elapsed time from routine start
  - Calculate actual elapsed time (sum of actual task times)
  - Determine if ahead/behind and by how much
  - Update display in real-time
- Calculate and display estimated completion time:
  - Current time + remaining task time + remaining break time
  - Adjust based on ahead/behind status
- Wire settings icon to navigate to Task Management screen

**Verification:** Run the app and execute tasks. Verify schedule status updates correctly. Take longer than estimated on a task and verify "Behind" status. Finish a task faster and verify "Ahead" status. Verify estimated completion time updates appropriately. Tap settings icon and verify navigation.

---

### **Step 11: Main Screen - Task Drawer (Collapsed State)**
**Goal:** Implement the bottom drawer showing upcoming tasks.

**Tasks:**
- Create drawer UI anchored to bottom:
  - Partially visible by default
  - "Up Next" label
  - Horizontal scrollable row of task cards
  - Each card shows task name and estimated duration
  - "Show More" text link at top of drawer
- Display next 2-3 upcoming tasks in collapsed state
- Style cards to fill available space horizontally
- Make "Show More" tappable to expand drawer

**Verification:** Run the app during routine execution. Verify drawer shows at bottom with next tasks visible. Verify horizontal scrolling works if there are many upcoming tasks. Tap "Show More" (will expand in next step).

---

### **Step 12: Main Screen - Task Drawer (Expanded State)**
**Goal:** Complete the drawer with full task lists.

**Tasks:**
- Implement expanded drawer state:
  - Takes up more vertical space
  - "Upcoming Tasks" section with horizontal scrollable cards
  - "Completed Tasks" section with horizontal scrollable cards
- Display all upcoming tasks with task name and estimated duration
- Display all completed tasks with:
  - Task name
  - Actual time taken (format: "Took: X min Y sec")
  - Checkmark icon
  - Strike-through or greyed-out styling
- Add collapse functionality (tap background or "Show Less" link)
- Implement smooth expand/collapse animation
- Update lists in real-time as tasks are completed

**Verification:** Run the app and complete several tasks. Tap "Show More" to expand drawer. Verify both upcoming and completed task lists display correctly with horizontal scrolling. Verify completed tasks show actual time taken. Collapse drawer and verify it returns to minimal state.

---

### **Step 13: Break Handling During Execution**
**Goal:** Integrate breaks into routine execution flow.

**Tasks:**
- Update routine execution logic to handle breaks:
  - When a task is completed, check if next item is a break
  - If break is active, display break screen/state
  - Timer counts down break duration
  - Automatically advance to next task when break completes
- Create break display state:
  - Show "Break Time" or similar message
  - Show break countdown timer
  - Keep background green during break
  - Option to skip break with a button
- Update schedule tracking to account for break time
- Update drawer to show breaks in upcoming tasks list

**Verification:** Run the app with breaks enabled between tasks. Complete a task and verify break starts automatically. Verify break timer counts down. Verify automatic transition to next task after break. Test skip break button. Verify breaks appear in "Up Next" section.

---

### **Step 14: Routine Completion**
**Goal:** Handle the end of the routine gracefully.

**Tasks:**
- Implement completion detection:
  - Check when last task is completed
  - Trigger completion state
- Create completion screen:
  - Display "Morning Accomplished!" message
  - Show summary statistics:
    - Total time spent
    - Number of tasks completed
    - Final ahead/behind status
  - Button to return to task management or reset routine
- Add option to save completion data to Firebase (for future analytics)

**Verification:** Run the app and complete all tasks. Verify completion screen appears with correct summary. Verify button returns to task management. Restart routine and verify it resets properly.

---

## **Phase 6: Polish & Optimization**

### **Step 15: Responsive Layout & Tablet Optimization**
**Goal:** Ensure UI works perfectly on tablet screens in landscape.

**Tasks:**
- Audit all screens for tablet landscape layout
- Use MediaQuery to adjust sizing and spacing
- Optimize font sizes for readability at distance
- Ensure touch targets are appropriate size
- Test on multiple screen sizes
- Adjust card sizes in drawer to fill space effectively
- Fine-tune two-column layout on task management screen

**Verification:** Run the app on a tablet or tablet emulator in landscape mode. Verify all screens look polished and professional. Test on different screen sizes. Verify text is readable and buttons are easily tappable.

---

### **Step 16: Edge Cases & Error Handling**
**Goal:** Handle all edge cases and potential errors gracefully.

**Tasks:**
- Handle empty task list scenario
- Handle no internet connection (show cached data)
- Handle Firebase errors with user-friendly messages
- Prevent negative durations in task creation
- Handle duplicate task names
- Add confirmation dialogs for destructive actions (delete task)
- Handle app backgrounding/foregrounding during routine
- Persist timer state so routine continues correctly after app restart
- Handle timezone changes
- Validate all user inputs

**Verification:** Test each edge case individually. Try to break the app with invalid inputs. Disconnect internet and verify graceful degradation. Background the app during a routine and verify it resumes correctly.

---

### **Step 17: Animations & Visual Polish**
**Goal:** Add smooth animations and final visual touches.

**Tasks:**
- Add smooth color transition from green to red when timer expires
- Animate task cards in drawer
- Add expand/collapse animation to drawer
- Animate progress bar updates
- Add subtle hover effects to buttons
- Add haptic feedback to button presses
- Polish all typography and spacing
- Ensure consistent visual style across all screens
- Add icon for the app

**Verification:** Run through the entire app flow. Verify all transitions are smooth. Verify animations enhance rather than distract from usability. Get feedback from test users on visual appeal.

---

### **Step 18: Testing & Bug Fixes**
**Goal:** Comprehensive testing and bug resolution.

**Tasks:**
- Write unit tests for all BLoC logic
- Write unit tests for time calculations
- Write widget tests for key UI components
- Perform end-to-end testing of complete user flows
- Test on physical devices (Android and iOS tablets)
- Fix all discovered bugs
- Optimize performance (ensure smooth 60fps)
- Check memory usage and optimize if needed

**Verification:** Run all automated tests and verify they pass. Manually test all user flows multiple times. Have beta testers use the app for real morning routines and collect feedback.

---

## **Phase 7: Deployment**

### **Step 19: Production Preparation**
**Goal:** Prepare app for production release.

**Tasks:**
- Set up Firebase for production environment
- Configure proper security rules in Firestore
- Add analytics tracking (if desired)
- Create app store assets (screenshots, descriptions)
- Prepare privacy policy
- Test production builds on physical devices
- Optimize app size
- Configure proper app signing

**Verification:** Create production builds for Android and iOS. Install on physical devices and verify everything works. Verify Firebase security rules are appropriate.

---

### **Step 20: Launch & Monitor**
**Goal:** Deploy to app stores and monitor initial usage.

**Tasks:**
- Submit to Google Play Store and/or Apple App Store
- Set up crash reporting and monitoring
- Monitor user feedback and reviews
- Track analytics for usage patterns
- Prepare hotfix process for critical bugs
- Plan first update with user-requested features

**Verification:** App is live in stores. Monitor crash reports and user reviews. Verify analytics data is being collected. Ensure you can deploy hotfixes quickly if needed.

---

## **Summary**

This plan breaks down the Routine Timer app into 20 concrete, testable steps. Each step builds upon the previous ones and produces a working, verifiable increment. The plan follows a logical progression:

1. **Foundation** - Setup and core architecture
2. **Task Management** - Build the configuration interface
3. **Firebase** - Add data persistence
4. **Pre-Start** - Countdown before routine begins
5. **Main Execution** - Core timer and task tracking
6. **Polish** - Refinement and optimization
7. **Deployment** - Launch preparation

You can adjust the order slightly based on priorities, but dependencies should be respected (e.g., Firebase integration should come after basic UI is working). Each step should take 2-8 hours of focused development time, making this a manageable project that can be completed incrementally.
