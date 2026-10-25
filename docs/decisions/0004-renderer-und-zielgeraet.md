# ADR 0004 – Mobile-Renderer, Terrain-Texturen begrenzen, schwaches Zielgerät

**Status:** angenommen – Zielgerät noch zu benennen
**Datum:** 2026-10-25
**Quelle:** Plan-Verbesserungen H4

## Kontext

Mobile läuft auf schwacher Hardware, ist dort aber langsamer als Compatibility. Terrain3D hat im
Compatibility-Renderer Shader-Kompilierfehler (u. a. Android, Issue #768), unterstützt Mobile aber voll.
Handys schaffen weniger Textur-Array-Ebenen als gemeldet (Issue #668).

## Entscheidung

- Renderer **Mobile**, auch auf Windows (gleiche Optik).
- Terrain3D: max. 8 Boden-Texturen, PNG/TGA-Quellen (kein DDS), Import ETC2/ASTC aktiv, Texturgröße ≤ 1024².
- Kein Wechsel auf Compatibility ohne Terrain3D-Test auf Android.

## Zielgerät

_Noch zu benennen:_ ein konkretes Einsteiger-Android der Mali-G52/Adreno-610-Klasse.

| Feld | Wert |
|---|---|
| Modell | offen |
| GPU | offen |
| Android-Version | offen |

**Fertig-Kriterium:** ≥ 30 fps stabil über 5 min Fahrbot-Runde, gemessen per Remote-Debugger.
