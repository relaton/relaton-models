# 13 — Parser-based model extraction (replace regex with lutaml-lml)

**Status: done (validate_yaml.rb)** · Source: basicdoc-models `tools/validate_profile.rb`

## Why
Our `validate_yaml.rb` and `validate_csl.py` extract model structure
(class names, attributes, enums) via regex line scanning. This is fragile:
misses nested structures, brace-edge cases, and can silently mis-parse.
basicdoc-models uses `Lutaml::Lml::Pipeline.call(file_content)` to get real
domain objects (classes, enums, attributes with cardinalities) — robust and
type-safe.

## Changes
- `tools/validate_yaml.rb`: replace `defined_types` / `attributes_of` /
  `enum_values_of` regex functions with `Lutaml::Lml::Pipeline.call` on each
  model file
- `tools/generate_schema.py`: remains Python (regex); a Ruby JSON-dump
  bridge or direct parser port is a follow-up
- `tools/validate_csl.py`: reads the generated schema — transitively fixed

## Acceptance
`rake fixtures` green; no regex-based model extraction remains in tools/.
