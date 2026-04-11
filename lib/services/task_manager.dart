import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'web_storage.dart';
import '../models/task_model.dart';

class TaskManager {
  List<Task> _tasks = [];
  late File _taskFile;
  
  // Cache for column tasks to improve performance
  final Map<String, List<Task>> _columnCache = {};
  bool _cacheValid = false;

  Future<void> loadTasks() async {
    try {
      if (kIsWeb) {
        // Use web storage for web platform
        final jsonString = await WebStorage.loadKanbanTasks();
        if (jsonString != null) {
          final tasksJson = json.decode(jsonString) as List;
          _tasks = tasksJson.map((json) => Task.fromJson(json)).toList();
        } else {
          _tasks = [];
        }
      } else {
        // Use file storage for mobile/desktop platforms
        final directory = await getApplicationDocumentsDirectory();
        _taskFile = File('${directory.path}/kanban_tasks.json');
        if (await _taskFile.exists()) {
          final jsonString = await _taskFile.readAsString();
          final tasksJson = json.decode(jsonString) as List;
          _tasks = tasksJson.map((json) => Task.fromJson(json)).toList();
        }
      }
      // Invalidate cache when tasks are loaded
      _cacheValid = false;
    } catch (e) {
      // Handle errors gracefully with fallback to empty tasks
      debugPrint('Error loading tasks: $e');
      _tasks = [];
      
      // Re-throw to allow UI to show error notification
      throw Exception('Failed to load tasks: ${e.toString()}');
    }
  }

  List<Task> get allTasks => List.unmodifiable(_tasks);

  void addTask(String title, String column) {
    final task = Task(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      column: column,
    );
    _tasks.add(task);
    _cacheValid = false; // Invalidate cache
    saveTasks();
  }

  void editTask(Task task, String newTitle) {
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      // 直接更新标题，让toString方法处理前缀
      _tasks[index] = task.copyWith(title: newTitle);
      _cacheValid = false; // Invalidate cache
      saveTasks();
    }
  }

  void deleteTask(Task task) {
    _tasks.removeWhere((t) => t.id == task.id);
    _cacheValid = false; // Invalidate cache
    saveTasks();
  }

  void updateTask(Task task, {String? title, bool? isCompleted, bool? isHighPriority}) {
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      _tasks[index] = task.copyWith(
        title: title,
        isCompleted: isCompleted,
        isHighPriority: isHighPriority,
      );
      _cacheValid = false; // Invalidate cache
      saveTasks();
    }
  }

  void moveTask(Task task, String newColumn) {
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      // 更新任务信息，让toString方法来处理前缀
      _tasks[index] = task.copyWith(
        column: newColumn,
        isCompleted: newColumn == 'Done' ? true : task.isCompleted,
      );
      _cacheValid = false; // Invalidate cache
      saveTasks();
    }
  }

  void markTaskCompleted(Task task) {
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      _tasks[index] = task.copyWith(
        column: 'Done',
        isCompleted: true,
      );
      _cacheValid = false; // Invalidate cache
      saveTasks();
    }
  }

  void unmarkTaskCompleted(Task task) {
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      _tasks[index] = task.copyWith(
        column: 'To Do',
        isCompleted: false,
      );
      _cacheValid = false; // Invalidate cache
      saveTasks();
    }
  }

  void setTaskPriority(Task task, bool isHighPriority) {
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      _tasks[index] = task.copyWith(
        isHighPriority: isHighPriority,
      );
      _cacheValid = false; // Invalidate cache
      saveTasks();
    }
  }

  bool checkWipLimit(String column, int? limit) {
      if (limit == null) return true;
      return getTasksInColumn(column).length < limit;
    }

  List<Task> getTasksInColumn(String column) {
    // Use cache if available
    if (_cacheValid && _columnCache.containsKey(column)) {
      return _columnCache[column]!;
    }
    
    // Build cache if not available
    _columnCache.clear();
    for (final task in _tasks) {
      _columnCache.putIfAbsent(task.column, () => []).add(task);
    }
    _cacheValid = true;
    
    return _columnCache[column] ?? [];
  }

  int getCompletedTasksCount() {
      return getTasksInColumn('Done').length;
    }

  Future<void> saveTasks() async {
    try {
      final tasksJson = _tasks.map((task) => task.toJson()).toList();
      final jsonEncoder = JsonEncoder.withIndent('  ');
      final jsonString = jsonEncoder.convert(tasksJson);
      
      if (kIsWeb) {
        // Use web storage for web platform
        await WebStorage.saveKanbanTasks(jsonString);
      } else {
        // Use file storage for mobile/desktop platforms
        await _taskFile.writeAsString(jsonString);
      }
    } catch (e) {
      debugPrint('Error saving tasks: $e');
      // Re-throw to allow UI to show error notification
      throw Exception('Failed to save tasks: ${e.toString()}');
    }
  }

  void clearDoneColumn() {
    _tasks.removeWhere((task) => task.column == 'Done');
    _cacheValid = false; // Invalidate cache
    saveTasks();
  }

  void addTaskDirect(Task task) {
    _tasks.add(task);
    _cacheValid = false; // Invalidate cache
    saveTasks();
  }
}