# Making this work with any agent tool

Notes toward decoupling these conventions from Claude Code, so a session driven
by Codex — or anything else — gets the same scaffold.

**Nothing here is decided or implemented.** This is the shape of the problem and
a leaning, written down before the work so the reasoning survives it. Read it as
a proposal, not as a record of what the repository does.

*"Portability" here means agent tools, not operating systems. Platform
portability is what `stacks/` is about, and the two are unrelated axes.*

## The surface is small

Worth establishing first, because it changes how ambitious this should be. The
conventions are prose, shell and YAML; almost none of it knows what is reading
it. Everything tool-specific:

| | What is actually tool-specific |
| --- | --- |
| `core/claude/settings.json` | Whole file — a Claude Code permission schema |
| `core/claude/commands/*.md` | Frontmatter and the slash-command packaging; the procedure inside is not |
| `core/templates/CLAUDE.md` | The **filename** and the auto-load assumption. The content is neutral |
| `core/gitignore` (2 lines) | `.claude/settings.local.json`, `.claude/.cc-writes/` |
| `stacks/*/settings-additions.json` (×3) | Same schema as above |
| `SCAFFOLD.md` | The copy table, step 4, and one line of the clone checklist |
| `stacks/*/README.md` (×3) | One line each in their copy tables |

`decisions/`, `core/githooks/`, `core/setup-repo.sh`, `core/tool/worktree.sh`,
`core/workflows/`, `core/templates/docs/` and every `tool/checks/` and
`tool/doctor.sh` are already neutral. So is the whole of `stacks/*/`
troubleshooting content.

That is roughly a dozen touch points. The risk in this work is not difficulty;
it is inventing a mechanism bigger than the problem.

## The orientation file is the only real design question

Claude Code reads `CLAUDE.md`. The cross-tool convention that has emerged
elsewhere is `AGENTS.md` — plain Markdown, no schema, deliberately just a file
agents agree to look at. Codex is the reason this matters here.

Three ways to have both, and the third is the one to beat:

**Duplicate the file.** Rejected on sight. This repository shipped a drift
between two copies of a hook and only just added `tool/checks/lint` to catch it;
proposing a second copy of the single most-edited document in every generated
project, one week later, would be choosing the failure we just paid for. If any
option that duplicates content wins anyway, `tool/checks/lint` has to cover the
pair — that is not optional.

**Symlink `CLAUDE.md` → `AGENTS.md`.** Cheap, and git stores it fine. It breaks
on Windows checkouts without developer mode or with `core.symlinks=false`, where
the link arrives as a text file containing a path. This repository ships a
PowerShell overlay for Windows hosts, so that is a real host, not a hypothetical
one.

**One real file plus a pointer.** `AGENTS.md` holds the content. `CLAUDE.md` is
one line that imports it. Claude Code supports `@path` imports inside
`CLAUDE.md`, so the pointer costs a line and there is nothing to keep in sync.
Works on Windows, survives a tool that has never heard of imports (a reader
still sees where to go), and the direction is right: the neutral name is the
original, the tool-specific one is the adapter.

**Leaning: the third.** Verify the import syntax against the current Claude Code
before committing to it — see *Before implementing* below.

## The allowlist: the format is tool-specific, the line is not

`core/claude/settings.json` is a Claude Code schema and cannot be shared. But the
valuable part of that file was never the schema — it is the sentence in its own
`$comment`:

> anything that cannot lose committed work or reach outside the machine

and the list of what was deliberately left off for that reason: `git push`,
`git reset --hard`, `git rebase`, `rm`, `gh release`, `gh repo`, plus each
overlay's additions — `nix flake update`, `home-manager switch`,
`Install-Module`, `flutter pub upgrade`.

That reasoning is portable to a tool with a completely different permission
model, including one that has no in-repo allowlist at all and works from
approval modes instead. So the split is:

- The **rule and its exclusions** move into prose, somewhere every tool's
  orientation file can point at.
- `settings.json` becomes one tool's *expression* of that rule, sitting beside
  whatever another tool needs.

