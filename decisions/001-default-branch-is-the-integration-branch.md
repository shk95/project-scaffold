# 001 — The default branch is the integration branch

**The rule.** With a `master`/`dev` split, `dev` is the repository's default
branch. `master` holds the released state and moves only on a release.

## What went wrong

A project ran `master` as the default, which is the conventional choice. Over a
few days of work, `dev` accumulated the entire agent-session setup: the
orientation file loaded at the start of every session, the environment doctor,
the shared editor settings, the definition of done, the troubleshooting log.
None of it had been released yet, so none of it was on `master`.

Then someone cloned the repository to work on it:

```
CLAUDE.md                    missing
tool/doctor.sh               missing
.claude/settings.json        missing
docs/definition-of-done.md   missing
docs/troubleshooting.md      missing
```

The onboarding system was invisible to the one situation it was built for. It
had been working perfectly for weeks — on the machine that wrote it, which never
cloned anything.

## Why the conventional choice is wrong here

`master` as default assumes the primary audience is a *reader* looking for
stable code. When the primary audience is a *contributor* about to start work,
the default branch should be the one they will branch from. Otherwise every
contributor is one forgettable `git checkout dev` away from branching off the
wrong thing, and the branch they land on is by construction the most out-of-date
one in the repository.

Merging `dev` into `master` to fix it is worse: it puts unreleased work on the
branch that is supposed to mean "released".

## Cost

`master` sits visibly behind `dev` — often by dozens of commits. This looks like
drift and invites someone to "fix" it. Say so in the repository's own notes, or
it will get fixed.

## When this stops being right

When the repository's main audience becomes people consuming releases rather
than people contributing to it. A published library, or a project after it goes
public and traffic shifts to readers.
