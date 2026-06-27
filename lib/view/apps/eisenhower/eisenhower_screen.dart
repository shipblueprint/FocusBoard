import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:focusboard/app/controller/eisenhower_controller.dart';
import 'package:focusboard/app/model/eisenhower_config.dart';
import 'package:focusboard/app/model/eisenhower_task_model.dart';
import 'package:focusboard/app/model/task_validator.dart';
import 'package:focusboard/helpers/theme/app_theme.dart';
import 'package:focusboard/helpers/widgets/my_container.dart';
import 'package:focusboard/helpers/widgets/my_text.dart';
import 'package:get/get.dart';

// ponytail: AnimatedContainer + elevation + delay to match Kanban DnD feel

/// Eisenhower Matrix screen.
///
/// Lays out four quadrants in a 2x2 grid. Each quadrant is a [DragTarget]
/// for tasks so they can be reorganized visually.
class EisenhowerScreen extends StatelessWidget {
  const EisenhowerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final EisenhowerController controller =
        Get.find<EisenhowerController>();

    return Scaffold(
      backgroundColor: AppTheme.theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Eisenhower Matrix'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Add task',
            icon: const Icon(Icons.add),
            onPressed: () => _openAddTaskSheet(context, controller),
          ),
        ],
      ),
      body: SafeArea(
        child: Obx(
          () => Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: <Widget>[
                Expanded(
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: _Quadrant(
                          quadrant: EisenhowerQuadrant.urgentImportant,
                          tasks: controller.byQuadrant(
                              EisenhowerQuadrant.urgentImportant),
                          onMove: (String id, EisenhowerQuadrant target) =>
                              controller.moveToQuadrant(id, target),
                          onDelete: controller.deleteTask,
                        ),
                      ),
                      Expanded(
                        child: _Quadrant(
                          quadrant:
                              EisenhowerQuadrant.notUrgentImportant,
                          tasks: controller.byQuadrant(
                              EisenhowerQuadrant.notUrgentImportant),
                          onMove: (String id, EisenhowerQuadrant target) =>
                              controller.moveToQuadrant(id, target),
                          onDelete: controller.deleteTask,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: _Quadrant(
                          quadrant:
                              EisenhowerQuadrant.urgentNotImportant,
                          tasks: controller.byQuadrant(
                              EisenhowerQuadrant.urgentNotImportant),
                          onMove: (String id, EisenhowerQuadrant target) =>
                              controller.moveToQuadrant(id, target),
                          onDelete: controller.deleteTask,
                        ),
                      ),
                      Expanded(
                        child: _Quadrant(
                          quadrant:
                              EisenhowerQuadrant.notUrgentNotImportant,
                          tasks: controller.byQuadrant(
                              EisenhowerQuadrant.notUrgentNotImportant),
                          onMove: (String id, EisenhowerQuadrant target) =>
                              controller.moveToQuadrant(id, target),
                          onDelete: controller.deleteTask,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openAddTaskSheet(
      BuildContext context, EisenhowerController controller) async {
    final TextEditingController text = TextEditingController();
    bool urgent = false;
    bool important = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.theme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext ctx) {
        return StatefulBuilder(
          builder: (BuildContext ctx, void Function(void Function()) setState) {
            final EisenhowerQuadrant q =
                EisenhowerConfig.getQuadrantFromFlags(urgent, important);
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
                  MyText.titleMedium('New Task', fontWeight: 600),
                  const SizedBox(height: 12),
                  TextField(
                    controller: text,
                    autofocus: true,
                    maxLength: TaskValidator.maxTitleLength,
                    inputFormatters: <TextInputFormatter>[
                      LengthLimitingTextInputFormatter(
                          TaskValidator.maxTitleLength),
                    ],
                    decoration: const InputDecoration(
                      hintText: 'What needs to be done?',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Urgent'),
                    value: urgent,
                    onChanged: (bool v) => setState(() => urgent = v),
                  ),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Important'),
                    value: important,
                    onChanged: (bool v) => setState(() => important = v),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: MyText.bodySmall(
                      'Quadrant: ${EisenhowerConfig.getQuadrantName(q)}',
                      color: AppTheme.theme.hintColor,
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
                              await controller.addTask(
                                raw,
                                isUrgent: urgent,
                                isImportant: important,
                              );
                              if (ctx.mounted) Navigator.of(ctx).pop();
                            } catch (_) {
                              // ignore invalid input
                            }
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
      },
    );
  }
}

class _Quadrant extends StatelessWidget {
  const _Quadrant({
    required this.quadrant,
    required this.tasks,
    required this.onMove,
    required this.onDelete,
  });

  final EisenhowerQuadrant quadrant;
  final List<EisenhowerTask> tasks;
  final void Function(String id, EisenhowerQuadrant target) onMove;
  final Future<void> Function(String id) onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: DragTarget<String>(
        onAcceptWithDetails: (DragTargetDetails<String> details) {
          onMove(details.data, quadrant);
        },
        builder: (BuildContext ctx, List<String?> candidate,
            List<dynamic> rejected) {
          final bool hovering = candidate.isNotEmpty;
          final Color quadrantColor =
              EisenhowerConfig.getQuadrantColor(quadrant);
          return AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: hovering
                  ? quadrantColor.withValues(alpha: 0.08)
                  : AppTheme.theme.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: hovering ? quadrantColor : AppTheme.theme.dividerColor,
                width: hovering ? 2 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: quadrantColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: MyText.titleMedium(
                          EisenhowerConfig.getQuadrantName(quadrant),
                          fontWeight: 700,
                          color: Colors.white,
                        ),
                      ),
                      MyText.bodySmall(
                        EisenhowerConfig.getQuadrantDescription(quadrant),
                        color: Colors.white70,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: tasks.isEmpty
                      ? Center(
                          child: MyText.bodySmall(
                            'No tasks',
                            color: AppTheme.theme.hintColor,
                          ),
                        )
                      : ListView.separated(
                          itemCount: tasks.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 6),
                          itemBuilder: (BuildContext ctx, int i) {
                            final EisenhowerTask t = tasks[i];
                            return LongPressDraggable<String>(
                              data: t.id,
                              delay: const Duration(milliseconds: 200),
                              feedback: Material(
                                color: Colors.transparent,
                                elevation: 6,
                                child: SizedBox(
                                  width: 240,
                                  child: _QuadrantTaskTile(
                                    task: t,
                                    onDelete: () {},
                                  ),
                                ),
                              ),
                              childWhenDragging: Opacity(
                                opacity: 0.35,
                                child: _QuadrantTaskTile(
                                  task: t,
                                  onDelete: () => onDelete(t.id),
                                ),
                              ),
                              child: _QuadrantTaskTile(
                                task: t,
                                onDelete: () => onDelete(t.id),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _QuadrantTaskTile extends StatelessWidget {
  const _QuadrantTaskTile({required this.task, required this.onDelete});

  final EisenhowerTask task;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final EisenhowerQuadrant q =
        EisenhowerConfig.getQuadrantFromFlags(task.isUrgent, task.isImportant);
    final Color taskColor = EisenhowerConfig.getQuadrantColor(q);
    return MyContainer(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      borderRadiusAll: 6,
      color: AppTheme.theme.colorScheme.surface,
      border: Border(left: BorderSide(color: taskColor, width: 3)),
      child: Row(
        children: <Widget>[
          Expanded(
            child: MyText.bodySmall(task.title, fontWeight: 500),
          ),
          Semantics(
            label: 'Delete task',
            button: true,
            child: SizedBox(
              width: 48,
              height: 48,
              child: IconButton(
                tooltip: 'Delete',
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.close, size: 18),
                onPressed: onDelete,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