This also fixes something that is already awkward: three
`stacks/*/settings-additions.json` files each restate the same reasoning in a
`$comment` array, which is JSON pretending to be a document.

## The commands: the procedure is portable, the packaging is not

`/start-work` and `/finish-work` are the most valuable Claude-specific things
here, and they are barely Claude-specific. Strip the two-line YAML frontmatter
and what is left is a numbered procedure that any agent — or a person — can
follow.

The tension, and it is the one unresolved thing in this document: a slash
command has to *contain* its content, so a neutral copy plus per-tool command
files reintroduces exactly the duplication rejected above. Three ways out, none
free:

1. **Per-tool files are the originals; the neutral prose is a summary that
   points at them.** No duplication, but the neutral path is second-class, which
   inverts what we want.
2. **Neutral file is the original; each tool's command file imports it.** Clean,
   but depends on each tool supporting imports inside a command, which Claude
   Code's `CLAUDE.md` does and a command file may not.
3. **`SCAFFOLD.md` tells you to concatenate**: take the neutral procedure, prepend
   the frontmatter your tool wants. Honest for a copy-by-hand repository that is
   explicitly *"not a framework and not a generator"*, and it puts the assembly
   at the one moment a human is already reading the playbook.

Leaning toward 3, with 2 if imports turn out to work in command files.

## A layout, if this happens

Mirror `stacks/`. That model already exists in this repository and already
carries the discipline this needs — pick one, per-overlay README, honest limits.

```
core/agents/README.md      What every agent session needs, tool-neutral:
                           the procedure, and the allowlist rule with its
                           exclusions
core/agents/AGENTS.md      The orientation template (today's core/templates/CLAUDE.md,
                           renamed and with nothing tool-specific left in it)
core/agents/claude/        settings.json, commands/, and the one-line CLAUDE.md
                           pointer
core/agents/codex/         Whatever Codex actually needs — when someone has run it
```

`stacks/*/settings-additions.json` then becomes `stacks/*/agents/claude/…`, or
stays where it is with a note. Not worth deciding until the rest is.

## What must not be rewritten

`decisions/001-default-branch-is-the-integration-branch.md` lists
`CLAUDE.md` and `.claude/settings.json` among the files a real clone did not
get. **That is an account of something that happened**, not a specification. It
names the files that were actually missing on that day. Renaming them there
would be falsifying a record to match a later decision, and the decision files
are the one thing in this repository that has to stay true.

The same applies to `stacks/nix/troubleshooting.md`, which points at the sandbox
note by its current path — that one is a live cross-reference and simply needs
updating, but only because the file genuinely moved.

## The honesty rule applies here too

`README.md` says overlays belong here when someone has actually run them, and
the three stack READMEs each draw a verified/unverified line in public. An
agent-tool overlay is the same kind of claim and deserves the same treatment:

**A Codex overlay written from documentation is not a Codex overlay.** It is
unverified until a real session has been driven through `/start-work`,
a piece of work, and `/finish-work` under that tool, on a real repository.
Ship it after that, with its own honest-limits section.

This may be worth a decision record of its own — `008`, that an integration is
claimed only for the tool a session was actually run under. But per
`decisions/README.md`, a decision is written *only when something has gone
wrong*, and nothing has here yet. Writing it now would be exactly the
preference-dressed-as-decision that file warns about. Leave it until a
documentation-derived overlay has actually misled someone.

## Before implementing, verify

None of these are assumptions this document is entitled to make:

- Does Claude Code's `@path` import work in `CLAUDE.md` in the current version,
  and does it work in a `.claude/commands/*.md` file?
- Does Claude Code now read `AGENTS.md` directly? If it does, the pointer file
  is unnecessary and this gets simpler.
- What does Codex actually read for repository context, and does it support
  anything equivalent to a slash command or an in-repo permission allowlist?
- Does any target tool object to a repository containing *both* `AGENTS.md` and
  `CLAUDE.md`?

Answer these against the shipping tools, not from memory or from this file. The
whole repository is an argument for finding out rather than assuming, and a
portability layer built on a guessed integration would be the most embarrassing
possible place to stop taking that seriously.
