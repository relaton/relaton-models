# 09 — Generate the RNC from the LML (issue #35)

**Status: stage B done; stage C open** · Repo: relaton-models + lutaml

## Why
The original sin: two hand-maintained artifacts. 02 freezes the drift; 09
ends it — RNC becomes a derived artifact.

## Stages
- **A — vocabularies**: parity gate shipped (see 02; 19 vocabularies).
- **B — vocabulary emission**: `tools/generate_rnc.py` emits RNC vocab
  definitions from LML enums; `--check` mode validates generated ==
  committed (with kebab-fold normalization, consistent with the parity
  gate). All 4 base vocabularies green.
  (`DocRelationType = "includes" | …`); flip parity to "generated matches
  committed" then commit generated. Flavour `DocumentType` overlays included
  via the 02 map.
- **B — element structure**: base-module element sequences with an explicit
  LML↔wire mapping table (attribute → child element vs attribute,
  cardinality → `?`/`*`/`+`, `<<Basicdoc>>` types → basicdoc RNC include).
  Keep `## definition` doc-comments as RNC `##` annotations (they already
  mirror).
- **C — flip**: `rake grammar` regenerates `relaton/grammars/`;
  hand-editing RNC ends (CI asserts clean tree); flavours' overlays compose
  over generated base exactly as they do today.

Coordinate with lutaml/lutaml-uml#96 (renderer-level generation) — our
generator is domain-specific to the biblio wire format and lives here.
