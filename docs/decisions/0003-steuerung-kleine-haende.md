# ADR 0003 – Touch-Steuerung „Kleine Hände“: Halte-Tasten statt Joystick

**Status:** angenommen
**Datum:** 2026-10-25
**Quelle:** Plan-Verbesserungen H3, M4, L4

## Kontext

Tippen ist für Kleinkinder die intuitivste Geste; sie drücken zu fest und zu lange. Drag-Gesten sind unter
5 Jahren unzuverlässig, Pinch/Rotieren bis ca. 8 Jahre schwierig. Ein virtueller Joystick ist Drag + Halten.

## Entscheidung

**Modus „Kleine Hände“ (Standard):**
- Zwei große Halte-Tasten Vor/Zurück (≥ 15 mm, untere Bildschirmecken) und zwei große Lenk-Tasten.
- Auslösen bei Touch-Down; beliebig viele gleichzeitige Finger; Tipps bis 5 s und 10 mm Abweichung akzeptieren.
- Ghost-Touches des Handballens am Bildschirmrand ignorieren.
- Optionale Lenkhilfe: Fahrzeug folgt sanft dem nächsten Tor/Weg, Kind gibt nur Gas.
- Aussteigen/Einsteigen: ein großes Tür-Symbol, nur sichtbar, wenn möglich.

**Modus „Große Hände“ (ab ca. 6):** eingebauter VirtualJoystick-Node.

**Allgemein:**
- Seiten tauschbar (Linkshänder) im Elternmenü.
- Keine Doppeltipps, kein Pinch, keine Wischgesten für Kernfunktionen.
- Automatische Kamera ohne Pinch-Zoom.
- Orientierung ohne Text: immer sichtbarer „Haus“-Knopf zeigt leuchtende Spur zur Garage
  (Teleport optional per Langdruck). Strecken-Eingänge als farbige Bögen mit Fahrzeug-Symbol, nächstes Tor
  pulsiert und hat Klang-Beacon. Welt in 4–5 Zonen (Wald, Steinbruch, Matsch, See, Hügel) mit eigenem Musik-Motiv.
- Jede Berührung: Ton + visuelles Feedback binnen 100 ms.
- Elternschutz: 3 s halten **plus** einfache Zweitaufgabe (z. B. zwei Punkte gleichzeitig) – 5 s Halten
  allein reicht nicht, weil Kinder so lange halten.
