import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/eisenhower_task_model.dart';
import '../widgets/eisenhower_task_card.dart';

class EisenhowerQuadrantWidget extends StatefulWidget {
  final EisenhowerQuadrant quadrant;
  final List<EisenhowerTask> tasks;
  final Function(EisenhowerTask, EisenhowerQuadrant) onTaskMoved;
  final Function(EisenhowerTask) onTaskDeleted;
  final Function(EisenhowerTask) onTaskToggled;
  final Function(EisenhowerTask, String) onTaskEdited;
  final Function(String, bool, bool) onTasksPasted;
  final Function(EisenhowerQuadrant, int, int) onTaskReordered;

  const EisenhowerQuadrantWidget({
    super.key,
    required this.quadrant,
    required this.tasks,
    required this.onTaskMoved,
    required this.onTaskDeleted,
    required this.onTaskToggled,
    required this.onTaskEdited,
    required this.onTasksPasted,
    required this.onTaskReordered,
  });

  @override
  State<EisenhowerQuadrantWidget> createState() => _EisenhowerQuadrantWidgetState();
}

class _EisenhowerQuadrantWidgetState extends State<EisenhowerQuadrantWidget> {
  bool _isPasting = false;

  String get _quadrantTitle {
    switch (widget.quadrant) {
      case EisenhowerQuadrant.urgentImportant:
        return 'Do First';
      case EisenhowerQuadrant.notUrgentImportant:
        return 'Schedule';
      case EisenhowerQuadrant.urgentNotImportant:
        return 'Delegate';
      case EisenhowerQuadrant.notUrgentNotImportant:
        return 'Eliminate';
    }
  }

  String get _quadrantSubtitle {
    switch (widget.quadrant) {
      case EisenhowerQuadrant.urgentImportant:
        return 'Urgent & Important';
      case EisenhowerQuadrant.notUrgentImportant:
        return 'Not Urgent & Important';
      case EisenhowerQuadrant.urgentNotImportant:
        return 'Urgent & Not Important';
      case EisenhowerQuadrant.notUrgentNotImportant:
        return 'Not Urgent & Not Important';
    }
  }

  Color _getQuadrantColor(bool isDarkMode) {
    switch (widget.quadrant) {
      case EisenhowerQuadrant.urgentImportant:
        return isDarkMode ? Colors.green.shade800 : Colors.green.shade100;
      case EisenhowerQuadrant.notUrgentImportant:
        return isDarkMode ? Colors.orange.shade800 : Colors.orange.shade100;
      case EisenhowerQuadrant.urgentNotImportant:
        return isDarkMode ? Colors.blue.shade800 : Colors.blue.shade100;
      case EisenhowerQuadrant.notUrgentNotImportant:
        return isDarkMode ? Colors.red.shade800 : Colors.red.shade100;
    }
  }

  void _handlePaste(String? clipboardText) {
    if (clipboardText != null && clipboardText.trim().isNotEmpty) {
      final lines = clipboardText.split('\n').where((line) => line.trim().isNotEmpty).toList();
      if (lines.isNotEmpty) {
        // Determine urgency and importance based on quadrant
        bool isUrgent = false;
        bool isImportant = false;
        
        switch (widget.quadrant) {
          case EisenhowerQuadrant.urgentImportant:
            isUrgent = true;
            isImportant = true;
            break;
          case EisenhowerQuadrant.notUrgentImportant:
            isUrgent = false;
            isImportant = true;
            break;
          case EisenhowerQuadrant.urgentNotImportant:
            isUrgent = true;
            isImportant = false;
            break;
          case EisenhowerQuadrant.notUrgentNotImportant:
            isUrgent = false;
            isImportant = false;
            break;
        }
        
        widget.onTasksPasted(clipboardText, isUrgent, isImportant);
      }
    }
  }

