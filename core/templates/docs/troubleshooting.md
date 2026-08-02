# Things that already cost someone an afternoon

<!-- See decisions/004-state-and-findings-are-separate.md.

     Append-only. This file must never be rewritten to reflect the current
     state — that is docs/status.md's job, and mixing the two is how findings
     get deleted. -->

Findings that recur. Not a changelog and not a diary — `docs/status.md` holds the
current state and the decisions, this holds the things that will bite again.

**Search this file by the error text, not by reading it.** Headings are the
literal message you will see, so `grep` finds the entry that matches what is in
front of you.

**Bar for adding an entry:** it cost more than a quarter of an hour to work out,
*and* it will happen again — to a future session, on another machine, or after a
dependency upgrade. A typo you fixed in a minute does not belong here. Keep
entries to a few lines; a long one means the explanation belongs in a code
comment where the problem lives.

---

## <Category — the tool or layer, so related entries sit together>

### `<the literal error message>`

<Two to four lines: what is actually happening, and what to do. Link to the code
or test that pins the behaviour, if one exists.>
