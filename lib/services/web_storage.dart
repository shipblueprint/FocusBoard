import 'package:shared_preferences/shared_preferences.dart';

class WebStorage {
  static const String _kanbanTasksKey = 'kanban_tasks';
  static const String _eisenhowerTasksKey = 'eisenhower_tasks';

  static Future<void> save(String key, String jsonString) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonString);
  }

  static Future<String?> load(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  static Future<void> saveKanbanTasks(String jsonString) =>
      save(_kanbanTasksKey, jsonString);

  static Future<String?> loadKanbanTasks() => load(_kanbanTasksKey);

  static Future<void> saveEisenhowerTasks(String jsonString) =>
      save(_eisenhowerTasksKey, jsonString);

  static Future<String?> loadEisenhowerTasks() => load(_eisenhowerTasksKey);

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kanbanTasksKey);
    await prefs.remove(_eisenhowerTasksKey);
  }
}