  Future<void> _showPasteDialog() async {
    final clipboardData = await Clipboard.getData('text/plain');
    final clipboardText = clipboardData?.text;
    
    if (clipboardText != null && clipboardText.trim().isNotEmpty) {
      final lines = clipboardText.split('\n').where((line) => line.trim().isNotEmpty).toList();
      
      if (lines.isNotEmpty) {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Paste ${lines.length} Task${lines.length > 1 ? 's' : ''}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Create ${lines.length} new task${lines.length > 1 ? 's' : ''} in "$_quadrantTitle":'),
                const SizedBox(height: 8),
                Container(
                  height: 100,
                  width: double.maxFinite,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      lines.map((line) => '• ${line.trim()}').join('\n'),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Paste'),
              ),
            ],
          ),
        );

        if (confirmed == true) {
          _handlePaste(clipboardText);
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No text found in clipboard'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final quadrantColor = _getQuadrantColor(isDarkMode);

    return Focus(
      onKey: (node, event) {
        // Detect Ctrl+V or Cmd+V paste
        if (event is RawKeyDownEvent && 
            (event.logicalKey == LogicalKeyboardKey.keyV) &&
            (event.isControlPressed || event.isMetaPressed)) {
          // Use a microtask to handle the async dialog
          Future.microtask(() => _showPasteDialog());
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onLongPress: _showPasteDialog,
        child: DragTarget<Map<String, dynamic>>(
          onAcceptWithDetails: (details) {
            final task = details.data['task'] as EisenhowerTask;
            final fromQuadrant = details.data['fromQuadrant'] as EisenhowerQuadrant;
            if (fromQuadrant != widget.quadrant) {
              widget.onTaskMoved(task, widget.quadrant);
            }
          },
          onWillAcceptWithDetails: (details) {
            final fromQuadrant = details.data['fromQuadrant'] as EisenhowerQuadrant;
            return fromQuadrant != widget.quadrant;
          },
          builder: (context, candidateData, rejectedData) {
            return Container(
              decoration: BoxDecoration(
                color: candidateData.isNotEmpty ? quadrantColor.withValues(alpha: 0.5) : quadrantColor,
                border: Border.all(
                  color: candidateData.isNotEmpty 
                      ? (isDarkMode ? Colors.white : Colors.black)
                      : (isDarkMode ? Colors.grey.shade600 : Colors.grey.shade300),
                  width: candidateData.isNotEmpty ? 3 : 2,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              margin: const EdgeInsets.all(4),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: quadrantColor.withValues(alpha: 0.7),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(6),
                        topRight: Radius.circular(6),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                children: [
                                  Text(
                                    _quadrantTitle,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: isDarkMode ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                  Text(
                                    _quadrantSubtitle,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDarkMode ? Colors.white70 : Colors.black54,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${widget.tasks.length} tasks',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDarkMode ? Colors.white60 : Colors.black45,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.content_paste, size: 20),
                              tooltip: 'Paste tasks (Ctrl+V or long press)',
                              onPressed: _showPasteDialog,
                              color: isDarkMode ? Colors.white70 : Colors.black54,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      child: widget.tasks.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Drop tasks here',
                                    style: TextStyle(
                                      color: isDarkMode ? Colors.white38 : Colors.black38,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'or paste with Ctrl+V',
                                    style: TextStyle(
                                      color: isDarkMode ? Colors.white24 : Colors.black26,
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ReorderableListView(
                              onReorder: (int oldIndex, int newIndex) {
                                widget.onTaskReordered(widget.quadrant, oldIndex, newIndex);
                              },
                              children: [
                                for (int index = 0; index < widget.tasks.length; index++)
                                  EisenhowerTaskCard(
                                    key: ValueKey(widget.tasks[index].id),
                                    task: widget.tasks[index],
                                    quadrant: widget.quadrant,
                                    onTaskDeleted: widget.onTaskDeleted,
                                    onTaskToggled: widget.onTaskToggled,
                                    onTaskEdited: widget.onTaskEdited,
                                    enableExternalDrag: true, // Enable external drag for moving between quadrants
                                    enableInternalReorder: true,
                                  ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}