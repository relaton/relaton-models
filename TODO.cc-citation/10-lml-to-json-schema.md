# 10 — JSON Schema from the LML (issue #9)

**Status: core done** · Depends: 07 (consumes it)

## Decisions (settling the 8-year thread)
- JSON Schema draft 2020-12, generated from LML — JSON-LD `@context`
  generated from the same mapping afterwards (the comment thread converged
  on schema-first; JSON-LD remains a derived view).
- Naming convention = the fixtures' convention (06/07): camelCase LML
  attribute names, `class` discriminators, enum values verbatim.

## Done
`rake schema` generates `relaton/schema/bibitem-2020-12.json` (363
definitions: classes with attribute/cardinality/inheritance, enums,
marker-class polymorphism); `rake fixtures:schema` validates the YAML
fixture against it; CI regenerates and asserts the committed schema is
fresh. Remaining: JSON-LD @context derivation; acceptance corpus of real
Relaton YAML.

## Deliverables (remaining)
`rake schema` → `relaton/schema/bibitem-2020-12.json`; YAML fixtures
validate against it (extend `rake fixtures`); real Relaton YAML (gem test
corpora + caches) as acceptance corpus; `biblio.jsonld` becomes derived or
is retired. 07's style instances validate against schemas generated the
same way.
