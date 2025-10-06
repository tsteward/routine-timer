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
    on<UpdateTask>(_onUpdateTask);
    on<DuplicateTask>(_onDuplicateTask);
    on<DeleteTask>(_onDeleteTask);
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

  void _onUpdateTask(UpdateTask event, Emitter<RoutineBlocState> emit) {
    final model = state.model;
    if (model == null) return;
    if (event.index < 0 || event.index >= model.tasks.length) return;

    final updatedTasks = List<TaskModel>.from(model.tasks);
    updatedTasks[event.index] = event.task;

    emit(state.copyWith(model: model.copyWith(tasks: updatedTasks)));
  }

  void _onDuplicateTask(DuplicateTask event, Emitter<RoutineBlocState> emit) {
    final model = state.model;
    if (model == null) return;
    if (event.index < 0 || event.index >= model.tasks.length) return;

    final taskToDuplicate = model.tasks[event.index];
    final newTask = taskToDuplicate.copyWith(
      id: '${taskToDuplicate.id}_${DateTime.now().millisecondsSinceEpoch}',
      order: event.index + 1,
      isCompleted: false,
      actualDuration: null,
    );

    final updatedTasks = List<TaskModel>.from(model.tasks);
    updatedTasks.insert(event.index + 1, newTask);

    // Reassign order values to maintain consistency.
    final reindexed = <TaskModel>[];
    for (var i = 0; i < updatedTasks.length; i++) {
      reindexed.add(updatedTasks[i].copyWith(order: i));
    }

    // Also add a break after the duplicated task if breaks exist
    List<BreakModel>? updatedBreaks = model.breaks;
    if (updatedBreaks != null) {
      updatedBreaks = List<BreakModel>.from(updatedBreaks);
      final newBreak = BreakModel(
        duration: model.settings.defaultBreakDuration,
        isEnabled: model.settings.breaksEnabledByDefault,
      );
      updatedBreaks.insert(event.index + 1, newBreak);
    }

    emit(
      state.copyWith(
        model: model.copyWith(tasks: reindexed, breaks: updatedBreaks),
      ),
    );
  }

  void _onDeleteTask(DeleteTask event, Emitter<RoutineBlocState> emit) {
    final model = state.model;
    if (model == null) return;
    if (event.index < 0 || event.index >= model.tasks.length) return;
    if (model.tasks.length <= 1) return; // Don't delete the last task

    final updatedTasks = List<TaskModel>.from(model.tasks);
    updatedTasks.removeAt(event.index);

    // Reassign order values to maintain consistency.
    final reindexed = <TaskModel>[];
    for (var i = 0; i < updatedTasks.length; i++) {
      reindexed.add(updatedTasks[i].copyWith(order: i));
    }

    // Also remove the corresponding break if it exists
    List<BreakModel>? updatedBreaks = model.breaks;
    if (updatedBreaks != null && event.index < updatedBreaks.length) {
      updatedBreaks = List<BreakModel>.from(updatedBreaks);
      updatedBreaks.removeAt(event.index);
    }

    // Adjust currentTaskIndex if necessary
    int newCurrentIndex = model.currentTaskIndex;
    if (event.index == model.currentTaskIndex) {
      newCurrentIndex = event.index.clamp(0, reindexed.length - 1);
    } else if (event.index < model.currentTaskIndex) {
      newCurrentIndex = model.currentTaskIndex - 1;
    }

    emit(
      state.copyWith(
        model: model.copyWith(
          tasks: reindexed,
          breaks: updatedBreaks,
          currentTaskIndex: newCurrentIndex,
        ),
      ),
    );
  }
}
