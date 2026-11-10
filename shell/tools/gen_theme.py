#!/usr/bin/env python3
"""Génère le singleton QML Theme.qml à partir de branding/tokens.toml.

Usage : gen_theme.py <tokens.toml> <Theme.qml>
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
        "    // Couleur d'accent choisie par l'utilisateur (transparent = accent de marque).",
        '    property color accentOverride: "transparent"',
        "",
        "    // Accent (sobre, réservé aux états et à l'action principale)",
        f"    readonly property color accent: accentOverride.a > 0 ? accentOverride : (dark ? {qml_color(t['brand']['accent_fill'][0])} : {qml_color(t['brand']['accent_fill'][1])})",
        f"    readonly property color accentForeground: accentOverride.a > 0 ? accentOverride : (dark ? {qml_color(t['brand']['accent_foreground'][0])} : {qml_color(t['brand']['accent_foreground'][1])})",
        f"    readonly property color accentText: {qml_color(t['brand']['accent_text'])}",
        "    // Couleur du logo (marque) — ne pas utiliser pour l'interface",
        f"    readonly property color logo: {qml_color(t['brand']['logo'])}",
    ]
    out += ["", "    // États"]
    for key, val in t["state"].items():
        out.append(f"    readonly property color {camel(key)}: {qml_color(val)}")

    out += ["", "    // Couleurs liées au thème"]
    for key, (dark, light) in t["themed"].items():
        out.append(f"    readonly property color {camel(key)}: dark ? {qml_color(dark)} : {qml_color(light)}")

    out += ["", "    // Typographie", f'    readonly property string fontFamily: "{t["font"]["family"]}"']
    for key, val in t["font"].items():
        if key != "family":
            out.append(f"    readonly property int {camel('fs', key)}: {val}")

    for section, prefix in (("space", "space"), ("radius", "radius"), ("shell", ""), ("motion", "dur")):
        out += ["", f"    // {section}"]
        for key, val in t[section].items():
            name = camel(prefix, key.lstrip("s") if section == "space" else key) if prefix else camel(key)
            out.append(f"    readonly property int {name}: {val}")

    out += ["}", ""]
    with open(dst, "w", encoding="utf-8") as f:
        f.write("\n".join(out))


if __name__ == "__main__":
    main()
