import 'dart:io';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'web_storage.dart';
import '../models/eisenhower_task_model.dart';

class EisenhowerTaskManager {
  List<EisenhowerTask> _tasks = [];
  late File _taskFile;
  
  // Cache for quadrant tasks to improve performance
  final Map<EisenhowerQuadrant, List<EisenhowerTask>> _quadrantCache = {};
  bool _cacheValid = false;

  Future<void> loadTasks() async {
    try {
      if (kIsWeb) {
        // Use web storage for web platform
        final jsonString = await WebStorage.loadEisenhowerTasks();
        if (jsonString != null) {
          final tasksJson = json.decode(jsonString) as List;
          _tasks = tasksJson.map((json) => EisenhowerTask.fromJson(json)).toList();
        } else {
          _tasks = [];
        }
      } else {
        // Use file storage for mobile/desktop platforms
        final directory = await getApplicationDocumentsDirectory();
        _taskFile = File('${directory.path}/eisenhower_tasks.json');
        if (await _taskFile.exists()) {
          final jsonString = await _taskFile.readAsString();
          final tasksJson = json.decode(jsonString) as List;
          _tasks = tasksJson.map((json) => EisenhowerTask.fromJson(json)).toList();
        }
      }
      // Invalidate cache when tasks are loaded
      _cacheValid = false;
    } catch (e) {
      // Handle errors gracefully with fallback to empty tasks
      debugPrint('Error loading Eisenhower tasks: $e');
      _tasks = [];
      
      // Re-throw to allow UI to show error notification
      throw Exception('Failed to load Eisenhower tasks: ${e.toString()}');
    }
  }

  List<EisenhowerTask> get allTasks => List.unmodifiable(_tasks);

  List<EisenhowerTask> getTasksInQuadrant(EisenhowerQuadrant quadrant) {
    // Use cache if available
    if (_cacheValid && _quadrantCache.containsKey(quadrant)) {
      return _quadrantCache[quadrant]!;
    }
    
    // Build cache if not available
    _quadrantCache.clear();
    for (final task in _tasks) {
      _quadrantCache.putIfAbsent(task.quadrant, () => []).add(task);
    }
    _cacheValid = true;
    
    return _quadrantCache[quadrant] ?? [];
  }

  void addTask(String title, {bool isUrgent = false, bool isImportant = false}) {
    final task = EisenhowerTask(
      id: '${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(10000)}',
      title: title,
      isUrgent: isUrgent,
      isImportant: isImportant,
      column: 'Eisenhower',
    );
    _tasks.add(task);
    _cacheValid = false; // Invalidate cache
    saveTasks();
  }

  int addTasksFromText(String text, {bool isUrgent = false, bool isImportant = false}) {
    final lines = text.split('\n').where((line) => line.trim().isNotEmpty).toList();
    int addedCount = 0;
    for (final line in lines) {
      final trimmedLine = line.trim();
      if (trimmedLine.isNotEmpty) {
        addTask(trimmedLine, isUrgent: isUrgent, isImportant: isImportant);
        addedCount++;
      }
    }
    return addedCount;
  }

