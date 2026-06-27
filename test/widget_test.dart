import 'package:flutter_test/flutter_test.dart';
import 'package:focusboard/app/model/eisenhower_config.dart';
import 'package:focusboard/app/model/eisenhower_task_model.dart';
import 'package:focusboard/app/model/task_model.dart';
import 'package:focusboard/app/model/task_validator.dart';

void main() {
  group('Task model', () {
    test('round-trips through JSON', () {
      final Task t = Task(
        id: TaskValidator.generateUuid(),
        title: 'Hello world',
        isHighPriority: true,
        column: KanbanColumn.inProgress,
      );
      final Map<String, dynamic> json = t.toJson();
      final Task t2 = Task.fromJson(json);
      expect(t2.id, t.id);
      expect(t2.title, 'Hello world');
      expect(t2.isHighPriority, isTrue);
      expect(t2.column, KanbanColumn.inProgress);
    });

    test('rejects invalid id on parse', () {
      expect(
        () => Task.fromJson(<String, dynamic>{'id': '', 'title': 'x'}),
        throwsArgumentError,
      );
    });
  });

  group('EisenhowerTask model', () {
    test('computes quadrant from flags', () {
      final EisenhowerTask t = EisenhowerTask(
        id: 'id-1',
        title: 'do it now',
        isUrgent: true,
        isImportant: true,
      );
      expect(t.quadrant, EisenhowerQuadrant.urgentImportant);
      expect(t.quadrantName, 'Do First');
    });
  });
}
