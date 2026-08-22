# 06 — Full model + relationship inventory (machine-readable)

**Status: done**

## Why
"People can create citation schemes, styles, indexes using ISO 690 oriented
models" presumes the full list of models and relationships is *available as
data* — not scattered across diagram PNGs.

## Done
`rake site` emits `_site/inventory.json`: every module → classes, enums,
attributes, cardinalities; the complete relation vocabulary (59 values with
definitions); BibItemType and all shared enums. Generated from the LML —
single source, no drift possible.

## Done (all)
- `inventory.json` at the site root
- Atlas `/inventory.html` page: every module's types with attributes/values,
  linked from the primary navigation
- The citation module (07) models appear automatically (OCP: the generator
  globs `*/models/**/*.lml`)
