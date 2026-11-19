#!/usr/bin/env python3
"""Génère le singleton QML Theme.qml à partir de branding/tokens.toml.

Usage : gen_theme.py <tokens.toml> <Theme.qml> [vinxtokens.h]
Le troisième argument (facultatif) écrit les mêmes valeurs pour le C++ (applications Qt Widgets).
"""
import re
import sys
import tomllib

HEX = re.compile(r"^#([0-9a-fA-F]{6})([0-9a-fA-F]{2})?$")


def camel(*parts: str) -> str:
    words = "_".join(parts).split("_")
    return words[0] + "".join(w[:1].upper() + w[1:] for w in words[1:])


def qml_color(value: str) -> str:
    """#RRGGBB[AA] (CSS) → "#[AA]RRGGBB" (QML)."""
    m = HEX.match(value)
    if not m:
        raise ValueError(f"couleur invalide : {value}")
    rgb, alpha = m.group(1), m.group(2)
    return f'"#{alpha or ""}{rgb}"'.upper()


def main() -> None:
    src, dst = sys.argv[1], sys.argv[2]
    with open(src, "rb") as f:
        t = tomllib.load(f)

    out = [
        "// FICHIER GÉNÉRÉ par shell/tools/gen_theme.py depuis branding/tokens.toml — ne pas modifier.",
        "pragma Singleton",
        "import QtQuick",
        "",
        "QtObject {",
        "    // Thème courant ; modifiable à l'exécution (Paramètres).",
        "    property bool dark: true",
        "    // Accent choisi (identifiant de [accents] dans tokens.toml) ; réglé par AppearanceSync.",
        f'    property string accentId: "{t["brand"]["default_accent"]}"',
        "    // Nuancier : { id, name, fill, ink, text } (couleurs en chaînes #RRGGBB).",
        "    readonly property var accents: [",
    ]
    for key, a in t["accents"].items():
        for c in ("fill", "ink", "text"):
            qml_color(a[c])  # validation
        # Nom traduit (contexte « Accent ») : les textes source sont déclarés dans common/accentnames.h.
        out.append(f'        {{ id: "{key}", name: qsTranslate("Accent", "{a["name"]}"), fill: "{a["fill"]}", ink: "{a["ink"]}", text: "{a["text"]}" }},')
    out += [
        "    ]",
        "    readonly property var accentEntry: accents.find(a => a.id === accentId) || accents[0]",
        "",
        "    // Accent (sobre, réservé aux états et à l'action principale)",
        "    readonly property color accent: accentEntry.fill",
        "    // Texte, icônes et anneaux de focus colorés",
        "    readonly property color accentForeground: dark ? accentEntry.fill : accentEntry.text",
        "    // Encre posée sur l'accent",
        "    readonly property color accentText: accentEntry.ink",
        "    // Couleur du logo : suit l'accent",
        "    readonly property color logo: accentEntry.fill",
    ]
    out += ["", "    // États"]
    for key, val in t["state"].items():
        out.append(f"    readonly property color {camel(key)}: {qml_color(val)}")

    out += ["", "    // Couleurs liées au thème"]
    hc = t.get("themed_high_contrast", {})
    out.insert(out.index("    // Couleurs liées au thème"), "    // Contraste élevé (Accessibilité) : couleurs plus marquées pour le texte, les bordures et les fonds.")
    out.insert(out.index("    // Couleurs liées au thème"), "    property bool highContrast: false")
    for key, (dark, light) in t["themed"].items():
        normal = f"(dark ? {qml_color(dark)} : {qml_color(light)})"
        if key in hc:
            hd, hl = hc[key]
            out.append(f"    readonly property color {camel(key)}: highContrast ? (dark ? {qml_color(hd)} : {qml_color(hl)}) : {normal}")
        else:
            out.append(f"    readonly property color {camel(key)}: {normal}")

    out += ["", "    // Accessibilité (réglées par AppearanceSync depuis les préférences)",
            "    property bool reduceMotion: false",
            "    property real textScale: 1.0",
            "    // Style des formes : « soft » (coins arrondis, biseau réservé aux signatures) ou « bevel ».",
            "    property string shapeStyle: \"soft\""]
    out += ["", "    // Typographie", f'    readonly property string fontFamily: "{t["font"]["family"]}"']
    for key, val in t["font"].items():
        if key != "family":
            out.append(f"    readonly property int {camel('fs', key)}: Math.round({val} * textScale)")

    for section, prefix in (("space", "space"), ("radius", "radius"), ("shell", ""), ("motion", "dur")):
        out += ["", f"    // {section}"]
        for key, val in t[section].items():
            name = camel(prefix, key.lstrip("s") if section == "space" else key) if prefix else camel(key)
            v = f"reduceMotion ? 0 : {val}" if section == "motion" else val
            out.append(f"    readonly property int {name}: {v}")

    out += ["}", ""]
    with open(dst, "w", encoding="utf-8") as f:
        f.write("\n".join(out))
    if len(sys.argv) > 3:
        write_header(t, sys.argv[3])


def write_header(t: dict, dst: str) -> None:
    """vinxtokens.h : accents et couleurs liées au thème, pour le C++."""
    h = ["// FICHIER GÉNÉRÉ par shell/tools/gen_theme.py depuis branding/tokens.toml — ne pas modifier.",
         "#pragma once", "", "namespace vinx::tokens {", "",
         "struct Accent { const char *id, *name, *fill, *ink, *text; };",
         f'inline constexpr const char *defaultAccent = "{t["brand"]["default_accent"]}";',
         "inline constexpr Accent accents[] = {"]
    for key, a in t["accents"].items():
        h.append(f'    {{"{key}", "{a["name"]}", "{a["fill"]}", "{a["ink"]}", "{a["text"]}"}},')
    h += ["};", "", "// Couleurs liées au thème : { sombre, clair } (#RRGGBB ou #RRGGBBAA)."]
    for key, (dark, light) in t["themed"].items():
        qml_color(dark), qml_color(light)
        h.append(f'inline constexpr const char *{camel(key)}[2] = {{"{dark}", "{light}"}};')
    for key, val in t["state"].items():
        h.append(f'inline constexpr const char *{camel(key)} = "{val}";')
    h += ["", "} // namespace vinx::tokens", ""]
    with open(dst, "w", encoding="utf-8") as f:
        f.write("\n".join(h))


if __name__ == "__main__":
    main()
