# Nix overlay

Standalone home-manager, nix-darwin and NixOS configurations all live under
this one overlay rather than three separate ones: they share a flake, a
formatter, a linter and a verification model, and differ only in which
deployment target the flake declares. A single `flake.nix` can define any
combination of `homeConfigurations`, `darwinConfigurations` and
`nixosConfigurations` at once — the normal shape for a personal config
spanning several machines.

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

Name the blocked reasons this stack actually has when running
`core/setup-repo.sh`, one per system you cannot build locally:

```sh
BLOCKED_LABELS="needs-aarch64-darwin needs-nixos-host" \
  core/setup-repo.sh <owner>/<repo>
```

Prefer the full system string (`needs-aarch64-darwin`) over the kernel
(`needs-darwin`): on `x86_64-linux` an `aarch64-linux` configuration is
equally unbuildable, and a label saying `needs-linux` reads as satisfied by
the host that just skipped it.

## Verification is two tiers, and the tiers have different reach

This is the decision the rest of the overlay is built around.

| | Runs where | Catches |
| --- | --- | --- |
| **Tier 1 — eval** | every configuration, from any host | option typos, type errors, module assertions, bad imports |
| **Tier 2 — build** | only where the target system is this machine | packages that do not exist for that platform, derivations that fail |

Nix evaluates a configuration for a foreign system perfectly well; it just
cannot *realise* one. On an `x86_64-linux` box, a `darwinConfigurations` entry
evaluates all the way to a `.drv` path, and a bad option name in it fails
loudly — with suggestions. So **"I am on Linux, therefore the darwin config is
unverified" is only half true**, and treating it as fully true throws away the
cheap half of the verification.

`nix flake check` is neither tier. It validates the flake's shape and its
standard outputs, and does not look inside `homeConfigurations`,
`darwinConfigurations` or `nixosConfigurations` at all. A config repo running
only `nix flake check` is not checking its configurations — the bug that
produced this overlay's `nix.package` entry in `troubleshooting.md` sailed
through a green `nix flake check` and was caught by a plain `nix eval` of the
toplevel `drvPath`.

## The dangerous change is the shared one, not the platform-specific one

Editing a darwin-only module from Linux is an obvious gap; nobody is fooled by
it. Editing a module that *every* host imports is the one that hurts: the
Linux build goes green, the green covers half the surface, and green is what
gets believed. That is `decisions/003-done-must-be-mechanically-checkable.md`'s
"plausible code" in config form.

So `tool/checks/test` diffs the branch against `origin/dev` and names any
change whose blast radius reaches a configuration it could not build:

```
   homeConfigurations.user1               eval ✓ build ✓
   darwinConfigurations.mba               eval ✓ build —  (needs aarch64-darwin)

   ! darwinConfigurations.mba was not built here, and this branch changes:
     modules/common/packages.nix (shared)
```

Paste that block into the pull request. `decisions/003` already requires the
body to carry what was *not* verified; this makes the answer something the
tool produced rather than something the session claimed.

The blast-radius rule is a directory-name heuristic, not a dependency graph:
`darwin/` and `nixos/` path segments are platform-specific, and **everything
else counts as shared**. Wrong in the safe direction — a layout the rule has
never been taught over-warns instead of granting false confidence. Note that
`home/` is deliberately *not* treated as home-manager-only, because a
home-manager module is routinely imported by nix-darwin and NixOS as well.

For the heuristic to say anything useful, the layout has to carry the
distinction — `modules/common/`, `modules/darwin/`, `modules/nixos/`,
`hosts/<name>/` or similar. A single-flavour repo satisfies this trivially,
since everything in it is shared and buildable.

Warnings do not fail the check. A shared module reaching an unbuildable host
is the *normal* case in a multi-host config, and a gate that blocks every such
push only teaches people `--no-verify`. Eval and build failures do fail it.

## CI runs Linux only, and that is not the same as trusting the local run

No macOS runner. `tool/checks/test` already evaluates darwin configurations on
the Linux runner, and a macOS runner is billed at several times the Linux rate
to close a gap the person who owns the Mac closes for free the next time they
run `darwin-rebuild switch`. Record the gap; do not rent hardware to stare at
it.

But the Linux *build* stays in CI, and it is not redundant with the identical
command on the contributor's machine. A local build can pass because of that
machine's store, its `NIX_CONFIG` or its flake registry. CI's proves the flake
builds from nothing but the repository and `flake.lock` — which is
`decisions/006-verify-the-clone.md` in build form, and is the one thing no
local run can substitute for. This is also why
`decisions/002-hooks-are-opt-in-so-ci-must-backstop.md` still applies here in
full: the hook is for speed, CI is the thing that cannot be skipped.

## Other decisions specific to this stack

**The unix account and the git identity are separate variables, even when one
person owns both.** `user` (what `home.username` is set to) and
`gitname`/`gitmail` (what `programs.git` signs commits as) do not have to
match, and a flake that fuses them is why a WSL account named after a role
ends up signing commits as that role. Pass them separately through
`specialArgs`.

**`nix.package` must be set explicitly for standalone home-manager.** Only
`homeConfigurations` needs it — nix-darwin and NixOS already know which Nix
manages them. See `troubleshooting.md`.

**`flake.lock` is committed, never ignored.** It is the actual pin;
reproducibility is the entire point of this stack, and a repo that ignores its
lock file has none.

**`nix flake update` is not in `settings-additions.json`.** It rewrites
`flake.lock` to newer input revisions — a dependency-version decision, the
same category as `flutter pub upgrade`, which the Flutter overlay likewise
leaves off its allow-list.

**`home-manager switch`, `darwin-rebuild switch`, `nixos-rebuild switch` and
`nix-collect-garbage` are not on the allow-list either.** Everything listed
there inspects, builds or formats; these four mutate the running machine or
delete store paths, the same reasoning as core leaving out `git push`. Note
that a successful tier-2 build has already exercised option evaluation,
package resolution and the activation script's construction — activation adds
almost no verification value for the risk it carries.

## Honest limits

**Verified:** the two-tier model, end to end. `homeConfigurations` built on
WSL; a real `nix-darwin` configuration evaluated from Linux, including a
deliberately planted bad option caught with suggestions and an eval failure
correctly exiting non-zero; the skip-and-warn path exercised on a synthetic
two-flavour repo with a shared-module change; the missing-`origin` path
degrading to a printed note rather than silence.

**Not verified:** actually *building* a darwin or NixOS configuration, which
by definition needs those hosts. `nixos-rebuild`/`darwin-rebuild switch` have
never been run through these conventions. And the CI workflow has never been
watched passing on a real push — `DeterminateSystems/nix-installer-action` and
`magic-nix-cache-action` are used as documented, nothing more. Watch the first
run rather than trusting the YAML.

**Import-from-derivation defeats tier 1.** If a configuration uses IFD, then
evaluating it for a foreign system has to *build* something for that system
part-way through, and stops with `a 'aarch64-darwin' ... is required to build
..., but I am a 'x86_64-linux'`. Uncommon, but when it happens that
configuration drops to build-only verification on its native host. The entry
in `troubleshooting.md` names the message.

## What is not here

Secrets management (agenix, sops-nix) — add it when there is an actual secret
to manage. A NixOS-on-WSL path, deliberately out of scope until plain WSL plus
home-manager stops being enough. Darwin/homebrew interop and NixOS
`hardware-configuration.nix` generation, both real per-machine concerns this
overlay does not attempt to templatise.
