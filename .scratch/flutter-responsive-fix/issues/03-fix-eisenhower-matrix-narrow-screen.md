# 03: Fix Eisenhower Matrix quadrant layout on narrow screens

**What to build:** On a narrow Android viewport, each Eisenhower quadrant renders its title ("Do First", "Schedule", etc.) and subtitle ("Urgent & Important", etc.) without vertical character-by-character wrapping and without title/subtitle overlap. If the quadrant currently uses a `Stack` to layer text over a background color, it is refactored to a `Column` with `crossAxisAlignment: CrossAxisAlignment.start` and `mainAxisAlignment: MainAxisAlignment.spaceBetween` so background and text can no longer collide. Large titles that must remain horizontal get their narrow width constraints removed and are protected with `FittedBox(fit: BoxFit.scaleDown)` or `overflow: TextOverflow.ellipsis`; any title that is genuinely meant to read vertically uses `RotatedBox(quarterTurns: 3, child: Text(...))` instead of relying on wrapping. All changes follow the patterns recorded in ticket 01's findings.

**Blocked by:** 01: Responsive layout audit & shared fix patterns

**Status:** done

- [x] Quadrant titles render horizontally (or via RotatedBox if intentionally vertical) — never wrapped one character per line
- [x] Subtitles are fully visible and never overlapped by titles at narrow widths
- [x] Stack-based text overlays are replaced with a Column layout where they caused overlap
- [x] Large titles use `FittedBox(fit: BoxFit.scaleDown)` or `TextOverflow.ellipsis` so they degrade gracefully on ~360dp-wide viewports
- [x] No RenderFlex overflow warnings on the Eisenhower screen at narrow widths
- [x] Desktop/wide-screen rendering is unchanged
**Closed:** `89a913f`. Quadrant header is now a `Column` (name above description) with
`FittedBox(scaleDown)` + ellipsis. Covered by the 360dp Eisenhower test.

Caveat on the last box: there is no 1200dp Eisenhower regression test. Wide-screen rendering was
confirmed by running the Linux desktop build at 1332px, not by an automated check.
