#!/bin/sh
#
# Checks this machine can analyse, test and commit the project — and says
# plainly what is missing when it cannot.
#
# Run it at the start of a session. Two of the checks below exist because the
# failure they catch is silent: a clone with no git hooks commits without a
# secret scan, and a PowerShell profile that prints corrupts every command whose
# stdout is a pipe rather than a screen — including git over SSH.

cd "$(dirname "$0")/.." || exit 1

red='\033[31m'; yellow='\033[33m'; green='\033[32m'; dim='\033[2m'; off='\033[0m'
failed=0

ok()   { printf "  ${green}✓${off} %s\n" "$1"; }
warn() { printf "  ${yellow}!${off} %s\n     ${dim}%s${off}\n" "$1" "$2"; }
bad()  { printf "  ${red}✗${off} %s\n     ${dim}%s${off}\n" "$1" "$2"; failed=1; }

echo "Toolchain"

# Windows first: on WSL both builds may be present, and the Windows one is the
# interpreter the installed copy runs under.
PWSH=""
for candidate in pwsh.exe pwsh; do
  if command -v "$candidate" >/dev/null 2>&1; then PWSH=$candidate; break; fi
done

if [ -n "$PWSH" ]; then
  ver=$("$PWSH" -NoProfile -NonInteractive -Command '$PSVersionTable.PSVersion.ToString()' 2>/dev/null | tr -d '\r')
  major=${ver%%.*}
  if [ -n "$major" ] && [ "$major" -ge 7 ] 2>/dev/null; then
    ok "$PWSH $ver"
  else
    # 5.1 is not a lesser version of the same thing here. It reads a BOM-less
    # UTF-8 file as ANSI, so any script with a non-ASCII character fails to
    # parse, reporting a syntax error that has nothing to do with the syntax.
    bad "PowerShell $ver is too old" "This stack is pwsh 7 only. Install: https://aka.ms/powershell"
  fi
else
  bad "PowerShell 7 not on PATH" "Install: https://aka.ms/powershell"
fi

if [ -n "$PWSH" ]; then
  "$PWSH" -NoProfile -NonInteractive -Command \
    'if (Get-Module -ListAvailable -Name PSScriptAnalyzer) { exit 0 } else { exit 1 }' >/dev/null 2>&1 \
    && ok "PSScriptAnalyzer" \
    || bad "PSScriptAnalyzer not installed — tool/checks/lint and format cannot run" \
           "Install-Module PSScriptAnalyzer -Scope CurrentUser"

  # Windows ships Pester 3.4.0 in the system module path, and it stays there
  # after Pester 5 is installed. Asking for the version rather than for the
  # module is the difference between a real answer and a misleading one.
  pester=$("$PWSH" -NoProfile -NonInteractive -Command \
    '(Get-Module -ListAvailable -Name Pester | Sort-Object Version -Descending | Select-Object -First 1).Version.ToString()' \
    2>/dev/null | tr -d '\r')
  case "$pester" in
    "")      warn "Pester not installed" "Only needed once the project has *.Tests.ps1. Install-Module Pester -MinimumVersion 5.0 -Scope CurrentUser -Force" ;;
    [1-4].*) warn "Pester $pester is too old for tool/checks/test" "Install-Module Pester -MinimumVersion 5.0 -Scope CurrentUser -Force (3.4.0 ships with Windows and does not go away)" ;;
    *)       ok "Pester $pester" ;;
  esac
fi

echo
echo "Non-interactive output"
# The check that exists because its failure is invisible until it is expensive.
#
# PowerShell has no interactive/non-interactive profile split — no
# $PROFILE.Interactive, and -NonInteractive does not suppress it. So a profile
# that prints, prints into every captured pipe. When Windows OpenSSH's
# DefaultShell is pwsh, that includes `ssh host <command>`, scp, sftp and
# therefore git's transport, whose stdout is the pack protocol channel:
#
#   fatal: protocol error: bad line length character:  Lo
#
# Loading the profile is the point, so this is the one call here without
# -NoProfile.
if [ -n "$PWSH" ]; then
  leak=$("$PWSH" -Command 'exit 0' 2>/dev/null | wc -c | tr -d ' ')
  if [ "${leak:-0}" -eq 0 ] 2>/dev/null; then
    ok "the PowerShell profile is silent when stdout is a pipe"
  else
    bad "the PowerShell profile writes ${leak} byte(s) to stdout in a non-interactive session" \
        "Guard it: if (-not [Console]::IsOutputRedirected) { <the banner> }. Until then git over SSH to this machine fails with 'bad line length character'. Find the culprit with: pwsh -Command 'exit 0' | head"
  fi
fi

# Informational: whether this machine is even exposed to the failure above.
if command -v reg.exe >/dev/null 2>&1; then
  shell=$(reg.exe query 'HKLM\SOFTWARE\OpenSSH' /v DefaultShell 2>/dev/null | tr -d '\r' | awk '/DefaultShell/ {$1="";$2="";print substr($0,3)}')
  case "$shell" in
    "")     printf "  ${dim}· OpenSSH DefaultShell not set — ssh sessions get cmd.exe, which loads no profile${off}\n" ;;
    *pwsh*) printf "  ${dim}· OpenSSH DefaultShell is pwsh, so the check above applies to this machine${off}\n" ;;
    *)      printf "  ${dim}· OpenSSH DefaultShell: %s${off}\n" "$shell" ;;
  esac
fi

echo
echo "Version control"

hooks=$(git config core.hooksPath 2>/dev/null)
if [ "$hooks" = ".githooks" ]; then
  ok "git hooks enabled"
else
  # A hard failure, not a warning — see decisions/002 upstream. Without this a
  # clone commits with no formatting check, no lint and no secret scan.
  bad "git hooks are NOT enabled" "Run: git config core.hooksPath .githooks"
fi

# A .sh file that round-trips through Windows arrives in WSL with CRLF and dies
# with `$'\r': command not found`. Converting inside the installer only protects
# the copies that go through the installer.
if [ -n "$(find . -name '*.sh' -not -path './.git/*' -print -quit 2>/dev/null)" ]; then
  if [ -f .gitattributes ] && grep -q 'eol=lf' .gitattributes 2>/dev/null; then
    ok "shell scripts pinned to LF in .gitattributes"
  else
    warn "the repository has .sh files but .gitattributes does not pin line endings" \
         "Add: *.sh text eol=lf — otherwise a round trip through Windows breaks them in WSL"
  fi
fi

command -v gitleaks >/dev/null 2>&1 && ok "gitleaks" \
  || warn "gitleaks not installed — commits will not be scanned for secrets" "CI scans too, but only after you have pushed."

command -v gh >/dev/null 2>&1 && ok "gh" \
  || warn "gh not installed — cannot read or file blocked issues" "Install: https://cli.github.com"

echo
if [ "$failed" -eq 1 ]; then
  printf "${red}Not ready.${off} Fix the ✗ items above before starting work.\n"
  exit 1
fi
printf "${green}Ready.${off}\n"
