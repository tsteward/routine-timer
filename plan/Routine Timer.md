### **Routine Timer: Project Plan**

This document outlines the plan for a simple web application designed to help users manage and accomplish their morning tasks efficiently.

## **How the App Works**

### **Evening Setup**

The night before, you open the app to queue up your morning tasks. You add each task with an estimated time duration, then save the queue for tomorrow morning. You also configure a specific **Start Time** for your routine and global settings for breaks.

### **Pre-Start Phase**

Before the configured Start Time, the app will display a black screen with a prominent countdown showing how much time is left until your routine begins.

### **Morning Execution**

In the morning, once the Start Time is reached, the app automatically transitions to your first queued task. A large timer counts down the time remaining for the current task. When you finish the task (or when time runs out), you tap the "Done" button to move to the next task.

## **1\. Core Features**

* **Task Queue Management:** Users can add, edit, and reorder tasks to be completed for the morning. This list should be persistent.  
* **Routine Start Time Configuration:** Users can set a specific time for their morning routine to begin. This will be configurable on the task management screen.  
* **Pre-Start Countdown Display:** Before the routine's configured start time, the app will display a countdown to the start.  
* **Current Task Display:** Clearly displays the task currently being worked on.  
* **Countdown Timer:** A prominent timer shows the time remaining for the current task. The timer will go negative once the allocated time has run out.  
* **Current Task Progress Bar:** A visual progress bar that shows the completion percentage of the current task.  
* **Action Buttons:**  
  * **"Done" Button:** Marks the current task as complete, advancing to the next task.  
  * **"Previous" Button:** Allows the user to go back to the previously active task.  
* **Schedule Tracking:**  
  * Displays a concise indication of whether the user is "Ahead by X min," "Behind by Y min," or "On track."  
  * Displays the total estimated completion time for the entire morning routine (e.g., "Est. Completion: 8:30 AM").  
* **Task History/Completion Log:** A list of already completed tasks for the current morning is visible on the main screen, showing the task name and the actual time taken (e.g., "Took: 3 min 15 sec").  
* **Break Management:**  
  * **Global Default:** An option to "Enable Breaks by Default" which controls the initial state (active or disabled) for all gaps between tasks.  
  * **Individual Break Toggling:** Users can individually enable or disable breaks between specific tasks directly from the task list.  
  * **Configurable Default Break Duration:** Users can set a standard duration for breaks.  
  * Breaks will be visually represented and integrated into the routine's estimated start and completion times.  
* **Task Duplication:** Users can duplicate existing tasks for quick addition of similar tasks.

## **2\. User Interface (UI) Overview**

The UI is a clean, "Minimalist Dashboard" concept, easy to use in the morning and optimized for tablet-sized screens.

* **Pre-Start Screen:**  
  * **Solid Black Background:** The entire screen will be black.  
  * **Large Countdown Timer:** A prominent, central timer will count down the time remaining until the configured routine start time.  
  * A simple text like "Routine Starts In:" might accompany the countdown.  
* **Main Screen (During Routine):**  
  * **Optimized for Landscape:** The layout will take advantage of the wider screen real estate.  
  * **Dynamic Background Color:** The background has a solid **green** color when there is time remaining for the current task and turns a solid **red** once the allocated time has run out.  
  * **Header:** A header at the top of the screen contains the schedule status ("Ahead/Behind") on the left and a settings icon (gear symbol) on the right. Below the schedule status, the total estimated completion time for the routine is displayed.  
  * **Central Content:** The center of the screen is dedicated to the current task. It features the current task's name, a large countdown timer, a slim progress bar, and the "Previous" and "Done" action buttons positioned below the progress bar.  
* **Task Drawer (Footer):**  
  * A drawer is anchored to the bottom of the screen.  
  * **Partially Visible State:** By default, the drawer is partially open, labeled "Up Next," showing the immediate next one or two upcoming tasks as cards. These cards will be displayed **horizontally** and designed to fill the available space within the partially visible area. Each card will display the task name and its estimated duration (e.g., "Est: 15 min"). A "Show More" text link will be visible to expand the drawer.  
  * **Expanded State:** The drawer can be expanded by tapping "Show More" to reveal two distinct, scrollable lists presented as cards. These cards will be displayed **horizontally** and designed to fill the available space within their respective lists:  
    1. The full list of all **Upcoming Tasks**, each showing the task name and its estimated duration.  
    2. A list of all **Completed Tasks** for the current session, each showing the task name and the actual time it took to complete (e.g., "Took: 3 min 15 sec").  
