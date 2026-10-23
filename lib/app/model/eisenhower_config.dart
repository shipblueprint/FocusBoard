import 'package:flutter/painting.dart';
import 'package:focusboard/helpers/theme/app_theme.dart';

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

  /// Quadrant accents, drawn from the four-step brand ramp in `AppColors`.
  ///
  /// Luminance carries the meaning — darkest is the most important quadrant —
  /// so the four headers stay distinguishable without leaving the palette.
  static const Map<EisenhowerQuadrant, Color> quadrantColors =
      <EisenhowerQuadrant, Color>{
    EisenhowerQuadrant.urgentImportant: AppColors.espresso,
    EisenhowerQuadrant.notUrgentImportant: AppColors.deepMaroon,
    EisenhowerQuadrant.urgentNotImportant: AppColors.rustClay,
    EisenhowerQuadrant.notUrgentNotImportant: AppColors.harvestGold,
  };

  /// Text drawn on top of [quadrantColors]. harvestGold is only 2.8:1 against
  /// white, so it takes espresso ink instead of the white the dark steps use.
  static const Map<EisenhowerQuadrant, Color> quadrantInkColors =
      <EisenhowerQuadrant, Color>{
    EisenhowerQuadrant.urgentImportant: Color(0xFFFFFFFF),
    EisenhowerQuadrant.notUrgentImportant: Color(0xFFFFFFFF),
    EisenhowerQuadrant.urgentNotImportant: Color(0xFFFFFFFF),
    EisenhowerQuadrant.notUrgentNotImportant: AppColors.espresso,
  };

  static String getQuadrantName(EisenhowerQuadrant quadrant) =>
      quadrantNames[quadrant] ?? 'Unknown';

  static String getQuadrantDescription(EisenhowerQuadrant quadrant) =>
      quadrantDescriptions[quadrant] ?? 'Unknown';

  static Color getQuadrantColor(EisenhowerQuadrant quadrant) =>
      quadrantColors[quadrant] ?? AppColors.rustClay;

  static Color getQuadrantInkColor(EisenhowerQuadrant quadrant) =>
      quadrantInkColors[quadrant] ?? const Color(0xFFFFFFFF);

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
