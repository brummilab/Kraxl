#!/usr/bin/env python3
"""Erzeugt das Kraxl-Logo als SVG (Quelle der Wahrheit für alle Logo-Dateien).

Aufruf:  python3 tools/logo/build_logo.py   (braucht fontTools: pip install fonttools)
Ergebnis:
  icon.svg                         App-Symbol für Godot (quadratisch, ohne Text – Kinder lesen nicht)
  docs/logo/kraxl-icon.svg         dasselbe Symbol für Doku
  docs/logo/kraxl-logo.svg         Symbol + Schriftzug für helle Hintergründe
  docs/logo/kraxl-logo-dark.svg    Symbol + Schriftzug für dunkle Hintergründe
PNG-Vorschauen: node tools/logo/render_png.js

Der Schriftzug wird mit fontTools in Pfade umgewandelt, damit er ohne installierte Schrift überall gleich
aussieht. Schrift: Inter Display Black (SIL Open Font License 1.1, siehe assets/SOURCES.md).
"""

from pathlib import Path

from fontTools.pens.boundsPen import BoundsPen
from fontTools.pens.svgPathPen import SVGPathPen
from fontTools.ttLib import TTFont

ROOT = Path(__file__).resolve().parents[2]
FONT_BLACK = "/usr/share/fonts/opentype/inter/InterDisplay-Black.otf"
FONT_SEMIBOLD = "/usr/share/fonts/opentype/inter/InterDisplay-SemiBold.otf"

ORANGE = "#F28C1B"
ORANGE_DARK = "#C9680A"
NAVY = "#1F3A5F"
TIRE = "#23272E"


def text_path(font_file: str, text: str, x: float, baseline: float, size: float, tracking: float = 0.0):
    """Gibt (SVG-Pfade je Buchstabe, Endbreite) zurück; tracking in em."""
    font = TTFont(font_file)
    glyphs = font.getGlyphSet()
    cmap = font.getBestCmap()
    scale = size / font["head"].unitsPerEm
    paths = []
    cursor = x
    for ch in text:
        name = cmap[ord(ch)]
        pen = SVGPathPen(glyphs)
        glyphs[name].draw(pen)
        d = pen.getCommands()
        if d:
            paths.append((ch, f'<path transform="translate({cursor:.2f} {baseline:.2f}) scale({scale:.5f} {-scale:.5f})" d="{d}"/>'))
        cursor += glyphs[name].width * scale + tracking * size
    return paths, cursor - x - tracking * size


def wheel(cx: float, cy: float, r: float) -> str:
    """Rad mit Stollen, orangefarbener Nabe und Glanzpunkt."""
    nubs = []
    for i in range(14):
        nubs.append(
            f'<rect x="{-r * 0.11:.1f}" y="{-r * 1.08:.1f}" width="{r * 0.22:.1f}" height="{r * 0.2:.1f}" '
            f'rx="{r * 0.05:.1f}" fill="{TIRE}" transform="rotate({i * 360 / 14:.1f})"/>'
        )
    return f'''<g transform="translate({cx} {cy})">
      {''.join(nubs)}
      <circle r="{r}" fill="{TIRE}"/>
      <circle r="{r * 0.62}" fill="#3A404A"/>
      <circle r="{r * 0.42}" fill="{ORANGE}"/>
      <circle r="{r * 0.14}" fill="{TIRE}"/>
      <circle cx="{-r * 0.12}" cy="{-r * 0.16}" r="{r * 0.07}" fill="#FFFFFF" opacity="0.7"/>
    </g>'''


