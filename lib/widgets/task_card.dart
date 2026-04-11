import 'package:flutter/material.dart';
import '../models/task_model.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onTogglePriority;

  const TaskCard({
    super.key,
    required this.task,
    required this.onTap,
    required this.onLongPress,
    required this.onEdit,
    required this.onDelete,
    required this.onTogglePriority,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: _getCardColor(),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: task.isHighPriority ? Colors.red.withAlpha(179) : Colors.grey.withAlpha(128),
          width: 1,
        ),
      ),
      shadowColor: Colors.black.withAlpha(77),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (task.isCompleted || task.isHighPriority)
                Row(
                  children: [
                    if (task.isCompleted)
                      Container(
                        margin: const EdgeInsets.only(right: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.shade700,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Completed',
                          style: TextStyle(fontSize: 10, color: Colors.white),
                        ),
                      ),
                    if (task.isHighPriority)
                      Container(
                        margin: const EdgeInsets.only(right: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.shade700,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'High Priority',
                          style: TextStyle(fontSize: 10, color: Colors.white),
                        ),
                      ),
                    const Spacer(),
                  ],
                ),
              Expanded(
                child: Text(
                  task.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: task.isHighPriority ? FontWeight.bold : FontWeight.w500,
                    decoration:
                        task.isCompleted ? TextDecoration.lineThrough : null,
                    color:
                        task.isHighPriority
                            ? Colors.red.shade500
                            : Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children:
                    [
                      IconButton(
                        icon: Icon(Icons.flag, size: 16, color: task.isHighPriority ? Colors.red : Colors.grey.shade400),
                        onPressed: onTogglePriority,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: task.isHighPriority ? 'Remove high priority' : 'Set high priority',
                      ),
                      IconButton(
                        icon: Icon(Icons.edit, size: 16, color: Colors.blue.shade400),
                        onPressed: onEdit,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: 'Edit task',
                      ),
                      IconButton(
                        icon: Icon(Icons.close, size: 16, color: Colors.red.shade400),
                        onPressed: onDelete,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: 'Delete task',
                      ),
                    ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getCardColor() {
    if (task.isCompleted) return Colors.green.shade100;
    if (task.isHighPriority) return Colors.red.shade100;
    return Colors.white;
  }
}
