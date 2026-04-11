import '../models/task_model.dart';
import '../config/kanban_config.dart';
import 'base_task_manager.dart';

class TaskManager extends BaseTaskManager<Task> {
  static final TaskManager _instance = TaskManager._internal();
  factory TaskManager() => _instance;
  TaskManager._internal();

  @override
  String get storageKey => 'kanban_tasks';
  
  @override
  String get fileName => 'tasks.json';
  
  @override
  Task Function(Map<String, dynamic>) get fromJsonFactory => Task.fromJson;

  @override
  Map<String, dynamic> toJson(Task task) => task.toJson();

  List<Task> getTasksByColumn(String column) {
    return allTasks.where((task) => task.column == column).toList();
  }

  List<Task> get pendingTasks =>
      allTasks.where((task) => !task.isCompleted).toList();

  List<Task> get completedTasks =>
      allTasks.where((task) => task.isCompleted).toList();

  List<Task> get highPriorityTasks =>
      allTasks.where((task) => task.isHighPriority && !task.isCompleted).toList();

  int getWipCount(String column) {
    return getTasksByColumn(column).where((t) => !t.isCompleted).length;
  }

  bool isWipLimitReached(String column) {
    final limit = KanbanConfig.getWipLimit(column);
    if (limit == null) return false;
    return getWipCount(column) >= limit;
  }

  void addTask(Task task) {
    addTaskDirect(task);
  }

  void deleteTask(Task task) {
    removeTaskWhere((t) => t.id == task.id);
  }

  void updateTask(Task task) {
    final index = findTaskIndex((t) => t.id == task.id);
    if (index != -1) {
      updateTaskAtIndex(index, task);
    }
  }

  void markTaskCompleted(Task task) {
    final index = findTaskIndex((t) => t.id == task.id);
    if (index != -1) {
      updateTaskAtIndex(index, task.copyWith(isCompleted: true, column: KanbanConfig.columns.last));
    }
  }

  void setTaskPriority(Task task, bool isHighPriority) {
    final index = findTaskIndex((t) => t.id == task.id);
    if (index != -1) {
      updateTaskAtIndex(index, task.copyWith(isHighPriority: isHighPriority));
    }
  }

  void moveTask(Task task, String newColumn) {
    if (!KanbanConfig.isValidColumn(newColumn)) return;
    
    final index = findTaskIndex((t) => t.id == task.id);
    if (index != -1) {
      updateTaskAtIndex(index, task.copyWith(column: newColumn));
    }
  }

  void restoreTask(Task task) {
    final index = findTaskIndex((t) => t.id == task.id);
    if (index != -1) {
      updateTaskAtIndex(index, task.copyWith(
        isCompleted: false,
        column: KanbanConfig.getDefaultColumn(),
      ));
    }
  }

  void reorderTasks(String column, int oldIndex, int newIndex) {
    final columnTasks = getTasksByColumn(column);
    if (oldIndex < columnTasks.length && newIndex < columnTasks.length) {
      final task = columnTasks[oldIndex];
      final allTasksList = List<Task>.from(allTasks);
      final actualOldIndex = allTasksList.indexWhere((t) => t.id == task.id);
      
      if (actualOldIndex != -1) {
        allTasksList.removeAt(actualOldIndex);
        
        int actualNewIndex = allTasksList.indexWhere((t) => 
            t.column == column && 
            allTasksList.indexOf(t) >= newIndex);
        
        if (actualNewIndex == -1) {
          actualNewIndex = allTasksList.length;
        }
        
        allTasksList.insert(actualNewIndex, task);
        tasksInternal = allTasksList;
        cacheValid = false;
        saveTasks();
      }
    }
  }

  Task? findTaskById(String id) {
    final tasks = allTasks;
    for (final task in tasks) {
      if (task.id == id) return task;
    }
    return null;
  }
}
