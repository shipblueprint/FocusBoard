import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'web_storage.dart';

abstract class BaseTaskManager<T> {
  List<T> _tasks = [];
  late File _taskFile;
  bool _cacheValid = false;

  List<T> get allTasks => List.unmodifiable(_tasks);
  bool get isCacheValid => _cacheValid;
  List<T> get tasksInternal => _tasks;
  set tasksInternal(List<T> value) => _tasks = value;
  set cacheValid(bool value) => _cacheValid = value;

  String get storageKey;
  String get fileName;
  T Function(Map<String, dynamic>) get fromJsonFactory;

  void invalidateCache() {
    _cacheValid = false;
  }

  Future<void> loadTasks() async {
    try {
      if (kIsWeb) {
        final jsonString = await WebStorage.load(storageKey);
        if (jsonString != null) {
          final tasksJson = json.decode(jsonString) as List;
          _tasks = tasksJson.map((json) => fromJsonFactory(json)).toList();
        } else {
          _tasks = [];
        }
      } else {
        final directory = await getApplicationDocumentsDirectory();
        _taskFile = File('${directory.path}/$fileName');
        if (await _taskFile.exists()) {
          final jsonString = await _taskFile.readAsString();
          final tasksJson = json.decode(jsonString) as List;
          _tasks = tasksJson.map((json) => fromJsonFactory(json)).toList();
        }
      }
      _cacheValid = false;
    } catch (e) {
      debugPrint('Error loading tasks: $e');
      _tasks = [];
      throw Exception('Failed to load tasks: ${e.toString()}');
    }
  }

  Future<void> saveTasks() async {
    try {
      final tasksJson = _tasks.map((task) => toJson(task)).toList();
      final jsonEncoder = JsonEncoder.withIndent('  ');
      final jsonString = jsonEncoder.convert(tasksJson);

      if (kIsWeb) {
        await WebStorage.save(storageKey, jsonString);
      } else {
        await _taskFile.writeAsString(jsonString);
      }
    } catch (e) {
      debugPrint('Error saving tasks: $e');
      throw Exception('Failed to save tasks: ${e.toString()}');
    }
  }

  Map<String, dynamic> toJson(T task);

  void addTaskDirect(T task) {
    _tasks.add(task);
    _cacheValid = false;
    saveTasks();
  }

  void removeTaskWhere(bool Function(T) test) {
    _tasks.removeWhere(test);
    _cacheValid = false;
    saveTasks();
  }

  void updateTaskAtIndex(int index, T task) {
    if (index >= 0 && index < _tasks.length) {
      _tasks[index] = task;
      _cacheValid = false;
      saveTasks();
    }
  }

  int findTaskIndex(bool Function(T) test) {
    return _tasks.indexWhere(test);
  }

  void clearAllTasks() {
    _tasks.clear();
    _cacheValid = false;
    saveTasks();
  }
}
