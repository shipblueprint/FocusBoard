import 'package:focusboard/app/model/task_validator.dart';

class Habit {
  String id;
  String name;
  DateTime createdAt;
  Set<String> completedDates;

  Habit({
    required this.id,
    required this.name,
    DateTime? createdAt,
    Set<String>? completedDates,
  })  : createdAt = createdAt ?? DateTime.now(),
        completedDates = completedDates ?? <String>{};

  bool isCompletedOn(String date) => completedDates.contains(date);

  void toggleDate(String date) {
    if (completedDates.contains(date)) {
      completedDates.remove(date);
    } else {
      completedDates.add(date);
    }
  }

  int currentStreak() {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final String todayKey = _dateKey(today);
    DateTime day = completedDates.contains(todayKey) ? today : today.subtract(const Duration(days: 1));
    int streak = 0;
    while (completedDates.contains(_dateKey(day))) {
      streak++;
      day = day.subtract(const Duration(days: 1));
    }
    return streak;
  }

  int bestStreak() {
    if (completedDates.isEmpty) return 0;
    final List<String> sorted = completedDates.toList()..sort();
    int best = 0;
    int current = 0;
    DateTime? prev;
    for (final String key in sorted) {
      final List<int> parts = key.split('-').map(int.tryParse).whereType<int>().toList();
      if (parts.length < 3) continue;
      final DateTime d = DateTime(parts[0], parts[1], parts[2]);
      if (prev != null && d.difference(prev).inDays == 1) {
        current++;
      } else {
        current = 1;
      }
      if (current > best) best = current;
      prev = d;
    }
    return best;
  }

  int weekDone() {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    int count = 0;
    for (int i = 6; i >= 0; i--) {
      if (completedDates.contains(_dateKey(today.subtract(Duration(days: i))))) {
        count++;
      }
    }
    return count;
  }

  List<(String, bool)> lastDays(int count) {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    return List<(String, bool)>.generate(count, (int i) {
      final DateTime d = today.subtract(Duration(days: count - 1 - i));
      final String key = _dateKey(d);
      return (key, completedDates.contains(key));
    });
  }

  List<(String dateKey, bool done, bool isFuture)> currentWeek() {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime monday = today.subtract(Duration(days: today.weekday - 1));
    return List<(String, bool, bool)>.generate(7, (int i) {
      final DateTime d = monday.add(Duration(days: i));
      return (_dateKey(d), completedDates.contains(_dateKey(d)), d.isAfter(today));
    });
  }

  static String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'createdAt': createdAt.toIso8601String(),
        'completedDates': completedDates.toList(),
      };

  factory Habit.fromJson(Map<String, dynamic> json) {
    return Habit(
      id: json['id'] as String? ?? TaskValidator.generateUuid(),
      name: TaskValidator.sanitizeTitle(json['name'] as String?),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
      completedDates: (json['completedDates'] as List<dynamic>?)
              ?.map((dynamic e) => e.toString())
              .toSet() ??
          <String>{},
    );
  }
}
