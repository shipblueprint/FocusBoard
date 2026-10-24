# 02: Fix Kanban board screen layout on narrow screens

**What to build:** On a narrow Android viewport, the Kanban board renders correctly: each board column has a bounded, usable width (e.g., ~80% of screen width if horizontally scrolled, or a flex share if in a `Row`), so columns no longer collapse to minimum intrinsic width. Inside each task card (e.g., "Plan weekly focus", "Refactor task model"), the title text takes the card's remaining horizontal space and wraps as normal multi-line text — never character-by-character vertically. The row holding the radio/status icon and the task title uses `crossAxisAlignment: CrossAxisAlignment.start` so the icon aligns with the first line of wrapped text. The "WIP" badge is positioned so it no longer overlaps the task list. All changes follow the patterns recorded in ticket 01's findings.

**Blocked by:** 01: Responsive layout audit & shared fix patterns

**Status:** done

- [x] Each Kanban column has an explicit width or flex constraint — no unbounded width on narrow screens
- [x] Task card title text is wrapped in `Expanded`/`Flexible` and wraps word-by-word, not character-by-character
- [x] Icon + title row in task cards uses `crossAxisAlignment: CrossAxisAlignment.start`
- [x] "WIP" badge does not overlap the task list on a ~360dp-wide viewport
- [x] No RenderFlex overflow warnings on the Kanban screen at narrow widths
- [x] Desktop/wide-screen rendering is unchanged
**Closed:** `89a913f`. Columns page horizontally below 600dp, the task-card icon row is
`CrossAxisAlignment.start`, long titles wrap word-by-word. Covered by
`test/narrow_screen_layout_test.dart` ("KanbanScreen at 360dp") plus the 1200dp
"keeps three side-by-side columns" regression test.
