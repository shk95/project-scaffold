<!-- Append to docs/troubleshooting.md. Headings are the literal error text so
     they can be found by grep. -->

## Nix

### `A corresponding Nix package must be specified via 'nix.package' for generating nix.conf.`

Standalone home-manager (no NixOS or nix-darwin underneath) cannot infer which
Nix binary should generate `nix.conf` the way the OS-level modules can. Set
`nix.package = pkgs.nix;` in whichever module sets `nix.settings`. Only
`homeConfigurations` needs this — nix-darwin and NixOS already know.

### `Path 'flake.nix' in the repository "..." is not tracked by Git`

Flakes only see files known to git — an untracked file is invisible to flake
purity even when it is sitting right next to a tracked one. Before the first
`nix flake check` / `nix build` on brand-new files:

```sh
git add -N <the new files>
```

`-N` (intent-to-add) is enough; a full `git add` is not required yet. Name the
paths rather than running `git add -N .` — it fails outright the moment the
tree contains anything that is not a regular file or symlink, and the whole
command aborts instead of adding the files you actually meant.

An earlier version of this entry blamed "a stray character device masking a
dotfile", which is what the failure looks like from inside an agent sandbox.
Nothing is on disk: the devices are bind mounts in the agent's own mount
namespace, and `find . -type c` outside the sandbox returns nothing. The advice
above still holds — an agent runs inside that namespace, so `git add -N .`
really does abort there — but do not go hunting the repository for a device
node to delete. See the sandbox note in `core/templates/CLAUDE.md`.

### `nix flake check` passes but the configuration is broken

`nix flake check` validates the flake's shape and its standard outputs. It does
not descend into `homeConfigurations`, `nixosConfigurations` or
`darwinConfigurations` — those are arbitrary attributes as far as it is
concerned. Forcing the toplevel derivation is what actually evaluates them:

```sh
nix eval --raw '.#homeConfigurations."<name>".activationPackage.drvPath'
nix eval --raw '.#nixosConfigurations."<name>".config.system.build.toplevel.drvPath'
```

`tool/checks/test` does this for every configuration.

### `tool/doctor.sh`: `could not ask the flake whether nix-command works`

The doctor could not run `nix flake metadata`, and the failure was *not* the
experimental-features flag — so exporting `NIX_CONFIG` will not clear it. The
rest of the line is the root cause nix reported; act on that.

Seen so far: a read-only `~/.cache/nix` (agent sandboxes deny it), no network,
and an untracked `flake.nix`. Each of these used to be reported as
"nix-command/flakes not enabled by default", which sent you to a variable that
could not help.

### statix: `Found empty pattern in function argument`

A module written as `{...}: { ... }` when nothing from the module arguments is
used. statix wants `_: { ... }` instead — identical behaviour, but it does not
read as attrset-destructuring for a value that is never destructured. Modules
that do use some arguments (`{pkgs, ...}: ...`) are unaffected.

### deadnix reports unused code but `tool/checks/lint` still passes

deadnix's default exit code is 0 regardless of findings. The check must pass
`--fail` (or `-f`), or the check is cosmetic.

### `evaluation warning: The default value of 'programs.X.Y' has changed ... because 'home.stateVersion' is less than "..."`

Cosmetic, but recurs on every build until addressed. Either pin the option
explicitly (keeps the old behaviour, silences the warning) or bump
`stateVersion` deliberately after reading the home-manager release notes for
what else changes with it — pinning is the lower-risk fix in the middle of
unrelated work.
