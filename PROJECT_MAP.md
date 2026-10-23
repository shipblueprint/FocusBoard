# PROJECT_MAP — FocusBoard

Living map of the codebase for whoever (human or agent) edits it next.
Update it in the same change that alters anything described here; anything you
deprecate or deliberately leave broken goes in [Pending gaps](#8-pending-gaps).

Last reviewed: 2026-10-24 (brand palette applied to the 7 feature accents).

---

## 1. Entry points and wiring

```
lib/main.dart              main() → LocalStorage/AppStyle/ThemeCustomizer init → FocusBoardApp
                             GetMaterialApp(initialRoute: route.appLayout, getPages: getPageRoute())
lib/route/routes_name.dart Route name registry, exposed as the global `route` (route/route_method.dart)
lib/route/routes.dart      GetPage list. Only `route.appLayout` carries a binding.
lib/view/app_layout/       AppLayout: IndexedStack shell + NavigationBar for the 4 tabs
                             Kanban · Eisenhower · Habits · Analytics
lib/app/controller/app_binding.dart
                           AppBinding.dependencies() Get.put's all four controllers `permanent: true`
                             ORDER MATTERS: Kanban → Eisenhower → Analytics → Habit
```

Screens resolve controllers with `Get.find<T>()`; state survives tab switches because
the controllers are permanent and the tabs live in an `IndexedStack`.

## 2. Layers

| Layer | Files | Owns |
| --- | --- | --- |
| Model | `app/model/task_model.dart` | `KanbanColumn` (toDo/inProgress/done, `label`, `fromString`), `Task` (id, title, isCompleted, isHighPriority, column) |
| | `app/model/eisenhower_config.dart` | `EisenhowerQuadrant` + names (Do First / Schedule / Delegate / Eliminate), colours, flag↔quadrant conversion |
| | `app/model/eisenhower_task_model.dart` | `EisenhowerTask extends Task` — adds `isUrgent`/`isImportant`, derives `quadrant`; `toJson` also writes `type: 'eisenhower'` |
| | `app/model/task_validator.dart` | `sanitizeTitle`, `validateId`, `parseBoolean`, `generateUuid` — the only input-validation seam |
| | `app/model/habit_model.dart` | `Habit` + per-day check-ins |
| Data | `app/data/task_storage.dart` | `TaskStorage` static SharedPreferences JSON bridge (keys below). No logic. |
| Controller | `app/controller/kanban_controller.dart` | board task list, WIP limits |
| | `app/controller/eisenhower_controller.dart` | matrix task list, quadrant bucketing |
| | `app/controller/habit_controller.dart` | habit list + streaks |
| | `app/controller/analytics_controller.dart` | read-only derived metrics; owns no tasks |
| View | `view/apps/{kanban,eisenhower,habit,analytics}/` | one screen per tab |
| | `view/apps/eisenhower/eisenhower_screen.dart` | 2×2 `_Quadrant` grid, `_openAddTaskSheet`, `_QuadrantTaskTile` |
| Design system | `helpers/theme/app_theme.dart`, `helpers/widgets/my_*.dart` | flat-design tokens (`MyText`, `MyContainer`, `MyCard`, spacing, shadows) plus `AppColors` — the single source of brand colour (§5). Much of `helpers/` is inherited from the Codelessly/MyTheme boilerplate and is unused by the four tabs. |

## 3. Cross-controller seams

Controllers never mutate each other's lists; they call a public method on the other
controller and that method owns its own rules and persistence.

| Seam | Direction | Method | Resolved via |
| --- | --- | --- | --- |
| Analytics reads both | read | `AnalyticsController` getters | ctor `?: Get.find` fallback |
| Board → matrix | write | `EisenhowerController.importFromTask(Task, isUrgent:, isImportant:)` | copy (leaves the board task in place) |
| Matrix → board | write | `EisenhowerController.moveDoFirstToKanban()` → `KanbanController.importTasks(List<Task>)` | move (id-preserving, empties Do First) |

`EisenhowerController` now has a constructor (`{KanbanController? kanban}`) defaulting to
`Get.find<KanbanController>()`. **Any new site that constructs it must register
`KanbanController` first**, or pass one explicitly — otherwise construction throws.
`AppBinding` already satisfies this; the test passes the instance in.

## 4. Do First → Kanban To Do

`SPEC-do-first-to-kanban.md` is the authority; this is the shape.

- UI: `EisenhowerScreen` AppBar action `Icons.swap_horiz`, tooltip "Move Do First to
  Kanban", wrapped in `Obx` so it disables itself while Do First is empty.
- `EisenhowerController.moveDoFirstToKanban() → Future<int>`: selects
  `byQuadrant(urgentImportant)`, hands it to the board, then removes the quadrant and
  persists. Returns the number that left the matrix; `0` is a no-op that writes nothing.
- `KanbanController.importTasks(List<Task>)`: rebuilds each entry as a **plain `Task`**
  (not `copyWith` — `EisenhowerTask.copyWith` would keep the Eisenhower fields alive and
  leak them into `kanban_tasks_v1` through `toJson`'s dynamic dispatch), forces
  `column: KanbanColumn.toDo`, skips ids already on the board, persists once.
- Write order: board first, matrix second, so a task is never in neither system.
- Logging: `debugPrint('Kanban: imported N task(s) into To Do')` and
  `debugPrint('Eisenhower: moved N Do First task(s) to Kanban To Do')`.

## 5. Brand palette

Every brand colour resolves to `class AppColors` at the bottom of
`lib/helpers/theme/app_theme.dart`. **That class already lives there** (it shipped with the
template, mostly unused) — creating `helpers/theme/app_colors.dart` alongside it produces two
`AppColors` classes and a storm of `undefined_getter` errors.

```
harvestGold    0xFFBB9457   espresso       0xFF432818   rustClay    0xFF99582A
deepMaroon     0xFF6F1D1B   ivoryPorcelain 0xFFEFE3D2   brand = deepMaroon
```

Roles are assigned by measured WCAG contrast, not preference: `harvestGold` is 2.6:1 on the
light surface, so it is a **fill only** and must never carry text — its ink is `espresso`.
Alpha-dimmed ink (the old `Colors.white70`) fails contrast on gold and clay, so every accent
now pairs with a full-opacity ink.

The 7 feature accents, each `{fill → ink}`:

| Slot | Fill | Ink |
| --- | --- | --- |
| Kanban To Do | harvestGold | espresso |
| Kanban In Progress | rustClay | white |
| Kanban Done | deepMaroon | white |
| Eisenhower Do First | espresso | white |
| Eisenhower Schedule | deepMaroon | white |
| Eisenhower Delegate | rustClay | white |
| Eisenhower Eliminate | harvestGold | espresso |

- Kanban keeps its pair in `KanbanScreen._columnColors` / `_columnInk`; `_ColumnView` takes an
  `ink:` argument. Both maps are class-private, so a sibling widget must qualify them as
  `KanbanScreen._columnColors[...]`.
- Eisenhower keeps its pair in `EisenhowerConfig.quadrantColors` / `quadrantInkColors` with
  `getQuadrantColor` / `getQuadrantInkColor`. `quadrantColorsHex` and `getQuadrantChartColor`
  were deleted as a dead duplicate — the Analytics chart now reads `getQuadrantColor`, so the
  matrix, the board and the chart share one source.
- Chrome: `AppTheme.primaryColor = AppColors.brand`, both `ColorScheme.fromSeed(seedColor:
  AppColors.brand)`, and a `navigationBarTheme` per theme (ivoryPorcelain surface, harvestGold
  indicator, espresso selected ink, `navInkUnselectedLight/Dark` unselected). M3's
  `iconSelectedColor`/`labelSelectedColor` do not exist on `NavigationBarThemeData`, hence the
  `WidgetStateProperty.resolveWith` on `iconTheme`/`labelTextStyle`.

## 6. Persistence

`TaskStorage` (`app/data/task_storage.dart`), JSON strings in SharedPreferences:

| Key | Payload | Read by |
| --- | --- | --- |
| `kanban_tasks_v1` | `List<Task>` | `KanbanController._load` / `importTasks` / every mutation |
| `eisenhower_tasks_v1` | `List<EisenhowerTask>` | `EisenhowerController._load` / `_persist` |
| `kanban_wip_limits_v1` | `Map<String, int>` | `KanbanController` WIP limits |
| `habits_v1` | `List<Habit>` | `HabitController`, also `hasEverSaved()` |

Every `_load()` seeds sample tasks when storage is empty — tests must clear or replace the
lists after that seed settles (see `test/eisenhower_kanban_transfer_test.dart` setUp).

## 7. Tests

| File | Covers |
| --- | --- |
| `test/eisenhower_kanban_transfer_test.dart` | the matrix→board transfer: selection, column forcing, identity, dedupe, no-op, persistence, plain-`Task` serialization — plus two widget tests that pump `EisenhowerScreen` and tap the AppBar action |
| `test/task_validator_test.dart` | title sanitising, id validation, boolean parsing |
| `test/my_text_test.dart` | `MyText` renders without network fonts |
| `test/widget_test.dart` | boilerplate smoke test |

Controller tests use `SharedPreferences.setMockInitialValues({})`, `Get.put(...)`,
`Get.reset()` in `tearDown` — no mocking package is present, and `Get.reset()` returns
`void` in GetX 4.6.6 so it must not be awaited.

`flutter analyze` baseline: **3 pre-existing info lints** (2 × `deprecated_member_use` in
`app_theme.dart`, 1 × `curly_braces_in_flow_control_structures` in `my_dotted_line.dart`).
A change that adds a 4th is not clean.

## 8. Pending gaps

Recorded, not fixed — each is outside the change that surfaced it.

1. **Kanban WIP limits are advisory and UI-only.** `isWipLimitReached` is consulted by the
   drag layer in `kanban_screen.dart` only; `addTask` and `importTasks` both push past the
   To Do limit (default 8) unchecked. A bulk move can therefore overflow the column.
2. **`importFromTask` has no dedupe**, unlike `importTasks`. Re-importing the same board
   task twice yields two matrix entries.
3. **No undo.** Moving Do First clears the quadrant; the tasks are recoverable only by
   dragging them back from the board one at a time.
4. **Standalone routes without bindings.** `route.eisenhower`, `route.kanban`,
   `route.habit` and `route.analytics` in `routes.dart` have no `binding:`, so they only
   work after `AppLayout` has run `AppBinding`. They appear unused by the shell today.
5. **`pubspec.yaml` version is `0.1.0+1`** while the published GitHub releases are `v1.0.x`.
6. **Android/iOS/macOS application ids are still `com.example.henox`** — the FocusBoard
   rename only reached `linux/CMakeLists.txt` (`io.github.shipblueprint.focusboard`).
7. **`_Quadrant` overflows its Column by 1px at 800×600.** Surfaced by the transfer widget
   test, which pumps the screen; unrelated to the AppBar action (no vertical height is
   added). The test therefore runs at a 1600×1200 surface instead of asserting on the
   overflow. The layout itself is still unfixed: the quadrant `Column` has a fixed-height
   header plus `Expanded` list and has no slack at short heights.
8. **`lib/controller/my_controller.dart`, `lib/model/*`, and most of `lib/helpers/widgets/my_*`
   are unused boilerplate** from the template the app started from. Dead, but load-bearing
   for nothing; delete only as a deliberate cleanup, not as collateral.
9. **Off-brand colours left on purpose by the accent pass.** The Habits tab still uses the
   template teal (`AppColors.success` / `0xff1abc9c` family), the Kanban high-priority card
   border is `Colors.orange.withValues(alpha: 0.6)`, and the Analytics screen keeps its own
   chart palette apart from the `getQuadrantColor` line. The user scoped that pass to the 7
   accents and the chrome; Analytics was explicitly deferred.
10. **`AppColors` still carries the template `ColorGroup` registry** (`list`, `get`, `random`,
    `getColorByRating`) which nothing in the four tabs reads. The brand constants live in the
    same class, so deleting the registry means editing the file that owns the palette.
11. **`AppTheme.createTheme()` is dead** — the app installs `AppTheme.theme`, so only the two
    `lightTheme`/`darkTheme` builders below it are on the colour path.

## 9. Verifying a change

```
/mnt/data/flutter/bin/flutter test                       # 28 tests as of 2026-10-24
/mnt/data/flutter/bin/flutter analyze --no-pub           # baseline is 3 info lints
/mnt/data/gtkdev/flutter-linux-build.sh --release        # needs the GTK prefix until gtk3-devel is installed
scripts/install-linux.sh                                 # build → ~/.local/share/focusboard + .desktop + icons
build/linux/x64/release/bundle/FocusBoard                # boots; AppBinding resolves the Kanban→Eisenhower order here
```

Only `bundle/lib/libapp.so` (the Dart payload) changes for Dart-only edits — a stale-looking
`FocusBoard` executable timestamp is normal. Confirm a rebuild took with
`strings bundle/lib/libapp.so | grep '<new log line>'`. `scripts/install-linux.sh` refuses to
install a bundle older than `lib/`, so a forgotten rebuild cannot reach the install.

To eyeball a colour change on this GNOME host: GNOME's screenshot D-Bus is blocked and
`xwininfo`/`xdotool`/`grim` are absent, but ImageMagick can grab a single window by id —
`xprop -root _NET_CLIENT_LIST` to find it, then `magick x:0x600007 out.png`. A window taller
than the screen hides the nav bar; `python3 -c` with `Xlib` (`pip install --user python-xlib`)
can `configure(x=0, y=0)` it and drive `xtest.fake_input` clicks on the destinations.
