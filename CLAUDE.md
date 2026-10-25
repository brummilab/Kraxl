# Kraxl – Regeln für Agenten

Diese Regeln sind nicht verhandelbar. Weil Sub-Agents in Worktrees diese Datei nicht zuverlässig laden
(siehe ADR/M3), muss jede Agent-Definition in `.claude/agents/*.md` sie zusätzlich im eigenen Prompt tragen.
Regeländerungen nur durch den Team-Lead auf `main`.

## Kinder-Regeln

1. Keine Sprachaufnahmen, Fotos oder Videos von Kindern im Repo. `assets/kids_voice/` ist ignoriert.
2. Kinderzeichnungen nur ohne Namen, Signatur, Alter – weder in Datei, Metadaten noch Commit-Message.
3. Kein Netzwerkzugriff, keine Datenerfassung, keine Werbung, keine Käufe, keine Drittanbieter-SDKs mit Netzwerk.
4. Kein Scheitern: kein Countdown, kein „Falsch“-Sound, Belohnungen nur kosmetisch und nie verlierbar.
5. Bedienung ohne Lesen: Symbole, Formen, Farben, Klang. Farbe nie als einzige Information.

## Technik-Regeln

- Godot 4.7.2-stable (bzw. Rückfall 4.6.3 laut ADR 0001). Physik-Engine explizit „Jolt Physics“.
- Physik-Konstanten nur in `src/vehicle/vehicle_constants.gd`. Tick-Rate 120, Interpolation an.
- Kein `VehicleBody3D`. Rad-Kontakt per `ShapeCast3D` mit `force_shapecast_update()` im `_physics_process`.
- Reifenmodell: keine Division durch |v| nahe 0; unter `PARK_SPEED_THRESHOLD` ohne Gas greift die Parkbremse.
- Renderer Mobile. Kein Wechsel auf Compatibility ohne Terrain3D-Test auf Android.
- Steuerung: Auslösen bei Touch-Down, Multi-Touch tolerant, keine Doppeltipps/Pinch/Wischgesten für Kernfunktionen.
- Eingaben laufen über eine `InputSource`-Abstraktion (Touch-UI und Fahrbot gleichermaßen).
- Neue Abhängigkeiten nur mit Eintrag in `docs/dependencies.md`.

## Prozess-Regeln

- Gate muss grün sein vor jedem Merge. Android-Export darf keine `uses-permission` enthalten.
- Physik-Änderungen liefern eine Vorher/Nachher-Tabelle der Fahrbot-Metriken.
- Änderungen an Fahrphysik, Kamera oder Steuerung brauchen die Freigabe nach `docs/feel-check.md`.
- Keystores nie committen.
- Entscheidungen in `docs/decisions/` festhalten; `README.md` und `Projektinhalt.md` bei jeder Änderung aktualisieren.
