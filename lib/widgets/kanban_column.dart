import 'package:flutter/material.dart';
import '../models/task_model.dart';

class KanbanColumn extends StatelessWidget {
  final String title;
  final List<Task> tasks;
  final Color color;
  final ValueChanged<Task> onTaskTap;
  final ValueChanged<Task> onTaskLongPress;
  final ValueChanged<Task> onTaskEdit;
  final ValueChanged<Task> onTaskDelete;
  final ValueChanged<Task> onTogglePriority;
  final Function(String)? onAddTask;
  final bool showAddButton;
  final int? wipLimit;
  final Function(int)? onWipLimitChange;
  final Function(Task, String)? onDragReceived; // 更新为包含目标列的回调

  const KanbanColumn({
    super.key,
    required this.title,
    required this.tasks,
    required this.color,
    required this.onTaskTap,
    required this.onTaskLongPress,
    required this.onTaskEdit,
    required this.onTaskDelete,
    required this.onTogglePriority,
    this.onAddTask,
    this.showAddButton = false,
    this.wipLimit,
    this.onWipLimitChange,
    this.onDragReceived,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(minWidth: 280, minHeight: double.infinity),
      child: Container(
        width: double.infinity,
        height: double.infinity,
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey.shade800,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade700),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 列标题
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '${tasks.length}${wipLimit != null ? '/$wipLimit' : ''}',
                    style: const TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                ],
              ),
            ),

            // 任务列表区域
            Expanded(
              flex: 1,
              child: DragTarget<Task>(
                onAcceptWithDetails: (details) {
          if (onDragReceived != null) {
            // 不允许从Done列移动任务到其他列
            if (details.data.column == 'Done' && title != 'Done') {
              return;
            }
            
            // 其他情况检查列不同且未达到WIP限制
            if (details.data.column != title &&
                (wipLimit == null || tasks.length < wipLimit!)) {
              // 将目标列传递给父组件
              onDragReceived!(details.data, title);
            }
          }
        },
                onWillAcceptWithDetails: (details) {
          // 不允许从Done列移动任务到其他列
          if (details.data.column == 'Done' && title != 'Done') {
            return false;
          }
          
          // 其他情况检查列不同且未达到WIP限制
          return details.data.column != title &&
              (wipLimit == null || tasks.length < wipLimit!);
        },
                builder: (context, candidateData, rejectedData) {
                  return Container(
                    color: candidateData.isNotEmpty ? Colors.grey.shade700 : null,
                    child: ListView.builder(
                      padding: EdgeInsets.all(8), // Add padding around the list
                      itemCount: tasks.length,
                      itemBuilder: (context, index) {
                        final task = tasks[index];
                        return Draggable<Task>(
                          data: task,
                          feedback: Material(
                            color: Colors.transparent,
                            child: Container(
                              width: MediaQuery.of(context).size.width / 4,
                              decoration: BoxDecoration(
                                    color: Colors.grey.shade800.withAlpha(242),
                                    borderRadius: BorderRadius.circular(8.0),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withAlpha(128),
                                    spreadRadius: 3,
                                    blurRadius: 5,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(12.0),
                              child: Text(
                                task.toString(),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight:
                                      task.isHighPriority
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                  color:
                                      task.isHighPriority
                                          ? Colors.red.shade500
                                          : Colors.grey.shade100,
                                ),
                              ),
                            ),
                          ),
                          child: GestureDetector(
                            onTap: () => onTaskTap(task),
                              onLongPress: () => onTaskLongPress(task),
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 6.0), // Increase vertical spacing
                                padding: const EdgeInsets.all(16.0), // Increase padding for better touch targets
                              decoration: BoxDecoration(
                                    color: Colors.grey.shade800.withAlpha(242),
                                    borderRadius: BorderRadius.circular(10.0),
                                    border: Border.all(
                                      color:
                                          task.isHighPriority
                                              ? Colors.red.withAlpha(179)
                                              : Colors.grey.withAlpha(128),
                                      width: 1,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withAlpha(25),
                                        spreadRadius: 1,
                                        blurRadius: 3,
                                        offset: const Offset(0, 1),
                                      ),
                                    ]
                                  ),
                                child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Expanded(
                                    child: Text(
                                      task.toString(),
                                      style: TextStyle(
                                        fontSize: 18, // Increase font size for better readability
                                        fontWeight:
                                            task.isHighPriority
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                        color:
                                              task.isHighPriority
                                                  ? Colors.red.shade500
                                                  : Colors.grey.shade100,
                                        ),
                                        maxLines: 3, // Allow more lines to show more content
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                SizedBox(width: 4),
                                IconButton(
                                   icon: Icon(
                                     task.isHighPriority ? Icons.flag : Icons.flag_outlined,
                                     size: 16,
                                     color: task.isHighPriority ? Colors.red : Colors.grey,
                                   ),
                                  onPressed: () => onTogglePriority(task),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  tooltip: task.isHighPriority ? 'Remove priority' : 'Set as high priority',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit, size: 16, color: Colors.blue),
                                  onPressed: () => onTaskEdit(task),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  tooltip: 'Edit task',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                                  onPressed: () => onTaskDelete(task),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  tooltip: 'Delete task',
                                ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),

            // 添加任务按钮和WIP限制（仅To Do列）
            if (showAddButton && title == 'To Do') ...[
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    if (wipLimit != null && onWipLimitChange != null)
                      Row(
                        children: [
                          const Text('WIP Limit: '),
                          Expanded(
                            child: Slider(
                              value: (wipLimit ?? 5).toDouble(),
                              min: 1,
                              max: 10,
                              divisions: 9,
                              label: '${wipLimit ?? 5}',
                              onChanged: (value) {
                                if (onWipLimitChange != null) {
                                  onWipLimitChange!(value.toInt());
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ElevatedButton(
                      onPressed: () {
                        if (onAddTask != null) {
                          onAddTask!(title);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Add Task'),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
