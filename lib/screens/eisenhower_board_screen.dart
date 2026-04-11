import 'package:flutter/material.dart';
import '../models/eisenhower_task_model.dart';
import '../services/eisenhower_task_manager.dart';
import '../services/task_manager.dart';
import '../services/task_transfer_service.dart';
import '../config/eisenhower_config.dart';
import '../widgets/eisenhower_quadrant.dart';

class EisenhowerBoardScreen extends StatefulWidget {
  const EisenhowerBoardScreen({super.key});

  @override
  State<EisenhowerBoardScreen> createState() => _EisenhowerBoardScreenState();
}

class _EisenhowerBoardScreenState extends State<EisenhowerBoardScreen> {
  late EisenhowerTaskManager _taskManager;
  late TaskManager _kanbanTaskManager;
  late TaskTransferService _transferService;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _taskManager = EisenhowerTaskManager();
    _kanbanTaskManager = TaskManager();
    _transferService = TaskTransferService(
      eisenhowerTaskManager: _taskManager,
      kanbanTaskManager: _kanbanTaskManager,
    );
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    await _taskManager.loadTasks();
    await _kanbanTaskManager.loadTasks();
    setState(() {
      _isLoading = false;
    });
  }

  void _showAddTaskDialog() {
    final TextEditingController controller = TextEditingController();
    bool isUrgent = false;
    bool isImportant = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, dialogSetState) => AlertDialog(
          title: const Text('Add New Task'),
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
                        dialogSetState(() {
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
                        dialogSetState(() {
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
                  final task = EisenhowerTask(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    title: controller.text.trim(),
                    isUrgent: isUrgent,
                    isImportant: isImportant,
                  );
                  _taskManager.addTask(task);
                  Navigator.pop(context);
                  setState(() {});
                }
              },
              child: const Text('Add Task'),
            ),
          ],
        ),
      ),
    );
  }

  void _onTaskMoved(EisenhowerTask task, EisenhowerQuadrant newQuadrant) {
    _taskManager.moveTaskToQuadrant(task, newQuadrant);
    setState(() {});
  }

  void _onTaskDeleted(EisenhowerTask task) {
    _taskManager.deleteTask(task);
    setState(() {});
  }

  void _onTaskToggled(EisenhowerTask task) {
    _taskManager.markTaskCompleted(task);
    setState(() {});
  }

  void _onTaskEdited(EisenhowerTask task, String newTitle) {
    _taskManager.updateTask(task.copyWith(title: newTitle));
    setState(() {});
  }

  void _onTaskReordered(EisenhowerQuadrant quadrant, int oldIndex, int newIndex) {
    setState(() {});
  }

  void _onTasksPasted(String text, bool isUrgent, bool isImportant) {
    final lines = text.split('\n').where((line) => line.trim().isNotEmpty);
    for (final line in lines) {
      final task = EisenhowerTask(
        id: '${DateTime.now().millisecondsSinceEpoch}_${line.hashCode}',
        title: line.trim(),
        isUrgent: isUrgent,
        isImportant: isImportant,
      );
      _taskManager.addTask(task);
    }
    setState(() {});
    final quadrant = EisenhowerConfig.getQuadrantFromFlags(isUrgent, isImportant);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added ${lines.length} task(s) to ${EisenhowerConfig.getQuadrantName(quadrant)}'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _transferDoFirstToKanban() async {
    final doFirstCount = _taskManager.urgentImportantTasks.length;
    
    if (doFirstCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No "Do First" tasks to transfer'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Transfer Tasks'),
        content: Text('Transfer $doFirstCount "Do First" task${doFirstCount > 1 ? 's' : ''} to Kanban "To Do" column?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Transfer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _transferService.transferDoFirstTasksToKanban();
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully transferred $doFirstCount task${doFirstCount > 1 ? 's' : ''} to Kanban'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error transferring tasks: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Eisenhower Matrix'),
        backgroundColor: isDarkMode ? Colors.deepPurple.shade800 : Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz),
            tooltip: 'Transfer Do First tasks to Kanban',
            onPressed: _transferDoFirstToKanban,
          ),
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: () {
              final counts = _taskManager.getQuadrantCounts();
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Task Analytics'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ...EisenhowerQuadrant.values.map((q) {
                        final name = EisenhowerConfig.getQuadrantName(q);
                        return Text('$name: ${counts[q]}');
                      }),
                      const SizedBox(height: 16),
                      Text('Total: ${_taskManager.getTotalTaskCount()}'),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Drag and drop tasks between quadrants to prioritize your work',
                    style: TextStyle(
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: EisenhowerQuadrantWidget(
                          quadrant: EisenhowerQuadrant.urgentImportant,
                          tasks: _taskManager.urgentImportantTasks,
                          onTaskMoved: _onTaskMoved,
                          onTaskDeleted: _onTaskDeleted,
                          onTaskToggled: _onTaskToggled,
                          onTaskEdited: _onTaskEdited,
                          onTasksPasted: _onTasksPasted,
                          onTaskReordered: _onTaskReordered,
                        ),
                      ),
                      Expanded(
                        child: EisenhowerQuadrantWidget(
                          quadrant: EisenhowerQuadrant.urgentNotImportant,
                          tasks: _taskManager.urgentNotImportantTasks,
                          onTaskMoved: _onTaskMoved,
                          onTaskDeleted: _onTaskDeleted,
                          onTaskToggled: _onTaskToggled,
                          onTaskEdited: _onTaskEdited,
                          onTasksPasted: _onTasksPasted,
                          onTaskReordered: _onTaskReordered,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: EisenhowerQuadrantWidget(
                          quadrant: EisenhowerQuadrant.notUrgentImportant,
                          tasks: _taskManager.notUrgentImportantTasks,
                          onTaskMoved: _onTaskMoved,
                          onTaskDeleted: _onTaskDeleted,
                          onTaskToggled: _onTaskToggled,
                          onTaskEdited: _onTaskEdited,
                          onTasksPasted: _onTasksPasted,
                          onTaskReordered: _onTaskReordered,
                        ),
                      ),
                      Expanded(
                        child: EisenhowerQuadrantWidget(
                          quadrant: EisenhowerQuadrant.notUrgentNotImportant,
                          tasks: _taskManager.notUrgentNotImportantTasks,
                          onTaskMoved: _onTaskMoved,
                          onTaskDeleted: _onTaskDeleted,
                          onTaskToggled: _onTaskToggled,
                          onTaskEdited: _onTaskEdited,
                          onTasksPasted: _onTasksPasted,
                          onTaskReordered: _onTaskReordered,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTaskDialog,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}
