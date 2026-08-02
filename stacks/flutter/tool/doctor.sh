#!/bin/sh
#
# Checks this machine can build, test and commit the project — and says plainly
# what is missing when it cannot.
#
# Run it at the start of a session. The failure it exists to prevent is the
# quiet one: a clone with no git hooks commits without a secret scan, and a
# mismatched SDK version fails much later in a way that looks like a code
# problem.

cd "$(dirname "$0")/.." || exit 1

red='\033[31m'; yellow='\033[33m'; green='\033[32m'; dim='\033[2m'; off='\033[0m'
failed=0

ok()   { printf "  ${green}✓${off} %s\n" "$1"; }
warn() { printf "  ${yellow}!${off} %s\n     ${dim}%s${off}\n" "$1" "$2"; }
bad()  { printf "  ${red}✗${off} %s\n     ${dim}%s${off}\n" "$1" "$2"; failed=1; }

echo "Toolchain"

wanted=$(cat .flutter-version 2>/dev/null)
if ! command -v flutter >/dev/null 2>&1; then
  bad "flutter not on PATH" "Install Flutter $wanted, or add it to PATH."
else
  found=$(flutter --version 2>/dev/null | head -1 | awk '{print $2}')
  if [ "$found" = "$wanted" ]; then
    ok "flutter $found"
  else
    warn "flutter $found, but this project pins $wanted" \
         "CI builds on $wanted. Differences will show up there, not here."
  fi
fi

command -v dart >/dev/null 2>&1 && ok "dart" \
  || bad "dart not on PATH" "It ships with Flutter; check the Flutter install."

echo
echo "Version control"

hooks=$(git config core.hooksPath 2>/dev/null)
if [ "$hooks" = ".githooks" ]; then
  ok "git hooks enabled"
else
  # A hard failure, not a warning. Without this a clone commits with no
  # formatting check, no analysis and no secret scan at all.
  bad "git hooks are NOT enabled" "Run: git config core.hooksPath .githooks"
fi

if command -v gitleaks >/dev/null 2>&1; then
  ok "gitleaks"
else
  warn "gitleaks not installed — commits will not be scanned for secrets" \
       "brew install gitleaks   (CI scans too, but only after you have pushed)"
fi

command -v gh >/dev/null 2>&1 && ok "gh" \
  || warn "gh not installed — cannot read or file blocked issues" "brew install gh"

echo
echo "Platform targets"

if command -v java >/dev/null 2>&1 && java -version 2>&1 | grep -q '"17'; then
  ok "JDK 17"
else
  warn "JDK 17 not the default java" \
       "Needed for Android builds. Point Flutter at one: flutter config --jdk-dir <path>"
fi

if flutter config --list 2>/dev/null | grep -q 'android-sdk' || [ -n "$ANDROID_HOME" ]; then
  ok "Android SDK configured"
else
  warn "Android SDK not configured" "Android builds will fail. Desktop work is unaffected."
fi

if [ "$(uname)" = "Darwin" ]; then
  if xcodebuild -version >/dev/null 2>&1; then
    ok "Xcode"
  else
    warn "Xcode not fully installed" \
         "macOS builds will fail. Command Line Tools alone are not enough."
  fi
fi

echo
echo "Project"
if [ -d .dart_tool ]; then
  ok "dependencies fetched"
else
  warn "dependencies not fetched" "Run: flutter pub get"
fi

echo
if [ "$failed" -eq 1 ]; then
  printf "${red}Not ready.${off} Fix the ✗ items above before starting work.\n"
  exit 1
fi
printf "${green}Ready.${off} Warnings above only limit which platforms you can build.\n"
