import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class WebStorage {
  static const String _kanbanTasksKey = 'kanban_tasks';
  static const String _eisenhowerTasksKey = 'eisenhower_tasks';

  static Future<void> saveKanbanTasks(String jsonString) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kanbanTasksKey, jsonString);
  }

  static Future<String?> loadKanbanTasks() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kanbanTasksKey);
  }

  static Future<void> saveEisenhowerTasks(String jsonString) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_eisenhowerTasksKey, jsonString);
  }

  static Future<String?> loadEisenhowerTasks() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_eisenhowerTasksKey);
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kanbanTasksKey);
    await prefs.remove(_eisenhowerTasksKey);
  }
}