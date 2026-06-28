import 'package:flutter/material.dart';
import 'package:focusboard/app/controller/habit_controller.dart';
import 'package:focusboard/app/model/habit_model.dart';
import 'package:focusboard/app/model/task_validator.dart';
import 'package:focusboard/helpers/theme/app_theme.dart';
import 'package:focusboard/helpers/widgets/my_container.dart';
import 'package:focusboard/helpers/widgets/my_text.dart';
import 'package:get/get.dart';

class HabitScreen extends StatelessWidget {
  const HabitScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final HabitController controller = Get.find<HabitController>();
    final String today = _today();

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
            if (controller.habits.isEmpty) {
              return Center(
                child: MyText.bodyMedium('No habits yet. Add one!'),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: MyText.titleMedium(today, fontWeight: 600),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: controller.habits.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (BuildContext ctx, int i) {
                      final Habit habit = controller.habits[i];
                      final bool done = habit.isCompletedOn(today);
                      return MyContainer(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        borderRadiusAll: 8,
                        color: AppTheme.theme.colorScheme.surface,
                        child: Row(
                          children: <Widget>[
                            SizedBox(
                              width: 48,
                              height: 48,
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                icon: Icon(
                                  done
                                      ? Icons.check_circle
                                      : Icons.radio_button_unchecked,
                                  color: done
                                      ? const Color(0xFF17A497)
                                      : AppTheme.theme.hintColor,
                                ),
                                onPressed: () =>
                                    controller.toggleDate(habit.id, today),
                              ),
                            ),
                            Expanded(
                              child: MyText.bodyMedium(
                                habit.name,
                                fontWeight: done ? 400 : 500,
                                decoration:
                                    done ? TextDecoration.lineThrough : TextDecoration.none,
                                color: done ? AppTheme.theme.hintColor : null,
                              ),
                            ),
                            SizedBox(
                              width: 48,
                              height: 48,
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                tooltip: 'Delete',
                                icon: Icon(Icons.delete_outline,
                                    color: AppTheme.theme.hintColor),
                                onPressed: () =>
                                    controller.deleteHabit(habit.id),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
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

  static String _today() {
    final DateTime d = DateTime.now();
    final List<String> months = <String>[
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    final List<String> days = <String>[
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
    ];
    return '${days[d.weekday - 1]}, ${months[d.month - 1]} ${d.day}, ${d.year}';
  }
}
