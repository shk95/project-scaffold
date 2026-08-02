# Scaffolding playbook

Instructions for an agent setting up a new project from these conventions.
Follow them in order.

## Before anything else

Read [`decisions/README.md`](decisions/README.md) and skim the decision files.
You are about to copy a set of rules; you cannot adapt them sensibly without
knowing what each one is defending against. Several look like arbitrary
preferences until you know the failure.

## 1. Ask

Do not guess these. Each changes what gets written.

| | Why it matters |
| --- | --- |
| What is being built, in a sentence | Goes at the top of `CLAUDE.md`; also tells you which invariants will matter |
| Language and framework | Selects the overlay from `stacks/`, and the contents of `tool/checks/` |
| Where it will be distributed | Decides whether release workflows and signing are needed at all |
| Public or private | Decides whether "write everything in English" applies, and how careful `.gitignore` has to be |
| Licence | MIT unless told otherwise |
| Repository name and owner | Needed for `setup-repo.sh` |

If no overlay exists for the stack, say so plainly. Write `tool/checks/` by
hand from what that ecosystem actually uses, and do not pretend the result is
verified.

## 2. Copy the core

```
core/gitignore              → .gitignore          (append the stack's own ignores)
core/githooks/*             → .githooks/          (chmod +x)
core/tool/worktree.sh       → tool/worktree.sh    (chmod +x)
core/claude/settings.json   → .claude/settings.json
core/claude/commands/*      → .claude/commands/
core/workflows/secret-scan.yml → .github/workflows/  (or merge into an existing CI job)
core/templates/CLAUDE.md    → CLAUDE.md
core/templates/docs/*       → docs/
```

The templates carry `<PLACEHOLDER>` markers and HTML comments explaining what
each section is for. **Fill them in and delete the comments** — a template left
half-filled is worse than none, because it looks like documentation.

## 3. Add the stack overlay

From `stacks/<stack>/`. At minimum it supplies:

- `tool/checks/format`, `tool/checks/lint`, `tool/checks/test` — the core hooks
  delegate to these and skip any that are absent. Small executables, one command
  each.
- `tool/doctor.sh` — checks the toolchain, **and** that `core.hooksPath` is set.
  That check is a hard failure, not a warning.
- A CI workflow running the same three checks.

## 4. Fill in `CLAUDE.md`

The most valuable section is *the rules that are expensive to break*: the
invariants a session could violate without noticing. You will not know them on
day one. Write what you know, and add to it every time something turns out to
have been load-bearing.

Keep the file short. It is loaded at the start of every session, so length is a
recurring cost.

## 5. Set the repository up

```sh
git init -b master
# first commit, then create the repo and push both branches
git branch dev && git push -u origin master dev

core/setup-repo.sh <owner>/<repo>
git config core.hooksPath .githooks
```

`setup-repo.sh` creates the blocked-work labels, makes the integration branch
the default, and protects the release branch. Adjust the required status check
names to match what your CI actually reports, or the protection rule will block
every merge waiting for a check that never runs.

## 6. Verify by cloning

Not optional, and not the same as believing it works — see
[`decisions/006-verify-the-clone.md`](decisions/006-verify-the-clone.md).

```sh
git clone <url> /tmp/verify && cd /tmp/verify
```

Then follow the README you just wrote, **in order**, using nothing you happen to
know. Check:

- the clone lands on the integration branch, with `CLAUDE.md`, `tool/` and
  `docs/` present
- `tool/doctor.sh` fails on the unset hooks path and names the exact command
- after the setup steps, the build and tests pass
- a deliberately malformed commit message is rejected
- `tool/worktree.sh new` **and `done`** both work — `done` is the path that
  never gets exercised during development

Fix what this finds before reporting the project ready. It always finds
something.

## What not to copy

The source project's own invariants. Rules like "every instant is stored in UTC"
or "no proprietary dependencies" are real and load-bearing *there*, and
meaningless noise anywhere else. `CLAUDE.md`'s rules section is written fresh
per project; only its shape is reused.
