# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Architectural rule (cannot be violated)

**The models ARE the LML files.** Every model is defined in LutaML: `models/*.lml` are the definition modules, `views/*.lml` are the diagram views. The RNC files in `grammars/` are implementation grammars that *accompany* the LML models — never a substitute for them. A flavour directory containing only an RNC overlay is incomplete; its model must exist as LML. This is also stated prominently in README.adoc. Enforced by `rake parity`.


## Views vs models (hard separation)

| Path | Contains | Must NOT contain |
|------|----------|------------------|
| `*/models/**/*.lml` | `class` / `enum` / `data_type` definitions only | `diagram`, `view`, `association`, `title` |
| `*/views/*.lml` | one `diagram`/`view`, `include`s, `association`s, title/caption | class/enum/data_type bodies |

Rakefile globs **only** `*/views/*.lml` for PNG output. `rake parity` must fail if a `diagram` keyword appears under `models/` or a class body appears under `views/`. Cross-module reuse = relative `include` of the real file — never a stub copy under the consumer's `models/`.

## Repository layout

One module per directory, uniform internal layout everywhere:

- `relaton/` — the shared RelBib base models (was the unnamespaced top-level `models/`, `views/`, `images/`, `grammars/`; moved here to match the flavour layout, mirroring `standoc/` in standoc-models)
- `basicdoc/` — git submodule of [metanorma/basicdoc-models](https://github.com/metanorma/basicdoc-models). Provides `Image`, `BasicElement`, `BasicBlock` and the rest of the Basicdoc types that RelBib attributes reference via `<<Basicdoc>>Type`. Do not vendor copies under `relaton/models/`.
- `<flavour>/` (29 total) — each former `relaton-model-<flavour>` repository, merged with full git history via git-subtree (see `git-subtree-dir:` markers in merge commits)

Each module: `models/` (LML definitions), `views/` (LML diagrams), `images/` (rendered PNGs, committed), `grammars/` (RNC overlays).

History provenance:
- The 29 flavour histories arrive via git-subtree merges from `relaton-model-<flavour>`.
- Bibliographic models restored from standoc-models / migrated from WSD (iso, cc, bsi, gb, ogc, bipm, iho, itu, nist, mpfa, ieee) additionally carry their original `metanorma-model-<flavour>` histories, grafted as `merge -s ours` commits — tree unchanged, ancestry recorded.

### Querying grafted history

`git log --follow` on a current path will not jump the path+extension rename into a grafted tip. Query the grafted tip directly:

```sh
# list grafted second-parents
git log --grep='metanorma-model-.*history' --format='%h %s'

# history of a file under its original path inside the grafted tip
git log --oneline <grafted-sha> -- models/ItuBibliographicItem.wsd
```

## Build commands

```sh
git submodule update --init --recursive
bundle install
bundle exec rake render          # regenerate all */images/*.png from */views/*.lml (default)
bundle exec rake <module>        # render one module (e.g. rake iso, rake relaton)
bundle exec rake clean           # remove regenerable PNGs only
bundle exec rake verify          # assert PNG magic bytes on every committed diagram
bundle exec rake parity          # assert every flavour has LML models + RNC overlay; basicdoc submodule present
bundle exec rake check           # render + verify + parity
bundle exec rake <module>/images/<Name>.png   # render a single diagram
```

Rendering uses `lutaml-lml` (graphviz-backed); `dot` must be on PATH. CI (`.github/workflows/rake.yml`) runs `rake clean render`, `rake verify`, and `rake parity` on ubuntu-latest with `submodules: recursive`.

## Model file conventions

- **Never duplicate a base model in a flavour.** If a flavour view needs a base type, include it by relative path across modules: `include ../../relaton/models/BibliographicItem.lml`. Same for Basicdoc: `include ../../basicdoc/models/idelements/Image.lutaml` (submodule still uses `.lutaml` until basicdoc-models is upgraded to `.lml`).
- gb's models live under `gb/models/gb_document/metadata/`; iso's bib models under `iso/models/iso_document/metadata/`.
- LML parser notes (lutaml-lml >= 0.1.3): quoted titles accept any character (parentheses, Unicode); definition bodies track brace depth so `ZB{code}` is fine. A space is still conventional before `{` after class names.
- `rake render` failure usually means an included path is broken — check that every `include` resolves relative to the including file.
- Legacy `.wsd` files may sit next to their LML successors as historical source; nothing renders from `.wsd`.

## Consumers

The Metanorma grammar hub (metanorma/standoc-models) consumes the base grammars (`relaton/grammars/biblio*.rnc`) and the flavour overlays (`<flavour>/grammars/relaton-<flavour>.rnc`). Document-structure models remain in standoc-models — do not import those here.
