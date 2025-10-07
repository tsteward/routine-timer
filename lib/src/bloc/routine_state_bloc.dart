part of 'routine_bloc.dart';

class RoutineBlocState extends Equatable {
  const RoutineBlocState({
    required this.loading,
    this.model,
    this.errorMessage,
    this.saving = false,
    this.saveError,
  });

  final bool loading;
  final RoutineStateModel? model;
  final String? errorMessage;
  final bool saving;
  final String? saveError;

  factory RoutineBlocState.initial() => const RoutineBlocState(loading: false);

  RoutineBlocState copyWith({
    bool? loading,
    RoutineStateModel? model,
    String? errorMessage,
    bool? saving,
    String? saveError,
  }) {
    return RoutineBlocState(
      loading: loading ?? this.loading,
      model: model ?? this.model,
      errorMessage: errorMessage,
      saving: saving ?? this.saving,
      saveError: saveError,
    );
  }

  @override
  List<Object?> get props => [loading, model, errorMessage, saving, saveError];
}
