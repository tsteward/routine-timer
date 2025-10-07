import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:routine_timer/src/utils/simple_bloc_observer.dart';

// Simple test bloc for observer testing
class TestEvent {}

class TestState {
  const TestState(this.value);
  final int value;
}

class TestBloc extends Bloc<TestEvent, TestState> {
  TestBloc() : super(const TestState(0)) {
    on<TestEvent>((event, emit) {
      emit(TestState(state.value + 1));
    });
  }

  void triggerError() {
    addError(Exception('Test error'), StackTrace.current);
  }
}

void main() {
  group('SimpleBlocObserver', () {
    late SimpleBlocObserver observer;

    setUp(() {
      observer = const SimpleBlocObserver();
    });

    test('onEvent is called when bloc receives event', () {
      final bloc = TestBloc();
      final event = TestEvent();

      // This test verifies onEvent is called without errors
      expect(() => observer.onEvent(bloc, event), returnsNormally);
    });

    test('onChange is called when bloc state changes', () {
      final bloc = TestBloc();
      const change = Change<TestState>(
        currentState: TestState(0),
        nextState: TestState(1),
      );

      // This test verifies onChange is called without errors
      expect(() => observer.onChange(bloc, change), returnsNormally);
    });

    test('onError is called when bloc encounters error', () {
      final bloc = TestBloc();
      final error = Exception('Test exception');
      final stackTrace = StackTrace.current;

      // This test verifies onError is called without errors
      expect(
        () => observer.onError(bloc, error, stackTrace),
        returnsNormally,
      );
    });

    test('observer can be set as global Bloc.observer', () {
      expect(() => Bloc.observer = observer, returnsNormally);
    });

    test('observer handles multiple event types', () {
      final bloc = TestBloc();
      final event1 = TestEvent();
      final event2 = TestEvent();

      expect(() {
        observer.onEvent(bloc, event1);
        observer.onEvent(bloc, event2);
      }, returnsNormally);
    });

    test('observer handles multiple state changes', () {
      final bloc = TestBloc();
      const change1 = Change<TestState>(
        currentState: TestState(0),
        nextState: TestState(1),
      );
      const change2 = Change<TestState>(
        currentState: TestState(1),
        nextState: TestState(2),
      );

      expect(() {
        observer.onChange(bloc, change1);
        observer.onChange(bloc, change2);
      }, returnsNormally);
    });

    test('observer handles null events', () {
      final bloc = TestBloc();

      expect(() => observer.onEvent(bloc, null), returnsNormally);
    });

    test('observer works with real bloc lifecycle', () {
      Bloc.observer = observer;
      final bloc = TestBloc();

      expect(() {
        bloc.add(TestEvent());
      }, returnsNormally);

      bloc.close();
    });

    test('observer handles errors with different stack traces', () {
      final bloc = TestBloc();
      final error1 = Exception('Error 1');
      final error2 = Exception('Error 2');
      final stackTrace1 = StackTrace.current;
      final stackTrace2 = StackTrace.current;

      expect(() {
        observer.onError(bloc, error1, stackTrace1);
        observer.onError(bloc, error2, stackTrace2);
      }, returnsNormally);
    });
  });
}
