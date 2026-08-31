# 07 — Citation scheme, citation style, bibliographic index & style AS MODELS

**Status: models + first style done; engine open** · Repo: relaton-models (new `citation/` module),
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

## Done
1. `citation/` module: 14 LML models (CitationScheme, CitationStyle,
   BibliographicIndex, BibliographicStyle + CitationSystem enum,
   DisambiguationRules, NameFormRules, LocalizedStrings, TemplateMap,
   TypeTemplate, SortRule, CollationRules, GroupingRule, LayoutRules).
   Four views, rendered, parity + lint green.
2. First style instance: `citation/styles/iso-690.yml` — the ISO 690
   name-and-date scheme as data, validated against the schema generated
   from the LML (rake fixtures:schema).
3. Atlas: the four citation-model cards render alongside every other
   module.

## Open
4. relaton-render v2: strip Liquid/config/i18n to a template evaluator +
   field resolver over the inventory; all existing flavours' configurations
   ported to style instances.
5. BibliographicIndex/BibliographicStyle instances (the index + layout
   counterparts to the style).

## Acceptance
A new style (e.g. "ISO 690 numeric, French") = one YAML instance + schema
validation. Engine repo diff: zero lines.
