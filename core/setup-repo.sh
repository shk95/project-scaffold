#!/bin/sh
#
# Applies the repository-side conventions that live on GitHub rather than in
# files: the blocked-work labels, the default branch, and protection on the
# release branch.
#
# Run once, after the first push of both branches. Needs `gh` authenticated.
#
#   core/setup-repo.sh <owner>/<repo> [release-branch] [integration-branch]

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
for what in needs-android-device needs-windows needs-manual-check; do
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
