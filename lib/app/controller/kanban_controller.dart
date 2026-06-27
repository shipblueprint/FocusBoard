import 'package:focusboard/app/data/task_storage.dart';
import 'package:focusboard/app/model/task_model.dart';
import 'package:focusboard/app/model/task_validator.dart';
import 'package:get/get.dart';

/// Reactive controller that owns the Kanban tasks list and its
/// [KanbanColumn] bucketing.
class KanbanController extends GetxController {
  final RxList<Task> tasks = <Task>[].obs;

  @override
  void onInit() {
    super.onInit();
    _load();
  }

  Future<void> _load() async {
    final List<Task> loaded = await TaskStorage.loadKanban();
    if (loaded.isNotEmpty) {
      tasks.assignAll(loaded);
    } else {
      // Seed with a tiny sample so the empty state isn't the only view.
      tasks.assignAll(<Task>[
        Task(
          id: TaskValidator.generateUuid(),
          title: 'Plan weekly focus',
          column: KanbanColumn.toDo,
        ),
        Task(
          id: TaskValidator.generateUuid(),
          title: 'Refactor task model',
          column: KanbanColumn.inProgress,
          isHighPriority: true,
        ),
      ]);
      _persist();
    }
  }

  Future<void> _persist() async {
    await TaskStorage.saveKanban(tasks.toList(growable: false));
  }

  List<Task> byColumn(KanbanColumn column) =>
      tasks.where((Task t) => t.column == column).toList(growable: false);

  Future<void> addTask(String rawTitle, {bool isHighPriority = false}) async {
    final String title = TaskValidator.sanitizeTitle(rawTitle);
    final Task task = Task(
      id: TaskValidator.generateUuid(),
      title: title,
      isHighPriority: isHighPriority,
      column: KanbanColumn.toDo,
    );
    tasks.add(task);
    await _persist();
  }

  Future<void> moveTask(String id, KanbanColumn target) async {
    final int index = tasks.indexWhere((Task t) => t.id == id);
    if (index < 0) return;
    final Task original = tasks[index];

    // Block moving out of Done once complete.
    if (original.column == KanbanColumn.done && !original.isCompleted) {
      return;
    }

    tasks[index] = original.copyWith(
      column: target,
      isCompleted: target == KanbanColumn.done,
    );
    await _persist();
  }

  Future<void> togglePriority(String id) async {
    final int index = tasks.indexWhere((Task t) => t.id == id);
    if (index < 0) return;
    tasks[index] =
        tasks[index].copyWith(isHighPriority: !tasks[index].isHighPriority);
    await _persist();
  }

  Future<void> toggleCompleted(String id) async {
    final int index = tasks.indexWhere((Task t) => t.id == id);
    if (index < 0) return;
    final Task original = tasks[index];
    final bool next = !original.isCompleted;
    tasks[index] = original.copyWith(
      isCompleted: next,
      column: next ? KanbanColumn.done : KanbanColumn.toDo,
    );
    await _persist();
  }

  Future<void> deleteTask(String id) async {
    tasks.removeWhere((Task t) => t.id == id);
    await _persist();
  }

  Future<void> clearDone() async {
    tasks.removeWhere((Task t) => t.column == KanbanColumn.done);
    await _persist();
  }

  /// WIP limits per column (null = unlimited). Persisted alongside the
  /// task list so the user's chosen limits survive a restart.
  final RxMap<KanbanColumn, int> wipLimits = <KanbanColumn, int>{
    KanbanColumn.toDo: 8,
    KanbanColumn.inProgress: 5,
    KanbanColumn.done: 999,
  }.obs;

  @override
  void onReady() {
    super.onReady();
    _loadWip();
  }

  Future<void> _loadWip() async {
    final Map<String, int> raw = await TaskStorage.loadKanbanWipLimits();
    raw.forEach((String k, int v) {
      final KanbanColumn col = KanbanColumn.fromString(k);
      wipLimits[col] = v;
    });
  }

  Future<void> _saveWip() async {
    await TaskStorage.saveKanbanWipLimits(
      <String, int>{
        for (final KanbanColumn c in KanbanColumn.values)
          c.label: wipLimits[c] ?? 999,
      },
    );
  }

  Future<void> setWipLimit(KanbanColumn col, int value) async {
    wipLimits[col] = value;
    await _saveWip();
  }

  bool isWipLimitReached(KanbanColumn col) {
    final int? limit = wipLimits[col];
    if (limit == null) return false;
    return byColumn(col).length >= limit;
  }
}
