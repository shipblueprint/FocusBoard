import 'package:focusboard/app/data/task_storage.dart';
import 'package:focusboard/app/model/habit_model.dart';
import 'package:focusboard/app/model/task_validator.dart';
import 'package:get/get.dart';

class HabitController extends GetxController {
  final RxList<Habit> habits = <Habit>[].obs;

  @override
  void onInit() {
    super.onInit();
    _load();
  }

  Future<void> _load() async {
    final List<Habit> loaded = await TaskStorage.loadHabits();
    if (loaded.isNotEmpty) {
      habits.assignAll(loaded);
    } else if (!await TaskStorage.hasEverSaved()) {
      _seed();
    }
  }

  Future<void> _seed() async {
    final DateTime now = DateTime.now();
    habits.addAll(<Habit>[
      Habit(
        id: TaskValidator.generateUuid(),
        name: 'Morning walk',
        createdAt: now.subtract(const Duration(days: 7)),
      ),
      Habit(
        id: TaskValidator.generateUuid(),
        name: 'Read 30 mins',
        createdAt: now.subtract(const Duration(days: 3)),
      ),
      Habit(
        id: TaskValidator.generateUuid(),
        name: 'Drink 8 glasses of water',
        createdAt: now,
      ),
    ]);
    await _persist();
  }

  Future<void> _persist() async {
    await TaskStorage.saveHabits(habits.toList(growable: false));
  }

  Future<void> addHabit(String name) async {
    final Habit habit = Habit(
      id: TaskValidator.generateUuid(),
      name: name,
    );
    habits.add(habit);
    await _persist();
  }

  void toggleDate(String habitId, String date) {
    final int index = habits.indexWhere((Habit h) => h.id == habitId);
    if (index == -1) return;
    habits[index].toggleDate(date);
    habits.refresh();
    _persist();
  }

  Future<void> deleteHabit(String habitId) async {
    habits.removeWhere((Habit h) => h.id == habitId);
    await _persist();
  }
}
