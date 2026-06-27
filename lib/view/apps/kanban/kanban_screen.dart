import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:focusboard/app/controller/kanban_controller.dart';
import 'package:focusboard/app/model/task_model.dart';
import 'package:focusboard/app/model/task_validator.dart';
import 'package:focusboard/helpers/theme/app_theme.dart';
import 'package:focusboard/helpers/widgets/my_container.dart';
import 'package:focusboard/helpers/widgets/my_text.dart';
import 'package:get/get.dart';

/// Kanban board screen.
///
/// Subscribes to [KanbanController] via [Obx] for fully reactive updates.
class KanbanScreen extends StatelessWidget {
  const KanbanScreen({super.key});

  static const List<KanbanColumn> _columns = <KanbanColumn>[
    KanbanColumn.toDo,
    KanbanColumn.inProgress,
    KanbanColumn.done,
  ];

  // Column colors — distinct enough to scan at a glance, calm enough for
  // sustained focus work.
  static const Map<KanbanColumn, Color> _columnColors = <KanbanColumn, Color>{
    KanbanColumn.toDo: Color(0xFF275AC5),
    KanbanColumn.inProgress: Color(0xFFFEC20D),
    KanbanColumn.done: Color(0xFF17A497),
  };

  @override
  Widget build(BuildContext context) {
    final KanbanController controller = Get.find<KanbanController>();

    return Scaffold(
      backgroundColor: AppTheme.theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Kanban Board'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Add task',
            icon: const Icon(Icons.add),
            onPressed: () => _openAddTaskSheet(context, controller),
          ),
          IconButton(
            tooltip: 'Clear done column',
            icon: const Icon(Icons.clear_all),
            onPressed: () => _confirmClearDone(context, controller),
          ),
        ],
      ),
      body: SafeArea(
        child: Obx(
          () => Row(
            children: _columns
                .map(
                  (KanbanColumn col) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: _ColumnView(
                        column: col,
                        color: _columnColors[col]!,
                        tasks: controller.byColumn(col),
                        wipLimit: controller.wipLimits[col] ?? 999,
                        onAdd: () => _openAddTaskSheet(context, controller),
                        onMove: (String taskId, KanbanColumn target) =>
                            controller.moveTask(taskId, target),
                        onDelete: controller.deleteTask,
                        onTogglePriority: controller.togglePriority,
                        onToggleComplete: controller.toggleCompleted,
                        onWipLimitChange: (int v) =>
                            controller.setWipLimit(col, v),
                      ),
                    ),
                  ),
                )
                .toList(growable: false),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmClearDone(
      BuildContext context, KanbanController controller) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Clear Done Column'),
        content: const Text(
            'Delete all completed tasks? This action cannot be undone.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await controller.clearDone();
    }
  }

  Future<void> _openAddTaskSheet(
      BuildContext context, KanbanController controller) async {
    final TextEditingController text = TextEditingController();
    bool highPriority = false;

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
                    title: const Text('High priority'),
                    value: highPriority,
                    onChanged: (bool v) => setState(() => highPriority = v),
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
                              await controller.addTask(raw,
                                  isHighPriority: highPriority);
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

class _ColumnView extends StatelessWidget {
  const _ColumnView({
    required this.column,
    required this.color,
    required this.tasks,
    required this.wipLimit,
    required this.onAdd,
    required this.onMove,
    required this.onDelete,
    required this.onTogglePriority,
    required this.onToggleComplete,
    required this.onWipLimitChange,
  });

  final KanbanColumn column;
  final Color color;
  final List<Task> tasks;
  final int wipLimit;
  final VoidCallback onAdd;
  final void Function(String taskId, KanbanColumn target) onMove;
  final Future<void> Function(String id) onDelete;
  final Future<void> Function(String id) onTogglePriority;
  final Future<void> Function(String id) onToggleComplete;
  final ValueChanged<int> onWipLimitChange;

  bool get _isWipReached => tasks.length >= wipLimit;

  @override
  Widget build(BuildContext context) {
    return MyContainer(
      padding: const EdgeInsets.all(12),
      borderRadiusAll: 12,
      color: AppTheme.theme.cardColor,
      border: Border.all(
        color: AppTheme.theme.dividerColor.withValues(alpha: 0.5),
        width: 1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // Column header — colored band with title, count, and WIP.
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: MyText.bodyMedium(
                    column.label,
                    color: Colors.white,
                    fontWeight: 700,
                  ),
                ),
                MyText.bodySmall(
                  _isWipReached
                      ? '${tasks.length}/$wipLimit'
                      : tasks.length.toString(),
                  color: Colors.white,
                  fontWeight: 600,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // WIP limit slider — applied to To Do and In Progress only.
          if (column != KanbanColumn.done)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Row(
                children: <Widget>[
                  MyText.bodySmall('WIP', fontWeight: 600),
                  Expanded(
                    child: Slider(
                      value: wipLimit.toDouble(),
                      min: 1,
                      max: 20,
                      divisions: 19,
                      label: wipLimit.toString(),
                      onChanged: (double v) => onWipLimitChange(v.toInt()),
                    ),
                  ),
                  SizedBox(
                    width: 28,
                    child: MyText.bodySmall(
                      wipLimit.toString(),
                      fontWeight: 600,
                    ),
                  ),
                ],
              ),
            ),

          // Drop target + task list.
          Expanded(
            child: DragTarget<String>(
              onWillAcceptWithDetails: (DragTargetDetails<String> details) {
                // Don't allow dropping on the source column.
                if (details.data.isEmpty) return false;
                // Block moving out of Done (tasks are sticky once complete).
                final Task? moving = _findTask(context, details.data);
                if (moving == null) return false;
                if (moving.column == KanbanColumn.done &&
                    column != KanbanColumn.done) {
                  return false;
                }
                if (moving.column == column) return false;
                if (_isWipReached) return false;
                return true;
              },
              onAcceptWithDetails: (DragTargetDetails<String> details) {
                onMove(details.data, column);
              },
              builder: (BuildContext ctx, List<String?> candidate,
                  List<dynamic> rejected) {
                final bool hovering = candidate.isNotEmpty;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    color: hovering
                        ? color.withValues(alpha: 0.08)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: hovering
                          ? color
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: tasks.isEmpty && !hovering
                      ? Center(
                          child: MyText.bodySmall(
                            'No tasks',
                            color: AppTheme.theme.hintColor,
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(4),
                          itemCount: tasks.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (BuildContext ctx, int i) {
                            final Task t = tasks[i];
                            return _DraggableTask(
                              task: t,
                              column: column,
                              onDelete: () => onDelete(t.id),
                              onTogglePriority: () => onTogglePriority(t.id),
                              onToggleComplete: () => onToggleComplete(t.id),
                            );
                          },
                        ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Task? _findTask(BuildContext context, String id) {
    final KanbanController controller = Get.find<KanbanController>();
    return controller.tasks
        .cast<Task?>()
        .firstWhere((Task? t) => t?.id == id, orElse: () => null);
  }
}

class _DraggableTask extends StatelessWidget {
  const _DraggableTask({
    required this.task,
    required this.column,
    required this.onDelete,
    required this.onTogglePriority,
    required this.onToggleComplete,
  });

  final Task task;
  final KanbanColumn column;
  final VoidCallback onDelete;
  final VoidCallback onTogglePriority;
  final VoidCallback onToggleComplete;

  @override
  Widget build(BuildContext context) {
    final bool isDone = column == KanbanColumn.done;
    return LongPressDraggable<String>(
      data: task.id,
      delay: const Duration(milliseconds: 200),
      feedback: Material(
        color: Colors.transparent,
        elevation: 6,
        child: SizedBox(
          width: 280,
          child: _TaskCard(
            task: task,
            isDone: isDone,
            onDelete: () {},
            onTogglePriority: () {},
            onToggleComplete: () {},
            elevated: true,
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.35,
        child: _TaskCard(
          task: task,
          isDone: isDone,
          onDelete: onDelete,
          onTogglePriority: onTogglePriority,
          onToggleComplete: onToggleComplete,
        ),
      ),
      child: _TaskCard(
        task: task,
        isDone: isDone,
        onDelete: onDelete,
        onTogglePriority: onTogglePriority,
        onToggleComplete: onToggleComplete,
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.task,
    required this.isDone,
    required this.onDelete,
    required this.onTogglePriority,
    required this.onToggleComplete,
    this.elevated = false,
  });

  final Task task;
  final bool isDone;
  final VoidCallback onDelete;
  final VoidCallback onTogglePriority;
  final VoidCallback onToggleComplete;
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    return MyContainer(
      padding: const EdgeInsets.all(10),
      borderRadiusAll: 8,
      color: AppTheme.theme.colorScheme.surface,
      bordered: true,
      borderColor: task.isHighPriority
          ? Colors.orange.withValues(alpha: 0.6)
          : AppTheme.theme.dividerColor.withValues(alpha: 0.4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Semantics(
                label: task.isCompleted
                    ? 'Mark task as incomplete'
                    : 'Mark task as complete',
                button: true,
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: IconButton(
                    tooltip: task.isCompleted ? 'Uncomplete' : 'Complete',
                    padding: EdgeInsets.zero,
                    icon: Icon(
                      task.isCompleted
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: task.isCompleted
                          ? const Color(0xFF17A497)
                          : AppTheme.theme.hintColor,
                    ),
                    onPressed: onToggleComplete,
                  ),
                ),
              ),
              Expanded(
                child: MyText.bodyMedium(
                  task.title,
                  fontWeight: task.isHighPriority ? 600 : 400,
                  decoration: task.isCompleted
                      ? TextDecoration.lineThrough
                      : TextDecoration.none,
                  color: task.isCompleted
                      ? AppTheme.theme.hintColor
                      : null,
                ),
              ),
              Semantics(
                label: task.isHighPriority
                    ? 'Remove high priority'
                    : 'Mark as high priority',
                button: true,
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: IconButton(
                    tooltip: 'Toggle priority',
                    padding: EdgeInsets.zero,
                    icon: Icon(
                      task.isHighPriority
                          ? Icons.flag
                          : Icons.outlined_flag,
                      color: task.isHighPriority
                          ? Colors.orange
                          : AppTheme.theme.hintColor,
                    ),
                    onPressed: onTogglePriority,
                  ),
                ),
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
                    icon: const Icon(Icons.delete_outline),
                    onPressed: onDelete,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
