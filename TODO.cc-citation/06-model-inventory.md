# 06 — Full model + relationship inventory (machine-readable)

**Status: done (inventory.json); atlas page open**

## Why
"People can create citation schemes, styles, indexes using ISO 690 oriented
models" presumes the full list of models and relationships is *available as
data* — not scattered across diagram PNGs.

## Done
`rake site` emits `_site/inventory.json`: every module → classes, enums,
attributes, cardinalities; the complete relation vocabulary (59 values with
definitions); BibItemType and all shared enums. Generated from the LML —
single source, no drift possible.

## Open
- Atlas `/models` page rendering the inventory (searchable, filterable,
  per-model anchors) — extend `site/templates` with an inventory view.
- Emit `_data` form for consumers (07's style models will import it).
