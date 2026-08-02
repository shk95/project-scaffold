<!-- Append to docs/troubleshooting.md. Headings are the literal error text so
     they can be found by grep. -->

## drift

### `The name 'X' isn't a type` inside a generated `.g.dart`

The generated file is a `part` of the database file, and a part inherits the
imports of its *host library* — not of the file where the tables are declared.
Any enum used by `textEnum` must be imported in the host file as well.

### `Static members from supertypes must be qualified` inside a generated `.g.dart`

A `static const` declared on a table class. drift generates a subclass and
references it unqualified, which does not compile. Move the constant to the top
level of the file.

### `The getter 'X' recursively returns itself` on a `check()` column

A false positive. `check(hour.isBetweenValues(0, 23))` is drift's documented
syntax; drift_dev reads the expression statically at build time and the getter
is never called at runtime. Add a file-level
`// ignore_for_file: recursive_getters`.

Related trap: the generated constraint is a **closure**, not a literal
`CHECK (...)` string, so grepping the generated file will not tell you whether
it worked. Prove it with a test that inserts an invalid row, or read the live
schema: `sqlite3 <db> "SELECT sql FROM sqlite_master WHERE name='<table>';"`

### `isNull` is imported from both drift and matcher

drift exports SQL expression builders with the same names as the test matchers.
In test files: `import 'package:drift/drift.dart' hide isNotNull, isNull;`

### A `DateTime` written as UTC comes back as local time

drift's default encoding stores timestamps as unix integers, which have no UTC
flag. Set `DriftDatabaseOptions(storeDateTimeAsText: true)` on the database.
Removing it silently shifts every stored time by the zone offset for anyone
outside Greenwich.

### A watched query emits twice, the first time with the old value

drift's watchers fire on any *write* to a table, including one SQLite ignores.
An unconditional `insertOrIgnore` used to seed a row makes every subsequent save
emit the old value and then the new one, so anything rebuilding on that stream
does so spuriously. Read before writing so the common case issues no write.

## Flutter and packages

### `AsyncValue` has no `valueOrNull`

Riverpod 3 removed it; the nullable accessor is `.value`, and `.requireValue`
throws on loading or error. Riverpod 2 examples found online will not compile.

### A stream matcher reports `Actual: <Instance of '_MapStream…'>`

`expect` cannot await an asynchronous matcher. Use `expectLater`, keep the
returned future, trigger the change, then await it:

```dart
final expectation = expectLater(repo.watch(), emitsInOrder([a, b]));
await repo.save(...);
await expectation;
```

### `pub add` installed a `-dev` prerelease and broke version solving

`pub add` will pick a prerelease when the stable line lags, and the prerelease
may require an analyzer version incompatible with another code generator. After
any `pub add`, check `pubspec.yaml` for a version containing `-dev` or `-beta`
and pin the stable one by hand.

### `package:timezone` moves a time rather than clamping it

Asking for a wall-clock time that does not exist — 02:30 on a spring-forward day
— returns 03:30, shifted forward by the size of the gap, not clamped. This
matches `java.time` and therefore Android. On a fall-back day the repeated hour
resolves to the *first* pass. Pin both with tests.

The package cannot discover the device's zone on its own — `tz.local` is UTC
until something calls `setLocalLocation`. `flutter_timezone` supplies it.

## Platforms and distribution

### An unsigned macOS build will not launch on Apple Silicon at all

Not a Gatekeeper prompt — an outright refusal. arm64 binaries must carry at
least an ad-hoc signature. macOS ad-hoc signs on first run only when the
quarantine flag is absent, and a downloaded app always has it, so signing has to
happen at build time. `codesign --force --deep --sign -` is free.

### macOS 15.1 removed the right-click → Open shortcut

The long-standing advice for opening an unsigned app no longer works. Users must
go to **System Settings → Privacy & Security → Open Anyway**, or run
`xattr -dr com.apple.quarantine <app>`. Release notes have to say this, because
the app looks simply broken otherwise.

### `zip` corrupts a macOS `.app` bundle

It does not preserve the symlinks inside the bundle, and the unpacked app fails
to launch. Use `ditto -c -k --keepParent`.

### F-Droid does not need an Android keystore

It builds from source on its own infrastructure and signs with its own key. A
keystore is only needed for APKs distributed directly. What F-Droid *does*
require is that every dependency be free software, that Flutter be vendored as a
git submodule, and that `versionCode` only ever increase.
