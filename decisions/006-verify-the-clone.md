# 006 — Verify the clone; do not assert it works

**The rule.** Before claiming a repository is ready to be worked on elsewhere,
clone it into a scratch directory and follow your own instructions in order.

## What went wrong

A repository had documentation covering setup, an environment doctor, versioned
hooks, a worktree helper and agent commands. All of it had been written
carefully. All of it was reported as ready.

One clone found three failures:

1. **The clone got none of the tooling.** The default branch predated all of it
   (see [001](001-default-branch-is-the-integration-branch.md)).
2. **The worktree helper's cleanup command never matched anything.** It searched
   for a directory pattern that did not match the layout it created. It had
   never been run — only its `new` and `list` paths had.
3. **The setup instructions taught people to skip the hooks.** Build steps came
   first; the hooks line was further down under a "Development" heading. Anyone
   following in order committed without them
   (see [002](002-hooks-are-opt-in-so-ci-must-backstop.md)).

Each is obvious in hindsight. None was visible from the machine that wrote them,
because that machine already had every piece of state a clone lacks.

## Why this is a category, not an accident

Documentation is written by someone who cannot see what they already have —
configured hooks, resolved dependencies, a checked-out branch, tools on PATH.
Every one of those is invisible until it is missing, and the author is the one
person who will never experience it missing.

The same asymmetry produces the untested code path: `new` and `list` get run
constantly during development, `done` gets run once, at the end, by someone
else.

## The check

```sh
git clone <url> /tmp/verify && cd /tmp/verify
# then follow the README, in order, without using anything you know
```

Watch for the step where you reach for knowledge that is not written down. That
step is the bug.

## Cost

Minutes. It has never not found something.

## When this stops being right

Never.
