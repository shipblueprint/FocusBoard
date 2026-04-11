import 'package:flutter/material.dart';
import '../models/task_model.dart';
import 'task_card.dart';

class TaskList extends StatelessWidget {
  final List<Task> tasks;
  final String columnTitle;
  final ValueChanged<Task> onTaskTap;
  final ValueChanged<Task> onTaskLongPress;
  final ValueChanged<Task> onTaskEdit;
  final ValueChanged<Task> onTaskDelete;
  final ValueChanged<Task> onTogglePriority;
  final bool canDrag;
  final bool canReceive;

  const TaskList({
    super.key,
    required this.tasks,
    required this.columnTitle,
    required this.onTaskTap,
    required this.onTaskLongPress,
    required this.onTaskEdit,
    required this.onTaskDelete,
    required this.onTogglePriority,
    this.canDrag = true,
    this.canReceive = true,
  });

  @override
  Widget build(BuildContext context) {
    return tasks.isEmpty
        ? _buildEmptyList()
        : ListView.builder(
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            final task = tasks[index];
            return canDrag && columnTitle != 'Done'
                ? _buildDraggableTask(task)
                : TaskCard(
                  task: task,
                  onTap: () => onTaskTap(task),
                  onLongPress: () => onTaskLongPress(task),
                  onEdit: () => onTaskEdit(task),
                  onDelete: () => onTaskDelete(task),
                  onTogglePriority: () => onTogglePriority(task),
                );
          },
        );
  }

  Widget _buildEmptyList() {
    return Center(
      child: Text(
        columnTitle == 'Done'
            ? 'No completed tasks yet.'
            : 'No tasks in $columnTitle',
        style: const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
      ),
    );
  }

  Widget _buildDraggableTask(Task task) {
    return Draggable<Task>(
      data: task,
      feedback: Material(
        elevation: 5,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 250,
          child: TaskCard(
            task: task,
            onTap: () {},
            onLongPress: () {},
            onEdit: () {},
            onDelete: () {},
            onTogglePriority: () {},
          ),
        ),
      ),
      childWhenDragging: const SizedBox(height: 60),
      child: TaskCard(
        task: task,
        onTap: () => onTaskTap(task),
        onLongPress: () => onTaskLongPress(task),
        onEdit: () => onTaskEdit(task),
        onDelete: () => onTaskDelete(task),
        onTogglePriority: () => onTogglePriority(task),
      ),
    );
  }
}
