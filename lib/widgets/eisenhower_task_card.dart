import 'package:flutter/material.dart';
import '../models/eisenhower_task_model.dart';
import '../config/eisenhower_config.dart';

class EisenhowerTaskCard extends StatelessWidget {
  final EisenhowerTask task;
  final EisenhowerQuadrant quadrant;
  final Function(EisenhowerTask) onTaskDeleted;
  final Function(EisenhowerTask) onTaskToggled;
  final Function(EisenhowerTask, String) onTaskEdited;
  final bool enableExternalDrag;
  final bool enableInternalReorder;

  const EisenhowerTaskCard({
    super.key,
    required this.task,
    required this.quadrant,
    required this.onTaskDeleted,
    required this.onTaskToggled,
    required this.onTaskEdited,
    this.enableExternalDrag = true,
    this.enableInternalReorder = false,
  });

  void _showEditDialog(BuildContext context) {
    final TextEditingController controller = TextEditingController(text: task.title);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Task'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Task Title',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: CheckboxListTile(
                    title: const Text('Urgent'),
                    value: task.isUrgent,
                    onChanged: (value) {
                      Navigator.pop(context);
                      _showEditDialogWithValues(context, controller.text, value ?? false, task.isImportant);
                    },
                  ),
                ),
                Expanded(
                  child: CheckboxListTile(
                    title: const Text('Important'),
                    value: task.isImportant,
                    onChanged: (value) {
                      Navigator.pop(context);
                      _showEditDialogWithValues(context, controller.text, task.isUrgent, value ?? false);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                onTaskEdited(task, controller.text.trim());
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showEditDialogWithValues(BuildContext context, String title, bool isUrgent, bool isImportant) {
    final TextEditingController controller = TextEditingController(text: title);
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Task'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'Task Title',
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: CheckboxListTile(
                      title: const Text('Urgent'),
                      value: isUrgent,
                      onChanged: (value) {
                        setState(() {
                          isUrgent = value ?? false;
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: CheckboxListTile(
                      title: const Text('Important'),
                      value: isImportant,
                      onChanged: (value) {
                        setState(() {
                          isImportant = value ?? false;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  final updatedTask = task.copyWith(
                    title: controller.text.trim(),
                    isUrgent: isUrgent,
                    isImportant: isImportant,
                  );
                  onTaskEdited(updatedTask, updatedTask.title);
                  Navigator.pop(context);
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final quadrantColor = EisenhowerConfig.getQuadrantColor(quadrant, isDarkMode);
    
    final cardContent = Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
      child: ListTile(
        leading: IconButton(
          icon: Icon(
            task.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
            color: task.isCompleted 
                ? Colors.green 
                : (isDarkMode ? Colors.white70 : Colors.grey),
          ),
          onPressed: () => onTaskToggled(task),
        ),
        title: Text(
          task.title,
          style: TextStyle(
            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        subtitle: Row(
          children: [
            Icon(
              task.isUrgent ? Icons.schedule : Icons.schedule_outlined,
              size: 14,
              color: task.isUrgent ? Colors.red : Colors.grey,
            ),
            const SizedBox(width: 4),
            Text(
              task.isUrgent ? 'Urgent' : 'Not Urgent',
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(width: 8),
            Icon(
              task.isImportant ? Icons.star : Icons.star_outline,
              size: 14,
              color: task.isImportant ? Colors.amber : Colors.grey,
            ),
            const SizedBox(width: 4),
            Text(
              task.isImportant ? 'Important' : 'Not Important',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, size: 18),
              onPressed: () => _showEditDialog(context),
            ),
            IconButton(
              icon: const Icon(Icons.delete, size: 18, color: Colors.red),
              onPressed: () => onTaskDeleted(task),
            ),
          ],
        ),
        onLongPress: () => _showEditDialog(context),
      ),
    );
    
    if (enableInternalReorder) {
      if (enableExternalDrag) {
        return Draggable<Map<String, dynamic>>(
          data: {
            'task': task,
            'fromQuadrant': quadrant,
          },
          feedback: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 200,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: quadrantColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.grey.shade400,
                  width: 1,
                ),
              ),
              child: Text(
                task.title,
                style: TextStyle(
                  decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
            ),
          ),
          child: cardContent,
        );
      }
      return cardContent;
    }
    
    if (enableExternalDrag) {
      return Draggable<Map<String, dynamic>>(
        data: {
          'task': task,
          'fromQuadrant': quadrant,
        },
        feedback: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 200,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: quadrantColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.grey.shade400,
                width: 1,
              ),
            ),
            child: Text(
              task.title,
              style: TextStyle(
                decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ),
        child: cardContent,
      );
    }
    
    return cardContent;
  }
}
