import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/src/models/task.dart';

void main() {
  group('TaskModel', () {
    test('toMap/fromMap roundtrip', () {
      const task = TaskModel(
        id: 't1',
        name: 'Shower',
        estimatedDuration: 600,
        actualDuration: 580,
        isCompleted: true,
        order: 1,
      );
      final map = task.toMap();
      final decoded = TaskModel.fromMap(map);
      expect(decoded.id, task.id);
      expect(decoded.name, task.name);
      expect(decoded.estimatedDuration, task.estimatedDuration);
      expect(decoded.actualDuration, task.actualDuration);
      expect(decoded.isCompleted, task.isCompleted);
      expect(decoded.order, task.order);
    });

    test('copyWith updates selected fields', () {
      const task = TaskModel(
        id: 't',
        name: 'A',
        estimatedDuration: 60,
        order: 0,
      );
      final updated = task.copyWith(name: 'B', order: 2);
      expect(updated.name, 'B');
      expect(updated.order, 2);
      expect(updated.id, task.id);
      expect(updated.estimatedDuration, task.estimatedDuration);
    });

    test('toJson/fromJson roundtrip', () {
      const task = TaskModel(
        id: 't2',
        name: 'Exercise',
        estimatedDuration: 900,
        actualDuration: 850,
        isCompleted: true,
        order: 2,
      );
      final json = task.toJson();
      expect(json, isA<String>());

      final decoded = TaskModel.fromJson(json);
      expect(decoded.id, task.id);
      expect(decoded.name, task.name);
      expect(decoded.estimatedDuration, task.estimatedDuration);
      expect(decoded.actualDuration, task.actualDuration);
      expect(decoded.isCompleted, task.isCompleted);
      expect(decoded.order, task.order);
    });

    test('copyWith can update individual fields', () {
      const task = TaskModel(
        id: 't1',
        name: 'Original',
        estimatedDuration: 100,
        order: 0,
      );

      final withId = task.copyWith(id: 't2');
      expect(withId.id, 't2');
      expect(withId.name, 'Original');

      final withActual = task.copyWith(actualDuration: 95);
      expect(withActual.actualDuration, 95);

      final withCompleted = task.copyWith(isCompleted: true);
      expect(withCompleted.isCompleted, true);

      final withEstimated = task.copyWith(estimatedDuration: 200);
      expect(withEstimated.estimatedDuration, 200);
    });
  });
}
