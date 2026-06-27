import 'package:flutter/material.dart';
import 'package:focusboard/helpers/services/storage/local_storage.dart';
import 'package:focusboard/helpers/theme/app_theme.dart';
import 'package:focusboard/helpers/theme/theme_customizer.dart';
import 'package:focusboard/helpers/widgets/my.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppNotifier extends ChangeNotifier {
  AppNotifier();

  Future<void> init() async {
    _changeTheme();
    notifyListeners();
  }

  updateTheme(ThemeCustomizer themeCustomizer) {
    _changeTheme();

    notifyListeners();

    LocalStorage.setCustomizer(themeCustomizer);
  }

  Future<void> updateInStorage(ThemeCustomizer themeCustomizer) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    sharedPreferences.setString("theme_customizer", themeCustomizer.toJSON());
  }

  void changeDirectionality(TextDirection textDirection, [bool notify = true]) {
    AppTheme.textDirection = textDirection;
    My.setTextDirection(textDirection);

    if (notify) notifyListeners();
  }

  void _changeTheme() {
    AppTheme.theme = AppTheme.getThemeFromThemeMode();
    AppStyle.changeMyTheme();
  }
}
