import '../models/task_model.dart';
import '../config/kanban_config.dart';
import 'task_manager.dart';

typedef TaskAction = void Function(TaskManager manager, Task task);

class TaskActionDispatcher {
  static final Map<String, TaskAction> _actions = {
    KanbanActions.complete: (mgr, task) => mgr.markTaskCompleted(task),
    KanbanActions.setPriority: (mgr, task) => mgr.setTaskPriority(task, true),
    KanbanActions.removePriority: (mgr, task) => mgr.setTaskPriority(task, false),
    KanbanActions.edit: (mgr, task) {},
    KanbanActions.delete: (mgr, task) => mgr.deleteTask(task),
    KanbanActions.restore: (mgr, task) => mgr.restoreTask(task),
  };

  static void dispatch(String action, TaskManager manager, Task task) {
    final handler = _actions[action];
    if (handler != null) {
      handler(manager, task);
    }
  }

  static bool hasAction(String action) => _actions.containsKey(action);

  static List<String> getAvailableActions(Task task) {
    if (task.isCompleted) {
      return KanbanActions.doneTaskActions;
    }
    return KanbanActions.activeTaskActions;
  }
}
