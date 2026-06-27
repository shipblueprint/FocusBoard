/// Centralized validation & sanitization helpers for task input.
///
/// Replaces the previous [InputValidator] singleton with pure functions
/// so they can be unit-tested without side effects.
library;

import 'dart:math';

class TaskValidator {
  TaskValidator._();

  static const int maxTitleLength = 200;
  static const int minTitleLength = 1;

  static final Random _random = Random.secure();

  /// Sanitize a raw title:
  ///  * trims whitespace,
  ///  * strips HTML tags and dangerous characters (XSS prevention),
  ///  * collapses internal whitespace,
  ///  * truncates to [maxTitleLength].
  ///
  /// Throws [ArgumentError] for null/empty input or titles whose only
  /// content was invalid characters.
  static String sanitizeTitle(String? rawTitle) {
    if (rawTitle == null || rawTitle.trim().isEmpty) {
      throw ArgumentError('Task title cannot be null or empty');
    }

    String sanitized = rawTitle.trim();

    // Remove HTML tags
    sanitized = sanitized.replaceAll(RegExp(r'<[^>]*>'), '');

    // Remove dangerous characters individually to avoid regex escaping issues
    sanitized =
        sanitized.replaceAll('<', '').replaceAll('>', '').replaceAll('&', '');
    sanitized = sanitized
        .replaceAll('"', '')
        .replaceAll("'", '')
        .replaceAll('\\', '');

    // Collapse multiple spaces into a single space
    sanitized = sanitized.replaceAll(RegExp(r'\s+'), ' ');

    // Truncate to max length
    if (sanitized.length > maxTitleLength) {
      sanitized = '${sanitized.substring(0, maxTitleLength - 3)}...';
    }

    if (sanitized.isEmpty) {
      throw ArgumentError('Task title contains only invalid characters');
    }

    return sanitized;
  }

  /// Generate a simple unique id suitable for client-only persistence.
  static String generateUniqueId() {
    final int timestamp = DateTime.now().millisecondsSinceEpoch;
    final int randomPart = _random.nextInt(0xFFFFFFFF);
    return '$timestamp-${randomPart.toRadixString(16)}';
  }

  /// Generate a UUID v4-like string without any third-party dependency.
  static String generateUuid() {
    final int timestamp = DateTime.now().millisecondsSinceEpoch;
    final int random1 = _random.nextInt(0xFFFFFFFF);
    final int random2 = _random.nextInt(0xFFFFFFFF);

    final String hex1 =
        (timestamp & 0xFFFFFFFF).toRadixString(16).padLeft(8, '0');
    final String hex2 =
        (random1 & 0xFFFF).toRadixString(16).padLeft(4, '0');
    final String hex3 = (((random1 >> 16) & 0xFFFF) | 0x4000)
        .toRadixString(16)
        .padLeft(4, '0');
    final String hex4 = ((random2 & 0x3FFF) | 0x8000)
        .toRadixString(16)
        .padLeft(4, '0');
    final String hex5 = ((random2 >> 16) & 0xFFFF)
        .toRadixString(16)
        .padLeft(4, '0');
    final String hex6 =
        _random.nextInt(0xFFFF).toRadixString(16).padLeft(4, '0');

    return '$hex1-$hex2-$hex3-$hex4-$hex5$hex6';
  }

  /// Validate that an id is non-null and non-empty.
  static bool validateId(String? id) {
    if (id == null || id.isEmpty) return false;
    return id.trim().isNotEmpty;
  }

  /// Parse a value (bool / String / null) into a strict [bool].
  static bool parseBoolean(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    return false;
  }
}
