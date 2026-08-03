#!/bin/sh
#
# Applies the repository-side conventions that live on GitHub rather than in
# files: the blocked-work labels, the default branch, and protection on the
# release branch.
#
# Run once, after the first push of both branches. Needs `gh` authenticated.
#
#   core/setup-repo.sh <owner>/<repo> [release-branch] [integration-branch]
#
# What can block work is stack-specific, so the reasons beyond the universal
# one come from the environment. Each stack overlay names the ones its projects
# need:
#
#   BLOCKED_LABELS="needs-aarch64-darwin needs-nixos-host" \
#     core/setup-repo.sh <owner>/<repo>

set -e

repo=${1:?"usage: setup-repo.sh <owner>/<repo> [release-branch] [integration-branch]"}
release=${2:-master}
integration=${3:-dev}

echo "→ labels"
# Two labels per blocked issue: the umbrella, which is the only thing
# `gh issue list --label blocked` finds, plus what is actually missing.
# GitHub matches label names exactly — see
# decisions/005-unfinishable-work-becomes-an-issue.md
gh label create blocked --repo "$repo" --color B60205 --force \
  --description "Written but not verifiable on the host that wrote it" >/dev/null

# needs-manual-check is the only universal one: every stack eventually has
# something a human has to look at. Everything else — a device, an OS, a
# builder for another system — depends on what is being built, and hardcoding
# one stack's list here is how the second project to use this core ends up
# with labels for platforms it does not target.
for what in needs-manual-check ${BLOCKED_LABELS:-}; do
  gh label create "blocked/$what" --repo "$repo" --color D93F0B --force \
    --description "Blocked: $what" >/dev/null
done

echo "→ default branch: $integration"
# A clone lands here, so it must be the branch work starts from — see
# decisions/001-default-branch-is-the-integration-branch.md
gh repo edit "$repo" --default-branch "$integration" >/dev/null

echo "→ protecting $release"
# required_approving_review_count is 0 so a solo maintainer is not blocked,
# while direct pushes and force-pushes still are. enforce_admins stays false:
# this prevents accidents, not deliberate action.
#
# Adjust the contexts to the job names your CI actually reports.
gh api -X PUT "repos/$repo/branches/$release/protection" --input - >/dev/null <<JSON
{
  "required_status_checks": { "strict": true, "contexts": ["Secret scan"] },
  "enforce_admins": false,
  "required_pull_request_reviews": {
    "required_approving_review_count": 0,
    "dismiss_stale_reviews": false
  },
  "restrictions": null,
  "allow_force_pushes": false,
  "allow_deletions": false
}
JSON

echo
echo "Done. Remaining manual step, once per clone:"
echo "  git config core.hooksPath .githooks"
