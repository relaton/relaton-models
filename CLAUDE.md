# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Architectural rule (cannot be violated)

**The models ARE the LML files.** Every model is defined in LutaML: `models/*.lml` are the definition modules, `views/*.lml` are the diagram views. The RNC files in `grammars/` are implementation grammars that *accompany* the LML models — never a substitute for them. A flavour directory containing only an RNC overlay is incomplete; its model must exist as LML. This is also stated prominently in README.adoc.

## Repository layout

One module per directory, uniform internal layout everywhere:

- `relaton/` — the shared RelBib base models (was the unnamespaced top-level `models/`, `views/`, `images/`, `grammars/`; moved here to match the flavour layout, mirroring `standoc/` in standoc-models)
- `<flavour>/` (29 total: 3gpp, bipm, bsi, cc, ccsds, cen, cie, csa, ecma, etsi, gb, iana, iec, ieee, ietf, iho, iso, itu, jis, m3aawg, mpfa, nist, oasis, ogc, omg, plateau, ribose, un, w3c) — each former `relaton-model-<flavour>` repository, merged with full git history via git-subtree (see `git-subtree-dir:` markers in merge commits)

Each module: `models/` (LML definitions), `views/` (LML diagrams), `images/` (rendered PNGs, committed), `grammars/` (RNC overlays).

History provenance: the 29 flavour histories arrive via git-subtree merges; the bibliographic models restored from standoc-models (iso, cc, bsi, gb) and migrated from WSD (ogc, bipm, iho, itu, nist, mpfa, ieee) additionally carry their original `metanorma-model-<flavour>` histories, grafted as `merge -s ours` commits — tree unchanged, ancestry recorded.

Flavour model status:
- Full LML models + views: 3gpp, ccsds, ieee, oasis, w3c (from their relaton-model repos); iso, cc, bsi, gb (restored from metanorma/standoc-models); ogc, bipm, iho, itu, nist, mpfa (migrated from legacy PlantUML `.wsd` on 2026-08-19)
- Legacy `.wsd` files are retained as historical source next to their LML successors; nothing renders from `.wsd`
- RNC overlay only — LML models still need authoring: cen, cie, ecma, etsi, iana, iec, ietf, jis, omg, plateau

## Build commands

```sh
bundle install
bundle exec rake render        # regenerate all */images/*.png from */views/*.lml (default task)
bundle exec rake clean         # remove rendered PNGs
bundle exec rake verify        # assert PNG magic bytes on every committed diagram
bundle exec rake <module>/images/<Name>.png   # render a single diagram
```

Rendering uses `lutaml-lml` (graphviz-backed); `dot` must be on PATH. CI (`.github/workflows/make.yml`) runs `rake clean render` + `rake verify` on ubuntu/windows/macos. Note: `.github/workflows/make.yml` is named for the cimas convention — it runs Rake, not Make; there is no Makefile.

## Model file conventions

- **Never duplicate a base model in a flavour.** If a flavour view needs a base type, include it by relative path across modules: `include ../../relaton/models/BibliographicItem.lml`. Do not create stub copies (the old `class X <<Relaton>> {}` stubs in `models/relaton/` subdirs were removed for this reason).
- gb's models live under `gb/models/gb_document/metadata/` (structure inherited from standoc-models); iso's bib models under `iso/models/iso_document/metadata/`.
- LML parser gotchas: a space is required before `{` (`class Foo{` fails); literal `{`/`}` inside `definition { ... }` text breaks the parser; quoted strings (e.g. `title`) only accept `[a-z A-Z 0-9 _ - / +]` — no parentheses, commas, or other punctuation; non-ASCII (Chinese) is fine.
- `rake render` failure usually means an included path is broken — check that every `include` resolves relative to the including file.

## Consumers

The Metanorma grammar hub (metanorma/standoc-models) consumes the base grammars (`relaton/grammars/biblio*.rnc`) and the flavour overlays (`<flavour>/grammars/relaton-<flavour>.rnc`). Bibliographic LML for iso/cc/bsi/gb/ogc was restored from standoc-models (2026-08-19); document-structure models remain in standoc-models — do not import those here.
