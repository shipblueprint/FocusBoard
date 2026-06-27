import 'package:focusboard/helpers/theme/theme_customizer.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local persistence wrapper around [SharedPreferences].
///
/// Keeps a single pre-loaded instance for the whole app.
class LocalStorage {
  LocalStorage._();

  static const String _themeCustomizerKey = 'theme_customizer';

  static SharedPreferences? _preferencesInstance;

  static SharedPreferences get preferences {
    final SharedPreferences? instance = _preferencesInstance;
    if (instance == null) {
      throw StateError('Call LocalStorage.init() before use.');
    }
    return instance;
  }

  static Future<void> init() async {
    _preferencesInstance = await SharedPreferences.getInstance();
    final SharedPreferences prefs = _preferencesInstance!;
    ThemeCustomizer.fromJSON(prefs.getString(_themeCustomizerKey));
  }

  static Future<bool> setCustomizer(ThemeCustomizer customizer) {
    return preferences.setString(_themeCustomizerKey, customizer.toJSON());
  }
}
