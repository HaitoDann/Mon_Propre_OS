#!/usr/bin/env python3
"""Reporte les traductions de translations/<langue>_*.py dans translations/vinx_<langue>.ts.

Usage : fill_translations.py en [catalogue.ts]
Les messages du catalogue (extraits par lupdate) sont traduits d'après leur texte source français ;
le script échoue (code 1) et liste les textes sans traduction, pour que rien ne reste en français.
"""
import glob
import importlib.util
import os
import sys
import xml.etree.ElementTree as ET

lang = sys.argv[1] if len(sys.argv) > 1 else "en"
here = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "translations")
table = {}
for path in sorted(glob.glob(os.path.join(here, f"{lang}_*.py"))):
    spec = importlib.util.spec_from_file_location(os.path.basename(path)[:-3], path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    table.update(mod.T)

ts = sys.argv[2] if len(sys.argv) > 2 else os.path.join(here, f"vinx_{lang}.ts")
tree = ET.parse(ts)
missing = set()
for msg in tree.iter("message"):
    src = msg.findtext("source") or ""
    tr = msg.find("translation")
    if tr is None:
        tr = ET.SubElement(msg, "translation")
    for child in list(tr):
        tr.remove(child)
    tr.text = None
    tr.attrib.pop("type", None)
    value = table.get(src)
    if value is None:
        missing.add(src)
        tr.set("type", "unfinished")
        continue
    if msg.get("numerus") == "yes":
        one, many = value if isinstance(value, tuple) else (value, value)
        for form in (one, many):
            ET.SubElement(tr, "numerusform").text = form
    else:
        tr.text = value[1] if isinstance(value, tuple) else value

tree.write(ts, encoding="utf-8", xml_declaration=True)
if missing:
    print(f"{len(missing)} texte(s) sans traduction :", file=sys.stderr)
    for m in sorted(missing):
        print("  " + repr(m), file=sys.stderr)
    sys.exit(1)
print(f"{os.path.basename(ts)} : toutes les traductions sont présentes.")
