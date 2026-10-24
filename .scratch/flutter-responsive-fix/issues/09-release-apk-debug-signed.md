# 09: Release APK is signed with the debug key

**What to build:** `flutter build apk --release` produces an artifact signed with a real release
key, so the published APK can be upgraded in place by the next release and traced to a key the
project controls.

`android/app/build.gradle.kts` still carries the template default in its `release` build type:

```
signingConfig = signingConfigs.getByName("debug")
```

with the template's own TODO above it. There is no `key.properties`, no `*.jks` and no
`*.keystore` anywhere in `android/` (checked), so nothing is being ignored by accident — a key has
simply never been made. The APK published today is therefore a release-mode build carrying debug
signing: it installs and runs fine, but Android will refuse to update it with a properly signed
build later, which means the first real release either has to be a clean install for existing
users or keeps debug signing forever.

This blocks calling any Android asset a release. It does not block 07 or 08.

Decisions the ticket has to record, not invent: where the keystore lives and who holds it (it must
never be committed — `android/.gitignore` already excludes `key.properties`, `**/*.keystore` and
`**/*.jks`), how CI or a release machine obtains it, and whether the same applicationId is kept.
Note that `applicationId` is `com.example.focusboard`; if that is ever changed, the signed app
becomes a different application to Android and existing installs cannot be upgraded regardless of
the key. That trade-off belongs in this ticket, not in a later surprise.

**Blocked by:** none — but it gates any Android release that is meant to be upgradable.

**Status:** ready-for-agent

- [ ] A release keystore exists, its location and holder are recorded, and it is not in the repo
- [ ] `build.gradle.kts` reads the signing config from `key.properties` (or an equivalent outside
      version control) and falls back clearly when the file is absent, so a missing key fails loudly
      instead of silently shipping debug-signed
- [ ] `flutter build appbundle` and `flutter build apk --release` both produce artifacts signed by
      the release key, verified with `apksigner verify --print-certs`
- [ ] The applicationId question is settled and written down here
- [ ] A correctly signed Android asset replaces the debug-signed one on the Releases page
