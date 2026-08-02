# Definition of done

<!-- See decisions/003-done-must-be-mechanically-checkable.md.

     Items must be observations, not qualities. "Works correctly" cannot be
     checked; "returns 404 for a deleted record" can. If an item cannot be
     observed, it is not a definition of done — it is a hope. -->

Code that compiles is not finished work. This file says what "finished" means,
so a session cannot declare a milestone complete on the strength of a green
build.

**The rule for anything you cannot verify here:** do not quietly skip it and do
not claim it. Open a blocked issue naming what is missing, and say so in the
pull request.

```sh
gh issue create --label blocked --label blocked/<what-is-missing> \
  --title "<milestone>: <what still needs checking>" \
  --body "<what was built, what was tested, and the steps to close this>"
```

Always two labels: `blocked` — the umbrella that `gh issue list --label blocked`
finds, since GitHub matches labels exactly — plus one saying what is missing.

---

## Every change

- [ ] Static analysis is clean
- [ ] The test suite passes
- [ ] New behaviour has a test — or a note in the pull request saying which host
      capability makes one impossible
- [ ] Generated code, if any, was regenerated and committed
- [ ] Commits follow Conventional Commits
- [ ] `docs/status.md` updated if a decision was made that is expensive to
      reverse, with the reasoning — not just the conclusion

---

## <Milestone name>

<!-- One section per milestone. Phrase each item as something someone can watch
     happen. Where the milestone depends on hardware or a platform the CI does
     not have, say so explicitly — those are the items that get silently
     dropped. -->

- [ ] <observable outcome>
- [ ] <observable outcome, on real hardware if that is what the milestone means>
