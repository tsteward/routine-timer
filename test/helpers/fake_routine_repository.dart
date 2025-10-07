import 'package:routine_timer/src/models/routine_state.dart';
import 'package:routine_timer/src/repositories/routine_repository.dart';

/// A fake repository for testing that doesn't require Firebase.
/// Stores routine data in memory.
class FakeRoutineRepository extends RoutineRepository {
  FakeRoutineRepository({RoutineStateModel? initialRoutine})
    : _routine = initialRoutine,
      super(firestore: null, authService: null);

  RoutineStateModel? _routine;

  @override
  Future<bool> saveRoutine(RoutineStateModel routine) async {
    _routine = routine;
    return true;
  }

  @override
  Future<RoutineStateModel?> loadRoutine() async {
    return _routine;
  }

  @override
  Stream<RoutineStateModel?> watchRoutine() {
    return Stream.value(_routine);
  }

  @override
  Future<bool> deleteRoutine() async {
    _routine = null;
    return true;
  }
}
