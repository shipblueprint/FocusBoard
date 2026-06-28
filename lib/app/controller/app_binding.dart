import 'package:focusboard/app/controller/analytics_controller.dart';
import 'package:focusboard/app/controller/eisenhower_controller.dart';
import 'package:focusboard/app/controller/habit_controller.dart';
import 'package:focusboard/app/controller/kanban_controller.dart';
import 'package:get/get.dart';

/// Bindings that wire up all controllers in the [AppLayout] subtree.
///
/// Use [Get.put] with [permanent: true] so navigating between tabs
/// doesn't dispose the controllers — preserving task state.
class AppBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<KanbanController>(KanbanController(), permanent: true);
    Get.put<EisenhowerController>(EisenhowerController(), permanent: true);
    Get.put<AnalyticsController>(AnalyticsController(), permanent: true);
    Get.put<HabitController>(HabitController(), permanent: true);
  }
}
