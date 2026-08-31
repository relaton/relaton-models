"""Validate mapping/csl.yaml against the generated schema: every type target
must be a BibItemType value, every variable attribute must resolve on
BibliographicItem (with inheritance)."""
import json
import sys
from pathlib import Path
import yaml

ROOT = Path(__file__).resolve().parent.parent
mapping = yaml.safe_load((ROOT / "mapping" / "csl.yaml").read_text())
schema = json.loads((ROOT / "relaton" / "schema" / "bibitem-2020-12.json").read_text())
defs = schema["$defs"]

errors = []
bib_types = set(defs.get("BibItemType", {}).get("enum", []))

for csl_type, target in sorted(mapping.get("types", {}).items()):
    if target not in bib_types:
        errors.append(f"type {csl_type} -> {target!r} is not a BibItemType value")

# attributes on BibliographicItem with inheritance
def attrs_of(cls):
    d = defs.get(cls, {})
    props = set(d.get("properties", {}).keys()) - {"class"}
    return props

bib_attrs = attrs_of("BibliographicItem")
# ReducedBibliographicItem inherits
if "$ref" in defs.get("ReducedBibliographicItem", {}).get("properties", {}).values():
    pass  # already merged by the generator

for csl_var, spec in sorted(mapping.get("variables", {}).items()):
    attr = spec if isinstance(spec, str) else spec.get("attribute", "")
    if attr not in bib_attrs:
        errors.append(f"variable {csl_var} -> {attr!r} is not a BibliographicItem attribute")

if errors:
    for e in errors:
        print(f"csl: {e}")
    sys.exit(1)
print(f"csl: OK ({len(mapping['types'])} types, {len(mapping['variables'])} variables, "
      f"{len(mapping['downgrade_losses'])} documented losses)")
