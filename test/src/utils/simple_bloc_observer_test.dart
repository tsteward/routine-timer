import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/src/utils/simple_bloc_observer.dart';

/// A test bloc for exercising the observer
class TestBloc extends Bloc<TestEvent, int> {
  TestBloc() : super(0) {
    on<TestEvent>((event, emit) => emit(state + 1));
  }
}

class TestEvent {}

void main() {
  group('SimpleBlocObserver', () {
    late SimpleBlocObserver observer;

    setUp(() {
      observer = const SimpleBlocObserver();
    });

    test('onEvent logs bloc events', () {
      final bloc = TestBloc();
      final event = TestEvent();

      // Should not throw when logging event
      expect(() => observer.onEvent(bloc, event), returnsNormally);
    });

    test('onChange logs bloc changes', () {
      final bloc = TestBloc();
      const change = Change<int>(currentState: 0, nextState: 1);

      // Should not throw when logging change
      expect(() => observer.onChange(bloc, change), returnsNormally);
    });

    test('onError logs bloc errors', () {
      final bloc = TestBloc();
      final error = Exception('Test error');
      final stackTrace = StackTrace.current;

      // Should not throw when logging error
      expect(() => observer.onError(bloc, error, stackTrace), returnsNormally);
    });

    test('observer can be instantiated with const constructor', () {
      const observer1 = SimpleBlocObserver();
      const observer2 = SimpleBlocObserver();

      // Verify const constructor creates identical instances
      expect(observer1, equals(observer2));
    });

    test('onEvent with null event', () {
      final bloc = TestBloc();

      // Should handle null event gracefully
      expect(() => observer.onEvent(bloc, null), returnsNormally);
    });
  });
}
