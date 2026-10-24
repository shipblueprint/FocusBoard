# 08: Android app label reverted to lowercase "focusboard"

**What to build:** The launcher, the recent-apps card and Settings show **FocusBoard**, not
"focusboard".

Same family as 07: the Gradle migration re-ran the Android template over the project and
`android/app/src/main/AndroidManifest.xml` lost its `android:label="FocusBoard"`, regenerating as
the template's lowercase `android:label="focusboard"` (derived from the pubspec package name).
Fix is a one-word edit, but it is a user-visible name on every Android install, so it should land
with 07 rather than in some later pass — both are "the migration overwrote our identity" defects
with one root cause.

Checked while here, and already repaired rather than left broken: `.metadata` had been rewritten
with only `root` and `android` in `migration.platforms`, dropping ios/linux/macos/web/windows.
That does not break any current build (the directories exist and `flutter build linux` still works,
verified), but it silently tells a future `flutter create .` to stop regenerating those platforms.
The five entries are restored in the same commit as the Kotlin DSL migration.

**Blocked by:** none. Land together with 07.

**Status:** ready-for-agent

- [ ] `android:label` is `FocusBoard` in `AndroidManifest.xml`
- [ ] The label is verified on a device or emulator after install, not just in the manifest
- [ ] The other identity fields the template owns are audited in the same pass (theme names in
      `res/values/styles.xml`, `res/drawable/launch_background.xml`) so nothing else silently
      reverted to template defaults
