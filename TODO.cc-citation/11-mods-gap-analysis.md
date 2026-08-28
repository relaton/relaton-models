# 11 — Gap analysis against MODS (issue #18)

**Status: done** · Output: atlas page + filed issues

RelBib ↔ MODS 3.8 element mapping (titleInfo, name, originInfo/place/publisher,
dateIssued, identifier[@type=ISSN|ISBN|DOI|URI], location/physicalLocation/url,
typeOfResource ↔ BibItemType, relatedItem ↔ relation family, note,
classification ↔ classification, genre ↔ medium/genre, part/detail ↔ extent
+ numeration). Deliverable: mapping table as data (same shape as 08's
mapping/csl.yaml), gap findings as model issues feeding 03. MODS strengths
to check for absorption: held/record-level metadata, institutional item
records — exactly the L2 "external metadata sources" (clause 6) territory.

## Done
`docs/MODS-GAP-ANALYSIS.md` contains the full mapping table and gap findings.
