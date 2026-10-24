import 'package:flutter/material.dart';
import 'package:focusboard/app/controller/habit_controller.dart';
import 'package:focusboard/app/model/habit_model.dart';
import 'package:focusboard/app/model/task_validator.dart';
import 'package:focusboard/helpers/theme/app_theme.dart';
import 'package:focusboard/helpers/widgets/my_container.dart';
import 'package:focusboard/helpers/widgets/my_text.dart';
import 'package:get/get.dart';

// ponytail: horizontal cards, 7-day week grid, stats banner, encourage message

class HabitScreen extends StatelessWidget {
  const HabitScreen({super.key});

  static const List<String> _dayLabels = <String>['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  static const List<String> _encouragements = <String>[
    'Missed a day? No sweat — consistency isn\'t perfection, it\'s showing up again.',
    'A setback is just a setup for a comeback. Tomorrow\'s a fresh day.',
    'You don\'t need to be perfect, just persistent. Get back on track!',
    'Every streak starts with a single day. Reset and go again.',
    'Progress isn\'t linear. One miss doesn\'t erase your wins.',
    'Small daily wins compound into big results. Keep showing up.',
  ];

  @override
  Widget build(BuildContext context) {
    final HabitController controller = Get.find<HabitController>();
    final String today = _todayKey();
    final Color accent = AppTheme.theme.colorScheme.secondary;
    final Color accentInk = AppTheme.theme.colorScheme.onSecondary;

    return Scaffold(
      backgroundColor: AppTheme.theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Habits'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Add habit',
            icon: const Icon(Icons.add),
            onPressed: () => _openAddSheet(context, controller),
          ),
        ],
      ),
      body: SafeArea(
        child: Obx(
          () {
            try {
            if (controller.habits.isEmpty) {
              return Center(
                child: MyText.bodyMedium('No habits yet. Add one!'),
              );
            }

            // Person-level stats
            final Set<String> allDates = <String>{};
            for (final Habit h in controller.habits) {
              allDates.addAll(h.completedDates);
            }
            final String todayKey = _todayKey();
            final bool todayDone = allDates.contains(todayKey);

            int weekActive = 0;
            final DateTime now = DateTime.now();
            final DateTime weekStart = now.subtract(Duration(days: now.weekday - 1));
            for (int i = 0; i < 7; i++) {
              final DateTime d = weekStart.add(Duration(days: i));
              final String k = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
              if (allDates.contains(k)) weekActive++;
            }

            int currentStreak = 0;
            for (int i = todayDone ? 0 : 1; ; i++) {
              final DateTime d = now.subtract(Duration(days: i));
              final String k = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
              if (allDates.contains(k)) { currentStreak++; } else { break; }
            }

            int bestStreak = 0;
            if (allDates.isNotEmpty) {
              final List<String> sorted = allDates.toList()..sort();
              int cur = 0;
              DateTime? prev;
              for (final String key in sorted) {
                final List<int> parts = key.split('-').map(int.tryParse).whereType<int>().toList();
                if (parts.length < 3) continue;
                final DateTime d = DateTime(parts[0], parts[1], parts[2]);
                if (prev != null && d.difference(prev).inDays == 1) { cur++; } else { cur = 1; }
                if (cur > bestStreak) bestStreak = cur;
                prev = d;
              }
            }

            final String encouragement = !todayDone
                ? _encouragements[now.millisecondsSinceEpoch % _encouragements.length]
                : '';

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // Stats banner (person-level)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Row(
                    children: <Widget>[
                      Expanded(child: MyContainer(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        borderRadiusAll: 12,
                        color: AppTheme.theme.colorScheme.surface,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(children: <Widget>[
                              Icon(Icons.local_fire_department, color: accent, size: 14),
                              const SizedBox(width: 4),
                              Expanded(
                                child: MyText.bodySmall('Streak',
                                    color: AppTheme.theme.hintColor,
                                    fontWeight: 500,
                                    overflow: TextOverflow.ellipsis),
                              ),
                            ]),
                            const SizedBox(height: 4),
                            MyText.bodyMedium('$currentStreak days', fontWeight: 700),
                          ],
                        ),
                      )),
                      const SizedBox(width: 8),
                      Expanded(child: MyContainer(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        borderRadiusAll: 12,
                        color: AppTheme.theme.colorScheme.surface,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(children: <Widget>[
                              Icon(Icons.emoji_events, color: accent, size: 14),
                              const SizedBox(width: 4),
                              Expanded(
                                child: MyText.bodySmall('Best',
                                    color: AppTheme.theme.hintColor,
                                    fontWeight: 500,
                                    overflow: TextOverflow.ellipsis),
                              ),
                            ]),
                            const SizedBox(height: 4),
                            MyText.bodyMedium('$bestStreak days', fontWeight: 700),
                          ],
                        ),
                      )),
                      const SizedBox(width: 8),
                      Expanded(child: MyContainer(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        borderRadiusAll: 12,
                        color: AppTheme.theme.colorScheme.surface,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(children: <Widget>[
                              Icon(Icons.task_alt, color: accent, size: 14),
                              const SizedBox(width: 4),
                              Expanded(
                                child: MyText.bodySmall('Week',
                                    color: AppTheme.theme.hintColor,
                                    fontWeight: 500,
                                    overflow: TextOverflow.ellipsis),
                              ),
                            ]),
                            const SizedBox(height: 4),
                            MyText.bodyMedium('$weekActive/7', fontWeight: 700),
                          ],
                        ),
                      )),
                    ],
                  ),
                ),
                // Section header
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 2),
                  child: Row(
                    children: <Widget>[
                      MyText.bodyMedium('This Week', fontWeight: 600),
                      const Spacer(),
                      MyText.bodySmall(_weekRange(),
                          color: AppTheme.theme.hintColor),
                    ],
                  ),
                ),
                // Encouragement
                if (encouragement.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: MyText.bodySmall(encouragement,
                        color: accent, fontWeight: 500),
                  ),
                const SizedBox(height: 4),
                // Habit cards
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: controller.habits.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (BuildContext ctx, int i) {
                      final Habit habit = controller.habits[i];
                      final bool done = habit.isCompletedOn(today);
                      final int streak = habit.currentStreak();
                      final int weekDone = habit.weekDone();
                      final List<(String, bool, bool)> weekDays =
                          habit.currentWeek();
                      // Shared pieces of the habit card.
                      final Widget checkbox = SizedBox(
                        width: 52,
                        child: Center(
                          child: GestureDetector(
                            onTap: () =>
                                controller.toggleDate(habit.id, today),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: done ? accent : Colors.transparent,
                                border: Border.all(
                                  color: done
                                      ? accent
                                      : AppTheme.theme.hintColor,
                                  width: 2,
                                ),
                                boxShadow: done
                                    ? <BoxShadow>[
                                        BoxShadow(
                                          color:
                                              accent.withValues(alpha: 0.3),
                                          blurRadius: 12,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: done
                                  ? Icon(Icons.check,
                                      color: accentInk, size: 22)
                                  : null,
                            ),
                          ),
                        ),
                      );
                      final Widget nameStats = Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            MyText.bodyMedium(habit.name, fontWeight: 600),
                            const SizedBox(height: 2),
                            MyText.bodySmall(
                              streak > 0
                                  ? '🔥 $streak-day streak · $weekDone/7 this week'
                                  : '$weekDone/7 this week',
                              color: accent,
                              fontWeight: 500,
                              softWrap: true,
                            ),
                          ],
                        ),
                      );
                      final List<Widget> dayCircles =
                          List<Widget>.generate(7, (int j) {
                        final (String dk, bool d, bool f) = weekDays[j];
                        final bool isToday = dk == today;
                        return _DayCircle(
                          label: _dayLabels[j],
                          done: d,
                          isFuture: f,
                          isToday: isToday,
                          onTap: f
                              ? null
                              : () => controller.toggleDate(habit.id, dk),
                        );
                      });
                      final Widget menu = SizedBox(
                        width: 36,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: Icon(Icons.more_vert,
                              color: AppTheme.theme.hintColor),
                          onPressed: () => _confirmDelete(
                              context, controller, habit.id, habit.name),
                        ),
                      );

                      return MyContainer(
                        padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
                        borderRadiusAll: 12,
                        color: AppTheme.theme.colorScheme.surface,
                        child: LayoutBuilder(
                          builder: (BuildContext context,
                              BoxConstraints constraints) {
                            // Narrow cards can't fit checkbox + name + 7
                            // circles + menu on one line; give the circles
                            // their own evenly spaced row below the name.
                            final bool narrow =
                                constraints.maxWidth < 560;
                            if (narrow) {
                              return Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.stretch,
                                children: <Widget>[
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      checkbox,
                                      Expanded(child: nameStats),
                                      menu,
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: dayCircles,
                                  ),
                                ],
                              );
                            }
                            return Row(
                              children: <Widget>[
                                checkbox,
                                Expanded(child: nameStats),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: <Widget>[
                                      for (int j = 0; j < 7; j++) ...<Widget>[
                                        if (j > 0)
                                          const SizedBox(width: 4),
                                        dayCircles[j],
                                      ],
                                    ],
                                  ),
                                ),
                                menu,
                              ],
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
            } catch (e, s) {
              debugPrint('HabitScreen error: $e\n$s');
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: MyText.bodySmall('Error: $e', color: Colors.red),
                ),
              );
            }
          },
        ),
      ),
    );
  }

  String _weekRange() {
    final DateTime now = DateTime.now();
    final DateTime monday = now.subtract(Duration(days: now.weekday - 1));
    final DateTime sunday = monday.add(const Duration(days: 6));
    final List<String> months = <String>[
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    if (monday.month == sunday.month) {
      return '${months[monday.month - 1]} ${monday.day}–${sunday.day}';
    }
    return '${months[monday.month - 1]} ${monday.day} – ${months[sunday.month - 1]} ${sunday.day}';
  }

  Future<void> _openAddSheet(
      BuildContext context, HabitController controller) async {
    final TextEditingController text = TextEditingController();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.theme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: 16 + MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              MyText.titleMedium('New Habit', fontWeight: 600),
              const SizedBox(height: 12),
              TextField(
                controller: text,
                autofocus: true,
                maxLength: TaskValidator.maxTitleLength,
                decoration: const InputDecoration(
                  hintText: 'What habit do you want to build?',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () async {
                        final String raw = text.text.trim();
                        if (raw.isEmpty) return;
                        try {
                          await controller.addHabit(raw);
                          if (ctx.mounted) Navigator.of(ctx).pop();
                        } catch (_) {}
                      },
                      child: const Text('Add'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(BuildContext context,
      HabitController controller, String id, String name) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Delete habit?'),
        content: MyText.bodySmall('Delete "$name" forever?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok == true) controller.deleteHabit(id);
  }

  static String _todayKey() {
    final DateTime d = DateTime.now();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }
}

class _DayCircle extends StatelessWidget {
  final String label;
  final bool done;
  final bool isFuture;
  final bool isToday;
  final VoidCallback? onTap;

  const _DayCircle({
    required this.label,
    required this.done,
    required this.isFuture,
    required this.isToday,
    this.onTap,
  });

  bool get _isMissed => !done && !isFuture;

  @override
  Widget build(BuildContext context) {
    final double opacity = (isFuture || _isMissed) ? 0.5 : 1.0;
    final Color accent = AppTheme.theme.colorScheme.secondary;
    final Color accentInk = AppTheme.theme.colorScheme.onSecondary;
    return Opacity(
      opacity: opacity,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            MyText.bodySmall(label,
                color: isToday ? accent : AppTheme.theme.hintColor,
                fontWeight: isToday ? 700 : 500,
                fontSize: 10,
                decoration: _isMissed ? TextDecoration.lineThrough : TextDecoration.none),
            const SizedBox(height: 4),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done
                    ? accent
                    : _isMissed
                        ? AppTheme.theme.dividerColor.withValues(alpha: 0.3)
                        : Colors.transparent,
                border: Border.all(
                  color: done
                      ? accent
                      : _isMissed
                          ? AppTheme.theme.hintColor.withValues(alpha: 0.2)
                          : isFuture
                              ? AppTheme.theme.dividerColor
                              : AppTheme.theme.hintColor.withValues(alpha: 0.4),
                  width: isToday && !done ? 2 : 1.5,
                ),
                boxShadow: isToday && done
                    ? <BoxShadow>[
                        BoxShadow(
                          color: accent.withValues(alpha: 0.25),
                          blurRadius: 8,
                        ),
                      ]
                    : null,
              ),
              child: done
                  ? Icon(Icons.check, color: accentInk, size: 16)
                  : _isMissed
                      ? Icon(Icons.close, color: AppTheme.theme.hintColor.withValues(alpha: 0.3), size: 12)
                      : (isToday
                          ? Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: accent,
                                shape: BoxShape.circle,
                              ),
                            )
                          : null),
            ),
          ],
        ),
      ),
    );
  }
}
