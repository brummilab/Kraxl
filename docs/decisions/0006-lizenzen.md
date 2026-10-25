# ADR 0006 – Lizenzen trennen

**Status:** angenommen
**Datum:** 2026-10-25
**Quelle:** Plan-Verbesserungen M6, L1

## Entscheidung

- `LICENSE`: **MIT** für Code.
- `assets/LICENSE`: **CC BY 4.0** für eigene Modelle, Texturen und Sounds; Kinderzeichnungen bevorzugt CC0 (ADR 0005).
- `THIRD_PARTY_NOTICES.md`: Lizenztexte von Godot, Terrain3D und GUT. Die Datei wird in den Build kopiert und
  ist über das Elternmenü erreichbar (Godot verlangt den Lizenztext in weitergegebenen Builds).
- Fremd-Assets nur **CC0**, mit Herkunfts-URL in `assets/SOURCES.md`.
- Keine Drittanbieter-SDKs/Plugins mit Netzwerkzugriff; jede Abhängigkeit in `docs/dependencies.md`.

Creative-Commons-Lizenzen werden nicht für Software verwendet.
