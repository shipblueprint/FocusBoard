import 'eisenhower_task_manager.dart';
import 'task_manager.dart';
import '../models/eisenhower_task_model.dart';
import '../models/task_model.dart';

class TaskTransferService {
  final EisenhowerTaskManager eisenhowerTaskManager;
  final TaskManager kanbanTaskManager;

  TaskTransferService({
    required this.eisenhowerTaskManager,
    required this.kanbanTaskManager,
  });

  Future<void> transferDoFirstTasksToKanban() async {
    // Get all "Do First" tasks from Eisenhower board
    final doFirstTasks = eisenhowerTaskManager.getDoFirstTasks();
    
    if (doFirstTasks.isEmpty) {
      return; // No tasks to transfer
    }

    // Transfer each task to Kanban board's "To Do" column
    for (final eisenhowerTask in doFirstTasks) {
      // Create a new Kanban task from the Eisenhower task
      final kanbanTask = Task(
        id: eisenhowerTask.id, // Keep the same ID for consistency
        title: eisenhowerTask.title,
        isCompleted: eisenhowerTask.isCompleted,
        isHighPriority: eisenhowerTask.isHighPriority || 
                        (eisenhowerTask.isUrgent && eisenhowerTask.isImportant), // Mark as high priority if it's Do First
        column: 'To Do', // Transfer to "To Do" column in Kanban
      );
      
      // Add to Kanban board
      kanbanTaskManager.addTaskDirect(kanbanTask);
    }

    // Remove the transferred tasks from Eisenhower board
    eisenhowerTaskManager.removeTasks(doFirstTasks);
    
    // Save both managers
    await eisenhowerTaskManager.saveTasks();
    await kanbanTaskManager.saveTasks();
  }

  int getDoFirstTasksCount() {
    return eisenhowerTaskManager.getDoFirstTasks().length;
  }
}