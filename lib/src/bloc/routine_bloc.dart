import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/break.dart';
import '../models/routine_settings.dart';
import '../models/routine_state.dart';
import '../models/task.dart';

part 'routine_events.dart';
part 'routine_state_bloc.dart';

/// RoutineBloc manages the routine configuration and runtime navigation
/// between tasks. Firebase persistence will be added in a later step.
class RoutineBloc extends Bloc<RoutineEvent, RoutineBlocState> {
  RoutineBloc() : super(RoutineBlocState.initial()) {
    on<LoadSampleRoutine>(_onLoadSample);
    on<SelectTask>(_onSelectTask);
    on<ReorderTasks>(_onReorderTasks);
    on<ToggleBreakAtIndex>(_onToggleBreakAtIndex);
    on<UpdateSettings>(_onUpdateSettings);
    on<MarkTaskDone>(_onMarkTaskDone);
    on<GoToPreviousTask>(_onGoToPreviousTask);
    on<UpdateCurrentTask>(_onUpdateCurrentTask);
    on<DuplicateCurrentTask>(_onDuplicateCurrentTask);
    on<DeleteCurrentTask>(_onDeleteCurrentTask);
  }

  void _onLoadSample(LoadSampleRoutine event, Emitter<RoutineBlocState> emit) {
    emit(state.copyWith(loading: true));

    // Simple hard-coded sample data for development.
    final tasks = <TaskModel>[
      const TaskModel(
        id: '1',
        name: 'Morning Workout',
        estimatedDuration: 20 * 60,
        order: 0,
      ),
      const TaskModel(
        id: '2',
        name: 'Shower',
        estimatedDuration: 10 * 60,
        order: 1,
      ),
      const TaskModel(
        id: '3',
        name: 'Breakfast',
        estimatedDuration: 15 * 60,
        order: 2,
      ),
      const TaskModel(
        id: '4',
        name: 'Review Plan',
        estimatedDuration: 5 * 60,
        order: 3,
      ),
    ];

    final settings = RoutineSettingsModel(
      startTime: DateTime.now().millisecondsSinceEpoch,
      breaksEnabledByDefault: true,
      defaultBreakDuration: 2 * 60,
    );

    final breaks = <BreakModel>[
      BreakModel(duration: settings.defaultBreakDuration, isEnabled: true),
      BreakModel(duration: settings.defaultBreakDuration, isEnabled: false),
      BreakModel(duration: settings.defaultBreakDuration, isEnabled: true),
    ];

    final model = RoutineStateModel(
      tasks: tasks,
      breaks: breaks,
      settings: settings,
      currentTaskIndex: 0,
      isRunning: false,
    );

    emit(state.copyWith(loading: false, model: model));
  }

  void _onSelectTask(SelectTask event, Emitter<RoutineBlocState> emit) {
    emit(
      state.copyWith(
        model: state.model?.copyWith(currentTaskIndex: event.index),
      ),
    );
  }

  void _onReorderTasks(ReorderTasks event, Emitter<RoutineBlocState> emit) {
    final model = state.model;
    if (model == null) return;

    final updatedTasks = List<TaskModel>.from(model.tasks);
    final task = updatedTasks.removeAt(event.oldIndex);
    updatedTasks.insert(event.newIndex, task);

    // Reassign order values to maintain consistency.
    final reindexed = <TaskModel>[];
    for (var i = 0; i < updatedTasks.length; i++) {
      reindexed.add(updatedTasks[i].copyWith(order: i));
    }

    emit(state.copyWith(model: model.copyWith(tasks: reindexed)));
  }

  void _onToggleBreakAtIndex(
    ToggleBreakAtIndex event,
    Emitter<RoutineBlocState> emit,
  ) {
    final model = state.model;
    if (model == null || model.breaks == null) return;

    if (event.index < 0 || event.index >= model.breaks!.length) return;

    final updated = List<BreakModel>.from(model.breaks!);
    final target = updated[event.index];
    updated[event.index] = target.copyWith(isEnabled: !(target.isEnabled));

    emit(state.copyWith(model: model.copyWith(breaks: updated)));
  }

  void _onUpdateSettings(UpdateSettings event, Emitter<RoutineBlocState> emit) {
    final model = state.model;
    if (model == null) return;
    emit(state.copyWith(model: model.copyWith(settings: event.settings)));
  }

