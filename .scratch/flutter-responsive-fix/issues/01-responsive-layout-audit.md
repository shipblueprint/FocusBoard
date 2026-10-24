# 01: Responsive layout audit & shared fix patterns

**What to build:** A complete audit of the responsive layout defects across the four affected screens (Kanban, Eisenhower Matrix, Habits, Analytics) so every fix ticket has a confirmed, itemized list of the exact widgets causing unbounded width constraints. The audit output is a short findings note (added as a comment on this ticket or a scratch doc) listing, per screen: (a) every `Row` containing a `Text` that should fill space but is not wrapped in `Expanded`/`Flexible`; (b) every container relying on `width: double.infinity` or a hardcoded width that should become flex-based; (c) every large text element (big numbers, percentages, quadrant headers) that needs a `FittedBox` or `TextOverflow.ellipsis`; (d) any `Stack`-based text overlay that should be refactored to a `Column`. Also records the agreed fix patterns as decisions: flex-first layout, `FittedBox(fit: BoxFit.scaleDown)` for shrinkable numbers, `RotatedBox(quarterTurns: 3)` for genuinely vertical text, `crossAxisAlignment: CrossAxisAlignment.start` for icon+text rows. No user-facing behavior changes in this ticket — it is prefactoring reconnaissance that makes the four fix tickets easy.

**Blocked by:** None (can start immediately).

**Status:** done

- [x] Every `Text` inside a `Row` in the four screens is classified as "fills space (needs Expanded/Flexible)" or "intrinsic size (fine as-is)"
- [x] All hardcoded/`double.infinity` widths contributing to the narrow-screen collapse are listed per screen
- [x] All large text elements needing `FittedBox`/`TextOverflow.ellipsis` are listed per screen
- [x] Any `Stack` overlays producing text overlap are identified with a recommended `Column` refactor
- [x] Fix-pattern decisions (Expanded/Flexible, FittedBox, RotatedBox, CrossAxisAlignment.start) are recorded so fix tickets don't re-litigate them
- [x] Findings note is attached to this ticket and referenced by tickets 02–05
**Closed:** audit-findings.md is the deliverable and is referenced by tickets 02-05. Two of the
original hypotheses were disproved there and are recorded rather than dropped: most `Text` in a
`Row` was already wrapped, and no `Stack` overlay or `double.infinity` width contributed to the
collapse -- the defect class is fixed-width children summing past the viewport.
