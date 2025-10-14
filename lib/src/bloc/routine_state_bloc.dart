part of 'routine_bloc.dart';

class RoutineBlocState extends Equatable {
  const RoutineBlocState({
    required this.loading,
    this.model,
    this.errorMessage,
    this.saving = false,
    this.saveError,
    this.completionData,
    this.isCompleted = false,
  });

  final bool loading;
  final RoutineStateModel? model;
  final String? errorMessage;
  final bool saving;
  final String? saveError;
  final RoutineCompletionModel? completionData;
  final bool isCompleted;

  factory RoutineBlocState.initial() => const RoutineBlocState(loading: false);

  RoutineBlocState copyWith({
    bool? loading,
    RoutineStateModel? model,
    String? errorMessage,
    bool? saving,
    String? saveError,
    RoutineCompletionModel? completionData,
    bool? isCompleted,
  }) {
    return RoutineBlocState(
      loading: loading ?? this.loading,
      model: model ?? this.model,
      errorMessage: errorMessage,
      saving: saving ?? this.saving,
      saveError: saveError,
      completionData: completionData ?? this.completionData,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  @override
  List<Object?> get props => [
    loading,
    model,
    errorMessage,
    saving,
    saveError,
    completionData,
    isCompleted,
  ];
}
