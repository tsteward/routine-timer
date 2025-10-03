part of 'routine_bloc.dart';

class RoutineBlocState extends Equatable {
  const RoutineBlocState({
    required this.loading,
    this.model,
    this.errorMessage,
  });

  final bool loading;
  final RoutineStateModel? model;
  final String? errorMessage;

  factory RoutineBlocState.initial() => const RoutineBlocState(loading: false);

  RoutineBlocState copyWith({
    bool? loading,
    RoutineStateModel? model,
    String? errorMessage,
  }) {
    return RoutineBlocState(
      loading: loading ?? this.loading,
      model: model ?? this.model,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [loading, model, errorMessage];
}
