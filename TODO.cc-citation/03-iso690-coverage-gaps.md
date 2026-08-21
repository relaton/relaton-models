# 03 — Close the ISO 690 data-model coverage gaps (clause 7 → L3)

**Status: partial** · Repo: relaton-models, citation layer of cc-citation-models

Coverage matrix verdict: structural coverage is complete (see 00); the
genuine gaps and their fixes:

## Done
- **§7.6 audience-differentiated editions**: `Edition +audience: String[0..1]`
  (LML) + `attribute audience { text }?` on `edition` (RNC).
- **§7.8 production roles**: `printer`, `sponsor` added to
  `ContributorRoleType` (LML) and `role/@type` (RNC). Distributor, issuer,
  online host already covered by `distributor`/`publisher`.

## Designed, open
- **§7.15 provenance & authenticity**: proposal — extend `ValidityType` with
  `+provenance: <<Basicdoc>>BasicElement[0..*]` (chain of custody statement)
  and `+authenticity: { certified | copy | unknown }`; express as data, not
  notes. Needs a fixture exercising an archival item before merging.
- **§7.15 registered trademark / system requirements / restoration**: typed
  note entries (`TypedNote.type` values) rather than free `note` text;
  requires `NoteType` enum — model first, then fixture.

## Acceptance
Each gap closes with: LML + RNC + `rake parity` (vocab gate) + a fixture
instance exercising it (XML + YAML twins).
