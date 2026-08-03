# PowerShell overlay

For a PowerShell 7 project that installs itself onto a Windows machine —
a scheduled task, a service, a shell hook — rather than one that ships a
module to a gallery. Verified on two such projects, both driven from WSL
against a Windows 11 host.

**Scope: pwsh 7 only.** Windows PowerShell 5.1 is not a target, and the
overlay assumes `#Requires -Version 7.0` at the top of every script. That is
not a preference; see *5.1 does not degrade gracefully* below.

## Copy

```
tool/checks/*             → tool/checks/        (chmod +x)
tool/doctor.sh            → tool/doctor.sh      (chmod +x)
workflows/ci.yml          → .github/workflows/  (replaces core/workflows/secret-scan.yml,
                                                 which it already includes as a job)
gitignore-additions       → append to .gitignore
settings-additions.json   → merge into .claude/settings.json
troubleshooting.md        → append to docs/troubleshooting.md
```

`tool/checks/_pwsh` is not a check — it resolves the interpreter and is sourced
by the other three. The core pre-commit hook runs `format`, `lint` and `test`
by name, so it never picks the helper up.

The checks are POSIX `sh`, like the core hooks they are called from. On a
Windows-only workstation that means Git Bash or WSL; the scaffold already
assumes a POSIX shell for `.githooks/`, so this adds no new requirement.

## A profile is not a safe place to print

This is the decision the overlay is built around, and it is the one that cost
the most to find, because the symptom appears somewhere else entirely.

A project that greets you on login puts a call in `$PROFILE`. Later, `git
fetch` against a repository on that machine dies:

```
fatal: protocol error: bad line length character:  Lo
```

`Lo` is the start of the banner. Nothing in that message points at a profile.

The chain: Windows OpenSSH runs the shell named by
`HKLM\SOFTWARE\OpenSSH\DefaultShell` — which a banner project sets to
`pwsh.exe`, because the banner does not load under `cmd.exe`. From then on
`ssh <host> <command>`, `scp` and `sftp` all go through pwsh, and
**PowerShell loads `$PROFILE` even for those.** git's transport is one of those
commands, and its stdout is the pack protocol channel, not a screen. git reads
the first four bytes as a length header, finds text, and dies.

What makes this specific to this stack is the missing distinction. `bash` has
one: a non-interactive shell skips `.bashrc`, and the idiom
`[[ $- == *i* ]] || return` at the top of an rc file is decades old for exactly
this reason. **PowerShell has no interactive/non-interactive profile split at
all** — there is no `$PROFILE.Interactive`, and no flag the profile can read to
find out. `-NonInteractive` does not suppress it either. The profile has to
work out for itself whether anyone is looking.

`[Console]::IsOutputRedirected` is what answers that, and it is exact.
Measured on Windows 11 with OpenSSH's default shell set to pwsh 7.6.4:

| Session | `IsOutputRedirected` | `$env:SSH_TTY` |
| --- | --- | --- |
| `ssh host <command>` — no pty, what git uses | `True` | unset |
| `ssh host` — pty allocated, a human logging in | `False` | `windows-pty` |

`Write-Host` is not exempt. It writes to the host rather than the success
stream, which is often described as "not stdout", but the console host puts it
on stdout all the same — that is how the banner reached git in the first place.

### The guard goes in the thing that prints

Not in the hook. One of the two projects this overlay comes from had the guard
in the hook its installer generated, from the first commit, and still broke:
the user hand-wrote the hook after an unrelated installer bug ate their
profile, and a hand-written hook is `& '<path>'` with nothing around it. That
is also exactly what someone writes after reading a README.

So the entry point guards itself:

```powershell
if ([Console]::IsOutputRedirected -and -not $Force) { return }
```

and the equivalent on any shell script that a login file might source:

```sh
[ -t 1 ] || exit 0
```

Keep the guard in the generated hook too — two layers, and the hook's copy is
where a reader learns the reason.

`-Force` matters more than it looks. Without an escape hatch, every way of
*checking* the renderer stops working, because a session that captures output
is redirected by definition. An agent running the renderer through a tool sees
zero bytes and reads it as a crash. Ship the hatch and document it next to the
verification command.

### The check that catches it

```sh
pwsh -Command 'exit 0' | wc -c        # must be 0
ssh <host> 'Write-Output OK'          # must be exactly one line
```

`tool/doctor.sh` runs the first one. It is worth running on any machine whose
profile you did not write yourself: the leak is silent until the day something
needs a clean pipe.

## Other decisions specific to this stack

