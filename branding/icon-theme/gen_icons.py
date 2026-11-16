#!/usr/bin/env python3
"""Génère le thème d'icônes « VinX » (freedesktop) à partir des pictogrammes de branding/icons.

Style (docs/DESIGN.md, ADR 0015) : chaque icône a la silhouette de son objet (dossier, page,
enveloppe, globe, fenêtre…), remplie d'une teinte unie désaturée, avec le pictogramme VinX
blanc au trait centré dedans. Pas de dégradé, pas d'ombre : une seule ombre portée douce.

Usage : gen_icons.py DOSSIER_SORTIE
"""
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
GLYPHS = os.path.join(HERE, "..", "icons")

# Silhouettes sur une grille 64 × 64 (marges de 4 px).
SHAPES = {
    "folder":   "M6 16a4 4 0 0 1 4-4h14l5 5h25a4 4 0 0 1 4 4v29a4 4 0 0 1-4 4H10a4 4 0 0 1-4-4Z",
    "page":     "M14 6h24l14 14v34a4 4 0 0 1-4 4H14a4 4 0 0 1-4-4V10a4 4 0 0 1 4-4Z",
    "circle":   "M18 6H46A12 12 0 0 1 58 18V46A12 12 0 0 1 46 58H18A12 12 0 0 1 6 46V18A12 12 0 0 1 18 6Z",  # tuile arrondie (style doux)
    "envelope": "M8 14h48a4 4 0 0 1 4 4v28a4 4 0 0 1-4 4H8a4 4 0 0 1-4-4V18a4 4 0 0 1 4-4Z",
    "window":   "M10 8h44a5 5 0 0 1 5 5v38a5 5 0 0 1-5 5H10a5 5 0 0 1-5-5V13a5 5 0 0 1 5-5Z",
    "bag":      "M14 20h36l3 32a5 5 0 0 1-5 6H16a5 5 0 0 1-5-6Z",
    "drive":    "M8 34h48a3 3 0 0 1 3 3v12a4 4 0 0 1-4 4H9a4 4 0 0 1-4-4V37a3 3 0 0 1 3-3ZM14 12h36l7 22H7Z",
    "trash":    "M14 18h36l-3 36a4 4 0 0 1-4 4H21a4 4 0 0 1-4-4ZM10 12h44v6H10Z",
}
# Pli du coin de page, dessiné en plus clair.
PAGE_FOLD = "M38 6v10a4 4 0 0 0 4 4h10Z"
# Zone utile du pictogramme pour chaque silhouette : (x, y, taille).
GLYPH_BOX = {
    "folder": (19, 23, 26), "page": (19, 26, 26), "circle": (17, 17, 30), "envelope": (19, 19, 26),
    "window": (19, 20, 26), "bag": (20, 27, 24), "drive": (21, 13, 22), "trash": (22, 26, 20),
}

# Teintes sobres de luminosité proche (docs/DESIGN.md §5).
T = {"blue": "#4C6FA8", "orange": "#B8693F", "indigo": "#4F60A3", "green": "#3E8460", "teal": "#3F7896",
     "red": "#A8514F", "violet": "#6548AE", "grey": "#5F6270", "dark": "#2E3036", "ochre": "#A88A3E",
     "rose": "#9C5577", "wine": "#A34E62", "slate": "#55657A"}

