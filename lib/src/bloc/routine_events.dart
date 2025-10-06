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
  const SelectTask(this.index);
  final int index;

  @override
  List<Object?> get props => [index];
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

/// Update the currently selected task's editable fields.
class UpdateSelectedTask extends RoutineEvent {
  const UpdateSelectedTask({required this.name, required this.estimatedDurationSeconds});

  /// New human-friendly name.
  final String name;

  /// New estimated duration in seconds.
  final int estimatedDurationSeconds;

  @override
  List<Object?> get props => [name, estimatedDurationSeconds];
}

/// Duplicate the currently selected task, inserting the copy after it.
class DuplicateSelectedTask extends RoutineEvent {
  const DuplicateSelectedTask();
}

/// Delete the currently selected task.
class DeleteSelectedTask extends RoutineEvent {
  const DeleteSelectedTask();
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
