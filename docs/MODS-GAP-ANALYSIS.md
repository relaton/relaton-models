# Gap analysis: Relaton vs MODS 3.x

**Status:** initial mapping (TODO.cc-citation/11)

MODS (Metadata Object Description Schema, Library of Congress) is a
descriptive metadata standard for bibliographic resources. This document
maps Relaton constructs to MODS 3 elements and identifies gaps.

## Mapping

| MODS element | Relaton construct | Coverage |
|---|---|---|
| `<titleInfo>/<title>` | `TypedTitleString` (+ `TitleType`) | ✓ (typed) |
| `<titleInfo>@type` | `TitleType` enum | ✓ |
| `<name>` | `Contributor` → `Person`/`Organization` | ✓ |
| `<name>@type` (personal/corporate) | `Person` vs `Organization` | ✓ |
| `<nameRole>/<roleTerm>` | `ContributorRoleType` | ✓ (richer) |
| `<namePart>@type` (family/given/date/termsOfAddress) | `FullName.{surname, forenames, ...}` | ✓ |
| `<originInfo>/<place>` | `PlaceType` | ✓ |
| `<originInfo>/<publisher>` | `ContributionInfo[role=publisher]` | ✓ |
| `<originInfo>/<dateIssued>` | `BibliographicDate[type=published]` | ✓ |
| `<originInfo>/<dateCreated>` | `BibliographicDate[type=created]` | ✓ |
| `<originInfo>/<dateModified>` | `BibliographicDate[type=updated]` | ✓ |
| `<originInfo>/<edition>` | `Edition` (+ `audience`) | ✓ (richer) |
| `<typeOfResource>` | `BibItemType` | ✓ (ISO 690 types) |
| `<genre>` | `MediumType.genre` | ✓ |
| `<identifier>@type` (ISBN/ISSN/DOI/URI/LCCN/...) | `DocumentIdentifier.type` | ✓ (open) |
| `<location>/<url>` | `TypedUri` | ✓ (typed) |
| `<location>/<physicalLocation>` | `PlaceType` + `accessLocation` | ✓ |
| `<location>/<shelfLocator>` | `accessLocation` (URI) | ⚠ no dedicated shelf-locator |
| `<language>` | `Iso639Code` | ✓ |
| `<physicalDescription>` | `MediumType` | ✓ |
| `<abstract>` | `BasicBlock` (abstract) | ✓ |
| `<note>` | `TypedNote` | ✓ (typed) |
| `<subject>` | `classification` / `keyword` | ✓ |
| `<classification>` | `classification` | ✓ |
| `<relatedItem>@type` | `DocumentRelationType` | ✓ (much richer: 59 values) |
| `<part>/<detail>` | `extent` (LocalityStack) | ✓ |
| `<part>/<extent>` | `extent` | ✓ |
| `<recordInfo>` | (record-level metadata) | ⚠ gap |
| `<accessCondition>` | `license` | ✓ (simplified) |

## Gaps (Relaton → MODS)

1. **Shelf locator**: MODS has `<shelfLocator>` for physical location within
   a repository. Relaton uses generic `accessLocation` (URI) — consider a
   `ShelfLocator` data_type or a typed accessLocation variant.

2. **Record-level metadata**: MODS `<recordInfo>` (record creation date,
   record identifier, record origin, language of cataloging) maps to
   `fetched` + `schema_version` but has no dedicated construct. The Relaton
   `fetched` attribute partially covers record creation timestamp.

3. **Holdings**: MODS supports multiple `<location>` elements with different
   access conditions (physical, electronic, archival). Relaton has
   `accesslocation*` but no typed multi-location with per-location access
   conditions.

## Relaton advantages over MODS

- **63 relation types** (vs MODS ~10 relatedItem types)
- **ISO 690 resource types** (27 types with ISO 690 conformance)
- **Typed dates** (19 date types vs MODS's date point/range)
- **Contributor roles** (15 production roles vs MODS's free-text roleTerm)
- **FRBR-aware edition/version model** (audience-differentiated editions)
- **Validity windows** (not in MODS)
- **ISO 24229 spelling systems** (not in MODS)

## Recommendations

1. Consider adding a typed `ShelfLocator` or extending `accessLocation` with
   a location-type attribute
2. Document `recordInfo` mapping in the cc-citation-models document
3. Multi-location support is an architectural question for ISO 690
   (how many locations does a cited resource need?)
