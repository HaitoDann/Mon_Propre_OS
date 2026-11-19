#!/usr/bin/env python3
"""Contrastes WCAG 2.2 AA des couleurs de branding/tokens.toml (docs/DESIGN.md, § 2).

Texte courant ≥ 4,5:1 ; texte tertiaire (indications, désactivé) ≥ 3:1. Clair et sombre, sur
les surfaces où le texte est posé, pour chaque couleur d'accent.
Usage : contrast.py tokens.toml
"""
import sys
import tomllib


def rgb(c):
    c = c.lstrip("#")[:6]
    return [int(c[i:i + 2], 16) / 255 for i in (0, 2, 4)]


def lum(c):
    v = [x / 12.92 if x <= 0.04045 else ((x + 0.055) / 1.055) ** 2.4 for x in rgb(c)]
    return 0.2126 * v[0] + 0.7152 * v[1] + 0.0722 * v[2]


def ratio(a, b):
    la, lb = sorted((lum(a), lum(b)), reverse=True)
    return (la + 0.05) / (lb + 0.05)


t = tomllib.load(open(sys.argv[1], "rb"))
th = t["themed"]
fails = []


def check(label, fg, bg, minimum):
    r = ratio(fg, bg)
    if r < minimum:
        fails.append(f"{label} : {r:.2f}:1 < {minimum}:1 ({fg} sur {bg})")


for mode, i in (("sombre", 0), ("clair", 1)):
    for surf in ("background", "surface_window", "surface_glass_strong", "surface_sunken"):
        bg = th[surf][i]
        check(f"{mode} text/{surf}", th["text"][i], bg, 4.5)
        check(f"{mode} text_secondary/{surf}", th["text_secondary"][i], bg, 4.5)
        check(f"{mode} text_tertiary/{surf}", th["text_tertiary"][i], bg, 3.0)
for key, a in t["accents"].items():
    check(f"{key} : encre sur l'accent", a["ink"], a["fill"], 4.5)
    # Texte coloré : clair = « text » sur les surfaces claires ; sombre = l'accent lui-même.
    for surf in ("surface_window", "surface_sunken", "background"):
        check(f"{key} : texte coloré clair/{surf}", a["text"], th[surf][1], 4.5)
        check(f"{key} : texte coloré sombre/{surf}", a["fill"], th[surf][0], 4.5)

for f in fails:
    print("contraste insuffisant —", f)
print("contrastes : OK" if not fails else f"{len(fails)} contraste(s) insuffisant(s)")
sys.exit(1 if fails else 0)
