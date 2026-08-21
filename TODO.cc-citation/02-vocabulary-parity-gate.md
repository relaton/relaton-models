# 02 — Vocabulary parity gate: every LML enum ↔ its RNC enumerated list

**Status: done (base vocabularies)** · Repo: relaton-models

## Why
The grammar and the model drifted for years by hand (#73: three relation
values missing from RNC; #67: four to remove). A gate makes the class of
bug impossible while generation (09) is pending.

## Design (OCP)
`VOCAB_PARITY` map in the Rakefile: LML enum file → RNC definition name.
Base entries shipped: `DocumentRelationType`, `BibItemType`,
`BibliographicDateType`, `ContributorRoleType`, `TitleType`.
**Adding a vocabulary = adding one map entry** — no code changes.

Flavour vocabularies (e.g. `iso/models/.../IsoDocumentType` ↔
`iso/grammars/relaton-iso.rnc DocumentType`) are added per-flavour with a
`{ module:, lml:, rnc: }` tuple once 04 lands; entries listed in 09 stage A.

## Gates
`rake parity` asserts set equality (both directions), aborts with the diff.
CI runs it on every push.