  void _onMarkTaskDone(MarkTaskDone event, Emitter<RoutineBlocState> emit) {
    final model = state.model;
    if (model == null) return;

    final updatedTasks = List<TaskModel>.from(model.tasks);
    final current = updatedTasks[model.currentTaskIndex];
    updatedTasks[model.currentTaskIndex] = current.copyWith(
      isCompleted: true,
      actualDuration: event.actualDuration,
    );

    final nextIndex = (model.currentTaskIndex + 1).clamp(
      0,
      updatedTasks.length - 1,
    );
    emit(
      state.copyWith(
        model: model.copyWith(tasks: updatedTasks, currentTaskIndex: nextIndex),
      ),
    );
  }

  void _onGoToPreviousTask(
    GoToPreviousTask event,
    Emitter<RoutineBlocState> emit,
  ) {
    final model = state.model;
    if (model == null) return;
    final prevIndex = (model.currentTaskIndex - 1).clamp(
      0,
      model.tasks.length - 1,
    );
    emit(state.copyWith(model: model.copyWith(currentTaskIndex: prevIndex)));
  }

  void _onUpdateCurrentTask(
    UpdateCurrentTask event,
    Emitter<RoutineBlocState> emit,
  ) {
    final model = state.model;
    if (model == null) return;
    final index = model.currentTaskIndex;
    if (index < 0 || index >= model.tasks.length) return;

    final updatedTasks = List<TaskModel>.from(model.tasks);
    final current = updatedTasks[index];
    updatedTasks[index] = current.copyWith(
      name: event.name ?? current.name,
      estimatedDuration: event.estimatedDuration ?? current.estimatedDuration,
    );

    emit(state.copyWith(model: model.copyWith(tasks: updatedTasks)));
  }

  void _onDuplicateCurrentTask(
    DuplicateCurrentTask event,
    Emitter<RoutineBlocState> emit,
  ) {
    final model = state.model;
    if (model == null) return;
    final index = model.currentTaskIndex;
    if (index < 0 || index >= model.tasks.length) return;

    final source = model.tasks[index];
    final duplicate = source.copyWith(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: '${source.name} (copy)',
    );

    final updatedTasks = List<TaskModel>.from(model.tasks);
    final insertIndex = index + 1;
    updatedTasks.insert(insertIndex, duplicate);

    // Reassign order values for all tasks
    for (var i = 0; i < updatedTasks.length; i++) {
      updatedTasks[i] = updatedTasks[i].copyWith(order: i);
    }

    // Update breaks list to keep alignment: insert a break only when
    // the new duplicate is not the new last task (no break after last).
    List<BreakModel>? updatedBreaks;
    if (model.breaks != null) {
      updatedBreaks = List<BreakModel>.from(model.breaks!);
      final isNewLast = insertIndex == updatedTasks.length - 1;
      if (!isNewLast) {
        final defaults = model.settings;
        final newBreak = BreakModel(
          duration: defaults.defaultBreakDuration,
          isEnabled: defaults.breaksEnabledByDefault,
        );
        // Insert break after the inserted task, which is at index insertIndex
        final breakInsertIndex = insertIndex.clamp(0, updatedBreaks.length);
        updatedBreaks.insert(breakInsertIndex, newBreak);
      }
    }

    emit(
      state.copyWith(
        model: model.copyWith(
          tasks: updatedTasks,
          breaks: updatedBreaks ?? model.breaks,
          currentTaskIndex: insertIndex,
        ),
      ),
    );
  }

  void _onDeleteCurrentTask(
    DeleteCurrentTask event,
    Emitter<RoutineBlocState> emit,
  ) {
    final model = state.model;
    if (model == null) return;
    if (model.tasks.isEmpty) return;
    final index = model.currentTaskIndex;
    final updatedTasks = List<TaskModel>.from(model.tasks);
    updatedTasks.removeAt(index);

    // Reassign order values for all tasks
    for (var i = 0; i < updatedTasks.length; i++) {
      updatedTasks[i] = updatedTasks[i].copyWith(order: i);
    }

    // Update breaks: remove the break adjacent to the removed task.
    List<BreakModel>? updatedBreaks;
    if (model.breaks != null && model.breaks!.isNotEmpty) {
      updatedBreaks = List<BreakModel>.from(model.breaks!);
      if (index < updatedBreaks.length) {
        // Remove the break that was after the removed task
        updatedBreaks.removeAt(index);
      } else if (index > 0) {
        // Removed the last task; remove the break after the previous task
        updatedBreaks.removeAt(index - 1);
      }
    }

    // Compute new selection index
    final newIndex = updatedTasks.isEmpty
        ? 0
        : index.clamp(0, updatedTasks.length - 1);

    emit(
      state.copyWith(
        model: model.copyWith(
          tasks: updatedTasks,
          breaks: updatedBreaks ?? model.breaks,
          currentTaskIndex: newIndex,
        ),
      ),
    );
  }
}
