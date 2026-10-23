# SPEC — Move "Do First" tasks to the Kanban "To Do" column

Status: implemented 2026-10-24 — tests green, see §10 for where the code diverged from this plan
Feature request (verbatim): *"when user add tasks to eisenhower tab in do first there has to be to move them all to kanban todo column"*

---

## 1. Behaviour

The Eisenhower screen gains a new AppBar action, **Move Do First to Kanban**. Activating it
moves **every task currently in the `Do First` quadrant** (urgent + important) into the
Kanban board's **`To Do`** column.

Semantics of the operation:

- It is a **move**, not a copy. A task leaves the matrix and appears on the board exactly
  once. This mirrors the existing `moveToQuadrant` / `moveTask` verbs, which relocate a
  task rather than duplicating it.
- It is **user-initiated**, one quadrant at a time, all-or-nothing for that quadrant.
- **Ids survive.** A moved task keeps its `id`, `title`, `isCompleted` and
  `isHighPriority` values, so the move reads as the same piece of work changing systems.
- Other quadrants (`Schedule`, `Delegate`, `Eliminate`) are never touched.
- Both sides persist: the matrix writes `eisenhower_tasks_v1`, the board writes
  `kanban_tasks_v1`.

### 1.1 Why not "automatically on add"

The literal reading of the request — hook `EisenhowerController.addTask` so that any task
added as Do First instantly leaves the matrix — was rejected:

1. The Do First quadrant would be permanently empty and could never be rendered, so the
   matrix would lose the quadrant that gives the tool its name.
2. The task would have to change quadrant (via drag) to be visible again, which is
   impossible for a task the user can no longer see.
3. `moveToQuadrant` into Do First would also have to fire, otherwise the quadrant could
   still be populated by hand — meaning the automation must intercept two write paths.

The user-visible need behind the request is *"the urgent-and-important work has to end up on
my board's To Do list."* A one-tap bulk transfer satisfies that while keeping Do First a
real, inspectable quadrant. Recorded as **OQ-1** below in case the product owner wants the
automatic variant after all.

---

## 2. Impact analysis (Protocol 1)

| File | Change | Reason |
| --- | --- | --- |
| `lib/app/controller/kanban_controller.dart` | **add** `importTasks(List<Task>)` | `addTask` mints a new UUID and cannot preserve identity, so a second entry point is required. Bulk signature (not one-per-task) so the whole transfer is a single storage write. |
| `lib/app/controller/eisenhower_controller.dart` | **add** `moveDoFirstToKanban()`; **add** constructor taking `KanbanController` | Cross-controller seam for the transfer. Existing `importFromTask` is the reverse direction only. |
| `lib/view/apps/eisenhower/eisenhower_screen.dart` | **add** one `IconButton` to `AppBar.actions` | The only UI needed; the widget tree and the 2×2 grid stay untouched. |
| `lib/app/controller/app_binding.dart` | **no change** | Both controllers are already registered `permanent: true`, and `KanbanController` is put **before** `EisenhowerController`, which is what the `Get.find` fallback needs — the fallback resolves eagerly at construction, so that order is now a constraint on any new call site. |
| `lib/app/data/task_storage.dart` | **no change** | `saveKanban` / `saveEisenhower` already cover both writes. ⚠ This file is in the user's uncommitted WIP — it must not be edited. |
| `lib/app/model/*` | **no change** | `EisenhowerTask extends Task` already carries `column`, so the conversion is lossless with `column` forced to `toDo`. |
| `test/eisenhower_kanban_transfer_test.dart` | **new** | TDD per Protocol 3. |
| `PROJECT_MAP.md` | **new** | Does not exist yet; created under Protocol 4. |

## 3. Shared-layer design (Protocol 2)

`EisenhowerController` must not reach into `KanbanController`'s list directly, and must not
construct storage payloads itself. It follows the seam `AnalyticsController` already
establishes (`lib/app/controller/analytics_controller.dart`):

```dart
EisenhowerController({KanbanController? kanban})
    : _kanban = kanban ?? Get.find<KanbanController>();
```

Constructor injection with a `Get.find` fallback keeps production wiring implicit
(`AppBinding` unchanged) and makes the test able to hand the controller a real, isolated
`KanbanController`.

`importTasks` is the single owner of board-side rules for arriving tasks — dedupe by id,
force the landing column, one storage write per batch. `moveDoFirstToKanban` owns
matrix-side rules — which tasks qualify, removal, persistence order.

Logging: `debugPrint` (the repo idiom, e.g. `lib/view/apps/habit/habit_screen.dart:301`),
one line per controller per transfer with the count moved.

## 4. Data flow

```
IconButton
  → EisenhowerController.moveDoFirstToKanban()
      → byQuadrant(urgentImportant)                       // select
      → KanbanController.importTasks(doFirst)             // board write + persist
      → tasks.removeWhere(quadrant == urgentImportant)     // matrix write
      → _persist()                                         // matrix persist
```

`EisenhowerTask` → `Task` needs no field mapping: it *is* a `Task`. `importTasks` rebuilds
each entry as a plain `Task(id:, title:, isCompleted:, isHighPriority:, column:
KanbanColumn.toDo)` instead of calling `copyWith`, because `EisenhowerTask.copyWith` is
overridden to return an `EisenhowerTask` and `TaskStorage.saveKanban` dispatches `toJson()`
dynamically — a copyWith result would write `isUrgent`/`isImportant`/`type: eisenhower` into
`kanban_tasks_v1`.

## 5. Edge cases

