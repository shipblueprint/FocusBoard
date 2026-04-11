import '../config/kanban_config.dart';

class Task {
  String id;
  String title;
  bool isCompleted;
  bool isHighPriority;
  String column;

  Task({
    required this.id,
    required this.title,
    this.isCompleted = false,
    this.isHighPriority = false,
    this.column = 'To Do',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'isCompleted': isCompleted,
      'isHighPriority': isHighPriority,
      'column': column,
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    if (json['id'] == null || json['id'].toString().isEmpty) {
      throw ArgumentError('Task ID cannot be null or empty');
    }

    if (json['title'] == null || json['title'].toString().trim().isEmpty) {
      throw ArgumentError('Task title cannot be null or empty');
    }

    String sanitizedTitle = json['title'].toString().trim();
    sanitizedTitle = sanitizedTitle.replaceAll(RegExp(r'<[^>]*>'), '');
    if (sanitizedTitle.length > 200) {
      sanitizedTitle = '${sanitizedTitle.substring(0, 197)}...';
    }

    String column = json['column'] ?? KanbanConfig.getDefaultColumn();
    if (!KanbanConfig.isValidColumn(column)) {
      column = KanbanConfig.getDefaultColumn();
    }

    return Task(
      id: json['id'].toString(),
      title: sanitizedTitle,
      isCompleted: json['isCompleted'] == true,
      isHighPriority: json['isHighPriority'] == true,
      column: column,
    );
  }

  @override
  String toString() {
    final buffer = StringBuffer();
    if (isCompleted) buffer.write('[Completed] ');
    if (isHighPriority) buffer.write('[High Priority] ');
    buffer.write(title);
    return buffer.toString();
  }

  Task copyWith({
    String? id,
    String? title,
    bool? isCompleted,
    bool? isHighPriority,
    String? column,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      isHighPriority: isHighPriority ?? this.isHighPriority,
      column: column ?? this.column,
    );
  }
}
