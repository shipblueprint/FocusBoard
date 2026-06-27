import 'package:focusboard/app/controller/app_binding.dart';
import 'package:focusboard/route/route_method.dart';
import 'package:focusboard/view/app_layout/app_layout.dart';
import 'package:focusboard/view/apps/analytics/analytics_screen.dart';
import 'package:focusboard/view/apps/eisenhower/eisenhower_screen.dart';
import 'package:focusboard/view/apps/kanban/kanban_screen.dart';
import 'package:get/get.dart';

/// Returns the list of [GetPage] entries used by [GetMaterialApp].
///
/// [AppBinding] wires the three feature controllers (Kanban, Eisenhower,
/// Analytics) into the [AppLayout] subtree with `permanent: true` so that
/// tab switches preserve state and tasks aren't reloaded from disk.
List<GetPage<dynamic>> getPageRoute() => <GetPage<dynamic>>[
      GetPage(
        name: route.appLayout,
        page: () => const AppLayout(),
        binding: AppBinding(),
        transition: Transition.noTransition,
      ),
      GetPage(
        name: route.kanban,
        page: () => const KanbanScreen(),
        transition: Transition.noTransition,
      ),
      GetPage(
        name: route.eisenhower,
        page: () => const EisenhowerScreen(),
        transition: Transition.noTransition,
      ),
      GetPage(
        name: route.analytics,
        page: () => const AnalyticsScreen(),
        transition: Transition.noTransition,
      ),
    ];
