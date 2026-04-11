import 'eisenhower_task_manager.dart';
import 'task_manager.dart';
import '../models/task_model.dart';
import '../config/eisenhower_config.dart';
import '../config/kanban_config.dart';

class TaskTransferService {
  final EisenhowerTaskManager eisenhowerTaskManager;
  final TaskManager kanbanTaskManager;

  TaskTransferService({
    required this.eisenhowerTaskManager,
    required this.kanbanTaskManager,
  });

  Future<void> transferDoFirstTasksToKanban() async {
    final doFirstTasks = eisenhowerTaskManager.urgentImportantTasks;
    
    if (doFirstTasks.isEmpty) {
      return;
    }

    for (final eisenhowerTask in doFirstTasks) {
      final kanbanTask = Task(
        id: eisenhowerTask.id,
        title: eisenhowerTask.title,
        isCompleted: eisenhowerTask.isCompleted,
        isHighPriority: eisenhowerTask.isHighPriority || 
                        (eisenhowerTask.isUrgent && eisenhowerTask.isImportant),
        column: KanbanConfig.getDefaultColumn(),
      );
      
      kanbanTaskManager.addTask(kanbanTask);
    }

    eisenhowerTaskManager.removeTaskWhere((t) => 
        t.quadrant == EisenhowerQuadrant.urgentImportant);
    
    await eisenhowerTaskManager.saveTasks();
    await kanbanTaskManager.saveTasks();
  }

  int getDoFirstTasksCount() {
    return eisenhowerTaskManager.urgentImportantTasks.length;
  }
}
