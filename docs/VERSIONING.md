# Versioning and stability policy

## Version identifiers

The model is versioned as `MAJOR.MINOR.PATCH`, applied to the repository
as a whole (definition modules, grammars, diagrams, schema, citation
styles — they are one artifact).

- **PATCH** — editorial: definitions clarified, diagrams re-rendered,
  tooling and test changes. No construct, attribute, enumeration value,
  or cardinality changes.
- **MINOR** — additive: new constructs, new enumeration values, new
  well-known keys, cardinality *relaxations*. Everything conforming to
  N.x conforms to N.x+1.
- **MAJOR** — removing or renaming constructs, tightening cardinalities,
  changing semantics. Requires a deprecation cycle.

## Deprecation cycle

A construct scheduled for removal in MAJOR N+1 is first marked
*deprecated* in a MINOR release of N: its definition carries a
deprecation note, and the test suite grows an instance that exercises
it (a construct without a serializable instance is unfinished —
including deprecated ones). Removal follows no sooner than the next
MAJOR release.

## Standardization snapshots

At each milestone of ISO 690 (committee drafts, DIS, IS), an immutable
snapshot of this repository is tagged `standard/<milestone>` and
referenced by the cc-citation-models document (which is the model-form
implementation of the standard). Errata are PATCH releases of the tagged
snapshot; substantive change is balloted through the standard and lands
here only after adoption.

## Breaking-change audit

`rake check` (lint, parity, fixtures, csl, schema) is the gate: any
change that would alter the accepted instance set without an accompanying
version bump is a defect, not a release.

## Citation style compatibility

Citation styles (TODO.cc-citation/07) declare the model version they
target. Because styles are data validated against the generated schema,
a style targeting N.x is automatically validated against N.x+1 by the
`fixtures:schema` gate when the schema regenerates.
