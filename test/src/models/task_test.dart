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
        estimatedDuration: 1200,
        actualDuration: 1150,
        isCompleted: false,
        order: 2,
      );
      final json = task.toJson();
      final decoded = TaskModel.fromJson(json);
      expect(decoded.id, task.id);
      expect(decoded.name, task.name);
      expect(decoded.estimatedDuration, task.estimatedDuration);
      expect(decoded.actualDuration, task.actualDuration);
      expect(decoded.isCompleted, task.isCompleted);
      expect(decoded.order, task.order);
    });

    test('fromMap handles default isCompleted value', () {
      final map = {
        'id': 't3',
        'name': 'Task',
        'estimatedDuration': 300,
        'actualDuration': null,
        'order': 0,
      };
      final task = TaskModel.fromMap(map);
      expect(task.isCompleted, false); // Should default to false
    });

    test('copyWith can update all fields', () {
      const task = TaskModel(
        id: 't1',
        name: 'Original',
        estimatedDuration: 100,
        order: 0,
      );
      final updated = task.copyWith(
        id: 't2',
        name: 'Updated',
        estimatedDuration: 200,
        actualDuration: 180,
        isCompleted: true,
        order: 1,
      );
      expect(updated.id, 't2');
      expect(updated.name, 'Updated');
      expect(updated.estimatedDuration, 200);
      expect(updated.actualDuration, 180);
      expect(updated.isCompleted, true);
      expect(updated.order, 1);
    });
  });
}
