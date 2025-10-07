import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/src/models/task.dart';

void main() {
  group('TaskModel', () {
    test('creates instance with required parameters', () {
      const task = TaskModel(
        id: 'task1',
        name: 'Morning Run',
        estimatedDuration: 1800,
        order: 0,
      );
      expect(task.id, 'task1');
      expect(task.name, 'Morning Run');
      expect(task.estimatedDuration, 1800);
      expect(task.order, 0);
      expect(task.actualDuration, isNull); // optional, default null
      expect(task.isCompleted, false); // optional, default false
    });

    test('creates instance with all parameters', () {
      const task = TaskModel(
        id: 'task2',
        name: 'Breakfast',
        estimatedDuration: 900,
        actualDuration: 850,
        isCompleted: true,
        order: 1,
      );
      expect(task.id, 'task2');
      expect(task.name, 'Breakfast');
      expect(task.estimatedDuration, 900);
      expect(task.actualDuration, 850);
      expect(task.isCompleted, true);
      expect(task.order, 1);
    });

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

    test('fromMap handles null actualDuration', () {
      final map = {
        'id': 'task3',
        'name': 'Exercise',
        'estimatedDuration': 1200,
        'actualDuration': null,
        'isCompleted': false,
        'order': 2,
      };
      final task = TaskModel.fromMap(map);
      expect(task.id, 'task3');
      expect(task.actualDuration, isNull);
      expect(task.isCompleted, false);
    });

    test('fromMap uses default value for isCompleted when missing', () {
      final map = {
        'id': 'task4',
        'name': 'Meditation',
        'estimatedDuration': 600,
        'order': 0,
      };
      final task = TaskModel.fromMap(map);
      expect(task.isCompleted, false);
    });

    test('toJson creates valid JSON string', () {
      const task = TaskModel(
        id: 'task5',
        name: 'Reading',
        estimatedDuration: 1500,
        actualDuration: 1450,
        isCompleted: true,
        order: 3,
      );
      final json = task.toJson();
      expect(json, isA<String>());
      expect(json, contains('task5'));
      expect(json, contains('Reading'));
      expect(json, contains('1500'));
      expect(json, contains('1450'));
    });

    test('fromJson parses valid JSON string', () {
      const jsonString = '{"id":"task6","name":"Yoga","estimatedDuration":2400,'
          '"actualDuration":null,"isCompleted":false,"order":4}';
      final task = TaskModel.fromJson(jsonString);
      expect(task.id, 'task6');
      expect(task.name, 'Yoga');
      expect(task.estimatedDuration, 2400);
      expect(task.actualDuration, isNull);
      expect(task.isCompleted, false);
      expect(task.order, 4);
    });

    test('toJson/fromJson roundtrip', () {
      const original = TaskModel(
        id: 'task7',
        name: 'Stretching',
        estimatedDuration: 600,
        actualDuration: 630,
        isCompleted: true,
        order: 5,
      );
      final json = original.toJson();
      final decoded = TaskModel.fromJson(json);
      expect(decoded.id, original.id);
      expect(decoded.name, original.name);
      expect(decoded.estimatedDuration, original.estimatedDuration);
      expect(decoded.actualDuration, original.actualDuration);
      expect(decoded.isCompleted, original.isCompleted);
      expect(decoded.order, original.order);
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

    test('copyWith can update actualDuration and isCompleted', () {
      const task = TaskModel(
        id: 'task8',
        name: 'Task',
        estimatedDuration: 300,
        order: 0,
      );
      final completed = task.copyWith(
        actualDuration: 310,
        isCompleted: true,
      );
      expect(completed.actualDuration, 310);
      expect(completed.isCompleted, true);
      expect(completed.id, task.id);
      expect(completed.name, task.name);
    });

    test('copyWith with no parameters returns copy with same values', () {
      const task = TaskModel(
        id: 'task9',
        name: 'Original',
        estimatedDuration: 450,
        actualDuration: 460,
        isCompleted: true,
        order: 2,
      );
      final updated = task.copyWith();
      expect(updated.id, task.id);
      expect(updated.name, task.name);
      expect(updated.estimatedDuration, task.estimatedDuration);
      expect(updated.actualDuration, task.actualDuration);
      expect(updated.isCompleted, task.isCompleted);
      expect(updated.order, task.order);
    });
  });
}