| Case | Required behaviour |
| --- | --- |
| Do First empty | No-op; the action button is disabled so it is unreachable in the UI, and the method returns `0` defensively. Neither storage is rewritten. |
| Id already on the board | `importTasks` skips it and the matrix still drops it — the board must never hold two tasks with one id. Reachable if a task was moved Do First → Kanban and later re-imported from the board via `importFromTask`. The return count still includes it: the value is "tasks that left the matrix", not "tasks added to the board". |
| Kanban WIP limit on To Do (default 8) | **Not enforced.** `isWipLimitReached` is only consulted by the drag UI in `kanban_screen.dart`; `addTask` already ignores it. A bulk move is allowed to exceed the limit and the overflow is recorded as a pending gap in `PROJECT_MAP.md`. |
| A completed Do First task | Moves with `isCompleted: true` but stays in `To Do` — `moveToQuadrant` never sets `isCompleted`, so this can only arise from legacy data. Column wins; `importTasks` does not re-derive `isCompleted` from the column. |
| Transfer twice in a row | Second call is a no-op (Do First is now empty). |
| Persistence order | Board is written **before** the matrix is emptied. If the board write fails, the task is still in Do First and nothing is lost; a task can therefore never exist in neither system. |

## 6. Tasks (execution order)

1. [x] `test/eisenhower_kanban_transfer_test.dart` — write it, run it, **see it fail** (Protocol 3, red).
2. [x] `KanbanController.importTasks(List<Task>)` — dedupe by id, force `KanbanColumn.toDo`, persist once, `debugPrint`.
3. [x] `EisenhowerController` — `_kanban` field + constructor; `moveDoFirstToKanban()` returning `int`.
4. [x] `EisenhowerScreen` — AppBar `IconButton`, `Obx`-driven `onPressed: null` while Do First is empty.
5. [x] `flutter test` green, and `test/task_validator_test.dart` etc. still green (no regression). 26/26.
6. [x] `flutter analyze` — must not add to the 3 pre-existing info lints. Still exactly 3.
7. [x] `PROJECT_MAP.md` — created; seams, storage keys, and pending gaps recorded (Protocol 4).

## 7. Test plan

`SharedPreferences.setMockInitialValues({})`, `Get.put` both controllers, `await Get.reset()`
in `tearDown`.

1. Do First tasks land in `byColumn(KanbanColumn.toDo)`, other quadrants keep their tasks,
   Do First becomes empty.
2. Ids, titles and `isHighPriority` survive the move.
3. Empty Do First → count `0`, board length unchanged.
4. Id collision → board length unchanged, matrix entry removed.
5. A task dragged into Do First via `moveToQuadrant` is picked up by the transfer.
6. Re-running the transfer is a no-op.
7. Round trip → both storages reload the moved task through `TaskStorage`.
8. The moved entry is a plain `Task` — `toJson()` emits no `isUrgent` / `isImportant` /
   `type` keys (`eisenhower_tasks_v1` and `kanban_tasks_v1` stay schema-clean).
9. Widget: pumping `EisenhowerScreen` shows the action disabled while Do First is empty,
   enabled once a task is there, and disabled again after the tap transferred it.

## 8. Open questions

- **OQ-1** — Auto-move on add? Rejected in §1.1 for the reasons above; needs a product
  decision if the request really meant "immediately, without asking".
- **OQ-2** — Copy instead of move? §1 chose move to match the existing verbs and to avoid
  the same work appearing on both boards. Cheap to switch if the owner disagrees.
- **OQ-3** — Should `Schedule` (not urgent, important) also be transferable? Out of scope;
  the current feature names Do First only.
- **OQ-4** — Confirmation dialog before clearing the quadrant? Out of scope; the move is
  non-destructive (the task still exists on the board) so the risk is low.

## 9. Surgical-change compliance

No reformatting of adjacent code, no rephrasing of existing comments, no refactoring of
working code. Only `kanban_controller.dart`, `eisenhower_controller.dart` and
`eisenhower_screen.dart` gain lines; nothing else is touched. The uncommitted WIP in
`habit_controller.dart`, `habit_model.dart`, `task_storage.dart`, `habit_screen.dart`,
`pubspec.lock` and `analysis_options.yaml` stays exactly as it is.

## 10. Implementation record

Where the shipped code differs from the plan above, and why:

- **`importTasks(List<Task>)`, not `importTask(Task)`.** The transfer is inherently a bulk
  operation; a per-task entry point would issue N `saveKanban` writes for one user action.
  The rules (dedupe, forced column) are unchanged.
- **Plain-`Task` rebuild instead of `copyWith`** — see §4. The original draft assumed
  `Task.toJson` would be used; dynamic dispatch means it would not have been.
- **Test fixtures clear the seeded lists.** `_load()` seeds sample tasks whenever storage
  is empty, and `EisenhowerController`'s seed contains a Do First task, so the tests wait
  for that async seed and then replace both lists to assert on known counts.
- **`Get.reset()` is not awaitable** in GetX 4.6.6 (returns `void`); `tearDown` calls it
  synchronously. Recorded in `PROJECT_MAP.md` §6 so the next controller test does not
  rediscover it.
- **Two widget tests were added** beyond the plan, to exercise the real startup path —
  `EisenhowerController`'s new `Get.find<KanbanController>()` fallback only fires when the
  app binds the controllers, and the disabled/enabled state is `Obx` wiring no controller
  test can see. `flutter build linux --release` then booted the bundle (exit 124 under
  `timeout 25`, i.e. alive and clean) to confirm `AppBinding`'s ordering satisfies that
  dependency.
- **Pre-existing layout bug found on the way:** `_Quadrant`'s `Column` overflows by 1px at
  the 800×600 default test surface. Not caused by this change (the action adds no vertical
  height); the widget test pumps at 1600×1200 instead of asserting on it, and the overflow
  is recorded as pending gap 7 in `PROJECT_MAP.md`.

