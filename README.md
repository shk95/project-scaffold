# project-scaffold

Conventions for starting a software project that will be worked on by
short-lived agent sessions, on machines that come and go.

Not a framework and not a generator. It is a set of files worth copying, and —
more importantly — the reasons they are shaped the way they are.

## Why the reasons matter more than the files

Every rule here was earned by something going wrong. A rule stated without its
failure gets deleted by the next person who finds it inconvenient, and they will
be right to, because a rule with no reason attached is indistinguishable from
cargo cult.

So [`decisions/`](decisions/) is the actual content of this repository. The
templates are a convenience.

A sample:

| Rule | The failure that produced it |
| --- | --- |
| The default branch is the integration branch | A clone landed on the release branch and got none of the tooling — the entire session-onboarding setup was invisible to the situation it existed for |
| Secret scanning belongs in CI, not only in a hook | Hooks are per-clone configuration; a clone that skips the setup line commits with no scanning at all |
| "Done" must be mechanically checkable | Otherwise a session reports a milestone finished on the strength of a green build |
| State and findings are separate documents | Updating the state deletes the findings when they share a file |

## Using it

Point an agent session at [`SCAFFOLD.md`](SCAFFOLD.md). It asks what is being
built, then writes the files.

By hand: copy [`core/`](core/) into the new repository, add the overlay for the
stack from [`stacks/`](stacks/), and run `core/setup-repo.sh`.

## What is here

```
decisions/       Why each convention exists, and what went wrong without it
core/            Stack-agnostic: hooks, gitignore, doc templates, agent commands
stacks/flutter/  The Flutter overlay
stacks/nix/      The Nix overlay — home-manager, nix-darwin and NixOS configs
SCAFFOLD.md      The playbook an agent follows
```

The core hooks delegate their checks to `tool/checks/format`, `tool/checks/lint`
and `tool/checks/test`, which the stack overlay supplies. That is what keeps the
core actually stack-agnostic rather than nominally so.

## Honest limits

These conventions come from **one** project — a cross-platform Flutter alarm
clock. They have been used in anger there and nowhere else yet. The core is
written to be stack-agnostic, but "stack-agnostic" here means "nothing in it is
Flutter-specific", not "proven on four ecosystems".

That claim was not even fully true when it was written: the second stack to
use the core immediately found `setup-repo.sh` creating
`blocked/needs-android-device` for a project with no Android in it. Content
drifts stack-specific when only one stack ever exercises it, and the drift is
invisible from inside that stack.

The Flutter overlay is verified: built in anger, on the project these
conventions came from. The Nix overlay is only partly verified — see
[`stacks/nix/README.md`](stacks/nix/README.md) for exactly which part.
Overlays, and parts of overlays, belong here when someone has actually run
them, not before; where that line falls for Nix is written down rather than
implied.

## Licence

[MIT](LICENSE).
