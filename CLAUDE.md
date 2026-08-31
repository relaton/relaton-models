# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Architectural rule (cannot be violated)

**The models ARE the LML files.** Every model is defined in LutaML: `models/*.lml` are the definition modules, `views/*.lml` are the diagram views. The RNC files in `grammars/` are implementation grammars that *accompany* the LML models — never a substitute for them. A flavour directory containing only an RNC overlay is incomplete; its model must exist as LML. Enforced by `rake parity`. The JSON Schema (`relaton/schema/`) is generated from the LML — never hand-edit it.

## Views vs models (hard separation)

| Path | Contains | Must NOT contain |
|------|----------|------------------|
| `*/models/**/*.lml` | `class` / `enum` / `data_type` definitions only | `diagram`, `view`, `association`, `title` |
| `*/views/*.lml` | one `diagram`/`view`, `include`s, `association`s, title/caption | class/enum/data_type bodies |

Rakefile globs **only** `*/views/*.lml` for PNG output. `rake parity` fails if a `diagram` keyword appears under `models/` or a class body appears under `views/`. Cross-module reuse = relative `include` of the real file — never a stub copy under the consumer's `models/`.

## Repository layout

One module per directory, uniform internal layout everywhere:

| Path | Purpose |
|---|---|
| `relaton/` | Shared RelBib base models (BibliographicItem, Citation, Contributor, ...) |
| `basicdoc/` | Git submodule of metanorma/basicdoc-models (Basicdoc types: Image, BasicElement, BasicBlock) |
| `citation/` | Citation scheme/style/index/style models (CitationScheme, CitationStyle, BibliographicIndex, BibliographicStyle) |
| `<flavour>/` (29) | Each former `relaton-model-<flavour>` repository: models, views, images, grammar overlay |
| `profiles/` | Declarative flavour profiles (narrowing-only, YAML) |
| `examples/` | Twin XML/YAML fixtures + real Relaton instances |
| `mapping/` | CSL-to-Relaton subset mapping |
| `tools/` | Validation and generation scripts |
| `docs/` | Versioning policy, MODS gap analysis |
| `site/` | Atlas site generator (ERB templates + generate.rb) |
| `TODO.cc-citation/` | Mission plan (17 items) |

Each module: `models/` (LML), `views/` (diagrams), `images/` (committed PNGs), `grammars/` (RNC overlays).

## Build commands

```sh
git submodule update --init --recursive
bundle install
bundle exec rake ci                 # ALL gates (render, verify, lint, parity, profiles, fixtures, schema, CSL, RNC check)
bundle exec rake render             # regenerate all */images/*.png from */views/*.lml
bundle exec rake <module>           # render one module
bundle exec rake verify             # PNG magic bytes
bundle exec rake lint               # semantic LML lint
bundle exec rake parity             # LML/RNC parity + vocabulary parity (19 vocabularies)
bundle exec rake profiles           # flavour profiles (narrowing-only)
bundle exec rake fixtures           # XML/YAML/schema/CSL fixtures
bundle exec rake schema             # regenerate JSON Schema from LML
bundle exec rake csl                # validate CSL mapping against schema
bundle exec rake rnc:check          # LML-generated RNC vs committed
bundle exec rake site               # build atlas into _site/
```

## Construct doctrine

- Constructs are generic; formats specialize them via types and the attribute register.
- Relaxed content models: containers hold the broadest reasonable type.
- Composition: anything that can hold a block can hold a document.

## Flavour profiles

`profiles/*.yaml` declaratively narrow the RelBib base per flavour: excluded constructs, constrained cardinalities, enum subsets. Profiles may only narrow — widening is rejected by `rake profiles`. All 29 flavours have profiles.

## Citation models (TODO 07)

The `citation/` module defines how citations, styles, indexes, and bibliographic styles are expressed as DATA over the Relaton models. `citation/styles/iso-690.yml` is the first style instance, validated against the generated schema. A new style = a YAML instance, never code.

## Instance fixtures

`examples/` carries: `bibitem.xml` + `bibitem.yaml` (twin fixtures of the same BibliographicItem), `relaton-bibitem.xml` (real IETF instance), `csl-example.yml` (CSL import test). XML validates against RNC; YAML validates against LML and JSON Schema; CSL validates against the mapping.

## Model file conventions

- **Never duplicate a base model in a flavour.** Cross-module reuse by reference.
- **Views are fully encapsulated.** Include only own-module models; cross-module classes render as collapsed boxes.
- Every attribute has an explicit visibility marker (`+`/`#`/`-`), a resolvable type, and every class/enum a `definition { }`.

## Versioning

See `docs/VERSIONING.md` for the MAJOR.MINOR.PATCH policy, deprecation cycle, and standardization snapshot tags.

## Consumers

The Metanorma grammar hub (metanorma/standoc-models) consumes the base grammars and flavour overlays. relaton.org submodules this repo at `vendor/relaton-models` and syncs diagrams via `scripts/sync-models.sh`. The atlas at relaton.github.io/relaton-models is deployed by the `pages` workflow.
