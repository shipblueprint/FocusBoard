# Responsive layout audit — findings (Ticket 01)

Scope: `lib/view/apps/{kanban,eisenhower,habit,analytics}/*_screen.dart` at a ~360dp-wide Android viewport.

## Root cause summary

The global hypothesis (missing `Expanded` on `Text` inside `Row`) is **mostly wrong** — most Texts are already wrapped. The actual defect class is **fixed-width children summing to more than the narrow viewport**, so the flexible remainder collapses to ~0 and text wraps character-by-character / RenderFlex overflows.

## Per-screen findings

### Kanban (`kanban_screen.dart`)
- **K1 (primary):** 3 columns side-by-side via `Row` + `Expanded` (build method). At 360dp each column is ~104dp wide.
- **K2 (primary):** `_TaskCard` row packs three fixed 48px `IconButton`s (144px) + `Expanded(title)` into ~72dp of column content width → overflow → title collapses to char-by-char wrap. Row also lacks `crossAxisAlignment.start`.
- K3: Column header row (`Expanded(label)` + count) and WIP slider row (`Expanded(Slider)`) are structurally sound once the column has real width.
- Fix direction: narrow screens → horizontally paged columns (~85% viewport width each); wide screens keep side-by-side `Expanded`. Breakpoint 600dp.

### Eisenhower (`eisenhower_screen.dart`)
- **E1 (primary):** `_Quadrant` header is `Row[Expanded(titleMedium name), bodySmall description]` in ~140dp content width → description is squeezed, title wraps/overlaps subtitle. Not a `Stack` — no Stack refactor needed.
- E2: 2×2 `Expanded` grid structure is fine; quadrant task tiles (`Expanded(title)` + 48px delete) wrap acceptably once header is fixed.
- Fix direction: header becomes `Column(crossAxisAlignment: start)` — name on line 1 (protected by `FittedBox(scaleDown)` + ellipsis), description on line 2. All titles are meant horizontal — no `RotatedBox` needed.

### Habits (`habit_screen.dart`)
- **H1 (primary):** Habit card row = 52px checkbox + `Expanded(name+stats)` + 7 day circles (~246px fixed) + 36px menu ≈ 334px fixed > ~328px available → name squished to ~0 → vertical char wrap; circles clipped. This is a single `Row`; circles are NOT in their own row, so `spaceEvenly` cannot apply yet.
- H2: Stats banner (3× `Expanded`) is fine; "0/7 this week" sits inside an `Expanded` column and wraps fine once H1 is fixed.
- Fix direction: inside the card, narrow → two-row layout (Row[checkbox, Expanded(name+stats), menu] then day circles in their own `Row` with `spaceEvenly`); wide → current single row. Card-level breakpoint ~560dp.

### Analytics (`analytics_screen.dart`)
- A1: `_OverviewRow` already uses `Expanded ×4` — structure correct, but each card gets ~69dp at 360dp.
- **A2 (primary):** `_MetricCard` value (`headlineSmall`, e.g. "100%") overflows ~45dp content width; "High Priority" label wraps mid-word.
- Fix direction: keep `Expanded ×4`; wrap value in `FittedBox(fit: BoxFit.scaleDown)`, label gets `softWrap` + `TextOverflow.ellipsis`.

## Fix-pattern decisions (binding for tickets 02–05)

1. Flex-first: any space-filling `Text` in a `Row` stays in `Expanded`/`Flexible` (already true; keep).
2. Large numbers/percentages → `FittedBox(fit: BoxFit.scaleDown)`.
3. No intentionally vertical text exists → no `RotatedBox` needed.
4. Icon + wrapping-text rows → `crossAxisAlignment: CrossAxisAlignment.start`.
5. Width-adaptive structure via `LayoutBuilder`: 600dp screen breakpoint (Kanban); 560dp card breakpoint (Habits).
6. No `width: double.infinity` / hardcoded widths contribute to the collapse — nothing to replace there.

## Test seam (TDD)

Existing pattern (`test/eisenhower_kanban_transfer_test.dart`): `SharedPreferences.setMockInitialValues`, `Get.put` controllers, `tester.view.physicalSize` to control viewport. Each fix ticket gets a narrow-screen (360×800 logical) widget test that fails pre-fix (RenderFlex overflow throws in tests) and passes post-fix.
