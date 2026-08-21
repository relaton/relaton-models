# 01 — Retire draft-succession relation types (issue #67)

**Status: done** · Repo: relaton-models (+ cc-citation-models regen in 04)

## Why
Draft-ness is a property of an item's version/status, not of the relation.
The four terms conflate succession with draft-ness; no dataset carries them
(verified); no generator emits them.

## Changes
- `relaton/grammars/biblio.rnc` `DocRelationType`: remove
  `predecessorDraftOf`, `hasPredecessorDraft`, `successorDraftOf`,
  `hasSuccessorDraft`.
- `relaton/models/DocumentRelationType.lml`: remove the four entries;
  **widen** `successorOf`/`hasSuccessor` definitions from
  "ceased periodical" prose to general succession (any successor edition,
  version, draft or continuation).
- cc-citation-models `07141` regenerates from the model (see 04).

## Gates
`rake lint parity fixtures` green; cc `0714-relations` chapter vocabulary =
63 − 4 = 59 values. Split: relaton-bib gem enum update = andrew2net
(model-side is ours).

## Acceptance
- [x] grammar + LML aligned, gates green
- [x] widened definitions in LML prose
- [ ] cc regen lands via 04