**5.1 does not degrade gracefully.** Windows PowerShell 5.1 reads a file with
no BOM as ANSI, so a script saved as BOM-less UTF-8 containing any non-ASCII
character fails to *parse* — not to run. One project shipped an installer whose
scheduled task and `.cmd` shim both invoked `powershell.exe`; the install path
had never worked, and the error pointed at syntax rather than at encoding.
Write `#Requires -Version 7.0`, and resolve `pwsh.exe` by absolute path
everywhere a task or shim names an interpreter.

**A scheduled task running as SYSTEM does not inherit your PATH.** Resolve
`pwsh.exe` at install time and store the absolute path in the task action.
`Get-Command pwsh` at install time, falling back to
`$env:ProgramFiles\PowerShell\7\pwsh.exe`.

**`-replace` is `Regex.Replace`, including the replacement string.** `$_`,
`` $' ``, `` $` `` and `$1` are all substitutions *in the replacement*. Feeding
it a hook template that contains PowerShell variables makes a file that grows
exponentially each run — `` $' `` means "everything after the match", so the
file re-inserts itself. Marker-block editing should be line-based, not regex,
and then the question does not arise. This destroyed a user's profile in one of
the source projects.

**Aliases resolve before functions.** `Get-Alias r` is `Invoke-History`, so
`function R { }` is unreachable and every call re-runs the previous command
instead. In a login banner rendering seven rows, that is seven silent history
replays per login. Do not name helpers one or two characters.

**Variables are case-insensitive and scoping is dynamic.** `$g` and `$G` are
one variable, and `foreach` does not open a scope — so a caller's
`foreach ($g in ...)` shadows a script-scope `$G` for every function it calls,
including ones it never mentions. Name script-scope variables so they cannot
collide with a caller's locals (`$Glyph`, not `$G`).

**Every Windows identity and policy name is localised; use SIDs and GUIDs.**
`BUILTIN\Users` is `사용자` on a Korean install, and
`auditpol /set /subcategory:"Logon"` fails there. `S-1-5-32-545` and
`{0CCE9215-69AE-11D9-BED3-505054503030}` work everywhere. This is not a
theoretical concern on a machine whose OS language you did not choose.

**Write files as UTF-8 without a BOM, and set `.gitattributes`.** In pwsh 7
`-Encoding utf8` already means `utf8NoBOM`; the trap is `Set-Content` on a
round-trip introducing CRLF into a `.sh` file that WSL then refuses to run
(`$'\r': command not found`). `*.sh text eol=lf` in `.gitattributes` is the
durable fix; converting during install only helps the copies that go through
the installer.

**An installer that adds a hook must remove it.** Uninstall that leaves the
profile pointing at a deleted script is worse than no uninstall — the shell
errors on every start. Delimit with markers, strip between them on removal, and
preserve whatever else the file holds. The same marker contract makes install
idempotent.

**`Install-Module` is not on the allow-list.** It writes to the machine outside
the repository, and `-Scope CurrentUser` still installs into the user's module
path. `tool/doctor.sh` names the command to run; a human decides to run it.
Same reasoning as core leaving out `git push`.

## Honest limits

**Verified:** the profile/pipe finding end to end, on Windows 11 with pwsh
7.6.4 and OpenSSH's default shell set to pwsh — the failure reproduced, both
guards written, and `git ls-remote` over SSH then returning refs where it had
died before.

Both of the checks that need no extra module were exercised against a real
project, from a WSL working directory, and both were confirmed by control
experiment rather than by reading:

| | Negative | Positive |
| --- | --- | --- |
| `tool/doctor.sh` profile probe | 0 bytes with the guard in place | 19 bytes with an unguarded `Write-Host` injected, restored byte-for-byte after |
| `tool/checks/lint` parser pass | `✓ parsed 3 file(s)`, exit 0 | a deliberately unterminated string reported at the right file and line, exit 1 |

The rest of `tool/doctor.sh` was watched producing each of its verdicts on that
machine, including correctly reading the OpenSSH default shell out of the
registry and correctly refusing Pester 3.4.0.

**Not verified:** everything that needs PSScriptAnalyzer or Pester. Neither is
installed on the machine this overlay was written on — `Install-Module` there
would have been a change to someone's workstation made in passing, which is the
kind of thing this repository's `settings-additions.json` deliberately refuses
to allow. The analyzer and Pester invocations are written from their
documentation and should be treated as a starting point, not as something that
has been run. The CI workflow has never executed; the `windows-latest` runner
ships both modules, so it is the cheapest place to find out.

**Not attempted:** anything about modules published to the PowerShell Gallery —
manifests, versioning, `Publish-Module`, signing. This overlay is for projects
that install onto a machine.

## What is not here

Code signing and execution policy. Both source projects work around policy with
`-ExecutionPolicy Bypass` at the call site, which is honest for a local install
and wrong for anything distributed; a project that distributes needs a
certificate, and that is a decision with a purchase order attached rather than
a file to copy.
