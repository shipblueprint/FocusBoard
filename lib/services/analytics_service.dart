import '../models/eisenhower_task_model.dart';
import '../models/task_model.dart';
import '../config/eisenhower_config.dart';
import '../config/kanban_config.dart';
import 'task_manager.dart';
import 'eisenhower_task_manager.dart';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  Map<String, dynamic> getKanbanAnalytics(TaskManager taskManager) {
    final tasks = taskManager.allTasks;
    
    return {
      'totalTasks': tasks.length,
      'completedTasks': tasks.where((t) => t.isCompleted).length,
      'pendingTasks': tasks.where((t) => !t.isCompleted).length,
      'highPriorityTasks': tasks.where((t) => t.isHighPriority).length,
      'columnDistribution': _getColumnDistribution(tasks),
      'completionRate': tasks.isEmpty 
          ? 0.0 
          : (tasks.where((t) => t.isCompleted).length / tasks.length * 100),
    };
  }

  Map<String, int> _getColumnDistribution(List<Task> tasks) {
    final distribution = <String, int>{};
    for (final column in KanbanConfig.columns) {
      distribution[column] = tasks.where((t) => t.column == column).length;
    }
    return distribution;
  }

  Map<String, dynamic> getEisenhowerAnalytics(EisenhowerTaskManager taskManager) {
    final tasks = taskManager.allTasks;
    
    return {
      'totalTasks': tasks.length,
      'completedTasks': tasks.where((t) => t.isCompleted).length,
      'pendingTasks': tasks.where((t) => !t.isCompleted).length,
      'highPriorityTasks': tasks.where((t) => t.isHighPriority).length,
      'quadrantDistribution': _getQuadrantDistribution(tasks),
      'completionRate': tasks.isEmpty 
          ? 0.0 
          : (tasks.where((t) => t.isCompleted).length / tasks.length * 100),
    };
  }

  Map<String, int> _getQuadrantDistribution(List<EisenhowerTask> tasks) {
    final distribution = <String, int>{};
    for (final quadrant in EisenhowerQuadrant.values) {
      final name = EisenhowerConfig.getQuadrantName(quadrant);
      distribution[name] = tasks.where((t) => t.quadrant == quadrant).length;
    }
    return distribution;
  }

  Map<String, dynamic> getCombinedAnalytics(
    TaskManager kanbanManager,
    EisenhowerTaskManager eisenhowerManager,
  ) {
    final kanban = getKanbanAnalytics(kanbanManager);
    final eisenhower = getEisenhowerAnalytics(eisenhowerManager);
    
    return {
      'kanban': kanban,
      'eisenhower': eisenhower,
      'totalTasks': (kanban['totalTasks'] as int) + (eisenhower['totalTasks'] as int),
      'totalCompleted': (kanban['completedTasks'] as int) + (eisenhower['completedTasks'] as int),
      'overallCompletionRate': _calculateOverallRate(kanban, eisenhower),
    };
  }

  double _calculateOverallRate(Map<String, dynamic> kanban, Map<String, dynamic> eisenhower) {
    final total = (kanban['totalTasks'] as int) + (eisenhower['totalTasks'] as int);
    if (total == 0) return 0.0;
    
    final completed = (kanban['completedTasks'] as int) + (eisenhower['completedTasks'] as int);
    return (completed / total * 100);
  }

  List<ChartData> getQuadrantChartData(EisenhowerTaskManager taskManager) {
    final data = <ChartData>[];
    
    for (final quadrant in EisenhowerQuadrant.values) {
      final count = taskManager.getTasksByQuadrant(quadrant).length;
      final name = EisenhowerConfig.getQuadrantName(quadrant);
      final color = EisenhowerConfig.getQuadrantChartColor(quadrant);
      
      data.add(ChartData(
        label: name,
        value: count,
        color: color,
      ));
    }
    
    return data;
  }

  List<ChartData> getColumnChartData(TaskManager taskManager) {
    final data = <ChartData>[];
    
    for (final column in KanbanConfig.columns) {
      final count = taskManager.getTasksByColumn(column).length;
      final color = KanbanConfig.columnColors[column]?.value.toRadixString(16).substring(2) ?? '9E9E9E';
      
      data.add(ChartData(
        label: column,
        value: count,
        color: '#$color',
      ));
    }
    
    return data;
  }
}

class ChartData {
  final String label;
  final int value;
  final String color;

  ChartData({
    required this.label,
    required this.value,
    required this.color,
  });
}
