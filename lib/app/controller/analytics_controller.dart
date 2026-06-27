import 'package:focusboard/app/controller/eisenhower_controller.dart';
import 'package:focusboard/app/controller/kanban_controller.dart';
import 'package:focusboard/app/model/eisenhower_config.dart';
import 'package:focusboard/app/model/eisenhower_task_model.dart';
import 'package:focusboard/app/model/task_model.dart';
import 'package:get/get.dart';

/// Read-only controller that derives analytics from the live task stores.
///
/// It never owns tasks; it just reads from [KanbanController] and
/// [EisenhowerController] and exposes computed metrics.
class AnalyticsController extends GetxController {
  AnalyticsController({KanbanController? kanban, EisenhowerController? eisen})
      : _kanban = kanban ?? Get.find<KanbanController>(),
        _eisen = eisen ?? Get.find<EisenhowerController>();

  final KanbanController _kanban;
  final EisenhowerController _eisen;

  int get totalKanban => _kanban.tasks.length;
  int get totalEisenhower => _eisen.tasks.length;

  int get totalCompleted => _kanban.tasks
      .where((Task t) => t.isCompleted || t.column == KanbanColumn.done)
      .length;

  int get totalHighPriority => _kanban.tasks
      .where((Task t) => t.isHighPriority)
      .length;

  int get completionPercent {
    if (totalKanban == 0) return 0;
    return ((totalCompleted / totalKanban) * 100).round();
  }

  Map<EisenhowerQuadrant, int> get quadrantCounts {
    final Map<EisenhowerQuadrant, int> counts =
        <EisenhowerQuadrant, int>{};
    for (final EisenhowerQuadrant q in EisenhowerQuadrant.values) {
      counts[q] = 0;
    }
    for (final EisenhowerTask t in _eisen.tasks) {
      counts[t.quadrant] = (counts[t.quadrant] ?? 0) + 1;
    }
    return counts;
  }

  Map<KanbanColumn, int> get kanbanCounts {
    final Map<KanbanColumn, int> counts = <KanbanColumn, int>{};
    for (final KanbanColumn c in KanbanColumn.values) {
      counts[c] = _kanban.tasks.where((Task t) => t.column == c).length;
    }
    return counts;
  }
}
