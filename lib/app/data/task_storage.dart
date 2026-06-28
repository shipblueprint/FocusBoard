import 'dart:convert';

import 'package:focusboard/app/model/eisenhower_task_model.dart';
import 'package:focusboard/app/model/habit_model.dart';
import 'package:focusboard/app/model/task_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists Kanban and Eisenhower tasks to [SharedPreferences] as JSON.
class TaskStorage {
  TaskStorage._();

  static const String _kanbanKey = 'kanban_tasks_v1';
  static const String _eisenhowerKey = 'eisenhower_tasks_v1';
  static const String _kanbanWipKey = 'kanban_wip_limits_v1';

  static Future<List<Task>> loadKanban() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_kanbanKey);
    if (raw == null || raw.isEmpty) return <Task>[];
    try {
      final List<dynamic> data = jsonDecode(raw) as List<dynamic>;
      return data
          .map((dynamic e) => Task.fromJson(e as Map<String, dynamic>))
          .toList(growable: true);
    } catch (_) {
      return <Task>[];
    }
  }

  static Future<void> saveKanban(List<Task> tasks) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String raw = jsonEncode(tasks.map((Task t) => t.toJson()).toList());
    await prefs.setString(_kanbanKey, raw);
  }

  static Future<List<EisenhowerTask>> loadEisenhower() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_eisenhowerKey);
    if (raw == null || raw.isEmpty) return <EisenhowerTask>[];
    try {
      final List<dynamic> data = jsonDecode(raw) as List<dynamic>;
      return data
          .map((dynamic e) =>
              EisenhowerTask.fromJson(e as Map<String, dynamic>))
          .toList(growable: true);
    } catch (_) {
      return <EisenhowerTask>[];
    }
  }

  static Future<void> saveEisenhower(List<EisenhowerTask> tasks) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String raw =
        jsonEncode(tasks.map((EisenhowerTask t) => t.toJson()).toList());
    await prefs.setString(_eisenhowerKey, raw);
  }

  static Future<Map<String, int>> loadKanbanWipLimits() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_kanbanWipKey);
    if (raw == null || raw.isEmpty) return <String, int>{};
    try {
      final Map<String, dynamic> data =
          jsonDecode(raw) as Map<String, dynamic>;
      return data.map((String k, dynamic v) => MapEntry(k, (v as num).toInt()));
    } catch (_) {
      return <String, int>{};
    }
  }

  static Future<void> saveKanbanWipLimits(Map<String, int> limits) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kanbanWipKey, jsonEncode(limits));
  }

  static const String _habitKey = 'habits_v1';

  static Future<List<Habit>> loadHabits() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_habitKey);
    if (raw == null || raw.isEmpty) return <Habit>[];
    try {
      final List<dynamic> data = jsonDecode(raw) as List<dynamic>;
      return data
          .map((dynamic e) => Habit.fromJson(e as Map<String, dynamic>))
          .toList(growable: true);
    } catch (_) {
      return <Habit>[];
    }
  }

  static Future<void> saveHabits(List<Habit> habits) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String raw =
        jsonEncode(habits.map((Habit h) => h.toJson()).toList());
    await prefs.setString(_habitKey, raw);
  }
}
