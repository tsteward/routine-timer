import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/break.dart';
import '../models/routine_settings.dart';
import '../models/routine_state.dart';
import '../models/task.dart';
import '../repositories/routine_repository.dart';

part 'routine_events.dart';
part 'routine_state_bloc.dart';

/// RoutineBloc manages the routine configuration and runtime navigation
/// between tasks with Firebase persistence.
class RoutineBloc extends Bloc<RoutineEvent, RoutineBlocState> {
  RoutineBloc({RoutineRepository? repository})
    : _repository = repository ?? RoutineRepository(),
      super(RoutineBlocState.initial()) {
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
    on<AddTask>(_onAddTask);
    on<UpdateBreakDuration>(_onUpdateBreakDuration);
    on<ResetBreakToDefault>(_onResetBreakToDefault);
    on<LoadRoutineFromFirebase>(_onLoadFromFirebase);
    on<SaveRoutineToFirebase>(_onSaveToFirebase);
    on<ReloadRoutineForUser>(_onReloadRoutineForUser);
    on<StartBreak>(_onStartBreak);
    on<SkipBreak>(_onSkipBreak);
    on<CompleteBreak>(_onCompleteBreak);
  }

  final RoutineRepository _repository;

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

    // Set default start time to 6am today
    final now = DateTime.now();
    final sixAm = DateTime(now.year, now.month, now.day, 6, 0);

    final settings = RoutineSettingsModel(
      startTime: sixAm.millisecondsSinceEpoch,
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
      selectedTaskId: tasks.isNotEmpty ? tasks.first.id : null,
      isRunning: false,
    );

