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
  const UpdateTask({required this.index, required this.updatedTask});
  final int index;
  final TaskModel updatedTask;

  @override
  List<Object?> get props => [index, updatedTask];
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
