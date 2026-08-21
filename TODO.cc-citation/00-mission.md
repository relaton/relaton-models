# Mission — Relaton as the ISO 690 meta/model implementation

People must be able to **create citation schemes, citation styles,
bibliographic indexes and bibliographic styles using ISO 690 oriented
models — Relaton.** Everything below serves that sentence.

## The stack (single source of truth pipeline)

```
L1  STANDARD TEXT     metanorma/iso-690        (authoritative ISO 690 DIS)
L2  MODEL FORM        CalConnect/cc-citation-models
                      = L1 clauses + `Serialisation:` mappings + model chapters
                      + Annex A = include of canonical RNC
L3  MACHINE MODELS    relaton/relaton-models   (LML = THE model; RNC companions;
                                                lint/parity/fixtures gates; atlas)
L4  IMPLEMENTATIONS   relaton-bib gems · relaton-render (engine only) ·
                      metanorma · datasets · CSL import
```

## Invariants (no exceptions)

1. **Model-driven**: every layer is generated from or validated against the
   LML. No hand-maintained parallel artifacts. RNC, JSON Schema, the atlas,
   the citation-doc annex and the render configurations are all derived.
2. **OCP**: a new flavour, resource type, relation value, citation scheme or
   style = adding data/models, never editing engine code. Gates
   auto-discover.
3. **OOP/MECE**: each construct defined exactly once, in its owning module;
   reuse by reference (relative include or name), never by copy.
4. **Scope**: data models only. Citation *rendering guidance* (ISO 690
   Annex A citation systems as typography, element display order) is a
   separate presentation layer driven BY these models — it is not model
   coverage. CSL is a lower-level subset: less expressive, a special case
   of ISO 690/Relaton — imports downgrade, never extend.
5. **Proof**: every claim is gated — `rake lint parity fixtures`, real
   Relaton instances, site crawl.

## Item index

| # | Item | Status |
|---|------|--------|
| 01 | Relation vocabulary retirement (#67) | done |
| 02 | Vocabulary parity gate (LML ↔ RNC) | done |
| 03 | ISO 690 coverage gaps in the models | partial (audience, printer, sponsor done; provenance designed) |
| 04 | citation-doc chapter parity (L1 → L2) | open |
| 05 | Element parity gate (L2 → L3) | open |
| 06 | Full model + relationship inventory | done (inventory.json); atlas page open |
| 07 | Citation scheme/style/index/style models | open — flagship |
| 08 | CSL subset mapping and importer | open |
| 09 | LML → RNC generation (#35) | open |
| 10 | LML → JSON Schema (#9) | open |
| 11 | MODS gap analysis (#18) | open |
| 12 | relaton.org legacy site retirement (#59) | open |
