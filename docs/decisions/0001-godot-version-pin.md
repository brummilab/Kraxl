# ADR 0001 – Godot-Version pinnen, Terrain3D-Kompatibilität zuerst prüfen

**Status:** vorläufig – Spike-Ergebnis offen
**Datum:** 2026-10-25
**Quelle:** Plan-Verbesserungen H1

## Kontext

Aktuell stabil ist Godot 4.7.2 (18.08.2026). Jolt ist seit 4.6 Standard für neue 3D-Projekte; bestehende
Projekte behalten ihre Einstellung. Terrain3D 1.0.2 nennt „Godot 4.4–4.6+“; ein offizieller Hinweis auf 4.7 fehlt.

## Entscheidung

- Godot **4.7.2-stable** für Editor, Export-Templates und CI-Image (identisch).
- Version steht in `.tool-versions`, `project.godot` (`config/features`), README und CI-Workflow.
- Physik-Engine explizit auf „Jolt Physics“ gesetzt, nicht auf den Default verlassen.
- Erste Spike-Aufgabe: Terrain3D (gepinnte Release) auf 4.7.2 laden, 1 Region malen, auf Windows **und**
  einem Android-Gerät rendern.
- Schlägt das fehl: Rückfall auf **Godot 4.6.3**, Ergebnis hier dokumentieren.

## Spike-Ergebnis

_Noch offen._ Eintragen: Terrain3D-Version, Godot-Version, Windows ok/nicht ok, Android-Gerät + ok/nicht ok,
beobachtete Fehler, endgültige Entscheidung.
