# ADR 0001 – Godot-Version pinnen, Terrain3D-Kompatibilität zuerst prüfen

**Status:** Windows bestätigt (26.10.2026) – Android-Test offen
**Datum:** 2026-10-25
**Quelle:** Plan-Verbesserungen H1

## Kontext

Aktuell stabil ist Godot 4.7.2 (18.08.2026). Jolt ist seit 4.6 Standard für neue 3D-Projekte; bestehende
Projekte behalten ihre Einstellung. Der Plan ging davon aus, dass Terrain3D 1.0.2 nur „Godot 4.4–4.6+“ nennt.

## Entscheidung

- Godot **4.7.2-stable** für Editor, Export-Templates und CI (identisch).
- Version steht in `.tool-versions`, `project.godot` (`config/features`), README und `.github/workflows/fahrbot.yml`.
- Physik-Engine explizit auf „Jolt Physics“ gesetzt, nicht auf den Default verlassen.
- **Terrain3D 1.0.2-stable**, gepinnt per `tools/fetch_terrain3d.(sh|ps1)` mit SHA-256
  `a071850250ec5e596aa54da61c01d75768774eb379ee997584d426a45f4884a2`. Der Addon-Ordner wird nicht
  committet.
- Spike-Aufgabe: Terrain3D auf 4.7.2 laden, 1 Region malen, auf Windows **und** Android rendern
  (Ablauf: [docs/spike/spike-tag.md](../spike/spike-tag.md)).
- Schlägt das fehl: Rückfall auf **Godot 4.6.3**, Ergebnis hier dokumentieren.

## Vorab-Ergebnis (Cloud, 25.10.2026)

- Die Release-Notes von Terrain3D 1.0.2 nennen inzwischen **„Supports Godot 4.4-4.7“**. Das größte
  Risiko aus H1 ist damit offiziell entschärft.
- Unter Godot 4.7.2 (Linux) funktionieren:
  - Laden der GDExtension
  - Region per Code erzeugen
  - Kollision mit Jolt
  - Rendering im Compatibility-Renderer
- Mobile/Vulkan stürzt auf der Software-GPU (llvmpipe) ab, und zwar genauso mit Godot 4.6.3 und mit
  Terrain3D 1.1.0-rc1. Das ist eine Eigenheit der Testumgebung. Aussagekräftig ist nur echte Hardware.
- Godot 4.7.2 gibt die Warnung `instance_reset_physics_interpolation() is deprecated` aus. Ursache ist
  Terrain3D 1.0.2, Godot hat dafür eine Kompatibilitätsschicht.
- Alternative: Terrain3D **1.1.0-rc1** (Godot 4.5–4.8, bessere Mobile-Unterstützung) ist erschienen.
  Das finale 1.1.0 ist angekündigt. Wechsel erst nach dem stabilen Release und eigenem Spike.

## Spike-Ergebnis (Hardware)

### Windows – bestanden (26.10.2026, Product Owner)

| Feld | Ergebnis |
|---|---|
| Build | Windows-Exe aus der CI (Commit `11604e3`), Godot 4.7.2-stable, Terrain3D 1.0.2 |
| Renderer laut Statuszeile | `mobile` (Vulkan) |
| GPU / Board | AMD Radeon RX 6600 XT / B550M GAMING X WIFI6 |
| Terrain3D | rendert korrekt: Wiese, Erde am Hang, Auto-Shader |
| Bildrate | 59 fps (an die Bildwiederholrate gekoppelt) |
| Fahren | Kettenfahrer kraxelt den 35°-Hang |
| Gamepad | 8BitDo SN30 Pro über USB Wireless Adapter 2: „XInput Controller (bekannt)“ |

**Folgerung:** Godot 4.7.2 + Terrain3D 1.0.2 + Mobile-Renderer funktionieren auf Windows. Der Absturz in der
Cloud (llvmpipe) war wie vermutet eine Eigenheit der Software-GPU.

### Android – offen

Ablauf: [docs/spike/spike-tag.md](../spike/spike-tag.md), Blöcke 4–7. Erst danach wird 4.7.2 endgültig
festgeschrieben.
