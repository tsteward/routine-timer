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

/// Update a specific task's fields by index in the ordered list.
class UpdateTaskAtIndex extends RoutineEvent {
  const UpdateTaskAtIndex({
    required this.index,
    this.name,
    this.estimatedDuration,
  });

  /// Index into the tasks list to update.
  final int index;

  /// New task name; if null, keep existing.
  final String? name;

  /// New estimated duration in seconds; if null, keep existing.
  final int? estimatedDuration;

  @override
  List<Object?> get props => [index, name, estimatedDuration];
}

/// Duplicate the task at the given index. The new copy is inserted
/// immediately after the source and assigned a unique id and order.
class DuplicateTaskAtIndex extends RoutineEvent {
  const DuplicateTaskAtIndex(this.index);
  final int index;

  @override
  List<Object?> get props => [index];
}

/// Delete the task at the given index and fix up indices/orders.
class DeleteTaskAtIndex extends RoutineEvent {
  const DeleteTaskAtIndex(this.index);
  final int index;

  @override
  List<Object?> get props => [index];
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
