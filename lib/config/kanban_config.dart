import 'package:flutter/material.dart';

class KanbanConfig {
  static const List<String> columns = ['To Do', 'In Progress', 'Done'];
  
  static const Map<String, int?> wipLimits = {
    'To Do': 5,
    'In Progress': 3,
    'Done': null,
  };

  static const Map<String, Color> columnColors = {
    'To Do': Colors.blue,
    'In Progress': Colors.orange,
    'Done': Colors.green,
  };

  static const Map<String, IconData> columnIcons = {
    'To Do': Icons.list,
    'In Progress': Icons.pending_actions,
    'Done': Icons.check_circle,
  };

  static Color getColumnColor(String column, {bool withAlpha = true}) {
    final color = columnColors[column] ?? Colors.grey;
    return withAlpha ? color.withAlpha(204) : color;
  }

  static int? getWipLimit(String column) => wipLimits[column];

  static bool isValidColumn(String column) => columns.contains(column);

  static String getDefaultColumn() => columns.first;
}

class KanbanActions {
  static const String complete = 'complete';
  static const String setPriority = 'set_priority';
  static const String removePriority = 'remove_priority';
  static const String edit = 'edit';
  static const String delete = 'delete';
  static const String restore = 'restore';

  static const List<String> activeTaskActions = [
    complete,
    setPriority,
    edit,
    delete,
  ];

  static const List<String> doneTaskActions = [
    restore,
    delete,
  ];
}
