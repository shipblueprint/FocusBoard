import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:focusboard/helpers/services/json_decoder.dart';
import 'package:focusboard/helpers/theme/admin_theme.dart';
import 'package:focusboard/helpers/theme/app_theme.dart';

typedef ThemeChangeCallback = void Function(
    ThemeCustomizer oldVal, ThemeCustomizer newVal);

/// Application-wide theme and language configuration.
///
/// Lightweight reactive holder — uses an internal listener list instead of
/// [ChangeNotifier] so we don't need the `provider` package.
class ThemeCustomizer {
  ThemeCustomizer();

  static final List<ThemeChangeCallback> _notifier = [];

  ThemeMode theme = ThemeMode.system;
  ThemeMode leftBarTheme = ThemeMode.system;
  ThemeMode rightBarTheme = ThemeMode.system;
  ThemeMode topBarTheme = ThemeMode.system;

  bool rightBarOpen = false;
  bool leftBarCondensed = false;

  static ThemeCustomizer instance = ThemeCustomizer();
  static ThemeCustomizer oldInstance = ThemeCustomizer();

  static Future<void> init() async {
    // No-op for now; kept for future persistence.
  }

  String toJSON() {
    return jsonEncode({'theme': theme.name});
  }

  static ThemeCustomizer fromJSON(String? json) {
    instance = ThemeCustomizer();
    if (json != null && json.trim().isNotEmpty) {
      JSONDecoder decoder = JSONDecoder(json);
      instance.theme =
          decoder.getEnum('theme', ThemeMode.values, ThemeMode.system);
    }
    return instance;
  }

  static void addListener(ThemeChangeCallback callback) {
    _notifier.add(callback);
  }

  static void removeListener(ThemeChangeCallback callback) {
    _notifier.remove(callback);
  }

  static void _notify() {
    AdminTheme.setTheme();
    AppStyle.changeMyTheme();
    for (final ThemeChangeCallback value in _notifier) {
      value(oldInstance, instance);
    }
  }

  static void notify() {
    for (final ThemeChangeCallback value in _notifier) {
      value(oldInstance, instance);
    }
  }

  static void setTheme(ThemeMode newTheme) {
    oldInstance = instance.clone();
    instance.theme = newTheme;
    instance.leftBarTheme = newTheme;
    instance.rightBarTheme = newTheme;
    instance.topBarTheme = newTheme;
    _notify();
  }

  static void openRightBar(bool opened) {
    instance.rightBarOpen = opened;
    _notify();
  }

  static void toggleLeftBarCondensed() {
    instance.leftBarCondensed = !instance.leftBarCondensed;
    _notify();
  }

  ThemeCustomizer clone() {
    final ThemeCustomizer tc = ThemeCustomizer();
    tc.theme = theme;
    tc.rightBarTheme = rightBarTheme;
    tc.leftBarTheme = leftBarTheme;
    tc.topBarTheme = topBarTheme;
    tc.rightBarOpen = rightBarOpen;
    tc.leftBarCondensed = leftBarCondensed;
    return tc;
  }

  @override
  String toString() {
    return 'ThemeCustomizer{theme: $theme}';
  }
}
