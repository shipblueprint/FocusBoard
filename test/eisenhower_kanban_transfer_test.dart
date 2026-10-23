import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusboard/app/controller/eisenhower_controller.dart';
import 'package:focusboard/app/controller/kanban_controller.dart';
import 'package:focusboard/app/data/task_storage.dart';
import 'package:focusboard/app/model/eisenhower_config.dart';
import 'package:focusboard/app/model/eisenhower_task_model.dart';
import 'package:focusboard/app/model/task_model.dart';
import 'package:focusboard/view/apps/eisenhower/eisenhower_screen.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

EisenhowerTask matrixTask(
  String id, {
  required String title,
  bool isUrgent = false,
  bool isImportant = false,
  bool isHighPriority = false,
  KanbanColumn column = KanbanColumn.toDo,
}) {
  return EisenhowerTask(
    id: id,
    title: title,
    isUrgent: isUrgent,
    isImportant: isImportant,
    isHighPriority: isHighPriority,
    column: column,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late KanbanController kanban;
  late EisenhowerController eisen;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    kanban = Get.put<KanbanController>(KanbanController());
    eisen = Get.put<EisenhowerController>(EisenhowerController(kanban: kanban));

    // Both controllers seed sample tasks when storage is empty; let that load
    // finish, then take the lists under test control.
    await Future<void>.delayed(const Duration(milliseconds: 10));
    kanban.tasks.clear();
    eisen.tasks.clear();
  });

  tearDown(() {
    Get.reset();
  });

  group('EisenhowerController.moveDoFirstToKanban', () {
    test('moves every Do First task into the Kanban To Do column', () async {
      eisen.tasks.addAll(<EisenhowerTask>[
        matrixTask('a', title: 'Fire now', isUrgent: true, isImportant: true),
        matrixTask('b',
            title: 'Also on fire',
            isUrgent: true,
            isImportant: true,
            isHighPriority: true),
        matrixTask('c', title: 'Schedule me', isImportant: true),
        matrixTask('d', title: 'Delegate me', isUrgent: true),
        matrixTask('e', title: 'Eliminate me'),
      ]);
      kanban.tasks
          .add(Task(id: 'k1', title: 'Already on board', column: KanbanColumn.inProgress));

      final int moved = await eisen.moveDoFirstToKanban();

      expect(moved, 2);
      expect(eisen.byQuadrant(EisenhowerQuadrant.urgentImportant), isEmpty);
      expect(eisen.tasks.map((EisenhowerTask t) => t.id), <String>['c', 'd', 'e']);
      expect(
        kanban.byColumn(KanbanColumn.toDo).map((Task t) => t.id),
        <String>['a', 'b'],
      );
      expect(kanban.tasks.length, 3);
    });

    test('lands in To Do regardless of the task\'s previous column', () async {
      eisen.tasks.add(matrixTask(
        'a',
        title: 'Was parked in Done',
        isUrgent: true,
        isImportant: true,
        column: KanbanColumn.done,
      ));

      await eisen.moveDoFirstToKanban();

      expect(kanban.tasks.single.column, KanbanColumn.toDo);
    });

    test('imports a plain Task so no Eisenhower field reaches the board',
        () async {
      eisen.tasks.add(matrixTask('a',
          title: 'Becomes a board task',
          isUrgent: true,
          isImportant: true,
          isHighPriority: true));

      await eisen.moveDoFirstToKanban();

      final Task imported = kanban.tasks.single;
      expect(imported, isNot(isA<EisenhowerTask>()));
      expect(imported.id, 'a');
      expect(imported.title, 'Becomes a board task');
      expect(imported.isHighPriority, isTrue);
      expect(imported.toJson().keys,
          isNot(containsAll(<String>['isUrgent', 'isImportant', 'type'])));
    });

    test('is a no-op while Do First is empty', () async {
      eisen.tasks.add(matrixTask('c', title: 'Schedule me', isImportant: true));
      kanban.tasks.add(Task(id: 'k1', title: 'Already on board'));

      final int moved = await eisen.moveDoFirstToKanban();

      expect(moved, 0);
      expect(kanban.tasks.length, 1);
      expect(eisen.tasks.length, 1);
    });

    test('skips a duplicate id but still clears it from the matrix', () async {
      eisen.tasks.add(matrixTask('dup',
          title: 'Already queued', isUrgent: true, isImportant: true));
      kanban.tasks.add(Task(id: 'dup', title: 'Already queued'));

      final int moved = await eisen.moveDoFirstToKanban();

      expect(moved, 1);
      expect(kanban.tasks.length, 1);
      expect(eisen.tasks, isEmpty);
    });

    test('picks up a task that was dragged into Do First', () async {
      eisen.tasks.add(matrixTask('c', title: 'Was scheduled', isImportant: true));

      await eisen.moveToQuadrant('c', EisenhowerQuadrant.urgentImportant);
      await eisen.moveDoFirstToKanban();

      expect(kanban.tasks.single.id, 'c');
      expect(eisen.tasks, isEmpty);
    });

    test('running the transfer twice moves nothing the second time', () async {
      eisen.tasks.add(matrixTask('a',
          title: 'Fire now', isUrgent: true, isImportant: true));

      expect(await eisen.moveDoFirstToKanban(), 1);
      expect(await eisen.moveDoFirstToKanban(), 0);
      expect(kanban.tasks.length, 1);
    });

    test('persists the move to both storages', () async {
      eisen.tasks.add(matrixTask('a',
          title: 'Fire now', isUrgent: true, isImportant: true));

      await eisen.moveDoFirstToKanban();

      final List<Task> storedKanban = await TaskStorage.loadKanban();
      final List<EisenhowerTask> storedEisen = await TaskStorage.loadEisenhower();
      expect(storedKanban.map((Task t) => t.id), contains('a'));
      expect(storedKanban.single.column, KanbanColumn.toDo);
      expect(storedEisen.map((EisenhowerTask t) => t.id), isNot(contains('a')));
    });
  });

  group('EisenhowerScreen transfer action', () {
    // The quadrant grid overflows by 1px at the default 800x600 test surface
    // (pre-existing, unrelated to this action), so give it room.
    Future<void> pumpBoard(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(home: EisenhowerScreen()));
      await tester.pumpAndSettle();
    }

    IconButton moveButton(WidgetTester tester) => tester.widget<IconButton>(
          find.ancestor(
            of: find.byIcon(Icons.swap_horiz),
            matching: find.byType(IconButton),
          ),
        );

    testWidgets('is disabled while Do First is empty', (WidgetTester tester) async {
      eisen.tasks.add(matrixTask('c', title: 'Schedule me', isImportant: true));
      await pumpBoard(tester);

      expect(moveButton(tester).onPressed, isNull);
    });

    testWidgets('becomes enabled and transfers on tap',
        (WidgetTester tester) async {
      await pumpBoard(tester);
      eisen.tasks.add(matrixTask('a',
          title: 'Fire now', isUrgent: true, isImportant: true));
      await tester.pumpAndSettle();

      expect(moveButton(tester).onPressed, isNotNull);

      await tester.tap(find.byIcon(Icons.swap_horiz));
      await tester.pumpAndSettle();

      expect(
          kanban.byColumn(KanbanColumn.toDo).map((Task t) => t.id), <String>['a']);
      expect(eisen.byQuadrant(EisenhowerQuadrant.urgentImportant), isEmpty);
      // Emptying the quadrant disables the action again.
      expect(moveButton(tester).onPressed, isNull);
    });
  });
}
