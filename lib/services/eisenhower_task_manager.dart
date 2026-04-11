import '../models/eisenhower_task_model.dart';
import '../config/eisenhower_config.dart';
import 'base_task_manager.dart';

class EisenhowerTaskManager extends BaseTaskManager<EisenhowerTask> {
  static final EisenhowerTaskManager _instance = EisenhowerTaskManager._internal();
  factory EisenhowerTaskManager() => _instance;
  EisenhowerTaskManager._internal();

  @override
  String get storageKey => 'eisenhower_tasks';
  
  @override
  String get fileName => 'eisenhower_tasks.json';
  
  @override
  EisenhowerTask Function(Map<String, dynamic>) get fromJsonFactory => EisenhowerTask.fromJson;

  @override
  Map<String, dynamic> toJson(EisenhowerTask task) => task.toJson();

  List<EisenhowerTask> getTasksByQuadrant(EisenhowerQuadrant quadrant) {
    return allTasks.where((task) => task.quadrant == quadrant).toList();
  }

  List<EisenhowerTask> get urgentImportantTasks =>
      getTasksByQuadrant(EisenhowerQuadrant.urgentImportant);

  List<EisenhowerTask> get notUrgentImportantTasks =>
      getTasksByQuadrant(EisenhowerQuadrant.notUrgentImportant);

  List<EisenhowerTask> get urgentNotImportantTasks =>
      getTasksByQuadrant(EisenhowerQuadrant.urgentNotImportant);

  List<EisenhowerTask> get notUrgentNotImportantTasks =>
      getTasksByQuadrant(EisenhowerQuadrant.notUrgentNotImportant);

  void addTask(EisenhowerTask task) {
    addTaskDirect(task);
  }

  void deleteTask(EisenhowerTask task) {
    removeTaskWhere((t) => t.id == task.id);
  }

  void updateTask(EisenhowerTask task) {
    final index = findTaskIndex((t) => t.id == task.id);
    if (index != -1) {
      updateTaskAtIndex(index, task);
    }
  }

  void markTaskCompleted(EisenhowerTask task) {
    final index = findTaskIndex((t) => t.id == task.id);
    if (index != -1) {
      updateTaskAtIndex(index, task.copyWith(isCompleted: true));
    }
  }

  void setTaskPriority(EisenhowerTask task, bool isHighPriority) {
    final index = findTaskIndex((t) => t.id == task.id);
    if (index != -1) {
      updateTaskAtIndex(index, task.copyWith(isHighPriority: isHighPriority));
    }
  }

  void moveTaskToQuadrant(EisenhowerTask task, EisenhowerQuadrant newQuadrant) {
    final (isUrgent, isImportant) = EisenhowerConfig.getFlagsFromQuadrant(newQuadrant);
    final index = findTaskIndex((t) => t.id == task.id);
    if (index != -1) {
      updateTaskAtIndex(index, task.copyWith(
        isUrgent: isUrgent,
        isImportant: isImportant,
      ));
    }
  }

  EisenhowerTask? findTaskById(String id) {
    final tasks = allTasks;
    for (final task in tasks) {
      if (task.id == id) return task;
    }
    return null;
  }

  Map<EisenhowerQuadrant, int> getQuadrantCounts() {
    final counts = <EisenhowerQuadrant, int>{};
    for (final quadrant in EisenhowerQuadrant.values) {
      counts[quadrant] = getTasksByQuadrant(quadrant).length;
    }
    return counts;
  }

  int getTotalTaskCount() => allTasks.length;

  int getCompletedTaskCount() =>
      allTasks.where((task) => task.isCompleted).length;
}
