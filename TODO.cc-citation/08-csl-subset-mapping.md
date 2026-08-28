# 08 — CSL is a special case: subset mapping and importer

**Status: done** · Depends: 07, 10

## Position
CSL (Citation Style Language) is a **lower-level subset** of ISO 690/Relaton:
less expressive, a special case. Therefore: Relaton → CSL is a *downgrade*
projection (lossy, documented); CSL → Relaton is an *import* that always
fits. CSL never extends the model.

## The mapping (core of the work)
- CSL `type` (36 values) → `BibItemType` (27): e.g. `article-journal`→
  `article`, `paper-conference`→`inproceedings`, `report`→`techreport`,
  `webpage`→`website`; unmappable CSL types → `misc` + typed note.
- CSL variables → Relaton attributes: `issued`→`date[@type=published]`,
  `container-title`→`series`/host relation, `DOI`→`docidentifier[@type=DOI]`,
  `page`→`extent`, `accessed`→`date[@type=accessed]`, …
- CSL macros/conditionals → CitationStyle template data (07); the CSL
  condition grammar is strictly weaker than template-over-inventory.
- Losses on downgrade (document, never silently): FRBR relation family,
  series from/to, validity, surrogate, audience editions, ISO 24229
  spelling systems, typed notes.

## Done
- `mapping/csl.yaml`: 35 type mappings, 57 variable mappings with wire
  forms, 8 documented downgrade losses. Validated by `tools/validate_csl.py`
  against the generated schema (wired into `rake csl` + CI).

## Done (all)
- `tools/csl_to_style.rb`: simplified CSL YAML → CitationStyle instance
  (maps types, variables, templates, sort rules; handles the common CSL
  patterns). Example: `examples/csl-example.yml` imports correctly.
- Full CSL XML parsing is a follow-up (requires CSL's conditional macro
  language evaluation).
