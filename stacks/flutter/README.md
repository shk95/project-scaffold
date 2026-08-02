# Flutter overlay

Verified on one project: a cross-platform alarm clock targeting macOS, Android
and Windows, with drift, Riverpod and build_runner.

## Copy

```
tool/checks/*        → tool/checks/        (chmod +x)
tool/doctor.sh       → tool/doctor.sh      (chmod +x)
workflows/ci.yml     → .github/workflows/  (replaces core/workflows/secret-scan.yml,
                                            which it already includes as a job)
workflows/release.yml → .github/workflows/ (delete the jobs for targets you do
                                            not build)
gitignore-additions  → append to .gitignore
settings-additions.json → merge into .claude/settings.json
troubleshooting.md   → append to docs/troubleshooting.md
```

Then pin the SDK:

```sh
flutter --version | head -1 | awk '{print $2}' > .flutter-version
```

`.flutter-version` is read by both `tool/doctor.sh` and CI, so a contributor's
machine and CI cannot drift apart without one of them saying so.

## Decisions specific to this stack

**Commit the generated `*.g.dart` files.** A fresh clone then analyses and tests
without running the generator first, which removes a step from onboarding and
from any build server that would otherwise need the full toolchain. CI checks
they are current with `git diff --exit-code -- '*.g.dart'` after regenerating,
so the promise stays honest.

**Exclude generated files from the format check.** Their formatting is the
generator's business. Without the exclusion, a generator that emits differently
formatted output fails every commit.

**Store timestamps as text if you use drift.** Its default integer encoding
discards the UTC flag, so a value written as UTC reads back as local — which
silently shifts every stored time by the zone offset for anyone outside
Greenwich. `DriftDatabaseOptions(storeDateTimeAsText: true)`.

**Ad-hoc sign macOS builds even without a developer account.** Apple Silicon
refuses to execute an unsigned arm64 binary at all. `codesign --sign -` is free
and takes one CI step; without it the artifact simply does not run.

## What is not here

Android release signing, macOS notarisation and Windows code signing. The first
is free but only needed for direct distribution; the other two are paid yearly
subscriptions. Add them when there is something worth distributing widely.
