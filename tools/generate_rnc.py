"""Generate RNC vocabulary definitions from LML enums.

Stage B of the LML-to-RNC generation (TODO.cc-citation/09):
- Stage A: parity gate (done — vocabulary parity in rake parity)
- Stage B: emit RNC vocab definitions from LML (this tool)
- Stage C: flip canonical (RNC becomes derived; hand-editing ends)

Usage:
  python3 tools/generate_rnc.py            # emit all mapped vocabularies
  python3 tools/generate_rnc.py --check    # compare emitted vs committed
"""
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

# LML enum name → RNC definition name + RNC file (same map as Rakefile parity)
VOCAB_MAP = {
    "DocumentRelationType": ("DocRelationType", "relaton/grammars/biblio.rnc"),
    "BibItemType": ("BibItemType", "relaton/grammars/biblio.rnc"),
    "BibliographicDateType": ("BibliographicDateType", "relaton/grammars/biblio.rnc"),
    "ContributorRoleType": ("ContributorRoleType", "relaton/grammars/biblio.rnc"),
}

def find_lml(lml_type):
    for pat in [f"*/models/**/{lml_type}.lml", f"*/models/{lml_type}.lml"]:
        hits = [p for p in ROOT.glob(pat) if "basicdoc" not in p.parts]
        if hits:
            return sorted(hits)[0]
    return None

def lml_values(path):
    s = path.read_text()
    vals = re.findall(r"^  ([^\s}]+?)[ ]*(?:\{|$)", s, re.M)
    return [v for v in vals if v != "definition" and v != "}"]

def generate_rnc(lml_type, rnc_name):
    lml = find_lml(lml_type)
    if not lml:
        return None
    vals = lml_values(lml)
    lines = [f"{rnc_name} ="]
    for i, v in enumerate(vals):
        sep = " |" if i < len(vals) - 1 else ""
        lines.append(f'  "{v}"{sep}')
    return "\n".join(lines) + "\n"

def extract_committed(rnc_path, rnc_name):
    rnc = (ROOT / rnc_path).read_text()
    matches = list(re.finditer(rf"^\s*{re.escape(rnc_name)}\s*=", rnc, re.M))
    if not matches:
        return None
    # take the match with the most quoted values
    best = ""
    for m in matches:
        rest = rnc[m.end():]
        stop = re.search(r"^(?:[A-Za-z-]+\s*=|^##|^\})", rest, re.M)
        region = rest[:stop.start()] if stop else rest[:500]
        if region.count('"') > best.count('"'):
            best = region
    return f"{rnc_name} = {best.strip()}"

def main(check=False):
    for lml_type, (rnc_name, rnc_path) in sorted(VOCAB_MAP.items()):
        generated = generate_rnc(lml_type, rnc_name)
        if generated is None:
            print(f"rnc:gen SKIP {lml_type} (no LML file)")
            continue
        committed = extract_committed(rnc_path, rnc_name)
        if check:
            fold = lambda v: re.sub(r"[ _]", "-", v).lower()
            gen_vals = set(fold(v) for v in re.findall(r'"([^"]+)"', generated))
            com_vals = set(fold(v) for v in re.findall(r'"([^"]+)"', committed or ""))
            if gen_vals != com_vals:
                print(f"rnc:gen DRIFT {lml_type}: "
                      f"generated-only={sorted(gen_vals - com_vals)[:3]} "
                      f"committed-only={sorted(com_vals - gen_vals)[:3]}")
            else:
                print(f"rnc:gen OK {lml_type} ({len(gen_vals)} values)")
        else:
            print(f"--- {rnc_name} (from {lml_type}) ---")
            print(generated)

if __name__ == "__main__":
    main("--check" in sys.argv)
