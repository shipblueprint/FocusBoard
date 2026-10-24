import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusboard/app/controller/analytics_controller.dart';
import 'package:focusboard/app/controller/eisenhower_controller.dart';
import 'package:focusboard/app/controller/habit_controller.dart';
import 'package:focusboard/app/controller/kanban_controller.dart';
import 'package:focusboard/app/model/eisenhower_task_model.dart';
import 'package:focusboard/app/model/habit_model.dart';
import 'package:focusboard/app/model/task_model.dart';
import 'package:focusboard/view/apps/analytics/analytics_screen.dart';
import 'package:focusboard/view/apps/eisenhower/eisenhower_screen.dart';
import 'package:focusboard/view/apps/habit/habit_screen.dart';
import 'package:focusboard/view/apps/kanban/kanban_screen.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Narrow-screen (360x800 logical, typical Android phone) layout regression
/// tests. RenderFlex overflow throws during pump, so these fail on any
/// unbounded-width defect.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late KanbanController kanban;
  late EisenhowerController eisen;
  late HabitController habits;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    kanban = Get.put<KanbanController>(KanbanController());
    eisen = Get.put<EisenhowerController>(EisenhowerController(kanban: kanban));
    habits = Get.put<HabitController>(HabitController());
    await Future<void>.delayed(const Duration(milliseconds: 10));
    kanban.tasks.clear();
    eisen.tasks.clear();
    habits.habits.clear();
  });

  tearDown(() {
    Get.reset();
  });

  Future<void> pumpNarrow(WidgetTester tester, Widget screen) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(home: screen));
    await tester.pumpAndSettle();
  }

  group('KanbanScreen at 360dp', () {
    testWidgets('renders columns and long task titles without overflow',
        (WidgetTester tester) async {
      kanban.tasks.add(Task(
        id: 'k1',
        title: 'Plan weekly focus with a deliberately long title',
        column: KanbanColumn.toDo,
      ));
      kanban.tasks.add(Task(
        id: 'k2',
        title: 'Refactor task model',
        column: KanbanColumn.inProgress,
      ));

      await pumpNarrow(tester, const KanbanScreen());

      expect(find.text('Plan weekly focus with a deliberately long title'),
          findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('EisenhowerScreen at 360dp', () {
    testWidgets('renders quadrant titles and descriptions without overflow',
        (WidgetTester tester) async {
      eisen.tasks.add(EisenhowerTask(
        id: 'e1',
        title: 'Fire drill with a deliberately long title to wrap',
        isUrgent: true,
        isImportant: true,
      ));

      await pumpNarrow(tester, const EisenhowerScreen());

      expect(find.text('Do First'), findsOneWidget);
      expect(find.text('Fire drill with a deliberately long title to wrap'),
          findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('HabitScreen at 360dp', () {
    testWidgets('renders habit names and all 7 day circles without overflow',
        (WidgetTester tester) async {
      habits.habits.addAll(<Habit>[
        Habit(id: 'h1', name: 'Morning walk'),
        Habit(id: 'h2', name: 'Read 30 mins before bed every night'),
      ]);

      await pumpNarrow(tester, const HabitScreen());

      expect(find.text('Morning walk'), findsOneWidget);
      // 7 day labels per habit row, 2 habits.
      expect(find.text('M'), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    });
  });

  group('Wide-screen regression at 1200dp', () {
    Future<void> pumpWide(WidgetTester tester, Widget screen) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(home: screen));
      await tester.pumpAndSettle();
    }

    testWidgets('Kanban keeps three side-by-side columns',
        (WidgetTester tester) async {
      kanban.tasks.add(Task(
        id: 'k1',
        title: 'Plan weekly focus',
        column: KanbanColumn.toDo,
      ));
      await pumpWide(tester, const KanbanScreen());
      // All three column headers visible at once (no horizontal paging).
      expect(find.text('To Do'), findsOneWidget);
      expect(find.text('In Progress'), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Habits keep the single-row card layout',
        (WidgetTester tester) async {
      habits.habits.add(Habit(id: 'h1', name: 'Morning walk'));
      await pumpWide(tester, const HabitScreen());
      expect(find.text('Morning walk'), findsOneWidget);
      expect(find.text('M'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('AnalyticsScreen at 360dp', () {
    testWidgets('renders stat cards without overflow',
        (WidgetTester tester) async {
      Get.put<AnalyticsController>(AnalyticsController(
          kanban: kanban, eisen: eisen));
      kanban.tasks.addAll(<Task>[
        Task(id: 'k1', title: 'One', column: KanbanColumn.toDo),
        Task(id: 'k2', title: 'Two', column: KanbanColumn.done),
      ]);

      await pumpNarrow(tester, const AnalyticsScreen());

      expect(find.text('High Priority'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
