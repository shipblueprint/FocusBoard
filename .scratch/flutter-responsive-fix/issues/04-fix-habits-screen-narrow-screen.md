# 04: Fix Habits screen row layout on narrow screens

**What to build:** On a narrow Android viewport, each habit row (e.g., "Morning walk", "Read 30 mins") lays out correctly: the habit name is wrapped in `Expanded` so it takes all available horizontal space and wraps as normal text, while the weekday circles (M, T, W, T, F, S, S) stay on-screen and are distributed across their allotted width using `mainAxisAlignment: MainAxisAlignment.spaceEvenly` or `spaceBetween` — never squished or pushed off-screen by the habit name. The "0/7 this week" progress text uses `softWrap: true` and has enough horizontal space from its parent to avoid awkward wrapping. All changes follow the patterns recorded in ticket 01's findings.

**Blocked by:** 01: Responsive layout audit & shared fix patterns

**Status:** done

- [x] Habit name `Text` is wrapped in `Expanded`/`Flexible` inside its row and wraps word-by-word
- [x] All seven weekday circles remain visible and evenly distributed at ~360dp width
- [x] "0/7 this week" text wraps cleanly without clipping or overflow
- [x] No RenderFlex overflow warnings on the Habits screen at narrow widths
- [x] Desktop/wide-screen rendering is unchanged
**Closed:** `89a913f`. Narrow cards move the seven day circles onto their own evenly spaced row
under the name; wide keeps the single row. Covered by the 360dp Habits test (asserts all seven
circles) and the 1200dp "keep the single-row card layout" regression test.
