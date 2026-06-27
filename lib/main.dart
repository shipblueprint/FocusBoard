import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:focusboard/helpers/services/storage/local_storage.dart';
import 'package:focusboard/helpers/theme/app_theme.dart';
import 'package:focusboard/helpers/theme/theme_customizer.dart';
import 'package:focusboard/route/route_method.dart';
import 'package:focusboard/route/routes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalStorage.init();
  AppStyle.init();
  await ThemeCustomizer.init();
  runApp(const FocusBoardApp());
}

class FocusBoardApp extends StatelessWidget {
  const FocusBoardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'FocusBoard',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeCustomizer.instance.theme,
      initialRoute: route.appLayout,
      getPages: getPageRoute(),
      defaultTransition: Transition.noTransition,
    );
  }
}