# nom d'icône → (silhouette, teinte, pictogramme, contexte)
ICONS = {
    # Applications
    "org.vinx.files": ("folder", T["blue"], "folder", "apps"),
    "system-file-manager": ("folder", T["blue"], "folder", "apps"),
    "org.kde.dolphin": ("folder", T["slate"], "grid", "apps"),
    "firefox-esr": ("circle", T["orange"], "globe", "apps"),
    "firefox": ("circle", T["orange"], "globe", "apps"),
    "libreoffice-writer": ("page", T["indigo"], "doc", "apps"),
    "libreoffice-calc": ("page", T["green"], "table", "apps"),
    "libreoffice-impress": ("page", T["orange"], "image", "apps"),
    "libreoffice-startcenter": ("page", T["grey"], "doc", "apps"),
    "thunderbird": ("envelope", T["teal"], "mail", "apps"),
    "org.vinx.store": ("bag", T["violet"], "bag", "apps"),
    "org.vinx.settings": ("circle", T["grey"], "sliders", "apps"),
    "systemsettings": ("circle", T["grey"], "sliders", "apps"),
    "org.vinx.welcome": ("circle", T["violet"], "info", "apps"),
    "utilities-terminal": ("window", T["dark"], "terminal", "apps"),
    "org.kde.konsole": ("window", T["dark"], "terminal", "apps"),
    "org.kde.kate": ("page", T["slate"], "note", "apps"),
    "accessories-text-editor": ("page", T["slate"], "note", "apps"),
    "org.kde.gwenview": ("window", T["rose"], "image", "apps"),
    "org.kde.okular": ("page", T["red"], "doc", "apps"),
    "vlc": ("circle", T["wine"], "video", "apps"),
    "calamares": ("circle", T["violet"], "download", "apps"),
    "help-browser": ("circle", T["grey"], "info", "apps"),
    "preferences-desktop-notification": ("circle", T["grey"], "bell", "apps"),
    # Emplacements
    "folder": ("folder", T["blue"], None, "places"),
    "inode-directory": ("folder", T["blue"], None, "mimetypes"),
    "user-home": ("folder", T["blue"], "home", "places"),
    "user-desktop": ("folder", T["blue"], "grid", "places"),
    "folder-documents": ("folder", T["blue"], "doc", "places"),
    "folder-download": ("folder", T["blue"], "download", "places"),
    "folder-downloads": ("folder", T["blue"], "download", "places"),
    "folder-pictures": ("folder", T["blue"], "image", "places"),
    "folder-images": ("folder", T["blue"], "image", "places"),
    "folder-music": ("folder", T["blue"], "music", "places"),
    "folder-videos": ("folder", T["blue"], "video", "places"),
    "folder-templates": ("folder", T["blue"], "note", "places"),
    "folder-publicshare": ("folder", T["blue"], "globe", "places"),
    "folder-remote": ("folder", T["slate"], "globe", "places"),
    "network-workgroup": ("circle", T["slate"], "globe", "places"),
    "user-trash": ("trash", T["grey"], None, "places"),
    "user-trash-full": ("trash", T["grey"], "doc", "places"),
    "drive-harddisk": ("drive", T["grey"], None, "devices"),
    "drive-removable-media": ("drive", T["slate"], None, "devices"),
    "drive-removable-media-usb": ("drive", T["slate"], None, "devices"),
    "media-removable": ("drive", T["slate"], None, "devices"),
    # Types de fichiers
    "text-x-generic": ("page", T["grey"], "note", "mimetypes"),
    "text-plain": ("page", T["grey"], "note", "mimetypes"),
    "application-pdf": ("page", T["red"], "doc", "mimetypes"),
    "image-x-generic": ("page", T["rose"], "image", "mimetypes"),
    "audio-x-generic": ("page", T["wine"], "music", "mimetypes"),
    "video-x-generic": ("page", T["wine"], "video", "mimetypes"),
    "application-x-executable": ("page", T["dark"], "terminal", "mimetypes"),
    "text-x-script": ("page", T["dark"], "terminal", "mimetypes"),
    "application-x-shellscript": ("page", T["dark"], "terminal", "mimetypes"),
    "package-x-generic": ("page", T["ochre"], "bag", "mimetypes"),
    "application-zip": ("page", T["ochre"], "bag", "mimetypes"),
    "application-x-compressed-tar": ("page", T["ochre"], "bag", "mimetypes"),
    "application-vnd.oasis.opendocument.text": ("page", T["indigo"], "doc", "mimetypes"),
    "application-vnd.openxmlformats-officedocument.wordprocessingml.document": ("page", T["indigo"], "doc", "mimetypes"),
    "x-office-document": ("page", T["indigo"], "doc", "mimetypes"),
    "application-vnd.oasis.opendocument.spreadsheet": ("page", T["green"], "table", "mimetypes"),
    "application-vnd.openxmlformats-officedocument.spreadsheetml.sheet": ("page", T["green"], "table", "mimetypes"),
    "x-office-spreadsheet": ("page", T["green"], "table", "mimetypes"),
    "application-vnd.oasis.opendocument.presentation": ("page", T["orange"], "image", "mimetypes"),
    "x-office-presentation": ("page", T["orange"], "image", "mimetypes"),
    "text-html": ("page", T["orange"], "globe", "mimetypes"),
    "application-x-generic": ("page", T["grey"], None, "mimetypes"),
    "unknown": ("page", T["grey"], None, "mimetypes"),
}


