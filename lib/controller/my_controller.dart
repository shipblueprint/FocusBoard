import 'package:focusboard/helpers/theme/theme_customizer.dart';
import 'package:get/get_state_manager/get_state_manager.dart';

/// Base class for GetX controllers that should rebuild on theme change.
abstract class MyController extends GetxController {
  @override
  void onInit() {
    super.onInit();
    ThemeCustomizer.addListener((ThemeCustomizer old, ThemeCustomizer newVal) {
      if (old.theme != newVal.theme) {
        update();
        onThemeChanged();
      }
    });
  }

  void onThemeChanged() {}
}
