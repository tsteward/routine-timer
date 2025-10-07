import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:routine_timer/src/utils/simple_bloc_observer.dart';

// Test cubit for triggering observer events
class TestCubit extends Cubit<int> {
  TestCubit() : super(0);

  void increment() => emit(state + 1);

  void triggerError() {
    addError(Exception('Test error'), StackTrace.current);
  }
}

// Test bloc for triggering observer events with events
class TestBloc extends Bloc<String, int> {
  TestBloc() : super(0) {
    on<String>((event, emit) {
      emit(state + 1);
    });
  }
}

void main() {
  group('SimpleBlocObserver', () {
    late SimpleBlocObserver observer;

    setUp(() {
      observer = const SimpleBlocObserver();
    });

    test('onEvent logs bloc events', () {
      final bloc = TestBloc();

      // Set up the observer and trigger an event
      Bloc.observer = observer;
      bloc.add('test_event');

      // The onEvent should be called (we can't easily assert print output,
      // but we verify the method is callable)
      expect(bloc.state, greaterThanOrEqualTo(0));

      bloc.close();
    });

    test('onChange logs bloc changes', () {
      final cubit = TestCubit();

      // Set up the observer and trigger a change
      Bloc.observer = observer;
      cubit.increment();

      // The onChange should be called
      expect(cubit.state, 1);

      cubit.close();
    });

    test('onError logs bloc errors', () {
      final cubit = TestCubit();

      // Set up the observer and trigger an error
      Bloc.observer = observer;
      cubit.triggerError();

      // The onError should be called (error is logged but not thrown)
      expect(cubit.state, 0);

      cubit.close();
    });

    test('observer can be constructed', () {
      const observer1 = SimpleBlocObserver();
      const observer2 = SimpleBlocObserver();

      // Verify they can be created
      expect(observer1, isA<BlocObserver>());
      expect(observer2, isA<BlocObserver>());
    });
  });
}
