# 05 — Element parity gate (L2 → L3): Serialisation paths must exist

**Status: open** · Repo: cc-citation-models (script + CI), validates against relaton-models

## Why
"Full implementation" must be machine-checkable: every element the
citation-doc promises (`Serialisation: bibitem/date/@type`) must exist in
the canonical grammar and have an LML attribute behind it — and reverse:
every RNC element must be documented in L2.

## Design (OCP)
`tools/check_serialisation.rb`: extract every `Serialisation:` path from
`sources/sections/**/*.adoc`; parse `biblio-standoc.rnc` via the relaton
validator's composer (tools/validate_xml.py `build_schema()`); walk each
path against the schema's element/attribute tree; report misses both ways.
New chapter content = new data; the gate auto-covers it.

## Acceptance
CI step in the cc repo; zero misses after 04 lands; the 13 current paths
grow to the full clause-7 map.
