import 'package:flutter/material.dart';

enum EisenhowerQuadrant {
  urgentImportant,
  notUrgentImportant,
  urgentNotImportant,
  notUrgentNotImportant,
}

class EisenhowerConfig {
  static const Map<EisenhowerQuadrant, String> quadrantNames = {
    EisenhowerQuadrant.urgentImportant: 'Do First',
    EisenhowerQuadrant.notUrgentImportant: 'Schedule',
    EisenhowerQuadrant.urgentNotImportant: 'Delegate',
    EisenhowerQuadrant.notUrgentNotImportant: 'Eliminate',
  };

  static const Map<EisenhowerQuadrant, String> quadrantDescriptions = {
    EisenhowerQuadrant.urgentImportant: 'Urgent & Important',
    EisenhowerQuadrant.notUrgentImportant: 'Not Urgent & Important',
    EisenhowerQuadrant.urgentNotImportant: 'Urgent & Not Important',
    EisenhowerQuadrant.notUrgentNotImportant: 'Not Urgent & Not Important',
  };

  static const Map<EisenhowerQuadrant, Color> quadrantColorsLight = {
    EisenhowerQuadrant.urgentImportant: Color(0xFFFFCDD2),
    EisenhowerQuadrant.notUrgentImportant: Color(0xFFC8E6C9),
    EisenhowerQuadrant.urgentNotImportant: Color(0xFFFFE0B2),
    EisenhowerQuadrant.notUrgentNotImportant: Color(0xFFE0E0E0),
  };

  static const Map<EisenhowerQuadrant, Color> quadrantColorsDark = {
    EisenhowerQuadrant.urgentImportant: Color(0xFFC62828),
    EisenhowerQuadrant.notUrgentImportant: Color(0xFF2E7D32),
    EisenhowerQuadrant.urgentNotImportant: Color(0xFFEF6C00),
    EisenhowerQuadrant.notUrgentNotImportant: Color(0xFF424242),
  };

  static const Map<EisenhowerQuadrant, String> quadrantChartColors = {
    EisenhowerQuadrant.urgentImportant: '#FF6B6B',
    EisenhowerQuadrant.notUrgentImportant: '#4ECDC4',
    EisenhowerQuadrant.urgentNotImportant: '#FFE66D',
    EisenhowerQuadrant.notUrgentNotImportant: '#95E1D3',
  };

  static String getQuadrantName(EisenhowerQuadrant quadrant) =>
      quadrantNames[quadrant] ?? 'Unknown';

  static String getQuadrantDescription(EisenhowerQuadrant quadrant) =>
      quadrantDescriptions[quadrant] ?? 'Unknown';

  static Color getQuadrantColor(EisenhowerQuadrant quadrant, bool isDarkMode) {
    final colors = isDarkMode ? quadrantColorsDark : quadrantColorsLight;
    return colors[quadrant] ?? Colors.grey;
  }

  static String getQuadrantChartColor(EisenhowerQuadrant quadrant) =>
      quadrantChartColors[quadrant] ?? '#9E9E9E';

  static EisenhowerQuadrant getQuadrantFromFlags(bool isUrgent, bool isImportant) {
    if (isUrgent && isImportant) return EisenhowerQuadrant.urgentImportant;
    if (!isUrgent && isImportant) return EisenhowerQuadrant.notUrgentImportant;
    if (isUrgent && !isImportant) return EisenhowerQuadrant.urgentNotImportant;
    return EisenhowerQuadrant.notUrgentNotImportant;
  }

  static (bool, bool) getFlagsFromQuadrant(EisenhowerQuadrant quadrant) {
    switch (quadrant) {
      case EisenhowerQuadrant.urgentImportant:
        return (true, true);
      case EisenhowerQuadrant.notUrgentImportant:
        return (false, true);
      case EisenhowerQuadrant.urgentNotImportant:
        return (true, false);
      case EisenhowerQuadrant.notUrgentNotImportant:
        return (false, false);
    }
  }
}