    emit(state.copyWith(loading: false, model: model));
  }

  void _onSelectTask(SelectTask event, Emitter<RoutineBlocState> emit) {
    final model = state.model;
    if (model == null) return;

    // Verify the task ID exists in the task list
    final taskExists = model.tasks.any((task) => task.id == event.taskId);
    if (!taskExists) return;

    emit(state.copyWith(model: model.copyWith(selectedTaskId: event.taskId)));
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

    // Auto-save after reordering
    add(const SaveRoutineToFirebase());
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

    // Auto-save after toggling break
    add(const SaveRoutineToFirebase());
  }

  void _onUpdateSettings(UpdateSettings event, Emitter<RoutineBlocState> emit) {
    final model = state.model;
    if (model == null) return;

    // Check if default break duration changed
    final oldDuration = model.settings.defaultBreakDuration;
    final newDuration = event.settings.defaultBreakDuration;

    if (oldDuration != newDuration && model.breaks != null) {
      // Update all non-customized breaks to use the new default duration
      final updatedBreaks = model.breaks!.map((breakModel) {
        if (!breakModel.isCustomized) {
          return breakModel.copyWith(duration: newDuration);
        }
        return breakModel;
      }).toList();

      emit(
        state.copyWith(
          model: model.copyWith(
            settings: event.settings,
            breaks: updatedBreaks,
          ),
        ),
      );
    } else {
      emit(state.copyWith(model: model.copyWith(settings: event.settings)));
    }

    // Auto-save after settings update
    add(const SaveRoutineToFirebase());
  }

  void _onMarkTaskDone(MarkTaskDone event, Emitter<RoutineBlocState> emit) {
    final model = state.model;
    if (model == null) return;

    final currentIndex = model.currentTaskIndex;
    if (currentIndex < 0 || currentIndex >= model.tasks.length) return;

    final updatedTasks = List<TaskModel>.from(model.tasks);
    final current = updatedTasks[currentIndex];
    updatedTasks[currentIndex] = current.copyWith(
      isCompleted: true,
      actualDuration: event.actualDuration,
    );

    // Check if there's an enabled break after this task
    final hasBreakAfter =
        model.breaks != null &&
        currentIndex < model.breaks!.length &&
        model.breaks![currentIndex].isEnabled;

    if (hasBreakAfter && currentIndex < model.tasks.length - 1) {
      // Start the break instead of advancing to next task immediately
      emit(
        state.copyWith(
          model: model.copyWith(
            tasks: updatedTasks,
            isOnBreak: true,
            currentBreakIndex: currentIndex,
          ),
        ),
      );
    } else {
      // No break, select the next task directly
      final nextIndex = (currentIndex + 1).clamp(0, updatedTasks.length - 1);
      final nextTaskId = nextIndex < updatedTasks.length
          ? updatedTasks[nextIndex].id
          : null;

      emit(
        state.copyWith(
          model: model.copyWith(
            tasks: updatedTasks,
            selectedTaskId: nextTaskId,
          ),
        ),
      );
    }
  }

  void _onGoToPreviousTask(
    GoToPreviousTask event,
    Emitter<RoutineBlocState> emit,
  ) {
    final model = state.model;
    if (model == null || model.tasks.isEmpty) return;

    final currentIndex = model.currentTaskIndex;
    final prevIndex = (currentIndex - 1).clamp(0, model.tasks.length - 1);
    final prevTaskId = model.tasks[prevIndex].id;

    emit(state.copyWith(model: model.copyWith(selectedTaskId: prevTaskId)));
  }

  void _onUpdateTask(UpdateTask event, Emitter<RoutineBlocState> emit) {
    final model = state.model;
    if (model == null) return;
    if (event.index < 0 || event.index >= model.tasks.length) return;

    final updatedTasks = List<TaskModel>.from(model.tasks);
    updatedTasks[event.index] = event.task;

    emit(state.copyWith(model: model.copyWith(tasks: updatedTasks)));

    // Auto-save after task update
    add(const SaveRoutineToFirebase());
  }

  void _onDuplicateTask(DuplicateTask event, Emitter<RoutineBlocState> emit) {
    final model = state.model;
    if (model == null) return;
    if (event.index < 0 || event.index >= model.tasks.length) return;

    final taskToDuplicate = model.tasks[event.index];
    final newTask = taskToDuplicate.copyWith(
      id: '${taskToDuplicate.id}-copy-${DateTime.now().millisecondsSinceEpoch}',
      order: event.index + 1,
    );

    final updatedTasks = List<TaskModel>.from(model.tasks);
    updatedTasks.insert(event.index + 1, newTask);

    // Reassign order values to maintain consistency.
    final reindexed = <TaskModel>[];
    for (var i = 0; i < updatedTasks.length; i++) {
      reindexed.add(updatedTasks[i].copyWith(order: i));
    }

    // Also duplicate the break if breaks exist
    List<BreakModel>? updatedBreaks = model.breaks;
    if (model.breaks != null && event.index < model.breaks!.length) {
      updatedBreaks = List<BreakModel>.from(model.breaks!);
      final breakToDuplicate = updatedBreaks[event.index];
      updatedBreaks.insert(event.index + 1, breakToDuplicate);
    }

    emit(
      state.copyWith(
        model: model.copyWith(tasks: reindexed, breaks: updatedBreaks),
      ),
    );

    // Auto-save after duplication
    add(const SaveRoutineToFirebase());
  }

  void _onDeleteTask(DeleteTask event, Emitter<RoutineBlocState> emit) {
    final model = state.model;
    if (model == null) return;
    if (event.index < 0 || event.index >= model.tasks.length) return;
    if (model.tasks.length <= 1) return; // Don't delete last task

    final taskToDelete = model.tasks[event.index];
    final isSelectedTaskBeingDeleted = model.selectedTaskId == taskToDelete.id;

    final updatedTasks = List<TaskModel>.from(model.tasks);
    updatedTasks.removeAt(event.index);

    // Reassign order values to maintain consistency.
    final reindexed = <TaskModel>[];
    for (var i = 0; i < updatedTasks.length; i++) {
      reindexed.add(updatedTasks[i].copyWith(order: i));
    }

    // Also remove the corresponding break if breaks exist
    List<BreakModel>? updatedBreaks = model.breaks;
    if (model.breaks != null && event.index < model.breaks!.length) {
      updatedBreaks = List<BreakModel>.from(model.breaks!);
      updatedBreaks.removeAt(event.index);
    }

    // Determine new selected task ID if the currently selected task was deleted
    String? newSelectedTaskId = model.selectedTaskId;
    if (isSelectedTaskBeingDeleted && reindexed.isNotEmpty) {
      // Select the task that's now at the same position, or the last task if we deleted the last one
      final newIndex = event.index >= reindexed.length
          ? reindexed.length - 1
          : event.index;
      newSelectedTaskId = reindexed[newIndex].id;
    }

    emit(
      state.copyWith(
        model: model.copyWith(
          tasks: reindexed,
          breaks: updatedBreaks,
          selectedTaskId: newSelectedTaskId,
        ),
      ),
    );

    // Auto-save after deletion
    add(const SaveRoutineToFirebase());
  }

  void _onAddTask(AddTask event, Emitter<RoutineBlocState> emit) {
    final model = state.model;
    if (model == null) return;

    // Generate a unique ID for the new task using timestamp + counter
    final now = DateTime.now().millisecondsSinceEpoch;
    final newId = '$now-${model.tasks.length}';
    final newOrder = model.tasks.length;

    final newTask = TaskModel(
      id: newId,
      name: event.name,
      estimatedDuration: event.durationSeconds,
      order: newOrder,
    );

    final updatedTasks = List<TaskModel>.from(model.tasks)..add(newTask);

    // Add a new break if breaks are enabled and there are existing tasks
    List<BreakModel>? updatedBreaks = model.breaks;
    if (model.breaks != null && model.tasks.isNotEmpty) {
      updatedBreaks = List<BreakModel>.from(model.breaks!)
        ..add(
          BreakModel(
            duration: model.settings.defaultBreakDuration,
            isEnabled: model.settings.breaksEnabledByDefault,
          ),
        );
    }

    emit(
      state.copyWith(
        model: model.copyWith(tasks: updatedTasks, breaks: updatedBreaks),
      ),
    );

    // Auto-save after adding task
    add(const SaveRoutineToFirebase());
  }

  void _onLoadFromFirebase(
    LoadRoutineFromFirebase event,
    Emitter<RoutineBlocState> emit,
  ) async {
    emit(state.copyWith(loading: true));

    final routine = await _repository.loadRoutine();

    if (routine != null) {
      emit(state.copyWith(loading: false, model: routine));
    } else {
      // No saved routine, load sample data
      emit(state.copyWith(loading: false));
      add(const LoadSampleRoutine());
    }
  }

  void _onSaveToFirebase(
    SaveRoutineToFirebase event,
    Emitter<RoutineBlocState> emit,
  ) async {
    final model = state.model;
    if (model == null) return;

    emit(state.copyWith(saving: true));

    final success = await _repository.saveRoutine(model);

    emit(
      state.copyWith(
        saving: false,
        saveError: success ? null : 'Failed to save routine',
      ),
    );
  }

  void _onReloadRoutineForUser(
    ReloadRoutineForUser event,
    Emitter<RoutineBlocState> emit,
  ) {
    // Clear current state
    emit(RoutineBlocState.initial());

    // Load data for new user
    add(const LoadRoutineFromFirebase());
  }

  void _onUpdateBreakDuration(
    UpdateBreakDuration event,
    Emitter<RoutineBlocState> emit,
  ) {
    final model = state.model;
    if (model == null || model.breaks == null) return;

    if (event.index < 0 || event.index >= model.breaks!.length) return;

    final updated = List<BreakModel>.from(model.breaks!);
    final target = updated[event.index];
    // Mark as customized when manually updated
    updated[event.index] = target.copyWith(
      duration: event.duration,
      isCustomized: true,
    );

    emit(state.copyWith(model: model.copyWith(breaks: updated)));

    // Auto-save after updating break duration
    add(const SaveRoutineToFirebase());
  }

  void _onResetBreakToDefault(
    ResetBreakToDefault event,
    Emitter<RoutineBlocState> emit,
  ) {
    final model = state.model;
    if (model == null || model.breaks == null) return;

    if (event.index < 0 || event.index >= model.breaks!.length) return;

    final updated = List<BreakModel>.from(model.breaks!);
    // Reset to default: set duration to default and mark as non-customized
    updated[event.index] = updated[event.index].copyWith(
      duration: model.settings.defaultBreakDuration,
      isCustomized: false,
    );

    emit(state.copyWith(model: model.copyWith(breaks: updated)));

    // Auto-save after resetting break
    add(const SaveRoutineToFirebase());
  }

  void _onStartBreak(StartBreak event, Emitter<RoutineBlocState> emit) {
    final model = state.model;
    if (model == null || model.breaks == null) return;

    if (event.breakIndex < 0 || event.breakIndex >= model.breaks!.length) {
      return;
    }

    final breakToStart = model.breaks![event.breakIndex];
    if (!breakToStart.isEnabled) return;

    emit(
      state.copyWith(
        model: model.copyWith(
          isOnBreak: true,
          currentBreakIndex: event.breakIndex,
        ),
      ),
    );
  }

  void _onSkipBreak(SkipBreak event, Emitter<RoutineBlocState> emit) {
    final model = state.model;
    if (model == null || !model.isOnBreak) return;

    _advanceToNextTask(emit, model);
  }

  void _onCompleteBreak(CompleteBreak event, Emitter<RoutineBlocState> emit) {
    final model = state.model;
    if (model == null || !model.isOnBreak) return;

    _advanceToNextTask(emit, model);
  }

  void _advanceToNextTask(
    Emitter<RoutineBlocState> emit,
    RoutineStateModel model,
  ) {
    final currentIndex = model.currentTaskIndex;
    final nextIndex = (currentIndex + 1).clamp(0, model.tasks.length - 1);
    final nextTaskId = nextIndex < model.tasks.length
        ? model.tasks[nextIndex].id
        : null;

    // Create a new model with break state cleared
    final updatedModel = RoutineStateModel(
      tasks: model.tasks,
      breaks: model.breaks,
      settings: model.settings,
      selectedTaskId: nextTaskId,
      isRunning: model.isRunning,
      isOnBreak: false,
      currentBreakIndex: null,
    );

    emit(state.copyWith(model: updatedModel));
  }
}
