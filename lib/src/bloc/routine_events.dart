part of 'routine_bloc.dart';

abstract class RoutineEvent extends Equatable {
  const RoutineEvent();

  @override
  List<Object?> get props => [];
}

class LoadSampleRoutine extends RoutineEvent {
  const LoadSampleRoutine();
}

class SelectTask extends RoutineEvent {
  const SelectTask(this.taskId);
  final String taskId;

  @override
  List<Object?> get props => [taskId];
}

class ReorderTasks extends RoutineEvent {
  const ReorderTasks({required this.oldIndex, required this.newIndex});
  final int oldIndex;
  final int newIndex;

  @override
  List<Object?> get props => [oldIndex, newIndex];
}

class ToggleBreakAtIndex extends RoutineEvent {
  const ToggleBreakAtIndex(this.index);
  final int index;

  @override
  List<Object?> get props => [index];
}

class UpdateSettings extends RoutineEvent {
  const UpdateSettings(this.settings);
  final RoutineSettingsModel settings;

  @override
  List<Object?> get props => [settings];
}

class MarkTaskDone extends RoutineEvent {
  const MarkTaskDone({required this.actualDuration});
  final int actualDuration;

  @override
  List<Object?> get props => [actualDuration];
}

class GoToPreviousTask extends RoutineEvent {
  const GoToPreviousTask();
}

class UpdateTask extends RoutineEvent {
  const UpdateTask({required this.index, required this.task});
  final int index;
  final TaskModel task;

  @override
  List<Object?> get props => [index, task];
}

class DuplicateTask extends RoutineEvent {
  const DuplicateTask(this.index);
  final int index;

  @override
  List<Object?> get props => [index];
}

class DeleteTask extends RoutineEvent {
  const DeleteTask(this.index);
  final int index;

  @override
  List<Object?> get props => [index];
}

class AddTask extends RoutineEvent {
  const AddTask({required this.name, required this.durationSeconds});
  final String name;
  final int durationSeconds;

  @override
  List<Object?> get props => [name, durationSeconds];
}

class UpdateBreakDuration extends RoutineEvent {
  const UpdateBreakDuration({required this.index, required this.duration});
  final int index;
  final int duration;

  @override
  List<Object?> get props => [index, duration];
}

class ResetBreakToDefault extends RoutineEvent {
  const ResetBreakToDefault({required this.index});
  final int index;

  @override
  List<Object?> get props => [index];
}

/// Load routine data from Firebase
class LoadRoutineFromFirebase extends RoutineEvent {
  const LoadRoutineFromFirebase();
}

/// Save current routine data to Firebase
class SaveRoutineToFirebase extends RoutineEvent {
  const SaveRoutineToFirebase();
}

/// Reload routine when user changes (sign in/out)
class ReloadRoutineForUser extends RoutineEvent {
  const ReloadRoutineForUser();
}

/// Complete the current break and move to the next task
class CompleteBreak extends RoutineEvent {
  const CompleteBreak();
}

/// Skip the current break and move immediately to the next task
class SkipBreak extends RoutineEvent {
  const SkipBreak();
}

/// Complete the routine and save completion data
class CompleteRoutine extends RoutineEvent {
  const CompleteRoutine();
}

/// Reset the routine to start a new session
class ResetRoutine extends RoutineEvent {
  const ResetRoutine();
}
