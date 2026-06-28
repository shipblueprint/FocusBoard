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
