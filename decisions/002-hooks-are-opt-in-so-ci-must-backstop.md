# 002 — Hooks are opt-in, so CI has to repeat their checks

**The rule.** Any check that must not be skipped runs in CI. Git hooks are for
fast feedback, never for enforcement.

## What went wrong

Versioned hooks are a good pattern: put them in `.githooks/`, commit them, and
every clone has them. Except a clone does *not* have them until someone runs

```sh
git config core.hooksPath .githooks
```

`core.hooksPath` is local repository configuration. It is not cloned, not
inherited, and nothing reminds you. A clone that skips that line commits with no
formatting check, no static analysis, and — the one that actually matters — no
secret scan.

For a repository heading for public, that is the difference between catching a
credential before it exists in history and having it there permanently, because
deleting the file does not remove the commit.

## What follows

- Secret scanning runs in CI over the **full history**, not just the diff.
- The environment doctor treats an unset `core.hooksPath` as a hard failure, not
  a warning, and prints the exact command.
- The setup instructions put that line **first**, before the build steps.
  Ordering is not cosmetic: people follow instructions in order, and a
  contributor who reaches "run the tests" before "enable the hooks" has already
  made commits without them.

## Cost

The checks run twice, so CI is slower than it strictly needs to be. Worth it:
the local run catches the mistake in seconds, and the CI run is the one that
cannot be bypassed.

## When this stops being right

Never, as long as clones are made by people or agents you do not control. A
single-machine project with one operator can rely on hooks alone — until the
day it is cloned.
