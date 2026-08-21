# 02 — Vocabulary parity gate: every LML enum ↔ its RNC enumerated list

**Status: done (base + 14 flavour document-type vocabularies)** · Repo: relaton-models

## Why
The grammar and the model drifted for years by hand (#73: three relation
values missing from RNC; #67: four to remove). A gate makes the class of
bug impossible while generation (09) is pending.

## Design (OCP)
`VOCAB_PARITY` map in the Rakefile: LML enum file → RNC definition name.
Base entries shipped: `DocumentRelationType`, `BibItemType`,
`BibliographicDateType`, `ContributorRoleType`, `TitleType`.
**Adding a vocabulary = adding one map entry** — no code changes.

Flavour `*DocumentType` vocabularies are wired for bsi, gb, ieee, iso,
etsi, iec, ietf, jis, plateau, csa, m3aawg, ribose, un, itu (kebab-fold
comparison tolerates wire/LML spelling: spaces, underscores, accents).
First run caught and fixed: bsi/iso camelCase drift, ieee missing 5 wire
values, gb out-of-wire values, itu missing 3, BibItemType missing 4
(electronic-resource, notated-music, performed-music,
personal-communication), etsi accent loss.

## Gates
`rake parity` asserts set equality (both directions), aborts with the diff.
CI runs it on every push.
