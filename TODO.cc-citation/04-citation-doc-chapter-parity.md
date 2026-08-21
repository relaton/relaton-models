# 04 — citation-doc chapter parity with iso-690 (L1 → L2)

**Status: open** · Repo: CalConnect/cc-citation-models, source metanorma/iso-690

## Why
citation-doc must be the full implementation of ISO 690 in model form. It is
missing four chapters that exist in iso-690 (0704-component-parts,
0707-date, 0713-surrogate, 0714-relation) and every shared chapter lags the
DIS text (latest: a07b75b "DIS FR003-014"). Most of its 285 dangling xrefs
point into exactly this missing content.

## Changes
1. Port the four chapters from iso-690, adding the `Serialisation:` mapping
   lines (cc's annotation pattern) per element:
   - 0704 → `bibitem/relation[type=includedIn|includes]`, `bibitem/extent`,
     `relation/locality`
   - 0707 → `bibitem/date`, `date/@type`, `date/on|from|to`, `date/@text`
   - 0713 → `bibitem/relation[type=manifestationOf|reproductionOf]`
   - 0714 → `bibitem/relation/@type` (the 59-value vocabulary, 07141 already
     generated from the model)
2. Re-sync drifted shared chapters to DIS a07b75b **preserving** cc's
   `Source:`/`Serialisation:` annotations (mechanical three-way: DIS text as
   base, re-apply annotations).
3. Restore the four includes in `07-elements.adoc`; verify anchor parity
   (every `[[x]]` in iso-690 clause 7 exists in cc).
4. Note: iso-690 has uncommitted WIP in `03-termsdef.adoc` — never touch;
   sync from committed DIS only.

## Gates
`metanorma -t cc` / `-t iso` build with zero unresolved includes;
dangling-xref count drops from 285 to the MODS-era residue; include crawl 0.
