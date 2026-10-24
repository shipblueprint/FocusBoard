# 07: Android launcher icon regressed to the Flutter template logo

**What to build:** The installed Android app shows the FocusBoard mark again, in the launcher, on the recent-apps card and in Settings → Apps.

This is a regression, not a missing feature. `HEAD` carries a generated FocusBoard `ic_launcher.png` per density (xxhdpi is 11,041 bytes: the purple target mark). The Gradle Groovy → Kotlin DSL migration re-ran the Android scaffolding over the top of them and replaced every density with the Flutter template logo (xxhdpi is now 1,031 bytes). The Android asset published today therefore ships the wrong icon; that release stands until this ticket lands, so the fix ships as a follow-up asset rather than a re-tag.

`focusboard_icon.png` in the repo root (1024×1024) is the single source of truth — the Linux hicolor set and the Windows icon are already generated from it. Regenerate the five `mipmap-*/ic_launcher.png` from it rather than restoring from `HEAD`, so the fix also re-derives the densities the migration may have resized differently.

Decide and record while working: whether to add adaptive icons (`mipmap-anydpi-v26/ic_launcher.xml` with foreground/background layers, plus a monochrome layer for Android 13+ themed icons). `AndroidManifest.xml` points at `@mipmap/ic_launcher` and there is no adaptive-icon XML in the tree at all, so on Android 8+ the launcher letterboxes the flat PNG instead of masking it — worth fixing in the same pass since the source art is square and already has its own rounded background.

Also decide: commit the generated PNGs (keeps the build reproducible with no extra tooling, matches what Linux/Windows do) or add `flutter_launcher_icons` as a dev_dependency and generate at build time (keeps the binaries out of the diff but adds a step to every release). Do not do both.

**Blocked by:** none — but it must land before the Android module migration currently sitting in the working tree is considered done, and before any Android release is labelled icon-correct.

**Status:** ready-for-agent

- [ ] All five `android/app/src/main/res/mipmap-*/ic_launcher.png` are regenerated from `focusboard_icon.png` at the correct density (mdpi 48, hdpi 72, xhdpi 96, xxhdpi 144, xxxhdpi 192)
- [ ] No density still matches the Flutter template logo byte-for-byte
- [ ] Adaptive icon added with foreground/background layers, and the choice recorded here if the monochrome layer is skipped
- [ ] `flutter build apk --release` produces an APK whose launcher icon is verified on a device or emulator, not just in the resource tree
- [ ] The approach (committed PNGs vs `flutter_launcher_icons`) is chosen, recorded above, and applied consistently
- [ ] A corrected Android asset is published and the ticket is referenced from the release notes so the wrong-icon release is explained rather than silently replaced
