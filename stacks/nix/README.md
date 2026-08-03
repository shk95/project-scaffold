# Nix overlay

For a Nix flake that configures the machine it is worked on: standalone
home-manager, NixOS, or both in one flake. Verified on standalone
home-manager under WSL.

**Scope: every configuration targets the host you run the checks on.** That is
true of a single-host repo and of WSL work, where everything is
`x86_64-linux` whether or not NixOS is involved. A configuration for another
system is refused by name rather than half-handled — see *Growing past one
host* below, which is a design note, not a feature.

## Copy

```
tool/checks/*            → tool/checks/        (chmod +x)
tool/doctor.sh            → tool/doctor.sh      (chmod +x)
workflows/ci.yml          → .github/workflows/  (replaces core/workflows/secret-scan.yml,
                                                 which it already includes as a job)
gitignore-additions       → append to .gitignore
settings-additions.json   → merge into .claude/settings.json
troubleshooting.md        → append to docs/troubleshooting.md
```

No SDK version to pin the way the Flutter overlay pins `.flutter-version`:
`flake.lock` already is that pin, for every input, and `tool/doctor.sh` checks
that flakes are enabled rather than checking a version number.

If the flake declares a `nixosConfigurations` for a host you do not activate
from, name that when running `core/setup-repo.sh`:

```sh
BLOCKED_LABELS="needs-nixos-host" core/setup-repo.sh <owner>/<repo>
```

## `nix flake check` does not check your configurations

This is the decision the overlay is built around, and it is not obvious.

`nix flake check` validates the flake's shape and its standard outputs. It does
**not** descend into `homeConfigurations`, `nixosConfigurations` or
`darwinConfigurations` — those are arbitrary attributes as far as it is
concerned. A repository whose CI runs only `nix flake check` is not checking
the thing it exists to produce.

`tool/checks/test` therefore forces each configuration's toplevel derivation
itself, in two tiers:

| | Catches |
| --- | --- |
| **eval** — force `.drvPath` | option typos, type errors, module assertions, bad imports |
| **build** — realise it | packages that do not exist, derivations that fail |

The split earned itself immediately: a missing `nix.package` in a standalone
home-manager config sailed through a green `nix flake check` and failed the
moment `.drvPath` was forced. That bug is in `troubleshooting.md`.

## Growing past one host

Not implemented, deliberately. Written down because the problem is real and
the shape of it is worth knowing before you hit it.

Once a flake declares configurations for more than one system, the checks stop
being able to build them all — Nix does not cross-compile to Darwin, and an
`aarch64-linux` closure needs an `aarch64-linux` builder. Evaluation still
works from anywhere, which is more useful than it sounds: a `darwinConfigurations`
entry evaluates to a `.drv` from Linux, and a bad option name in it fails
loudly, with suggestions. So the honest position is not "unverified" but
"evaluated, not built".

The trap that follows is specific. Editing a platform-specific module from the
wrong host is an obvious gap and fools nobody. Editing a module that *every*
host imports is the dangerous one: the build that can run goes green, the green
covers half the surface, and green is what gets believed. Whatever detects that
has to answer "does this change reach a configuration I could not build?",
which needs the repository's layout to distinguish shared modules from
platform-specific ones — and that layout is a decision the repository has not
made yet at the point this overlay is copied in.

An earlier version of this overlay shipped a directory-name heuristic for it.
It was removed: it could not fire in any repository this overlay had been used
on, and it guessed at a layout convention rather than following one that
existed. Build it when there is a real multi-host repository to build it
against, and it will fit that repository instead of an imagined one.

## Other decisions specific to this stack

**The unix account and the git identity are separate variables, even when one
person owns both.** `user` (what `home.username` is set to) and
`gitname`/`gitmail` (what `programs.git` signs commits as) do not have to
match, and a flake that fuses them is why an account named after a role or a
machine ends up authoring commits. Pass them separately through `specialArgs`.

**`nix.package` must be set explicitly for standalone home-manager.** Only
`homeConfigurations` needs it — NixOS and nix-darwin already know which Nix
manages them. See `troubleshooting.md`.

**`flake.lock` is committed, never ignored.** It is the actual pin;
reproducibility is the entire point of this stack, and a repo that ignores its
lock file has none.

**CI's build is not redundant with the local one.** A local build can pass
because of that machine's store, its `NIX_CONFIG` or its flake registry. CI's
proves the flake builds from nothing but the repository and `flake.lock` —
`decisions/006-verify-the-clone.md` in build form, and the one thing no local
run substitutes for. This is also why
`decisions/002-hooks-are-opt-in-so-ci-must-backstop.md` applies here in full:
the hook is for speed, CI is what cannot be skipped.

**No binary cache action.** `magic-nix-cache-action` now needs a FlakeHub
account; without one it caches nothing, writes an error-level annotation onto
every green run, and costs time — 6m39s with it, 1m23s and 1m28s without, same
repository and same checks. Add a cache deliberately if builds get slow, rather
than carrying a broken one.

**`nix flake update` is not in `settings-additions.json`.** It rewrites
`flake.lock` to newer input revisions — a dependency-version decision, the same
category as `flutter pub upgrade`, which the Flutter overlay likewise leaves
off its allow-list.

**Neither are the commands that mutate the machine** — `home-manager switch`,
`nixos-rebuild switch`, `nix-collect-garbage`. Everything on the allow-list
inspects, builds or formats, the same reasoning as core leaving out
`git push`. A successful build has already exercised option evaluation,
package resolution and the activation script's construction, so activation
adds little verification for the risk it carries.

## Honest limits

**Verified:** the two-tier model end to end on standalone home-manager under
WSL, including an eval failure correctly exiting non-zero; the CI workflow
watched passing on real pull requests, with the build job taking about a
minute and a half.

**Not verified:** `nixosConfigurations` — nothing here has built or activated
one. The NixOS paths are written from how the module system is documented to
work and should be read as a starting point to correct against real use.

**One defect this overlay shipped with, for calibration.** `tool/doctor.sh`
asks the flake for its own metadata to test whether `nix-command` and `flakes`
are on. Good probe — `nix config show` needs nix-command in order to inspect
nix-command, so it cannot answer. But the first version discarded the error and
reported *every* failure as "flakes are not enabled", so a read-only
`~/.cache/nix` sent you to export a variable that could not help. Found by
control experiment, not by reading, and only because a sandbox happened to
block the cache. The fix splits the verdict three ways, including
could-not-tell. Assume the rest of this overlay contains its share of the same
thing: a fallback branch that is one of the real answers rather than an
admission.

## What is not here

Secrets management (agenix, sops-nix) — add it when there is an actual secret
to manage. Multi-host and cross-system verification, per *Growing past one
host*. NixOS `hardware-configuration.nix` generation, a per-machine concern
this overlay does not attempt to templatise.