  void editTask(EisenhowerTask task, String newTitle, {bool? isUrgent, bool? isImportant}) {
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      _tasks[index] = task.copyWith(
        title: newTitle,
        isUrgent: isUrgent ?? task.isUrgent,
        isImportant: isImportant ?? task.isImportant,
      );
      _cacheValid = false; // Invalidate cache
      saveTasks();
    }
  }

  void deleteTask(EisenhowerTask task) {
    _tasks.removeWhere((t) => t.id == task.id);
    _cacheValid = false; // Invalidate cache
    saveTasks();
  }

  void moveTaskToQuadrant(EisenhowerTask task, EisenhowerQuadrant newQuadrant) {
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      bool newUrgent = task.isUrgent;
      bool newImportant = task.isImportant;

      switch (newQuadrant) {
        case EisenhowerQuadrant.urgentImportant:
          newUrgent = true;
          newImportant = true;
          break;
        case EisenhowerQuadrant.notUrgentImportant:
          newUrgent = false;
          newImportant = true;
          break;
        case EisenhowerQuadrant.urgentNotImportant:
          newUrgent = true;
          newImportant = false;
          break;
        case EisenhowerQuadrant.notUrgentNotImportant:
          newUrgent = false;
          newImportant = false;
          break;
      }

      _tasks[index] = task.copyWith(
        isUrgent: newUrgent,
        isImportant: newImportant,
      );
      _cacheValid = false; // Invalidate cache
      saveTasks();
    }
  }

  void toggleTaskCompletion(EisenhowerTask task) {
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      _tasks[index] = task.copyWith(
        isCompleted: !task.isCompleted,
      );
      _cacheValid = false; // Invalidate cache
      saveTasks();
    }
  }

  Map<String, int> getQuadrantCounts() {
    return {
      'urgentImportant': getTasksInQuadrant(EisenhowerQuadrant.urgentImportant).length,
      'notUrgentImportant': getTasksInQuadrant(EisenhowerQuadrant.notUrgentImportant).length,
      'urgentNotImportant': getTasksInQuadrant(EisenhowerQuadrant.urgentNotImportant).length,
      'notUrgentNotImportant': getTasksInQuadrant(EisenhowerQuadrant.notUrgentNotImportant).length,
    };
  }

  Future<void> saveTasks() async {
    try {
      final tasksJson = _tasks.map((task) => task.toJson()).toList();
      final jsonEncoder = JsonEncoder.withIndent('  ');
      final jsonString = jsonEncoder.convert(tasksJson);
      
      if (kIsWeb) {
        // Use web storage for web platform
        await WebStorage.saveEisenhowerTasks(jsonString);
      } else {
        // Use file storage for mobile/desktop platforms
        await _taskFile.writeAsString(jsonString);
      }
    } catch (e) {
      debugPrint('Error saving Eisenhower tasks: $e');
      // Re-throw to allow UI to show error notification
      throw Exception('Failed to save Eisenhower tasks: ${e.toString()}');
    }
  }

  void clearQuadrant(EisenhowerQuadrant quadrant) {
    _tasks.removeWhere((task) => task.quadrant == quadrant);
    saveTasks();
  }

  List<EisenhowerTask> getDoFirstTasks() {
    return getTasksInQuadrant(EisenhowerQuadrant.urgentImportant);
  }

  void removeTasks(List<EisenhowerTask> tasksToRemove) {
    for (final task in tasksToRemove) {
      _tasks.removeWhere((t) => t.id == task.id);
    }
    saveTasks();
  }

  void reorderTasksInQuadrant(EisenhowerQuadrant quadrant, int oldIndex, int newIndex) {
    final quadrantTasks = _tasks.where((task) => task.quadrant == quadrant).toList();
    if (oldIndex < 0 || oldIndex >= quadrantTasks.length || newIndex < 0 || newIndex >= quadrantTasks.length) {
      return;
    }

    final task = quadrantTasks[oldIndex];
    final oldGlobalIndex = _tasks.indexWhere((t) => t.id == task.id);
    
    // Remove the task from its current position
    _tasks.removeAt(oldGlobalIndex);
    
    // Calculate the new global position
    int newGlobalIndex;
    if (newIndex == 0) {
      // Insert at the beginning of the quadrant
      newGlobalIndex = _tasks.indexWhere((t) => t.quadrant == quadrant);
      if (newGlobalIndex == -1) {
        newGlobalIndex = _tasks.length; // No other tasks in this quadrant
      }
    } else if (newIndex >= quadrantTasks.length - 1) {
      // Insert at the end of the quadrant
      final lastQuadrantTask = quadrantTasks.last;
      newGlobalIndex = _tasks.indexWhere((t) => t.id == lastQuadrantTask.id) + 1;
    } else {
      // Insert in the middle
      final targetTask = quadrantTasks[newIndex > oldIndex ? newIndex : newIndex - 1];
      newGlobalIndex = _tasks.indexWhere((t) => t.id == targetTask.id) + (newIndex > oldIndex ? 1 : 0);
    }
    
    // Insert at the calculated position
    _tasks.insert(newGlobalIndex, task);
    saveTasks();
  }
}