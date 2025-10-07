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
  });
}
