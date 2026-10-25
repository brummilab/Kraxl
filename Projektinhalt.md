# Kraxl – Projektinhalt

## Ziel

Offline-Sandkasten-Fahrspiel für Kinder ab 4 Jahren auf Windows und Android. Fahrzeuge erkunden eine
offene Welt (ca. 1×1 km) mit Hängen, Steinen, Matsch und Toren. Ohne Punkte, ohne Scheitern, ohne Internet.

## Rollen

- **Product Owner:** David (Mensch, Fahrgefühl-Abnahme, Kindertest nach jedem Release)
- **Team-Lead-Agent:** merged Worktree-Branches nach grünem Gate, pflegt Regeln auf `main`
- **Sub-Agents:** arbeiten in Worktrees (`isolation: worktree`) mit eigenen Regeln im Prompt
- **Reviewer-Agent:** Screenshots/Fahrbot-Videos über Godot-MCP, Metrik-Tabellen

## Entscheidungen (ADRs)

| Nr. | Thema | Status |
|---|---|---|
| [0001](docs/decisions/0001-godot-version-pin.md) | Godot 4.7.2 pinnen, Terrain3D zuerst prüfen | vorläufig, Spike offen |
| [0002](docs/decisions/0002-rad-controller.md) | Eigener Rad-Controller mit ShapeCast + Parkbremse | angenommen |
| [0003](docs/decisions/0003-steuerung-kleine-haende.md) | Halte-Tasten statt Joystick | angenommen |
| [0004](docs/decisions/0004-renderer-und-zielgeraet.md) | Mobile-Renderer, schwaches Zielgerät | angenommen, Gerät offen |
| [0005](docs/decisions/0005-kinderbeitraege.md) | Kinderbeiträge: Zeichnungen ja, Stimmen nein | angenommen |
| [0006](docs/decisions/0006-lizenzen.md) | MIT für Code, CC BY 4.0 für Assets | angenommen |
| [0007](docs/decisions/0007-ci-und-tests.md) | CI-Ablauf, Secrets, Manifest-Gate, GUT | angenommen, Umsetzung offen |

## Fahrphysik-Ziele (Spike)

- 30-cm-Stufe überwinden
- 35°-Hang: Drift < 2 cm in 10 s im Stand
- Winkelgeschwindigkeit im Stand < 0,01 rad/s (kein Zittern)
- Rad-Einsinken in 15-cm-Spalt = 0
- Aufstellen nach Umkippen < 3 s
- Android-Zielgerät: ≥ 30 fps stabil über 5 min Fahrbot-Runde

## Offene Aufgaben

- [ ] Spike-Tag: Terrain3D auf Godot 4.7.2 (Windows + Android), Ergebnis in ADR 0001
- [ ] Konkretes Einsteiger-Android-Zielgerät benennen (ADR 0004)
- [ ] Terrain3D- und GUT-Version pinnen, Lizenztexte in `THIRD_PARTY_NOTICES.md` einfügen
- [ ] CI-Workflow (Import → Tests → Export + Manifest-Gate) anlegen
- [ ] Godot-MCP-Server auswählen und pinnen (M2)
- [ ] Sub-Agent-Definitionen in `.claude/agents/` mit eingebetteten Regeln (M3)
- [ ] `InputSource`-Abstraktion für Touch-UI und Fahrbot (M1)
- [ ] Release-Keystore erzeugen, offline sichern, als CI-Secret hinterlegen
- [ ] Zustimmung beider Elternteile für Kinderzeichnungen schriftlich einholen

## Verlauf

- **2026-10-25** – Repo angelegt. Priorisierte Verbesserungen (Stand Oktober 2026) als
  `docs/plan-verbesserungen-2026-10.md` übernommen und in ADRs 0001–0007, `CLAUDE.md`,
  `project.godot`, Physik-Konstanten, Lizenzdateien und Pre-commit-Hook umgesetzt.
