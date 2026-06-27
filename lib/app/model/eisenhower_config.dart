import 'package:flutter/painting.dart';

/// Quadrant classification for the Eisenhower Matrix.
enum EisenhowerQuadrant {
  urgentImportant,
  notUrgentImportant,
  urgentNotImportant,
  notUrgentNotImportant,
}

/// Static configuration for the Eisenhower Matrix.
///
/// Holds display names, descriptions, colors, and helper logic for
/// converting between (urgent, important) flags and [EisenhowerQuadrant].
class EisenhowerConfig {
  static const Map<EisenhowerQuadrant, String> quadrantNames =
      <EisenhowerQuadrant, String>{
    EisenhowerQuadrant.urgentImportant: 'Do First',
    EisenhowerQuadrant.notUrgentImportant: 'Schedule',
    EisenhowerQuadrant.urgentNotImportant: 'Delegate',
    EisenhowerQuadrant.notUrgentNotImportant: 'Eliminate',
  };

  static const Map<EisenhowerQuadrant, String> quadrantDescriptions =
      <EisenhowerQuadrant, String>{
    EisenhowerQuadrant.urgentImportant: 'Urgent & Important',
    EisenhowerQuadrant.notUrgentImportant: 'Not Urgent & Important',
    EisenhowerQuadrant.urgentNotImportant: 'Urgent & Not Important',
    EisenhowerQuadrant.notUrgentNotImportant: 'Not Urgent & Not Important',
  };

  static const Map<EisenhowerQuadrant, String> quadrantColorsHex =
      <EisenhowerQuadrant, String>{
    EisenhowerQuadrant.urgentImportant: '#FF6B6B',
    EisenhowerQuadrant.notUrgentImportant: '#4ECDC4',
    EisenhowerQuadrant.urgentNotImportant: '#FFE66D',
    EisenhowerQuadrant.notUrgentNotImportant: '#95A5A6',
  };

  /// Flat design quadrant colors that pair with the FocusBoard design system.
  static const Map<EisenhowerQuadrant, int> quadrantColors =
      <EisenhowerQuadrant, int>{
    EisenhowerQuadrant.urgentImportant: 0xFFE53935,
    EisenhowerQuadrant.notUrgentImportant: 0xFF00897B,
    EisenhowerQuadrant.urgentNotImportant: 0xFFFB8C00,
    EisenhowerQuadrant.notUrgentNotImportant: 0xFF757575,
  };

  static String getQuadrantName(EisenhowerQuadrant quadrant) =>
      quadrantNames[quadrant] ?? 'Unknown';

  static String getQuadrantDescription(EisenhowerQuadrant quadrant) =>
      quadrantDescriptions[quadrant] ?? 'Unknown';

  static String getQuadrantChartColor(EisenhowerQuadrant quadrant) =>
      quadrantColorsHex[quadrant] ?? '#9E9E9E';

  static Color getQuadrantColor(EisenhowerQuadrant quadrant) =>
      Color(quadrantColors[quadrant] ?? 0xFF9E9E9E);

  static EisenhowerQuadrant getQuadrantFromFlags(
      bool isUrgent, bool isImportant) {
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