def glyph_body(name):
    """Contenu (éléments) d'un pictogramme 24 × 24 au trait."""
    with open(os.path.join(GLYPHS, name + ".svg"), encoding="utf-8") as f:
        svg = f.read()
    return re.sub(r"^.*?<svg[^>]*>|</svg>\s*$", "", svg, flags=re.S)


def lighten(hex_color, amount):
    c = [int(hex_color[i:i + 2], 16) for i in (1, 3, 5)]
    c = [round(v + (255 - v) * amount) for v in c]
    return "#%02X%02X%02X" % tuple(c)


def icon_svg(shape, tint, glyph):
    parts = [
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64">',
        '<defs><filter id="s" x="-20%" y="-20%" width="140%" height="140%">'
        '<feDropShadow dx="0" dy="1" stdDeviation="1" flood-color="#000" flood-opacity=".25"/></filter></defs>',
        f'<path d="{SHAPES[shape]}" fill="{tint}" filter="url(#s)"/>',
    ]
    if shape == "page":
        parts.append(f'<path d="{PAGE_FOLD}" fill="{lighten(tint, .35)}"/>')
    if shape == "folder":   # rabat avant légèrement plus clair, donne la forme du dossier
        parts.append(f'<path d="M6 24a4 4 0 0 1 4-4h44a4 4 0 0 1 4 4v26a4 4 0 0 1-4 4H10a4 4 0 0 1-4-4Z" fill="{lighten(tint, .12)}"/>')
    if glyph:
        x, y, size = GLYPH_BOX[shape]
        s = size / 24
        parts.append(f'<g transform="translate({x} {y}) scale({s:.4f})" color="#FFFFFF" fill="none" stroke="#FFFFFF" '
                     f'stroke-linecap="round" stroke-linejoin="round" stroke-width="{1.8 / s * 1.35:.2f}">'
                     f'{glyph_body(glyph)}</g>')
    parts.append("</svg>")
    return "".join(parts)


INDEX = """[Icon Theme]
Name=VinX
Comment=Icônes de VinX OS : silhouettes unies et pictogrammes au trait
Inherits=breeze,hicolor
Directories=scalable/apps,scalable/places,scalable/mimetypes,scalable/devices

[scalable/apps]
Size=64
MinSize=16
MaxSize=512
Type=Scalable
Context=Applications

[scalable/places]
Size=64
MinSize=16
MaxSize=512
Type=Scalable
Context=Places

[scalable/mimetypes]
Size=64
MinSize=16
MaxSize=512
Type=Scalable
Context=MimeTypes

[scalable/devices]
Size=64
MinSize=16
MaxSize=512
Type=Scalable
Context=Devices
"""


def main(out):
    for ctx in ("apps", "places", "mimetypes", "devices"):
        os.makedirs(os.path.join(out, "scalable", ctx), exist_ok=True)
    with open(os.path.join(out, "index.theme"), "w", encoding="utf-8") as f:
        f.write(INDEX)
    for name, (shape, tint, glyph, ctx) in ICONS.items():
        with open(os.path.join(out, "scalable", ctx, name + ".svg"), "w", encoding="utf-8") as f:
            f.write(icon_svg(shape, tint, glyph))
    print(f"{len(ICONS)} icônes générées dans {out}")


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else "VinX")
