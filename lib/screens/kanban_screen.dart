import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../services/task_manager.dart';
import '../services/task_action_dispatcher.dart';
import '../config/kanban_config.dart';
import '../widgets/kanban_column.dart';

class KanbanScreen extends StatefulWidget {
  const KanbanScreen({super.key});

  @override
  KanbanScreenState createState() => KanbanScreenState();
}

class KanbanScreenState extends State<KanbanScreen> {
  final TaskManager _taskManager = TaskManager();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    try {
      await _taskManager.loadTasks();
    } catch (e) {
      debugPrint('Error loading tasks: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onDragReceived(Task task, String targetColumn) {
    if (targetColumn == KanbanConfig.columns.last) {
      _taskManager.markTaskCompleted(task);
    } else if (task.column != KanbanConfig.columns.last) {
      if (!_taskManager.isWipLimitReached(targetColumn)) {
        _taskManager.moveTask(task, targetColumn);
      } else {
        _showWipLimitWarning();
        return;
      }
    }
    setState(() {});
  }

  void _addTask(String column) {
    showDialog(
      context: context,
      builder: (context) {
        final TextEditingController controller = TextEditingController();
        return AlertDialog(
          title: Text('Add Task to $column'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'Task name'),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  if (!_taskManager.isWipLimitReached(column)) {
                    final task = Task(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      title: controller.text.trim(),
                      column: column,
                    );
                    _taskManager.addTask(task);
                    setState(() {});
                  } else {
                    _showWipLimitWarning();
                  }
                }
                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _editTask(Task task) {
    showDialog(
      context: context,
      builder: (context) {
        final TextEditingController controller = TextEditingController(
          text: task.title,
        );
        return AlertDialog(
          title: const Text('Edit Task'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'Task name'),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  _taskManager.updateTask(task.copyWith(title: controller.text.trim()));
                  setState(() {});
                }
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showTaskMenu(Task task) {
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final actions = TaskActionDispatcher.getAvailableActions(task);
    
    showMenu(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromPoints(Offset.zero, Offset.zero),
        Offset.zero & overlay.size,
      ),
      items: actions.map((action) => _buildMenuItem(action, task)).toList(),
    ).then((value) {
      if (value != null) {
        _handleMenuSelection(value, task);
      }
    });
  }

  PopupMenuItem<String> _buildMenuItem(String action, Task task) {
    final labels = {
      KanbanActions.complete: 'Mark as Completed',
      KanbanActions.setPriority: 'Set High Priority',
      KanbanActions.removePriority: 'Remove High Priority',
      KanbanActions.edit: 'Edit Task',
      KanbanActions.delete: 'Delete Task',
      KanbanActions.restore: 'Move to To Do',
    };
    
    String label = labels[action] ?? action;
    if (action == KanbanActions.setPriority && task.isHighPriority) {
      label = labels[KanbanActions.removePriority]!;
    }
    
    return PopupMenuItem(value: action, child: Text(label));
  }

  void _handleMenuSelection(String action, Task task) {
    if (action == KanbanActions.edit) {
      _editTask(task);
      return;
    }
    
    if (action == KanbanActions.restore) {
      if (!_taskManager.isWipLimitReached(KanbanConfig.getDefaultColumn())) {
        _taskManager.restoreTask(task);
        setState(() {});
        _showMessage('Task restored to To Do!');
      } else {
        _showWipLimitWarning();
      }
      return;
    }
    
    TaskActionDispatcher.dispatch(action, _taskManager, task);
    setState(() {});
    
    final messages = {
      KanbanActions.complete: 'Task moved to Done!',
      KanbanActions.setPriority: 'Task marked as high priority!',
      KanbanActions.removePriority: 'High priority removed!',
      KanbanActions.delete: 'Task deleted!',
    };
    _showMessage(messages[action] ?? 'Action completed');
  }

  void _deleteTask(Task task) {
    _taskManager.deleteTask(task);
    setState(() {});
  }

  void _showWipLimitWarning() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('WIP Limit Reached'),
          content: const Text(
            'You cannot add more tasks to this column due to WIP limit.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _toggleTaskPriority(Task task) {
    _taskManager.setTaskPriority(task, !task.isHighPriority);
    setState(() {});
    _showMessage(
      task.isHighPriority
          ? 'High priority removed!'
          : 'Task marked as high priority!',
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Kanban Dashboard')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade900,
      appBar: AppBar(
        title: const Text('Kanban Dashboard'),
        backgroundColor: Colors.deepPurple.withAlpha(230),
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text('Clear Done Column'),
                    content: const Text(
                      'Are you sure you want to delete all completed tasks?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          _taskManager.clearAllTasks();
                          setState(() {});
                          Navigator.pop(context);
                        },
                        child: const Text(
                          'Delete',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isMobile = constraints.maxWidth < 600;
          final double columnHeight = constraints.maxHeight * 0.8;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildColumnCard(
                KanbanConfig.columns[0],
                columnHeight * 1.2,
                KanbanConfig.getColumnColor(KanbanConfig.columns[0]),
                showAddButton: true,
                wipLimit: KanbanConfig.getWipLimit(KanbanConfig.columns[0]),
              ),
              const SizedBox(height: 16),
              isMobile
                  ? Column(
                      children: [
                        _buildColumnCard(
                          KanbanConfig.columns[1],
                          columnHeight,
                          KanbanConfig.getColumnColor(KanbanConfig.columns[1]),
                          wipLimit: KanbanConfig.getWipLimit(KanbanConfig.columns[1]),
                        ),
                        const SizedBox(height: 16),
                        _buildColumnCard(
                          KanbanConfig.columns[2],
                          columnHeight,
                          KanbanConfig.getColumnColor(KanbanConfig.columns[2]),
                        ),
                      ],
                    )
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          SizedBox(
                            height: columnHeight,
                            width: (constraints.maxWidth - 48) / 2,
                            child: _buildColumnWidget(
                              KanbanConfig.columns[1],
                              KanbanConfig.getColumnColor(KanbanConfig.columns[1]),
                              wipLimit: KanbanConfig.getWipLimit(KanbanConfig.columns[1]),
                            ),
                          ),
                          SizedBox(
                            height: columnHeight,
                            width: (constraints.maxWidth - 48) / 2,
                            child: _buildColumnWidget(
                              KanbanConfig.columns[2],
                              KanbanConfig.getColumnColor(KanbanConfig.columns[2]),
                            ),
                          ),
                        ],
                      ),
                    ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildColumnCard(String title, double height, Color color, {bool showAddButton = false, int? wipLimit}) {
    return Card(
      elevation: 4,
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: _buildColumnWidget(title, color, showAddButton: showAddButton, wipLimit: wipLimit),
      ),
    );
  }

  Widget _buildColumnWidget(String title, Color color, {bool showAddButton = false, int? wipLimit}) {
    return KanbanColumn(
      title: title,
      tasks: _taskManager.getTasksByColumn(title),
      color: color,
      onTaskTap: _editTask,
      onTaskLongPress: _showTaskMenu,
      onTaskEdit: _editTask,
      onTaskDelete: _deleteTask,
      onTogglePriority: _toggleTaskPriority,
      onAddTask: _addTask,
      showAddButton: showAddButton,
      wipLimit: wipLimit,
      onWipLimitChange: null,
      onDragReceived: _onDragReceived,
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
