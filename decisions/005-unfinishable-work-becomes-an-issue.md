# 005 — Work that cannot be finished here becomes an issue

**The rule.** When a session cannot complete something because this machine
lacks a device, a platform or a human, it files an issue saying exactly what is
missing. It does not quietly leave it out.

## The problem

Sessions are short and machines differ. A session on a laptop can write an
Android scheduling pipeline but cannot watch a phone wake from Doze. A session
on macOS can build the Windows target in CI but cannot look at it.

Two bad outcomes are available, and both happen by default:

- The item is silently dropped, and the milestone looks complete.
- The item is mentioned in the session's closing message, which nobody reads
  again, and is lost when the session ends.

## Why an issue rather than a file

The obvious answer is a `BLOCKED.md`. It is the wrong one: several branches
working at once all append to it, and every merge conflicts on the same lines.

Issues have none of that, and they are queryable:

```sh
gh issue list --label blocked
```

which is the first thing a session runs — before choosing new work — so that
something already written and merely unverified gets finished before something
new is started.

## Labels

Two labels, always both:

- `blocked` — the umbrella, and the only thing that query finds
- `blocked/needs-android-device`, `blocked/needs-windows`,
  `blocked/needs-manual-check` — what is actually missing

**GitHub matches label names exactly.** An issue tagged only
`blocked/needs-android-device` does not appear under `--label blocked`. Getting
this wrong makes blocked work invisible from the moment it is filed, which is
worse than not filing it — it looks tracked.

## Writing the body

For someone with none of your context: what was built, what was tested, and the
steps to close it. "Needs a device" is not enough; say which scenario, and what
counts as passing.

## When this stops being right

When every contributor has every target platform and device. Rare, and it stops
being true the moment someone new joins.
