import 'package:focusboard/app/model/eisenhower_config.dart';
import 'package:focusboard/app/model/task_model.dart';
import 'package:focusboard/app/model/task_validator.dart';

/// A task that lives in the Eisenhower Matrix.
///
/// Carries the [isUrgent] / [isImportant] flags and derives its
/// [quadrant] from [EisenhowerConfig].
class EisenhowerTask extends Task {
  bool isUrgent;
  bool isImportant;

  EisenhowerQuadrant get quadrant =>
      EisenhowerConfig.getQuadrantFromFlags(isUrgent, isImportant);

  String get quadrantName => EisenhowerConfig.getQuadrantName(quadrant);

  EisenhowerTask({
    required super.id,
    required super.title,
    super.isCompleted = false,
    super.isHighPriority = false,
    super.column = KanbanColumn.toDo,
    this.isUrgent = false,
    this.isImportant = false,
  });

  factory EisenhowerTask.fromTask(
    Task task, {
    bool isUrgent = false,
    bool isImportant = false,
  }) {
    return EisenhowerTask(
      id: task.id,
      title: task.title,
      isCompleted: task.isCompleted,
      isHighPriority: task.isHighPriority,
      column: task.column,
      isUrgent: isUrgent,
      isImportant: isImportant,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = super.toJson();
    json['isUrgent'] = isUrgent;
    json['isImportant'] = isImportant;
    json['type'] = 'eisenhower';
    return json;
  }

  factory EisenhowerTask.fromJson(Map<String, dynamic> json) {
    if (!TaskValidator.validateId(json['id'] as String?)) {
      throw ArgumentError('EisenhowerTask ID cannot be null or empty');
    }

    final String sanitizedTitle =
        TaskValidator.sanitizeTitle(json['title'] as String?);

    return EisenhowerTask(
      id: json['id'].toString(),
      title: sanitizedTitle,
      isCompleted: TaskValidator.parseBoolean(json['isCompleted']),
      isHighPriority: TaskValidator.parseBoolean(json['isHighPriority']),
      column: KanbanColumn.fromString(json['column'] as String?),
      isUrgent: TaskValidator.parseBoolean(json['isUrgent']),
      isImportant: TaskValidator.parseBoolean(json['isImportant']),
    );
  }

  @override
  EisenhowerTask copyWith({
    String? id,
    String? title,
    bool? isCompleted,
    bool? isHighPriority,
    KanbanColumn? column,
    bool? isUrgent,
    bool? isImportant,
  }) {
    return EisenhowerTask(
      id: id ?? this.id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      isHighPriority: isHighPriority ?? this.isHighPriority,
      column: column ?? this.column,
      isUrgent: isUrgent ?? this.isUrgent,
      isImportant: isImportant ?? this.isImportant,
    );
  }
}
