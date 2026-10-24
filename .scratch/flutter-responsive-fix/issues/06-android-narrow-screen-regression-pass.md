# 06: Android narrow-screen regression pass

**What to build:** A final end-to-end verification that the responsive fix is complete. All four screens (Kanban, Eisenhower Matrix, Habits, Analytics) are exercised on a narrow Android viewport (~360dp wide, emulator or device) and on desktop/wide screen to confirm no regression. Verification covers: no character-by-character vertical text anywhere, no overlapping badges/titles/subtitles, no RenderFlex overflow errors in the console, weekday circles and stat cards fully visible, and horizontal Kanban scrolling still works if applicable. A short before/after screenshot set per screen is captured as evidence. Any residual defects found are filed as follow-up tickets rather than fixed ad hoc here.

**Blocked by:** 02: Fix Kanban board screen layout on narrow screens; 03: Fix Eisenhower Matrix quadrant layout on narrow screens; 04: Fix Habits screen row layout on narrow screens; 05: Fix Analytics stat cards layout on narrow screens

**Status:** blocked

- [ ] All four screens render correctly on a ~360dp-wide Android viewport with zero RenderFlex overflow errors
- [ ] No text wraps character-by-character; no overlapping widgets on any of the four screens
- [ ] Desktop/wide-screen rendering verified unchanged on all four screens
- [ ] Before/after screenshots captured for each screen and attached to this ticket
- [x] Any residual issues are filed as new follow-up tickets with blocking edges, not silently fixed

**Blocked by reality, not by code:** the fixes themselves are in (`89a913f`) and every screen is
covered by a 360x800 widget test, so the first three boxes are closeable in minutes on a device or
emulator -- what is missing is that evidence, which only an actual Android run produces. The
Android module is mid-migration (Gradle Groovy -> Kotlin DSL, `com.example.henox` ->
`com.example.focusboard`) and uncommitted, so there is no reproducible APK to install yet.

Residual issue found while preparing the Android asset: the launcher icon regressed to the Flutter
template logo. Filed as 07 with the root cause, not fixed ad hoc here.