* **Task Management Screen:**  
  * **Two-Column Layout:** The screen will feature a two-column layout in landscape mode.  
    * **Left Column (Task List):** Displays the ordered list of all queued tasks. Each task entry will show an expected start time, task name, and estimated duration. A reorder handle will be present for drag-and-drop functionality. Gaps between tasks will be interactive.  
      * **Interactive Gaps:** Each gap between tasks will be a clickable, two-state object:  
        * **State 1: Active Break:** A smaller, colored card showing a break icon (e.g., star) and the break duration (e.g., "2 min Break"). Tapping this card will disable the break. The estimated start time of the following task will include this break's duration.  
        * **State 2: Disabled Break:** A subtle, thin, dark placeholder with a dashed border. It will contain a greyed-out icon (e.g., a simple plus sign) and the text "Add Break." Tapping this placeholder will activate the break. The estimated start time of the following task will *not* include a break duration.  
    * **Right Column (Settings & Details Panel):** This column will be dedicated to routine-wide settings and detailed task editing.  
      * **Routine Settings Section:** Contains:  
        * "Routine Start Time" with a time picker (e.g., "08:00 AM").  
        * "Enable Breaks by Default" toggle: This toggle controls the *initial state* for every gap between tasks. If ON, every gap will automatically have an active break. If OFF, every gap will start in a disabled state.  
        * "Break Duration" input field (e.g., "2 min").  
        * "Cancel" and "Save Changes" buttons.  
      * **Task Details Section:** When a task is selected from the left column, its details will appear here, including:  
        * "Task Name" input field.  
        * "Estimated Duration" input field (e.g., "15 min").  
        * "Duplicate" button.  
        * "Delete Task" button.  
  * **Bottom Bar:** A persistent bottom bar will display the "Est. Finish" time for the entire routine and the "Total Time" of all tasks, along with a prominent "+ Add New Task" button.

#### **3\. Technical Considerations**

* **Front-end Framework:** Flutter (for cross-platform development targeting tablets)  
* **Styling:** Flutter's rich widget set and material design, with custom theming to achieve the desired minimalist aesthetic. Responsive layouts will be achieved using Flutter's layout widgets (e.g., MediaQuery, Expanded, Flex).  
* **State Management:** BLoC pattern will be used for robust state management in Flutter.  
* **Backend & Data Persistence:** Firebase (Firestore for database, Authentication for user management if needed). This will be the primary backend for storing task lists, the configured routine start time, break settings, and task details, ensuring data persistence across sessions and devices.  
* **Timer Logic:** Dart's Timer class for accurate countdowns. This will include logic for:  
  * The **pre-start countdown** (from current time to configured start time).  
  * The **task countdown** (from task duration, potentially going negative).  
  * Handling pausing, resuming, and triggering UI updates (like background color changes and progress bar updates).  
  * The progress bar will be calculated based on the elapsed time of the current task relative to its total estimated duration.

#### **4\. Workflow**

1. **Evening/Setup:** User opens the app and defines their morning tasks, estimated durations, routine start time, and break settings. This data is saved to Firebase.  
   * On the Task Management Screen, the user sets their default preference with the "Enable Breaks by Default" toggle. The task list on the left instantly reflects this default for all gaps.  
   * The user can then add new tasks, reorder tasks via drag-and-drop, edit task details by selecting a task to populate the "Task Details" panel, duplicate tasks, or delete tasks.  
   * The user can also scan their routine and simply **tap on any gap** (whether it's an active break or a disabled placeholder) to flip its state. The "Est. Start Time" for all subsequent tasks instantly recalculates and updates with every tap, giving the user immediate feedback on how their changes affect their total schedule.  
2. **Morning (Pre-Start):**  
   * If the current time is before the configured Routine Start Time, the app displays the **black background** with a **countdown timer** to the start time.  
   * The app waits until the Start Time is reached.  
3. **Morning (Routine Execution):**  
   * Once the configured Routine Start Time is reached, the app automatically transitions from the pre-start screen.  
   * It loads the task list and routine settings (including break configurations) from Firebase and calculates the total estimated completion time, displaying it in the header.  
   * The first task (or an initial break if configured) is displayed, its timer begins counting down, and the background is **green**.  
   * The ahead/behind schedule status is continuously updated.  
   * The user can see the next task in the partially visible drawer at the bottom, under the "Up Next" label. The cards in this section will fill the available space and be displayed **horizontally**.  
   * User works on the task. If the timer goes negative, the background turns **red**.  
   * When done, the user taps the **"Done"** button. The task is moved to the "Completed" list in the drawer, along with the actual time taken (including seconds). The actual time taken is factored into the overall schedule tracking.  
   * The next task appears, including any active breaks. The user can tap the **"Previous"** button to go back if needed.  
   * The user can expand the drawer at any time by tapping "Show More" to see all upcoming and completed tasks. These cards will also fill their available space and be displayed **horizontally**.  
   * If no more tasks remain, a "Morning Accomplished\!" message appears.

## **5\. Future Enhancements (Post-MVP)**

* **Analytics:** Track average task completion times.  
* **Preset Routines:** Save and load different morning routines.  
* **Audio Cues:** Sounds to indicate task start/end.