# 003 — "Done" must be mechanically checkable

**The rule.** Every milestone has a written checklist whose items can be
observed. "Works correctly" is not an item; "fires after the device has been
idle in deep Doze" is.

## What went wrong

A project's milestone descriptions lived in prose in a plan document. One of
them was the Android alarm-scheduling pipeline, whose real bar was four
scenarios on physical hardware: the app swiped away, the screen locked, the
device in deep Doze, and after a reboot.

Nothing in the repository said that. A session picking up that milestone would
write the platform code, watch it compile, watch the unit tests pass, and report
the milestone finished — truthfully, by the only standard available to it.

The failure mode is specific and nasty: the code is *plausible*. It compiles, it
is well structured, its tests pass. It has simply never been observed doing the
thing it exists to do.

## Why prose is not enough

An agent session, and a tired human, both reach for the nearest available
definition of finished. If the repository only offers "the build is green", that
becomes the definition. A checklist is not bureaucracy; it is the thing that
makes the real bar reachable at the moment someone is deciding whether to stop.

## What follows

- A `definition-of-done` document with an "every change" section and a section
  per milestone.
- Items phrased as observations, not qualities.
- A hard rule: an item you cannot verify on this machine is **not** skipped. It
  becomes an issue (see [005](005-unfinishable-work-becomes-an-issue.md)) and is
  named in the pull request.
- The pull request body carries the walkthrough, including what was *not*
  verified, so a reviewer sees the unproven parts without reading the diff.

## Cost

Writing the checklist up front, before the work is understood well enough to be
sure it is right. It will be wrong in places. Fix it when the work reveals that,
rather than deferring it until it is accurate — by then it has already failed to
do its job once.

## When this stops being right

For work whose correctness the test suite fully captures. Most work is not that.
