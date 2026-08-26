# 15 — Versioning and stability policy for the model

**Status: done** · Source: basicdoc-models `docs/VERSIONING.md`

## Why
relaton-models is the machine model for ISO 690. Consumers (relaton-bib
gems, metanorma, cc-citation-models, basicdoc-models) need stability
guarantees. basicdoc-models has a semver policy with deprecation cycles
and standardization snapshot tags.

## Changes
- `docs/VERSIONING.md`: MAJOR.MINOR.PATCH; MINOR is additive (new enum
  values, new attributes, cardinality relaxations); MAJOR removes/renames;
  PATCH is editorial. Deprecated constructs carry a note + a fixture.
- `standard/<milestone>` tags at ISO 690 milestones.
