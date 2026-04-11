import 'package:flutter/material.dart';
import '../config/eisenhower_config.dart';
import 'task_model.dart';

class EisenhowerTask extends Task {
  bool isUrgent;
  bool isImportant;

  EisenhowerQuadrant get quadrant =>
      EisenhowerConfig.getQuadrantFromFlags(isUrgent, isImportant);

  EisenhowerTask({
    required super.id,
    required super.title,
    super.isCompleted = false,
    super.isHighPriority = false,
    super.column = 'Eisenhower',
    this.isUrgent = false,
    this.isImportant = false,
  });

  factory EisenhowerTask.fromTask(Task task,
      {bool isUrgent = false, bool isImportant = false}) {
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
    if (json['id'] == null || json['id'].toString().isEmpty) {
      throw ArgumentError('EisenhowerTask ID cannot be null or empty');
    }

    if (json['title'] == null || json['title'].toString().trim().isEmpty) {
      throw ArgumentError('EisenhowerTask title cannot be null or empty');
    }

    String sanitizedTitle = json['title'].toString().trim();
    sanitizedTitle = sanitizedTitle.replaceAll(RegExp(r'<[^>]*>'), '');
    if (sanitizedTitle.length > 200) {
      sanitizedTitle = '${sanitizedTitle.substring(0, 197)}...';
    }

    return EisenhowerTask(
      id: json['id'].toString(),
      title: sanitizedTitle,
      isCompleted: json['isCompleted'] == true,
      isHighPriority: json['isHighPriority'] == true,
      column: 'Eisenhower',
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

  String get quadrantName => EisenhowerConfig.getQuadrantName(quadrant);

  Color getQuadrantColor(bool isDarkMode) =>
      EisenhowerConfig.getQuadrantColor(quadrant, isDarkMode);
}
