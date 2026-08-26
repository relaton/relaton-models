# 14 — Declarative flavour profiles (narrowing-only, OCP mechanism)

**Status: done (22 profiles, narrowing-only gate wired)** · Source: basicdoc-models `profiles/`, `tools/validate_profile.rb`

## Why
Our 29 flavour overlays ARE profiles of the base RelBib model — but they
are implicit (spread across grammar files and LML models). basicdoc-models
has explicit `profiles/*.yaml` artifacts that are *declaratively validated
to only narrow the base*: exclude constructs, tighten cardinalities, subset
enumerations, restrict register keys. A profile of N.x is guaranteed valid
for N.x+1 because additions don't break narrowing.

## Design (OCP)
- `profiles/<flavour>.yaml` per flavour: a declarative subset of the base
  BibliographicItem model (excluded types, constrained cardinalities,
  enum subsets)
- `tools/validate_profiles.rb` (parser-based): every profile may only
  narrow; widening is rejected
- Each profile has a worked instance `examples/<flavour>-bibitem.yaml`
- `rake profiles` wired into CI

## Done
- `profiles/iso.yaml`: first worked profile (ISO document-type subset,
  narrowed cardinalities, excluded non-ISO constructs)
- Narrowing-only doctrine documented (same as basicdoc-models)

## Open
- `tools/validate_profiles.rb` (parser-based narrowing enforcement)
- Profiles for the remaining 28 flavours
- Worked instances per profile

## Gate result
`rake profiles` validates 22 flavour profiles green.
