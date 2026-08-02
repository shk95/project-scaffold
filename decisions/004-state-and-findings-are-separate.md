# 004 — State and findings are separate documents

**The rule.** Two files. One holds where the project stands and why it was built
that way. The other holds errors that will happen again. They are never the same
file.

## What went wrong

A single working-notes document accumulated both: current state at the top,
hard-won discoveries about a code generator further down. Then the state
changed, the document was rewritten to match, and the discoveries went with it —
not deliberately, just as collateral of a rewrite whose purpose was something
else.

The two kinds of content have opposite lifetimes. State is true until it is not;
a finding about how a library treats generated files is true for as long as the
project uses that library. Storing them together means the shorter lifetime
wins.

## The split

**State** (`docs/status.md`) — where things stand, and decisions expensive to
reverse, with reasoning. Rewritten freely.

**Findings** (`docs/troubleshooting.md`) — append-only lookup table. Headings are
the *literal error text*, because the way anyone finds an entry is grepping the
message in front of them, not scanning a contents list.

## Two rules that keep the findings file useful

**A bar for entry.** More than a quarter of an hour to work out, *and* likely to
recur. Without a bar it becomes a diary; a file of trivia is one nobody greps,
and a lookup table nobody consults is pure cost.

**It is not loaded automatically.** The orientation file points at it in one
line — "grep this when something breaks in a way that makes no sense" — rather
than including it. Context is finite, and most entries are irrelevant to any
given task. It should cost nothing until something is actually broken.

## Cost

Two files to keep straight, and a judgement call each time about which one a new
paragraph belongs in. The bar makes most of those calls easy.

## When this stops being right

A project short enough that nothing has yet been learned twice.
