"""Validate examples/*.xml against relaton/grammars/biblio-standoc.rnc.

biblio.rnc is a pattern library: BibliographicItem is an unwrapped
attribute/child pattern, and consuming document grammars supply the
element wrapper, `start`, inline-markup constructs (br, fn), basicdoc
image patterns, and code-list types. This validator composes the same
way a consumer does, in a temp dir (rnc2rng resolves includes against
the CWD and cannot nest `grammar { }` wrappers, so the base wrapper is
stripped first).
"""
import os
import re
import sys
import tempfile
from pathlib import Path

import rnc2rng
from lxml import etree

ROOT = Path(__file__).resolve().parent.parent
G = ROOT / "relaton" / "grammars"

COMPOSER = """
include "biblio-standoc.rnc"

# Consuming grammars wrap the item pattern in the bibdata element.
start = element bibdata { BibData }

# Stubs for constructs supplied elsewhere: amend by the document grammar,
# br/fn/image-no-id by basicdoc, code-list types by their registries.
amend = notAllowed
br = element br { text }
fn = element fn { text }
TextElement = text
PureTextElement = text
BasicBlockNoId = text
image-no-id = element image { (attribute * { text })*, empty }
LanguageType = text
ScriptType = text
LocaleType = text
IdRefType = text
"""


def build_schema():
    with tempfile.TemporaryDirectory() as td:
        td = Path(td)
        base = re.sub(r"^\s*grammar\s*\{", "", (G / "biblio.rnc").read_text(), count=1)
        lines = base.rstrip().splitlines()
        while lines and (not lines[-1].strip() or lines[-1].strip() == "}"):
            lines.pop()
        (td / "biblio.rnc").write_text("\n".join(lines) + "\n")
        (td / "biblio-standoc.rnc").write_text((G / "biblio-standoc.rnc").read_text())
        (td / "composer.rnc").write_text(COMPOSER)
        cwd = os.getcwd()
        os.chdir(td)
        try:
            rng = rnc2rng.dumps(rnc2rng.loads(COMPOSER))
        finally:
            os.chdir(cwd)
    return etree.RelaxNG(etree.fromstring(rng.encode()))


schema = build_schema()

failed = 0
for xml_path in sorted((ROOT / "examples").glob("*.xml")):
    doc = etree.parse(str(xml_path))
    if schema.validate(doc):
        print(f"fixtures:xml OK {xml_path.name}")
    else:
        failed += 1
        print(f"fixtures:xml FAIL {xml_path.name}")
        for e in schema.error_log:
            print(f"  line {e.line}: {e.message}")
sys.exit(1 if failed else 0)
