import 'package:flutter/foundation.dart';
import '../models/task_model.dart';
import '../models/eisenhower_task_model.dart';
import 'task_manager.dart';
import 'eisenhower_task_manager.dart';

class TaskAnalytics {
  final int totalTasks;
  final int completedTasks;
  final int pendingTasks;
  final int highPriorityTasks;
  final double completionRate;
  final Map<String, int> tasksByColumn;
  final Map<String, int> tasksByPriority;
  final Map<EisenhowerQuadrant, int> eisenhowerDistribution;
  final double averageCompletionTime;
  final DateTime lastUpdated;

  TaskAnalytics({
    required this.totalTasks,
    required this.completedTasks,
    required this.pendingTasks,
    required this.highPriorityTasks,
    required this.completionRate,
    required this.tasksByColumn,
    required this.tasksByPriority,
    required this.eisenhowerDistribution,
    required this.averageCompletionTime,
    required this.lastUpdated,
  });
}

class AnalyticsService extends ChangeNotifier {
  final TaskManager _taskManager;
  final EisenhowerTaskManager _eisenhowerManager;
  TaskAnalytics? _currentAnalytics;

  AnalyticsService(this._taskManager, this._eisenhowerManager);

  TaskAnalytics? get currentAnalytics => _currentAnalytics;

  Future<void> refreshAnalytics() async {
    try {
      final tasks = _taskManager.allTasks;
      final eisenhowerTasks = _eisenhowerManager.allTasks;
      
      _currentAnalytics = _calculateAnalytics(tasks, eisenhowerTasks);
      notifyListeners();
    } catch (e) {
      debugPrint('Error refreshing analytics: $e');
      rethrow;
    }
  }

  TaskAnalytics _calculateAnalytics(List<Task> tasks, List<EisenhowerTask> eisenhowerTasks) {
    final allTasks = [...tasks, ...eisenhowerTasks];
    
    // Basic statistics
    final totalTasks = allTasks.length;
    final completedTasks = allTasks.where((task) => task.isCompleted).length;
    final pendingTasks = totalTasks - completedTasks;
    final highPriorityTasks = allTasks.where((task) => task.isHighPriority).length;
    final completionRate = totalTasks > 0 ? (completedTasks / totalTasks) * 100 : 0.0;

    // Column distribution
    final tasksByColumn = <String, int>{};
    for (final task in allTasks) {
      tasksByColumn[task.column] = (tasksByColumn[task.column] ?? 0) + 1;
    }

    // Priority distribution
    final tasksByPriority = <String, int>{
      'High Priority': highPriorityTasks,
      'Low Priority': totalTasks - highPriorityTasks,
    };

    // Eisenhower quadrant distribution
    final eisenhowerDistribution = <EisenhowerQuadrant, int>{};
    for (final quadrant in EisenhowerQuadrant.values) {
      eisenhowerDistribution[quadrant] = 0;
    }
    for (final task in eisenhowerTasks) {
      final quadrant = task.quadrant;
      eisenhowerDistribution[quadrant] = (eisenhowerDistribution[quadrant] ?? 0) + 1;
    }

    // Average completion time (placeholder - would need timestamps for real calculation)
    final averageCompletionTime = _calculateAverageCompletionTime(allTasks);

    return TaskAnalytics(
      totalTasks: totalTasks,
      completedTasks: completedTasks,
      pendingTasks: pendingTasks,
      highPriorityTasks: highPriorityTasks,
      completionRate: completionRate,
      tasksByColumn: tasksByColumn,
      tasksByPriority: tasksByPriority,
      eisenhowerDistribution: eisenhowerDistribution,
      averageCompletionTime: averageCompletionTime,
      lastUpdated: DateTime.now(),
    );
  }

  double _calculateAverageCompletionTime(List<Task> tasks) {
    // Placeholder implementation - would need actual timestamps
    // For now, return a default value
    return tasks.length > 0 ? 2.5 : 0.0;
  }

  Map<String, dynamic> getQuickStats() {
    if (_currentAnalytics == null) return {};
    
    return {
      'total': _currentAnalytics!.totalTasks,
      'completed': _currentAnalytics!.completedTasks,
      'pending': _currentAnalytics!.pendingTasks,
      'completionRate': _currentAnalytics!.completionRate.toStringAsFixed(1),
      'highPriority': _currentAnalytics!.highPriorityTasks,
    };
  }

  List<Map<String, dynamic>> getColumnChartData() {
    if (_currentAnalytics == null) return [];
    
    return _currentAnalytics!.tasksByColumn.entries
        .map((entry) => {
              'column': entry.key,
              'count': entry.value,
            })
        .toList();
  }

  List<Map<String, dynamic>> getPriorityChartData() {
    if (_currentAnalytics == null) return [];
    
    return _currentAnalytics!.tasksByPriority.entries
        .map((entry) => {
              'priority': entry.key,
              'count': entry.value,
            })
        .toList();
  }

  List<Map<String, dynamic>> getEisenhowerChartData() {
    if (_currentAnalytics == null) return [];
    
    return _currentAnalytics!.eisenhowerDistribution.entries
        .map((entry) => {
              'quadrant': _getQuadrantName(entry.key),
              'count': entry.value,
              'color': _getQuadrantColor(entry.key),
            })
        .toList();
  }

  String _getQuadrantName(EisenhowerQuadrant quadrant) {
    switch (quadrant) {
      case EisenhowerQuadrant.urgentImportant:
        return 'Urgent & Important';
      case EisenhowerQuadrant.notUrgentImportant:
        return 'Not Urgent & Important';
      case EisenhowerQuadrant.urgentNotImportant:
        return 'Urgent & Not Important';
      case EisenhowerQuadrant.notUrgentNotImportant:
        return 'Not Urgent & Not Important';
    }
  }

  String _getQuadrantColor(EisenhowerQuadrant quadrant) {
    switch (quadrant) {
      case EisenhowerQuadrant.urgentImportant:
        return '#FF6B6B'; // Red
      case EisenhowerQuadrant.notUrgentImportant:
        return '#4ECDC4'; // Teal
      case EisenhowerQuadrant.urgentNotImportant:
        return '#FFE66D'; // Yellow
      case EisenhowerQuadrant.notUrgentNotImportant:
        return '#95E1D3'; // Light green
    }
  }
}