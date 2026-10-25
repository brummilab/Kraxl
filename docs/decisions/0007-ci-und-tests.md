# ADR 0007 – CI-Ablauf, Secrets, Manifest-Gate und Tests

**Status:** angenommen – Workflow noch nicht umgesetzt
**Datum:** 2026-10-25
**Quelle:** Plan-Verbesserungen H6, M1, M2, M3, M7

## CI-Workflow

1. **Import:** `godot --headless --import --quit` (registriert `class_name` auf frischen Runnern).
2. **Tests:** GUT mit `-gexit` und JUnit-XML-Ausgabe; `GODOT_DISABLE_LEAK_CHECKS=1` im Testjob.
   Exit-Code und JUnit-Ergebnis auswerten, weil Godot beim Beenden trotz grüner Tests non-zero liefern kann.
3. **Export:** Windows + Android. `export_presets.cfg` ist committet.
4. **Gate:** `aapt2 dump permissions` (bzw. `bundletool dump manifest`) auf das fertige APK –
   Build schlägt fehl, sobald irgendeine `uses-permission` enthalten ist.

## Secrets

- Release-Keystore als Base64-Secret; Übergabe nur über `GODOT_ANDROID_KEYSTORE_RELEASE_PATH`,
  `GODOT_ANDROID_KEYSTORE_RELEASE_USER`, `GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD`.
- Debug- und Release-Keystore nie committen. Release-Keystore zusätzlich offline sichern
  (ohne ihn keine App-Updates).

## Tests

- GUT-Version passend zur gepinnten Godot-Minor (für 4.7 laut Sekundärquelle 9.7.1 – beim Pinnen prüfen).
- Input-Tests nicht über OS-Events, sondern über eine `InputSource`-Abstraktion, die Fahrbot und Touch-UI speist.

## Visuelle und spielerische Abnahme

- Reviewer-Agent nutzt einen fest gepinnten, nur lokal laufenden Godot-MCP-Server:
  6 feste Kamera-Szenarien als Golden Images (Pixel-Diff-Toleranz), Fahrbot-Videos (Movie-Maker-Modus)
  von 3 Referenzhindernissen, Farbsehschwäche-Simulationsfilter.
- Jede Physik-Änderung erzeugt eine Vorher/Nachher-Tabelle der Metriken.
- Fahrphysik/Kamera/Steuerung: Merge nur nach Freigabe gemäß `docs/feel-check.md`.

## Agenten und Worktrees

- Jeder Sub-Agent (`.claude/agents/*.md`) hat `isolation: worktree` und trägt seine Regeln im eigenen Prompt.
- Regeländerungen nur durch den Team-Lead auf `main`; Worktree-Branches nach grünem Gate mergen und löschen.

## Blender-Pipeline

- Assets nur per Blender-Python headless; `.glb` committet.
- Jedes Skript rendert eine 512²-Vorschau aus 3 festen Winkeln nach `docs/asset-previews/`.
- Budget pro Fahrzeug: ≤ 5 000 Dreiecke, ≤ 2 Materialien, reale Maße in Metern, Ursprung auf Bodenhöhe
  Achsmitte – ein Prüfskript validiert das nach dem Export.
