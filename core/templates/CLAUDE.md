# Working on this repository

<!-- Loaded automatically at the start of every agent session, so it costs
     context every time. Keep it short and high-signal: orientation and the
     rules that are expensive to break. Detail belongs in docs/, pointed at
     from here rather than included. -->

<ONE OR TWO SENTENCES: what this is and what it is built with.>

## Start here, every session

1. `tool/doctor.sh` — verifies the toolchain and that the git hooks are enabled.
   Do not skip it: a clone does not have hooks until `core.hooksPath` is set,
   and a wrong toolchain version fails in confusing ways much later.
2. `gh issue list --label blocked` — work a previous session could not finish
   because it needed something this host may now have. Check whether any is now
   unblocked before starting something new.
3. `docs/status.md` — current state, and the decisions that are expensive to
   reverse.

Then pick work from the milestone table in `README.md`.

**When something breaks in a way that makes no sense**, grep
`docs/troubleshooting.md` for the error text before investigating — its headings
are the literal messages. Do not read it end to end; it is a lookup table. Add
to it only when something cost you real time *and* will recur.

**If you are an agent, suspect your own sandbox first.** A shell tool that
sandboxes filesystem access typically does it with a mount namespace, bind-
mounting over the paths it denies. Inside that namespace `git status` can list
files nobody created — often `/dev/null` character devices wearing the names of
home-directory dotfiles — `git add -N .` can refuse the tree with *can only add
regular files, symbolic links or git-directories*, and git can warn *unable to
access '.gitmodules': Permission denied* while otherwise working. None of it is
true of the disk and none of it is reproducible by a person in a terminal. The
check is always the same: **run the command again outside the sandbox and
compare.** If the two disagree, the sandbox is the subject, not the repository.

## The rules that are expensive to break

<!-- The invariants a session could violate without noticing. Each should say
     what breaks, not just what to do. Three to six of them; a longer list
     stops being read. -->

- **<INVARIANT>** — <what goes wrong when it is violated>
- **<INVARIANT>** — <what goes wrong when it is violated>

## Workflow

**Everything written into this repository is in English** — documentation,
commit messages, code comments, issue and pull request text. <Delete this if it
does not apply; keep it if the project will be public.>

Branches: `master` (released) ← `dev` (integration) ← `feature/<name>` and
`fix/<name>`. `dev` is the default branch, so a clone is already on it. Branch
from `dev`, merge back to `dev`. Never commit to `master` directly — it is
protected and takes a pull request with CI passing.

Commits are [Conventional Commits](https://www.conventionalcommits.org); the
`commit-msg` hook rejects anything else.

Finishing a piece of work means meeting `docs/definition-of-done.md`. Anything
in it you cannot verify on this host is not a reason to skip it — open a blocked
issue instead, labelled `blocked` plus the specific reason, and say so in the
pull request.

## This host

<!-- Anything about the environment that will otherwise waste a session's time:
     sandbox restrictions, tools that need a wrapper, paths that are not
     standard. Delete the section if there is nothing. -->

## Parallel sessions

Use a worktree per branch rather than switching branches under a running
session:

```sh
tool/worktree.sh new <name> feature
tool/worktree.sh list
tool/worktree.sh done <name>
```

Worktrees share `.git`, so the hooks configuration carries over automatically.

**What does not parallelise:** <shared devices, a running instance of the app,
anything writing to one fixed path>. Only one session may hold those at a time.

## Layout

| Path | What lives there |
| --- | --- |
| `<path>` | <what> |
| `docs/definition-of-done.md` | What "finished" means, per milestone |
| `docs/status.md` | Current state and the decisions behind it |
| `docs/troubleshooting.md` | Errors that already cost someone an afternoon. Grep, don't read |
