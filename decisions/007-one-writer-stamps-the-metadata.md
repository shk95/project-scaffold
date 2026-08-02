# 007 — One writer stamps the metadata

**The rule.** When rows carry bookkeeping every write must maintain — timestamps,
a revision counter, an author — exactly one component performs writes, and it
applies that bookkeeping centrally. Callers cannot reach the table directly.

## What went wrong

A repository class stamped `updatedAt`, a monotonic `revision` and the writing
device's id on every mutation. One method took a whole row from the caller and
wrote it back, deriving the new revision from the row it was handed.

That row came from a UI screen opened some time earlier. Saving from it left the
revision unchanged or lower than what was stored.

A revision that fails to increase is precisely the signal a future sync uses to
decide an edit never happened. The write succeeded, the user saw their change,
and the record of it was already invisible to replication. The method's own
documentation claimed the caller's metadata was "ignored and recomputed" — the
comment was aspirational and the code was not.

A test written to assert the documented behaviour caught it.

## Two lessons, and the second is the general one

**Derive bookkeeping from stored state, never from the caller's copy.** Anything
the caller holds may be arbitrarily old.

**Make the correct path the only path.** After the fix, the stamping helper was
reachable only through the method that reads current state first. Not "callers
should"; callers *cannot*. Auditing call sites works exactly until someone adds
one, and half-stamped data is invisible rather than broken — nothing fails, the
record is simply not there when it matters.

## Where else this shape appears

Audit columns, soft deletes, tenant ids, `updated_by`, optimistic-lock versions,
event sequence numbers. Any field whose absence is silent rather than loud.

## Cost

The single writer becomes a chokepoint and grows. Worth it: the alternative is a
rule that decays with every new contributor.

## When this stops being right

If the database enforces it — triggers, generated columns, row-level policies —
push it there. A constraint the storage layer maintains beats a convention the
application maintains.
