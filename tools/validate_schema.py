"""Validate examples/*.yaml against the generated JSON Schema (draft 2020-12)."""
import sys
from pathlib import Path
import json
import yaml
from jsonschema import Draft202012Validator

ROOT = Path(__file__).resolve().parent.parent
base = json.loads((ROOT / "relaton" / "schema" / "bibitem-2020-12.json").read_text())
validator = Draft202012Validator(base)
style_validator = Draft202012Validator({**base, "$ref": "#/$defs/CitationStyle"})

failed = 0
for path in sorted((ROOT / "citation" / "styles").glob("*.yml")):
    data = yaml.safe_load(path.read_text())
    errors = sorted(style_validator.iter_errors(data), key=lambda e: list(e.path))
    if errors:
        failed += 1
        print(f"fixtures:schema FAIL {path.name} (CitationStyle)")
        for e in errors[:5]:
            print(f"  {'/'.join(map(str, e.path)) or '/'}: {e.message[:160]}")
    else:
        print(f"fixtures:schema OK {path.name} (CitationStyle)")

for path in sorted((ROOT / "examples").glob("*.yaml")):
    data = yaml.safe_load(path.read_text())
    if isinstance(data, dict) and len(data) == 1 and "class" not in data:
        data = next(iter(data.values()))
    errors = sorted(validator.iter_errors(data), key=lambda e: list(e.path))
    if errors:
        failed += 1
        print(f"fixtures:schema FAIL {path.name}")
        for e in errors[:5]:
            print(f"  {'/'.join(map(str, e.path)) or '/'}: {e.message[:160]}")
    else:
        print(f"fixtures:schema OK {path.name}")
sys.exit(1 if failed else 0)
