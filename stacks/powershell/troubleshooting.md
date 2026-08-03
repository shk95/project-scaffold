<!-- Append to docs/troubleshooting.md. Headings are the literal error text where
     one exists, so they can be found by grep; where the failure is silent the
     heading is the observable symptom instead. -->

## PowerShell

### `fatal: protocol error: bad line length character:  Lo`

Something in `$PROFILE` printed into a non-interactive SSH session, and git read
it as a pack protocol length header. The four characters after the colon are the
start of whatever was printed — a banner, a MOTD, a `Write-Host` left in from
debugging.

Windows OpenSSH runs the shell in `HKLM\SOFTWARE\OpenSSH\DefaultShell` for
`ssh <host> <command>`, `scp` and `sftp`, and PowerShell loads `$PROFILE` for
all of them. There is no non-interactive profile to move the line into — the
profile has to test for itself:

```powershell
if (-not [Console]::IsOutputRedirected) { & '<the banner>' }
```

Confirm the machine is clean with `pwsh -Command 'exit 0' | wc -c`, which must
be 0. `tool/doctor.sh` runs that. `Write-Host` is not exempt from this; it
reaches stdout through the console host.

### The renderer prints nothing when run from a script or an agent tool

Expected, if it guards itself with `[Console]::IsOutputRedirected` per the entry
above — anything that captures output is redirected by definition. Use the
script's `-Force` (or `-f`) escape hatch. Zero bytes here is not a crash, and
mistaking it for one costs a debugging session.

### `The string is missing the terminator` — but the quotes are balanced

Windows PowerShell 5.1 reading a BOM-less UTF-8 file. It decodes as ANSI, so
every non-ASCII character becomes mojibake and the parse fails somewhere
unrelated to the real problem. pwsh 7 reads the same file correctly.

Check which interpreter actually ran. A scheduled task, a `.cmd` shim or a
`#!` line naming `powershell.exe` gets 5.1 even when `pwsh` is on your PATH, so
this shows up in the installed copy while the repository works fine. Add
`#Requires -Version 7.0` to fail with the real reason, and resolve `pwsh.exe`
by absolute path when writing a task or a shim.

### `The file could not be read: The specified path is invalid.` naming `Microsoft.PowerShell.Core\FileSystem::\\wsl.localhost\...`

`pwsh.exe` invoked from a WSL directory. The Windows process lands on a UNC cwd,
and `Resolve-Path` returns a *provider-qualified* path
(`Microsoft.PowerShell.Core\FileSystem::\\wsl.localhost\...`) that .NET APIs
such as `Parser::ParseFile` cannot open, while cmdlets can. Use `.ProviderPath`,
or copy the files under `C:\Users\<you>\AppData\Local\Temp\` and work there.

That temp path is also the answer to the other half of the problem: WSL's
`$TMPDIR` is not visible from Windows, so it cannot be used to hand files to a
Windows process.

### `<3>WSL (…) ERROR: UtilConnectUnix:526: socket failed 1`

WSL interop refused. Calling a Windows binary from WSL goes over a unix socket,
and an agent sandbox that restricts socket access blocks it. Nothing to do with
the binary being called. Re-run outside the sandbox.

### `$'\r': command not found` / `set: pipefail: invalid option name`

A `.sh` file that crossed the Windows boundary and picked up CRLF. Repository
files can be pure LF and this still happens, because the download or the editor
did the conversion.

`*.sh text eol=lf` in `.gitattributes` is the fix that holds. Converting inside
the installer only protects the copies that go through the installer — a user
who runs the downloaded file directly bypasses it.

### A profile or hook file grows enormously each time the installer runs

`-replace` is `Regex.Replace`, and the *replacement* string has substitutions
too: `` $' `` is everything after the match, `$_` the whole input, `` $` ``
everything before. A hook template containing PowerShell variables therefore
splices the file into itself, and it compounds on every run. The first run looks
fine because it takes the `Add-Content` path.

Edit marker blocks line by line instead of with a regex. Then there is no
replacement string to interpret.

### A helper function is never called, and the previous command runs instead

PowerShell resolves **alias → function → cmdlet → executable**. Single and
double letter names collide with built-in aliases — `r` is `Invoke-History`, so
`function R` is unreachable and every call replays history. Under `-NoProfile`
the history is empty and it merely errors; in an interactive session it silently
re-runs whatever you last typed, once per call.

Do not name helpers one or two characters.

### A script-scope variable is empty inside a function that never touched it

Variable names are case-insensitive and scoping is dynamic, and `foreach` does
not open a scope. So `foreach ($g in $items)` in a caller creates a local `$g`
that shadows a script-scope `$G` for every function called from there —
including functions that have no idea either exists.

Only that direction is dangerous: assigning inside a function creates a fresh
local and cannot reach the parent. Name script-scope variables so they cannot
collide with a caller's locals.

### `auditpol` rejects a subcategory name that is spelled correctly

Audit subcategory names are localised. `/subcategory:"Logon"` does not exist on
a Korean install. Use the GUID — `{0CCE9215-69AE-11D9-BED3-505054503030}` —
which is stable across languages.

The same applies to every built-in identity: `BUILTIN\Users` is `사용자` there.
Use SIDs (`S-1-5-32-545`, `S-1-5-18`) in ACL code.
