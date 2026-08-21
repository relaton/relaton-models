# 07 — Citation scheme, citation style, bibliographic index & style AS MODELS

**Status: open — flagship** · Repo: relaton-models (new `citation/` module),
consumer: relaton-render v2 (engine only)

## Why
Today the rendering knowledge lives as ad-hoc artifacts: relaton-render's
Liquid templates, YAML config (`template:`, `nametemplate:`,
`seriestemplate:`), per-language i18n YAML, and flavour subclasses. That is
not model-driven. The mission sentence — *people create citation schemes,
citation styles and bibliographic indexes and bibliographic styles using
ISO 690 oriented models* — requires these four artifacts to be **data
instantiated over LML models**, so that adding one never touches engine
code (OCP, no exception).

## The models (LML, new `citation/` module)

```
CitationScheme        HOW a citation points at an entry (ISO 690 Annex A systems as data)
  +system: CitationSystem        -- name-date | numeric | named-tag | running-notes | implied
  +disambiguation: DisambiguationRules   -- "2000a" suffixing, name truncation rules
  +nameForm: NameFormRules       -- initials, given-name order, and/others lists
  +locale: LocalizedStrings      -- replaces relaton-render's i18n-*.yaml

CitationStyle         HOW a citation and a reference are formatted
  +scheme: CitationScheme
  +perType: TypeTemplate[0..*]   -- BibItemType → template map (no code switch)
  +templates: TemplateMap        -- general/name/series templates (today's liquid, as data)
  +sortKey: SortRule[0..*]

BibliographicIndex    an ordered reference list (extends RelBib Collection)
  +entries: BibliographicItem[0..*]
  +collation: CollationRules     -- language/script-aware sorting
  +grouping: GroupingRule[0..*]

BibliographicStyle    HOW the index is presented
  +index: BibliographicIndex
  +layout: LayoutRules           -- numbering, grouping headers, indentation
```

Templates are **data with constrained placeholders** (the inventory's
attribute names — 06), evaluated by a generic engine; the engine contains
zero styles, zero vocabularies, zero i18n.

## Execution
1. Model `citation/` in LML (module layout, parity, lint).
2. ISO 690 itself as the first style instance (`iso-690.yml` instantiating
   CitationStyle) — validated against the JSON Schema from 10.
3. relaton-render v2: strip Liquid/config/i18n to a template evaluator +
   field resolver over the inventory; all existing flavours' configurations
   ported to style instances (mechanical translation of their YAML).
4. Atlas page: browse styles/schemes like models.

## Acceptance
A new style (e.g. "ISO 690 numeric, French") = one YAML instance + schema
validation. Engine repo diff: zero lines.
