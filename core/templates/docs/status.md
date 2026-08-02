# Status and handover notes

<!-- See decisions/004-state-and-findings-are-separate.md.

     Rewritten freely as the project moves. Anything that must survive a rewrite
     — an error and its fix — belongs in troubleshooting.md instead. -->

Last updated: <date>.

---

## Where things stand

| Milestone | State |
| --- | --- |
| <M0 …> | done |
| <M1 …> | **next** |

```
<the commands that verify this, and their current output>
```

---

## This machine

<!-- What is installed and where, plus anything non-obvious about the setup.
     Prefer pointing at tool/doctor.sh over maintaining a table by hand — the
     script reports what is actually here, this table reports what was here
     when someone last edited it. -->

---

## Decisions that are expensive to reverse

<!-- The heart of this file. For each: what was decided, and *why* — the
     alternative that was rejected and what went wrong with it. A conclusion
     without its reasoning gets reversed by the next person who finds it
     inconvenient. -->

**<Decision>.** <Why. What breaks if it is undone.>

---

## Bugs worth remembering

<!-- Ones that revealed something about the design rather than a typo. Each
     should have a regression test; name it. -->

---

## Traps that will recur

Everything that has already cost time lives in
[`troubleshooting.md`](troubleshooting.md). **This file holds state and
decisions; that one holds findings**, so updating the state does not delete them.

When stuck, grep it for the error text rather than reading it.

---

## Next

<!-- What the following session should pick up, and what it needs to know
     before starting. Name the definition-of-done items that apply, so the bar
     is explicit before any code exists. -->

---

## Conventions

<!-- Branch strategy, commit format, hooks, CI, signing, anything a contributor
     needs and would otherwise have to infer. Keep the reasoning attached. -->
