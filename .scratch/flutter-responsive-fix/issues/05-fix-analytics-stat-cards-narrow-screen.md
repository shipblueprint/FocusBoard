# 05: Fix Analytics stat cards layout on narrow screens

**What to build:** On a narrow Android viewport, the Analytics screen's top stat cards ("Total", "Completed", etc.) share the row's width evenly: each card is wrapped in `Expanded` (with consistent spacing between cards, e.g., `SizedBox(width: 8)`), so no card is squished and labels wrap normally. Inside each stat card, the numeric value (e.g., "0%") is wrapped in a `FittedBox(fit: BoxFit.scaleDown)` so it shrinks gracefully instead of wrapping or overflowing on small screens. All changes follow the patterns recorded in ticket 01's findings.

**Blocked by:** 01: Responsive layout audit & shared fix patterns

**Status:** done

- [x] Each stat card in the top row is wrapped in `Expanded` and cards share width evenly
- [x] Numeric values use `FittedBox(fit: BoxFit.scaleDown)` and never wrap or clip at ~360dp width
- [x] Stat card labels (e.g., "Total", "Completed") wrap normally without character-by-character breaks
- [x] No RenderFlex overflow warnings on the Analytics screen at narrow widths
- [x] Desktop/wide-screen rendering is unchanged
**Closed:** `89a913f`. Metric values shrink via `FittedBox`, labels ellipsize. Covered by the
360dp Analytics test.

Caveat on the last box: no 1200dp Analytics regression test exists; wide rendering was checked by
hand on the Linux build.
