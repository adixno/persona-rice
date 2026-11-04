#!/usr/bin/env python3
"""Apply a red/black/white high-contrast scheme to the Caelestia shell.

Run again whenever `caelestia scheme set` or a wallpaper change overwrites it.
"""
import json
from pathlib import Path

state = Path.home() / ".local/state/caelestia/scheme.json"

RED, RED_DIM, RED_DARK = "e60012", "b8000e", "5c0007"
INK, PAPER = "0a0a0a", "f4f4f4"

c = {
    "background": INK, "onBackground": PAPER,
    "surface": INK, "surfaceDim": INK, "surfaceBright": "2a2a2a",
    "surfaceContainerLowest": "000000", "surfaceContainerLow": "111111",
    "surfaceContainer": "151515", "surfaceContainerHigh": "1d1d1d",
    "surfaceContainerHighest": "262626",
    "onSurface": PAPER, "surfaceVariant": "262626", "onSurfaceVariant": "c8c8c8",
    "inverseSurface": PAPER, "inverseOnSurface": INK,
    "outline": RED, "outlineVariant": "3a3a3a",
    "shadow": "000000", "scrim": "000000", "surfaceTint": RED,
    "primary": RED, "primaryDim": RED_DIM, "onPrimary": "ffffff",
    "primaryContainer": RED_DARK, "onPrimaryContainer": "ffffff",
    "inversePrimary": RED_DIM,
    "primaryFixed": "ff4d5e", "primaryFixedDim": RED, "onPrimaryFixed": "000000",
    "onPrimaryFixedVariant": RED_DARK,
    # secondary = white "paper" accents, tertiary = deeper red
    "secondary": PAPER, "secondaryDim": "d0d0d0", "onSecondary": INK,
    "secondaryContainer": "2e2e2e", "onSecondaryContainer": PAPER,
    "secondaryFixed": PAPER, "secondaryFixedDim": "d0d0d0",
    "onSecondaryFixed": INK, "onSecondaryFixedVariant": "2e2e2e",
    "tertiary": "ff3344", "tertiaryDim": RED, "onTertiary": "ffffff",
    "tertiaryContainer": RED_DIM, "onTertiaryContainer": "ffffff",
    "tertiaryFixed": "ff3344", "tertiaryFixedDim": RED,
    "onTertiaryFixed": "000000", "onTertiaryFixedVariant": RED_DARK,
    "error": "ffcc00", "errorDim": "d4a900", "onError": INK,
    "errorContainer": "5c4a00", "onErrorContainer": "fff0b3",
    "success": "f4f4f4", "onSuccess": INK, "successContainer": "2e2e2e",
    "onSuccessContainer": PAPER,
    "primary_paletteKeyColor": RED, "secondary_paletteKeyColor": "808080",
    "tertiary_paletteKeyColor": RED_DIM, "neutral_paletteKeyColor": "777777",
    "neutral_variant_paletteKeyColor": "777777",
    # terminal / catppuccin-style named colours
    "term0": "1a1a1a", "term1": RED, "term2": "f4f4f4", "term3": "ffcc00",
    "term4": "ff4d5e", "term5": "ff3344", "term6": "d0d0d0", "term7": PAPER,
    "term8": "4a4a4a", "term9": "ff3344", "term10": "ffffff", "term11": "ffe066",
    "term12": "ff8090", "term13": "ff6677", "term14": "e0e0e0", "term15": "ffffff",
    "text": PAPER, "subtext1": "d0d0d0", "subtext0": "a0a0a0",
    "overlay2": "8a8a8a", "overlay1": "6e6e6e", "overlay0": "555555",
    "surface2": "3a3a3a", "surface1": "2a2a2a", "surface0": "1d1d1d",
    "base": INK, "mantle": "070707", "crust": "000000",
}
for k in ("rosewater", "flamingo", "pink", "mauve", "red", "maroon", "peach"):
    c[k] = RED
for k in ("yellow",):
    c[k] = "ffcc00"
for k in ("green", "teal", "sky", "sapphire", "blue", "lavender"):
    c[k] = PAPER

if state.exists():
    backup = state.with_name("scheme.json.bak")
    if not backup.exists():
        backup.write_text(state.read_text())
    cur = json.loads(state.read_text())
else:
    cur = {}

# keep any keys we didn't override (k* KDE colours etc.)
colours = {**cur.get("colours", {}), **c}
state.parent.mkdir(parents=True, exist_ok=True)
state.write_text(json.dumps({
    "name": "persona", "flavour": "default", "mode": "dark",
    "variant": "tonalspot", "colours": colours,
}))
print(f"wrote {state}")
