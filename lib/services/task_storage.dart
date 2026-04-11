import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'web_storage.dart';
import '../models/task_model.dart';

class TaskStorage {
  static const String fileName = 'tasks.json';

  Future<File> get _localFile async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$fileName');
  }

  Future<Map<String, List<Task>>> loadTasks() async {
    try {
      String? contents;
      
      if (kIsWeb) {
        // Use web storage for web platform
        contents = await WebStorage.loadKanbanTasks();
        if (contents == null) {
          return _getEmptyColumns();
        }
      } else {
        // Use file storage for mobile/desktop platforms
        final file = await _localFile;
        if (!await file.exists()) {
          return _getEmptyColumns();
        }
        contents = await file.readAsString();
      }

      final data = jsonDecode(contents);
      
      final Map<String, List<Task>> tasks = _getEmptyColumns();
      
      // 处理新格式的数据
      if (data is Map && data.containsKey('tasks')) {
        final taskMaps = (data['tasks'] as List).cast<Map<String, dynamic>>();
        for (var taskMap in taskMaps) {
          final task = Task.fromJson(taskMap);
          if (tasks.containsKey(task.column)) {
            tasks[task.column]!.add(task);
          }
        }
      } else if (data is Map) {
        // 向后兼容旧格式
        data.forEach((column, taskList) {
          if (tasks.containsKey(column)) {
            for (var taskText in (taskList as List).cast<String>()) {
              final task = Task(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                title: taskText,
                isCompleted: taskText.contains('[Completed]'),
                isHighPriority: taskText.contains('[High Priority]'),
                column: column,
              );
              tasks[column]!.add(task);
            }
          }
        });
      }
      
      return tasks;
    } catch (e) {
      // Error loading tasks: $e
      return _getEmptyColumns();
    }
  }

  Future<void> saveTasks(Map<String, List<Task>> tasks) async {
    try {
      // 转换为适合保存的格式
      final allTasks = tasks.values.expand((element) => element).toList();
      final data = {
        'tasks': allTasks.map((task) => task.toJson()).toList(),
      };
      
      final jsonString = const JsonEncoder.withIndent('  ').convert(data);
      
      if (kIsWeb) {
        // Use web storage for web platform
        await WebStorage.saveKanbanTasks(jsonString);
      } else {
        // Use file storage for mobile/desktop platforms
        final file = await _localFile;
        await file.writeAsString(jsonString);
      }
    } catch (e) {
      // Error saving tasks: $e
    }
  }

  Map<String, List<Task>> _getEmptyColumns() {
    return {
      'To Do': [],
      'In Progress': [],
      'Done': [],
    };
  }
}