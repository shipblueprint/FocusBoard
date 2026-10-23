import 'package:flutter/foundation.dart';
import 'package:focusboard/app/controller/kanban_controller.dart';
import 'package:focusboard/app/data/task_storage.dart';
import 'package:focusboard/app/model/eisenhower_config.dart';
import 'package:focusboard/app/model/eisenhower_task_model.dart';
import 'package:focusboard/app/model/task_model.dart';
import 'package:focusboard/app/model/task_validator.dart';
import 'package:get/get.dart';

/// Reactive controller for the Eisenhower Matrix.
class EisenhowerController extends GetxController {
  EisenhowerController({KanbanController? kanban})
      : _kanban = kanban ?? Get.find<KanbanController>();

  final KanbanController _kanban;

  final RxList<EisenhowerTask> tasks = <EisenhowerTask>[].obs;

  @override
  void onInit() {
    super.onInit();
    _load();
  }

  Future<void> _load() async {
    final List<EisenhowerTask> loaded = await TaskStorage.loadEisenhower();
    if (loaded.isNotEmpty) {
      tasks.assignAll(loaded);
    } else {
      tasks.assignAll(<EisenhowerTask>[
        EisenhowerTask(
          id: TaskValidator.generateUuid(),
          title: 'Review analytics dashboard',
          isUrgent: false,
          isImportant: true,
        ),
        EisenhowerTask(
          id: TaskValidator.generateUuid(),
          title: 'Reply to urgent customer email',
          isUrgent: true,
          isImportant: true,
        ),
      ]);
      _persist();
    }
  }

  Future<void> _persist() async {
    await TaskStorage.saveEisenhower(tasks.toList(growable: false));
  }

  List<EisenhowerTask> byQuadrant(EisenhowerQuadrant q) => tasks
      .where((EisenhowerTask t) => t.quadrant == q)
      .toList(growable: false);

  Future<void> addTask(
    String rawTitle, {
    required bool isUrgent,
    required bool isImportant,
  }) async {
    final String title = TaskValidator.sanitizeTitle(rawTitle);
    final EisenhowerTask task = EisenhowerTask(
      id: TaskValidator.generateUuid(),
      title: title,
      isUrgent: isUrgent,
      isImportant: isImportant,
    );
    tasks.add(task);
    await _persist();
  }

  Future<void> moveToQuadrant(String id, EisenhowerQuadrant target) async {
    final int index = tasks.indexWhere((EisenhowerTask t) => t.id == id);
    if (index < 0) return;
    final (bool urgent, bool important) =
        EisenhowerConfig.getFlagsFromQuadrant(target);
    tasks[index] = tasks[index].copyWith(
      isUrgent: urgent,
      isImportant: important,
    );
    await _persist();
  }

  Future<void> deleteTask(String id) async {
    tasks.removeWhere((EisenhowerTask t) => t.id == id);
    await _persist();
  }

  /// Import a task from the Kanban board so it appears in the matrix.
  Future<void> importFromTask(
    Task task, {
    required bool isUrgent,
    required bool isImportant,
  }) async {
    tasks.add(EisenhowerTask.fromTask(
      task,
      isUrgent: isUrgent,
      isImportant: isImportant,
    ));
    await _persist();
  }

  /// Move every Do First task onto the Kanban board's To Do column.
  ///
  /// The board is written before the quadrant is emptied, so a task can never
  /// end up in neither system. Returns how many tasks left the matrix.
  Future<int> moveDoFirstToKanban() async {
    final List<EisenhowerTask> doFirst =
        byQuadrant(EisenhowerQuadrant.urgentImportant);
    if (doFirst.isEmpty) return 0;

    await _kanban.importTasks(doFirst);
    tasks.removeWhere(
        (EisenhowerTask t) => t.quadrant == EisenhowerQuadrant.urgentImportant);
    await _persist();
    debugPrint(
        'Eisenhower: moved ${doFirst.length} Do First task(s) to Kanban To Do');
    return doFirst.length;
  }
}
