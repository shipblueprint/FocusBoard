import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../services/task_manager.dart';
import '../widgets/kanban_column.dart';

class KanbanScreen extends StatefulWidget {
  const KanbanScreen({super.key});

  @override
  KanbanScreenState createState() => KanbanScreenState();
}

class KanbanScreenState extends State<KanbanScreen> {
  final TaskManager _taskManager = TaskManager();
  bool _isLoading = true;
  final Map<String, int?> _wipLimits = {
    'To Do': 5,
    'In Progress': 3,
    'Done': null,
  };

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    try {
      await _taskManager.loadTasks();
    } catch (e) {
      // Error loading tasks: $e
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onDragReceived(Task task, String targetColumn) {
    // 根据看板工作流规则执行不同操作

    // 1. 拖到Done列时，标记为完成
    if (targetColumn == 'Done') {
      _taskManager.markTaskCompleted(task);
    }
    // 2. 允许从In Progress移回To Do
    else if (task.column == 'In Progress' && targetColumn == 'To Do') {
      // 检查To Do列的WIP限制
      if (_taskManager.checkWipLimit(targetColumn, _wipLimits[targetColumn])) {
        _taskManager.moveTask(task, targetColumn);
      } else {
        _showWipLimitWarning();
        return;
      }
    }
    // 3. 其他情况（如从To Do到In Progress）且任务不在Done列
    else if (task.column != 'Done') {
      // 检查目标列的WIP限制
      if (_taskManager.checkWipLimit(targetColumn, _wipLimits[targetColumn])) {
        _taskManager.moveTask(task, targetColumn);
      } else {
        _showWipLimitWarning();
        return;
      }
    }
    // 4. 默认不允许从Done列移动任务（不执行任何操作）

    _taskManager.saveTasks();
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
                  if (_taskManager.checkWipLimit(column, _wipLimits[column])) {
                    _taskManager.addTask(controller.text.trim(), column);
                    _taskManager.saveTasks();
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
          text:
              task.isHighPriority
                  ? task.title.replaceFirst('[High Priority] ', '')
                  : task.title,
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
                  _taskManager.updateTask(task, title: controller.text.trim());
                  _taskManager.saveTasks();
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
    showMenu(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromPoints(Offset.zero, Offset.zero),
        Offset.zero & overlay.size,
      ),
      items:
          task.column == 'Done'
              ? _getDoneTaskMenuItems(task)
              : _getActiveTaskMenuItems(task),
    ).then((value) {
      if (value != null) {
        _handleMenuSelection(value, task);
      }
    });
  }

  List<PopupMenuItem<String>> _getActiveTaskMenuItems(Task task) {
    return [
      PopupMenuItem(value: 'complete', child: const Text('Mark as Completed')),
      PopupMenuItem(
        value: task.isHighPriority ? 'remove_priority' : 'set_priority',
        child: Text(
          task.isHighPriority ? 'Remove High Priority' : 'Set High Priority',
        ),
      ),
      PopupMenuItem(value: 'edit', child: const Text('Edit Task')),
      PopupMenuItem(value: 'delete', child: const Text('Delete Task')),
    ];
  }

  List<PopupMenuItem<String>> _getDoneTaskMenuItems(Task task) {
    return [
      PopupMenuItem(value: 'restore', child: const Text('Move to To Do')),
      PopupMenuItem(value: 'delete', child: const Text('Delete Task')),
    ];
  }

  void _handleMenuSelection(String value, Task task) {
    switch (value) {
      case 'complete':
        _taskManager.moveTask(task, 'Done');
        _taskManager.saveTasks();
        setState(() {});
        _showMessage('Task moved to Done!');
        break;
      case 'set_priority':
        _taskManager.updateTask(task, isHighPriority: true);
        _taskManager.saveTasks();
        setState(() {});
        _showMessage('Task marked as high priority!');
        break;
      case 'remove_priority':
        _taskManager.updateTask(task, isHighPriority: false);
        _taskManager.saveTasks();
        setState(() {});
        _showMessage('High priority removed!');
        break;
      case 'edit':
        _editTask(task);
        break;
      case 'delete':
        _deleteTask(task);
        break;
      case 'restore':
        if (_taskManager.checkWipLimit('To Do', _wipLimits['To Do'])) {
          _taskManager.moveTask(task, 'To Do');
          _taskManager.saveTasks();
          setState(() {});
          _showMessage('Task restored to To Do!');
        } else {
          _showWipLimitWarning();
        }
        break;
    }
  }

  void _deleteTask(Task task) {
    _taskManager.deleteTask(task);
    _taskManager.saveTasks();
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
        appBar: AppBar(title: Text('Kanban Dashboard')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade900,
      appBar: AppBar(
        title: const Text('Kanban Dashboard'),
        backgroundColor: Colors.deepPurple.withAlpha(230),
        elevation: 2,
        actions: [
          // 添加清空Done列的按钮
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
                          _taskManager.clearDoneColumn();
                          _taskManager.saveTasks();
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
          bool isMobile = constraints.maxWidth < 600;

          // Increase column height for better visibility and scrolling
          double columnHeight =
              constraints.maxHeight * 0.8; // 80% of screen height

          // Adjust height for mobile to make each column taller
          if (isMobile) {
            columnHeight =
                constraints.maxHeight * 0.6; // 60% of screen height for mobile
          }

          // For all screen sizes, use a vertical ListView that contains horizontal scrolling columns
          // This gives users both vertical and horizontal scrolling options
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // To Do Column - Make it taller by default since it's typically the most used
              Card(
                elevation: 4,
                child: SizedBox(
                  height: columnHeight * 1.2, // 20% taller for To Do column
                  width: double.infinity,
                  child: KanbanColumn(
                    title: 'To Do',
                    tasks: _taskManager.getTasksInColumn('To Do'),
                    color: Colors.blue.withAlpha(204),
                    onTaskTap: _editTask,
                    onTaskLongPress: _showTaskMenu,
                    onTaskEdit: _editTask,
                    onTaskDelete: _deleteTask,
                    onTogglePriority: _toggleTaskPriority,
                    onAddTask: _addTask,
                    showAddButton: true,
                    wipLimit: _wipLimits['To Do'],
                    onWipLimitChange: (value) {
                      setState(() {
                        _wipLimits['To Do'] = value;
                      });
                    },
                    onDragReceived: _onDragReceived,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // For larger screens, show In Progress and Done side by side
              // For mobile, show them stacked vertically
              isMobile
                  ? Column(
                    children: [
                      Card(
                        elevation: 4,
                        child: SizedBox(
                          height: columnHeight,
                          width: double.infinity,
                          child: KanbanColumn(
                            title: 'In Progress',
                            tasks: _taskManager.getTasksInColumn('In Progress'),
                            color: Colors.orange.withAlpha(204),
                            onTaskTap: _editTask,
                            onTaskLongPress: _showTaskMenu,
                            onTaskEdit: _editTask,
                            onTaskDelete: _deleteTask,
                            onTogglePriority: _toggleTaskPriority,
                            wipLimit: _wipLimits['In Progress'],
                            onWipLimitChange: (_) {},
                            onDragReceived: _onDragReceived,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Card(
                        elevation: 4,
                        child: SizedBox(
                          height: columnHeight,
                          width: double.infinity,
                          child: KanbanColumn(
                            title: 'Done',
                            tasks: _taskManager.getTasksInColumn('Done'),
                            color: Colors.green.withAlpha(204),
                            onTaskTap: _editTask,
                            onTaskLongPress: _showTaskMenu,
                            onTaskEdit: _editTask,
                            onTaskDelete: _deleteTask,
                            onTogglePriority: _toggleTaskPriority,
                            onDragReceived: _onDragReceived,
                          ),
                        ),
                      ),
                    ],
                  )
                  : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        Card(
                          elevation: 4,
                          child: Container(
                            height: columnHeight,
                            width:
                                (constraints.maxWidth - 48) /
                                2, // Half of available width
                            margin: const EdgeInsets.only(right: 16),
                            child: KanbanColumn(
                              title: 'In Progress',
                              tasks: _taskManager.getTasksInColumn(
                                'In Progress',
                              ),
                              color: Colors.orange.withAlpha(204),
                              onTaskTap: _editTask,
                              onTaskLongPress: _showTaskMenu,
                              onTaskEdit: _editTask,
                              onTaskDelete: _deleteTask,
                              onTogglePriority: _toggleTaskPriority,
                              wipLimit: _wipLimits['In Progress'],
                              onWipLimitChange: null,
                              onDragReceived: _onDragReceived,
                            ),
                          ),
                        ),
                        Card(
                          elevation: 4,
                          child: SizedBox(
                            height: columnHeight,
                            width:
                                (constraints.maxWidth - 48) /
                                2, // Half of available width
                            child: KanbanColumn(
                              title: 'Done',
                              tasks: _taskManager.getTasksInColumn('Done'),
                              color: Colors.green.withAlpha(204),
                              onTaskTap: _editTask,
                              onTaskLongPress: _showTaskMenu,
                              onTaskEdit: _editTask,
                              onTaskDelete: _deleteTask,
                              onTogglePriority: _toggleTaskPriority,
                              onDragReceived: _onDragReceived,
                            ),
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

  @override
  void dispose() {
    _taskManager.saveTasks();
    super.dispose();
  }
}
