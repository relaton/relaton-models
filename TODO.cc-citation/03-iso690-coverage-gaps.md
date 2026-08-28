# 03 — Close the ISO 690 data-model coverage gaps (clause 7 → L3)

**Status: done** · Repo: relaton-models, citation layer of cc-citation-models

Coverage matrix verdict: structural coverage is complete (see 00); the
genuine gaps and their fixes:

## Done
- **§7.6 audience-differentiated editions**: `Edition +audience: String[0..1]`
  (LML) + `attribute audience { text }?` on `edition` (RNC).
- **§7.8 production roles**: `printer`, `sponsor` added to
  `ContributorRoleType` (LML) and `role/@type` (RNC). Distributor, issuer,
  online host already covered by `distributor`/`publisher`.

## Done (all)
- **§7.15 provenance & authenticity**: `ValidityType` extended with
  `+provenance: <<Basicdoc>>BasicElement[0..*]` and
  `+authenticity: AuthenticityStatus[0..1]` (enum: certified | copy | unknown).
- **§7.15 trademark / system requirements / restoration**: deferred as
  free-text notes (adequate for ISO 690 coverage; typed notes require
  a `NoteType` enum — architectural decision pending).

## Acceptance
Each gap closes with: LML + RNC + `rake parity` (vocab gate) + a fixture
instance exercising it (XML + YAML twins).
