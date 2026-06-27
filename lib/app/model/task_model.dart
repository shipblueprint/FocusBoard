import 'package:focusboard/app/model/task_validator.dart';

/// Statuses a Kanban task can sit in.
enum KanbanColumn {
  toDo,
  inProgress,
  done;

  String get label => switch (this) {
        KanbanColumn.toDo => 'To Do',
        KanbanColumn.inProgress => 'In Progress',
        KanbanColumn.done => 'Done',
      };

  static KanbanColumn fromString(String? value) {
    return switch (value) {
      'In Progress' => KanbanColumn.inProgress,
      'Done' => KanbanColumn.done,
      _ => KanbanColumn.toDo,
    };
  }
}

/// A single task that lives in the Kanban board.
class Task {
  String id;
  String title;
  bool isCompleted;
  bool isHighPriority;
  KanbanColumn column;

  Task({
    required this.id,
    required this.title,
    this.isCompleted = false,
    this.isHighPriority = false,
    this.column = KanbanColumn.toDo,
  });

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'isCompleted': isCompleted,
      'isHighPriority': isHighPriority,
      'column': column.label,
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    if (!TaskValidator.validateId(json['id'] as String?)) {
      throw ArgumentError('Task ID cannot be null or empty');
    }

    final String sanitizedTitle =
        TaskValidator.sanitizeTitle(json['title'] as String?);

    return Task(
      id: json['id'].toString(),
      title: sanitizedTitle,
      isCompleted: TaskValidator.parseBoolean(json['isCompleted']),
      isHighPriority: TaskValidator.parseBoolean(json['isHighPriority']),
      column: KanbanColumn.fromString(json['column'] as String?),
    );
  }

  Task copyWith({
    String? id,
    String? title,
    bool? isCompleted,
    bool? isHighPriority,
    KanbanColumn? column,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      isHighPriority: isHighPriority ?? this.isHighPriority,
      column: column ?? this.column,
    );
  }

  @override
  String toString() {
    final StringBuffer buffer = StringBuffer();
    if (isCompleted) buffer.write('[Completed] ');
    if (isHighPriority) buffer.write('[High Priority] ');
    buffer.write(title);
    return buffer.toString();
  }
}
