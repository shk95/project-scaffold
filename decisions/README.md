# Decisions

One file per convention: what the rule is, what went wrong without it, and what
would have to change for it to stop being right.

That last part matters. A decision recorded without its conditions becomes
dogma, and dogma is what people delete when it gets in the way. If the condition
no longer holds, the rule should go — deliberately, not by accident.

| | Decision |
| --- | --- |
| [001](001-default-branch-is-the-integration-branch.md) | The default branch is the integration branch |
| [002](002-hooks-are-opt-in-so-ci-must-backstop.md) | Hooks are opt-in, so CI has to repeat their checks |
| [003](003-done-must-be-mechanically-checkable.md) | "Done" must be mechanically checkable |
| [004](004-state-and-findings-are-separate.md) | State and findings are separate documents |
| [005](005-unfinishable-work-becomes-an-issue.md) | Work that cannot be finished here becomes an issue |
| [006](006-verify-the-clone.md) | Verify the clone; do not assert it works |
| [007](007-one-writer-stamps-the-metadata.md) | One writer stamps the metadata |

## Writing a new one

Only when something went wrong. A convention nobody has been bitten by is a
preference, and preferences belong in a style guide, not here.
