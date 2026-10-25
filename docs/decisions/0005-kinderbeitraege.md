# ADR 0005 – Kinderbeiträge: Zeichnungen ja, Stimmen und Namen nein

**Status:** angenommen
**Datum:** 2026-10-25
**Quelle:** Plan-Verbesserungen H5, M6

## Kontext

Beim Spielen selbst fallen keine Daten an. Das öffentliche Repo ist aber eine Veröffentlichung im Internet
(EuGH Lindqvist C-101/01, OGH 6 Ob 56/21k). Eine identifizierbare Kinderstimme ist ein personenbezogenes Datum;
die Einwilligung der Eltern ist widerrufbar. CC-Lizenzen sind dagegen unwiderruflich, und Git-Historie bleibt in
Clones und Forks erhalten. Kinderzeichnungen können urheberrechtlich geschützt sein (§ 10 UrhG); die Lizenz
räumen die Eltern als gesetzliche Vertreter ein.

## Entscheidung

- **Zeichnungen:** dürfen nach `assets/kids_drawings/` – gescannt, ohne Namen/Signatur/Alter in Datei,
  Metadaten oder Commit-Message, mit Pseudonym-Credit. Vorher schriftliche Zustimmung **beider** Elternteile.
  Lizenz für Kinderzeichnungen bevorzugt **CC0** (CC BY 4.0 nimmt Persönlichkeitsrechte ausdrücklich aus).
- **Sprachaufnahmen:** nie ins öffentliche Repo. Entweder
  (a) nur lokal als Build-Input in `assets/kids_voice/` (in `.gitignore`, CI nutzt Platzhalter-Sounds) oder
  (b) stark verfremdet (Pitch-Shift, Effekte) und erst nach Freigabe beider Eltern.
- **Fotos/Videos der Kinder:** nie im Repo.
- **Technische Absicherung:** `scripts/hooks/pre-commit` blockiert Dateien unter `assets/kids_voice/` und
  prüft Bild-/Audio-Metadaten (EXIF/ID3) in `assets/kids_drawings/` auf Leere.

## Hinweis

Die Einordnung zu § 167 Abs. 3 ABGB und zu Kinderstimmen ist eine Wertung ohne einschlägige Rechtsprechung,
keine Rechtsberatung. Vor einer Store-Veröffentlichung kurz anwaltlich prüfen lassen.
