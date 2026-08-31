# 04 — citation-doc chapter parity with iso-690 (L1 → L2)

**Status: done (2026-08-31, CalConnect/cc-citation-models#12)** · Repo: CalConnect/cc-citation-models, source metanorma/iso-690

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

## Outcome (2026-08-31)

- Ported 0704/0707/0713/0714 with Serialisation mapping lines; chapters nest
  under clause 7 wrapper (`===`), fixing the flat top-level clause bug.
- Re-synced all shared clause-7 chapters to DIS a07b75b, preserving cc
  annotations and XML examples; date model content moved into 0707.
- Normative refs (ISO 4/216/3166-1/2/639-1/832) and bibliography entries
  (FIPS 202, PRONOM, IANA, Perma.CC, Wikipedia, DCC, APA, WIPO ST3) added.
- Gates: 0 asciidoctor errors; dangling xrefs 52 → 0 (577 xrefs resolve);
  anchor parity 65/65 DIS clause-7 anchors; cc-6900 published (CC 6900:2019),
  iso-6900 DIS 40.00.
- Also fixed metanorma.yml for the current metanorma-cli site manifest schema
  (collection under metanorma:), unblocking the site workflow (broken since
  2026-05 on all branches).
