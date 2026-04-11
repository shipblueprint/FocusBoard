import 'package:flutter/material.dart';
import 'task_model.dart';

enum EisenhowerQuadrant {
  urgentImportant,
  notUrgentImportant,
  urgentNotImportant,
  notUrgentNotImportant,
}

class EisenhowerTask extends Task {
  bool isUrgent;
  bool isImportant;

  EisenhowerQuadrant get quadrant {
    if (isUrgent && isImportant) return EisenhowerQuadrant.urgentImportant;
    if (!isUrgent && isImportant) return EisenhowerQuadrant.notUrgentImportant;
    if (isUrgent && !isImportant) return EisenhowerQuadrant.urgentNotImportant;
    return EisenhowerQuadrant.notUrgentNotImportant;
  }

  EisenhowerTask({
    required super.id,
    required super.title,
    super.isCompleted = false,
    super.isHighPriority = false,
    super.column = 'Eisenhower',
    this.isUrgent = false,
    this.isImportant = false,
  });

  factory EisenhowerTask.fromTask(Task task, {bool isUrgent = false, bool isImportant = false}) {
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
    final json = super.toJson();
    json['isUrgent'] = isUrgent;
    json['isImportant'] = isImportant;
    json['type'] = 'eisenhower';
    return json;
  }

  factory EisenhowerTask.fromJson(Map<String, dynamic> json) {
    // Validate and sanitize input data
    if (json['id'] == null || json['id'].toString().isEmpty) {
      throw ArgumentError('EisenhowerTask ID cannot be null or empty');
    }
    
    if (json['title'] == null || json['title'].toString().trim().isEmpty) {
      throw ArgumentError('EisenhowerTask title cannot be null or empty');
    }
    
    // Sanitize title to prevent XSS and UI issues
    String sanitizedTitle = json['title'].toString().trim();
    // Remove any potential HTML/script tags
    sanitizedTitle = sanitizedTitle.replaceAll(RegExp(r'<[^>]*>'), '');
    // Limit title length to prevent UI overflow
    if (sanitizedTitle.length > 200) {
      sanitizedTitle = sanitizedTitle.substring(0, 197) + '...';
    }
    
    // Validate column name
    String column = json['column'] ?? 'Eisenhower';
    const validColumns = ['Eisenhower'];
    if (!validColumns.contains(column)) {
      column = 'Eisenhower'; // Default to safe value
    }
    
    return EisenhowerTask(
      id: json['id'].toString(),
      title: sanitizedTitle,
      isCompleted: json['isCompleted'] == true,
      isHighPriority: json['isHighPriority'] == true,
      column: column,
      isUrgent: json['isUrgent'] == true,
      isImportant: json['isImportant'] == true,
    );
  }

  @override
  EisenhowerTask copyWith({
    String? id,
    String? title,
    bool? isCompleted,
    bool? isHighPriority,
    String? column,
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

  String get quadrantName {
    switch (quadrant) {
      case EisenhowerQuadrant.urgentImportant:
        return 'Do First';
      case EisenhowerQuadrant.notUrgentImportant:
        return 'Schedule';
      case EisenhowerQuadrant.urgentNotImportant:
        return 'Delegate';
      case EisenhowerQuadrant.notUrgentNotImportant:
        return 'Eliminate';
    }
  }

  Color getQuadrantColor(bool isDarkMode) {
    switch (quadrant) {
      case EisenhowerQuadrant.urgentImportant:
        return isDarkMode ? Colors.red.shade800 : Colors.red.shade100;
      case EisenhowerQuadrant.notUrgentImportant:
        return isDarkMode ? Colors.green.shade800 : Colors.green.shade100;
      case EisenhowerQuadrant.urgentNotImportant:
        return isDarkMode ? Colors.orange.shade800 : Colors.orange.shade100;
      case EisenhowerQuadrant.notUrgentNotImportant:
        return isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100;
    }
  }
}