def icon_body() -> str:
    """Szene 512×512: Himmel, Felsen, Crawler kraxelt den Hang hinauf, Fahne auf dem Gipfel."""
    crawler = f'''<g transform="translate(222 300) rotate(-24)">
      <!-- Schatten unter dem Fahrzeug -->
      <ellipse cx="0" cy="98" rx="150" ry="10" fill="#000" opacity="0.18"/>
      <!-- Überrollbügel -->
      <path d="M -46 -90 L -34 -138 L 58 -138 L 70 -90" fill="none" stroke="#E9EEF3" stroke-width="11" stroke-linejoin="round" stroke-linecap="round"/>
      <!-- Kabine -->
      <rect x="-52" y="-96" width="118" height="62" rx="16" fill="{ORANGE}"/>
      <rect x="-36" y="-84" width="44" height="34" rx="8" fill="#BDE7FF"/>
      <rect x="16" y="-84" width="36" height="34" rx="8" fill="#BDE7FF"/>
      <!-- Karosserie -->
      <rect x="-128" y="-46" width="256" height="70" rx="22" fill="{ORANGE}"/>
      <rect x="-128" y="0" width="256" height="24" rx="12" fill="{ORANGE_DARK}"/>
      <!-- Scheinwerfer und Rammschutz vorne (rechts) -->
      <rect x="112" y="-34" width="20" height="16" rx="5" fill="#FFF3A6"/>
      <rect x="128" y="-8" width="16" height="40" rx="6" fill="{TIRE}"/>
      {wheel(-82, 38, 58)}
      {wheel(84, 38, 58)}
    </g>'''
    return f'''<defs>
    <linearGradient id="sky" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#5CC6F2"/>
      <stop offset="1" stop-color="#BDEBFF"/>
    </linearGradient>
    <clipPath id="badge"><rect width="512" height="512" rx="112"/></clipPath>
  </defs>
  <g clip-path="url(#badge)">
    <rect width="512" height="512" fill="url(#sky)"/>
    <circle cx="112" cy="104" r="46" fill="#FFD84D"/>
    <circle cx="112" cy="104" r="64" fill="#FFD84D" opacity="0.25"/>
    <!-- ferne Berge -->
    <path d="M -10 330 L 120 210 L 210 290 L 300 190 L 420 300 L 530 230 L 530 520 L -10 520 Z" fill="#9CC3DA"/>
    <path d="M 300 190 L 330 218 L 312 222 L 300 210 L 286 226 L 272 220 Z" fill="#FFFFFF" opacity="0.9"/>
    <!-- Fels-Hang, den der Crawler hinaufkraxelt: Linie durch beide Radaufstandspunkte (24°) -->
    <path d="M -10 508 L 420 317 L 530 300 L 530 520 L -10 520 Z" fill="#8C7262"/>
    <path d="M -10 508 L 420 317 L 444 336 L 20 524 Z" fill="#A58A78"/>
    <path d="M 420 317 L 530 300 L 530 330 L 444 336 Z" fill="#B79E8C"/>
    <circle cx="300" cy="420" r="16" fill="#7A6152"/>
    <circle cx="400" cy="460" r="22" fill="#7A6152"/>
    <!-- Wiese unten links -->
    <path d="M -10 520 L -10 500 C 30 488 70 476 110 472 L 170 520 Z" fill="#5DBB4A"/>
    <!-- Gipfelfahne -->
    <rect x="458" y="232" width="7" height="84" rx="3" fill="#E9EEF3"/>
    <path d="M 465 236 L 500 249 L 465 263 Z" fill="#FFD84D"/>
    {crawler}
  </g>'''


def write(path: Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8")
    print("geschrieben:", path.relative_to(ROOT))


def icon_svg() -> str:
    return f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512" width="512" height="512">
  <title>Kraxl</title>
  {icon_body()}
</svg>
'''


def logo_svg(dark: bool) -> str:
    text_color = "#FFFFFF" if dark else NAVY
    sub_color = "#B8CBE0" if dark else "#4F6F91"
    word, word_width = text_path(FONT_BLACK, "Kraxl", 470, 262, 210, tracking=-0.02)
    letters = "".join(
        f'<g fill="{ORANGE if ch == "x" else text_color}">{p}</g>' for ch, p in word
    )
    tagline, _ = text_path(FONT_SEMIBOLD, "kraxeln · bauen · losfahren", 476, 344, 46, tracking=0.01)
    tag = "".join(p for _, p in tagline)
    width = int(470 + word_width + 60)
    return f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {width} 420" width="{width}" height="420">
  <title>Kraxl – kraxeln, bauen, losfahren</title>
  <g transform="translate(20 20) scale(0.75)">
    {icon_body()}
  </g>
  {letters}
  <g fill="{sub_color}">{tag}</g>
</svg>
'''


def main() -> None:
    icon = icon_svg()
    write(ROOT / "icon.svg", icon)
    write(ROOT / "docs/logo/kraxl-icon.svg", icon)
    write(ROOT / "docs/logo/kraxl-logo.svg", logo_svg(dark=False))
    write(ROOT / "docs/logo/kraxl-logo-dark.svg", logo_svg(dark=True))


if __name__ == "__main__":
    main()
