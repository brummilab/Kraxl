# ADR 0010 – Töne per Code (Motor, Hupe, Plumps, Klick)

**Status:** angenommen – umgesetzt, Feel-Check offen
**Datum:** 2026-10-26
**Quelle:** Plan-Verbesserungen M5 (Ton-Feedback, Lautstärke-Obergrenze), Wunsch des Product Owners

## Entscheidung

Alle Töne erzeugt `src/audio/sfx.gd` per Code. Es gibt keine fremden Sounddateien, also auch keine
Lizenzfragen. Echte Aufnahmen können später einzelne Töne ersetzen; Kinderstimmen bleiben nach ADR 0005
draußen.

| Ton | Wann | Wie |
|---|---|---|
| Motor | immer, solange der Crawler steht oder fährt | Schleife je Motor-Teil (gemütlich 55 Hz weich, normal 70 Hz, stark 85 Hz rau); Tonhöhe folgt Tempo und Gas, Lautstärke dem Gas |
| Ketten-Rattern | nur mit Reifen „Ketten“ | Klacker-Schleife, schneller und lauter mit dem Tempo |
| Hupe | Gamepad L3/R3 (Stick drücken), Tastatur H/Leertaste, Touch-Hupe über den Lenk-Tasten | Zweiklang |
| Plumps | Aufsetzen nach ≥ 0,25 s in der Luft (Signal `landed`) | tiefer Ton + Rauschen, Lautstärke nach Fallgeschwindigkeit |
| Dreiklang | nach dem Aufstellen (Signal `righted`) | fröhliches C-E-G, absichtlich kein „Fehler“-Ton (Kinder-Regel 4) |
| Klick | jede neue Berührung einer Touch-Taste | kurzer, leiser Tick |
| Plopp | Garage: Kategorie / Teil / Würfel | Tonhöhe je Kategorie |

- **Mobil-tauglich:** Schleifen werden einmal erzeugt und zwischengespeichert. Zur Laufzeit ändern sich nur
  `pitch_scale` und `volume_db`; es läuft keine Synthese pro Bild.
- **Lautstärke-Obergrenze:** Alle Effekte laufen über den Bus „Effekte“ mit `AudioEffectHardLimiter`
  (Decke −6 dB).
- **Fahrbot ohne Ton** (`KraxlVehicle.sounds = false`). Die Physik ist davon unberührt; `landed`/`righted`
  lesen nur Zustände.

## Offen

- Elternmenü mit getrennten Reglern für Musik und Effekte (M5).
- Musik je Zone (M4).
- Feel-Check: Ist der Motor zu laut oder zu leise? Ist die Hupe angenehm?
