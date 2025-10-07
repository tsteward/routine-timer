import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:routine_timer/src/utils/simple_bloc_observer.dart';

// Test bloc for observer testing
class TestEvent {}

class TestState {
  final int value;
  const TestState(this.value);
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

    test('can be instantiated', () {
      expect(observer, isNotNull);
      expect(observer, isA<BlocObserver>());
    });

    test('onEvent is called when bloc receives event', () {
      final bloc = TestBloc();
      
      // Set the observer
      final previousObserver = Bloc.observer;
      Bloc.observer = observer;

      // This should trigger onEvent (we can't directly test print output,
      // but we can verify the method can be called without error)
      bloc.add(TestEvent());
      
      // Clean up
      Bloc.observer = previousObserver;
      bloc.close();
    });

    test('onChange is called when bloc state changes', () {
      final bloc = TestBloc();
      
      // Set the observer
      final previousObserver = Bloc.observer;
      Bloc.observer = observer;

      // This should trigger onChange
      bloc.add(TestEvent());
      
      // Clean up
      Bloc.observer = previousObserver;
      bloc.close();
    });

    test('onError is called when bloc encounters error', () {
      final bloc = TestBloc();
      
      // Set the observer
      final previousObserver = Bloc.observer;
      Bloc.observer = observer;

      // This should trigger onError
      bloc.triggerError();
      
      // Clean up
      Bloc.observer = previousObserver;
      bloc.close();
    });

    test('onEvent does not throw exception', () {
      final bloc = TestBloc();
      final event = TestEvent();
      
      expect(
        () => observer.onEvent(bloc, event),
        returnsNormally,
      );
      
      bloc.close();
    });

    test('onChange does not throw exception', () {
      final bloc = TestBloc();
      final change = Change<TestState>(
        currentState: const TestState(0),
        nextState: const TestState(1),
      );
      
      expect(
        () => observer.onChange(bloc, change),
        returnsNormally,
      );
      
      bloc.close();
    });

    test('onError does not throw exception', () {
      final bloc = TestBloc();
      final error = Exception('Test error');
      final stackTrace = StackTrace.current;
      
      expect(
        () => observer.onError(bloc, error, stackTrace),
        returnsNormally,
      );
      
      bloc.close();
    });
  });
}
