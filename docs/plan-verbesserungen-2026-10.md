# Kraxl – priorisierte Verbesserungen am Plan (Stand Oktober 2026)

Der Plan steht im Kern. Die wichtigsten Lücken liegen an fünf Stellen: (1) ein konkreter Versions-Pin samt Kompatibilitätscheck für Terrain3D, (2) eine eigene „Parkbremse“-Logik gegen Rutschen und Zittern, (3) eine Steuerung, die auch Vierjährige ohne Joystick schaffen, (4) Tests auf einem echten schwachen Android-Gerät und (5) eine klare Regel, dass Kinderstimmen und andere identifizierende Beiträge nicht ins öffentliche Repo kommen.

## TL;DR
- **Technik:** Pinne Godot 4.7.2 (aktuell stabil, Jolt ist seit 4.6 Standard). Prüfe am ersten Spike-Tag, ob Terrain3D damit läuft; als Rückfallebene dient 4.6.3. Der eigene Raycast-Controller ist richtig, braucht aber eine explizite Halte-Logik am Hang, ShapeCasts statt einzelner Strahlen und 120 Hz Physik-Takt.
- **Kinder-UX:** Kein virtueller Joystick als Standard. Besser sind große Halte-Tasten, die beim Berühren auslösen, Multi-Touch-tolerant sind und eine optionale Lenkhilfe haben. Dazu eine automatische Kamera ohne Pinch-Zoom und eine „Nach-Hause“-Orientierung ohne Text.
- **Recht und Prozess:** Code unter MIT, Assets unter CC BY 4.0. Echte Kinderstimmen und Namen kommen nicht ins öffentliche Repo, weil CC-Lizenzen und Git-Historie praktisch unwiderruflich sind. Im Agenten-Prozess fehlt vor allem eine echte visuelle und spielerische Abnahme (MCP-Screenshots, deterministische Fahrbot-Szenarien, Mensch fühlt das Fahrgefühl).

## Priorität HOCH

### H1 – Godot-Version konkret pinnen, Terrain3D-Kompatibilität zuerst prüfen
**Begründung:** Aktuell stabil ist Godot 4.7.2 vom 18. August 2026, laut Godot-Download-Archiv; 4.7 erschien am 18. Juni 2026. [godotengine](https://godotengine.org/download/archive/) Mit Godot 4.6 (26. Januar 2026) wurde Jolt „nach dem Nachweis der Produktionsreife“ Standard für neue 3D-Projekte. [godotengine](https://docs.godotengine.org/en/latest/tutorials/physics/using_jolt_physics.html) [godotengine](https://forum.godotengine.org/t/godot-4-6-release-all-about-your-flow/131705) [godotengine](https://godotengine.org/download/archive/) Bestehende Projekte behalten laut Release-Notes ihre alte Einstellung. [alternativeto](https://alternativeto.net/news/2026/1/godot-4-6-debuts-modern-theme-jolt-physics-node-ids-and-libgodot-embed) [digitalproduction](https://digitalproduction.com/2026/01/28/godot-4-6-arrives-with-major-cg-friendly-updates/) Terrain3D 1.0.2 gibt als Voraussetzung „Godot 4.4–4.6+“ an und nennt Mobile und Web „experimentell“. [github](https://github.com/TokisanGames/Terrain3D/releases) Ein offizieller Hinweis auf 4.7 fehlt also. Ein ungeprüfter Pin wäre das größte technische Risiko des Projekts.
**Prompt-Formulierung:**
> „Pinne Godot 4.7.2-stable (Editor, Export-Templates und CI-Image identisch, Version in `project.godot`, `.tool-versions` bzw. README und Workflow). Stelle Physics > 3D > Physics Engine explizit auf ‚Jolt Physics‘ und verlass dich nicht auf den Default. Erste Spike-Aufgabe: Terrain3D (gepinnte Release-Version) auf 4.7.2 laden, 1 Region malen, auf Windows UND einem Android-Gerät rendern. Schlägt das fehl, auf Godot 4.6.3 zurückfallen und die Entscheidung in `docs/decisions/` festhalten.“

### H2 – Fahrphysik: Halte-Logik, ShapeCast, Physik-Takt
**Begründung:**
- Die Entscheidung gegen VehicleBody3D ist richtig. In Godot-Issue #88998 rutscht ein seitlich am Hang geparktes VehicleBody3D „never stand still unless the gravity is 0“. [github](https://github.com/godotengine/godot/issues/88998) Issue #98079 zeigt, dass es auch gebremst rutscht und Räder in Spalten „kleiner als das Rad“ einsinken. „Changing physics engine to Jolt or Rapier does not fix these issues.“ [github](https://github.com/godotengine/godot/issues/98079)
- Eigene Raycast-Controller haben eigene typische Fehler. Issue #23 im Projekt Dechode/Godot-Advanced-Vehicle beschreibt Zittern und Seitwärts-Rutschen im Stand: „The slip calculations (slip_vec.y division by near-zero z_vel, and planar_vect.normalized()) appear to generate extreme physics forces at low speeds.“
- Im Godot-Forum wurde ein Versatz durch veraltete Raycasts gelöst: „wheel.force_raycast_update()“. [godotengine](https://forum.godotengine.org/t/custom-raycast-vehicle-wheels-squish-onto-the-ground-at-high-speeds/129510)
- Das README von DAShoe1/Godot-Easy-Vehicle-Physics empfiehlt „a physics tick rate of at least 120“ und warnt, dass sich das Fahrverhalten beim Wechsel der Tickrate ändert.
- Die Godot-Doku nennt Physik-Interpolation als Mittel gegen sichtbares Zittern und mehr Ticks als Mittel gegen Instabilität. [godotengine](https://docs.godotengine.org/en/stable/tutorials/rendering/jitter_stutter.html) [godotengine](https://docs.godotengine.org/en/stable/tutorials/physics/troubleshooting_physics_issues.html)
- Für Steine und Baumstämme ist ein einzelner Strahl pro Rad zu dünn. Wolfe, der Autor von GDSim, empfiehlt im Devlog „Workshop I – Suspending a RigidBody“ einen Shape-Cast per SpringArm („you can cast a shape; this avoids issues with using a single raycast model“).
**Prompt-Formulierung:**
> „Rad-Controller-Regeln: (1) Pro Rad ShapeCast3D (Kugel/Zylinder in Radgröße) statt RayCast3D; Abfrage per `force_shapecast_update()` im `_physics_process`. (2) Reifenmodell mit expliziter Haftreibungs-Zone: unter v < 0,3 m/s und ohne Gas-Input wird die Kontaktgeschwindigkeit pro Rad per Gegen-Impuls auf 0 gezogen (‚Parkbremse‘), keine Division durch |v| nahe 0. (3) Physics Ticks per Second = 120, Physik-Interpolation an, Werte als Konstanten im Repo. (4) Jolt-Sleep für Fahrzeuge deaktivieren, solange ein Kind drin sitzt. (5) Fahrbot-Metriken zusätzlich zu den Spike-Zielen: Drift am 35°-Hang < 2 cm in 10 s, Winkelgeschwindigkeit im Stand < 0,01 rad/s, Rad-Einsinken in 15-cm-Spalt = 0.“

### H3 – Touch-Steuerung für 4-Jährige: Halte-Tasten statt Joystick
**Begründung:**
- Das Sesame-Workshop-Best-Practice-Papier nennt Tippen die „intuitivste“ Geste. Kinder drücken zu fest und zu lange, deshalb solle Eingabe „upon touch rather than on lift“ registriert werden. Doppeltippen gilt als unintuitiv. [joanganzcooneycenter](https://joanganzcooneycenter.org/wp-content/uploads/2020/02/SesameWorkshop-2012.pdf)
- Das TIDRC-Framework (IDC 2019) empfiehlt:
  - Tipps bis zu 5 Sekunden Dauer und 10 mm Zielabweichung akzeptieren;
  - Single- und Multi-Touch gleich behandeln;
  - Drag & Drop unter 4 Jahren vermeiden. [ufl](https://init.cise.ufl.edu/wp-content/uploads/sites/378/2019/04/TIDRC-Framework-soni-et-al-IDC19-final.pdf)
- UXPA: Kinder unter 5 können Drag-Gesten nicht zuverlässig, Pinch und Rotieren sind „bis zum Alter von 8“ schwierig. [uxpamagazine](https://uxpamagazine.org/playful-interfaces/?lang=en)
- Ein virtueller Joystick ist eine Drag-Geste mit Halten. Godot 4.7 bringt zwar einen eingebauten VirtualJoystick-Node mit; das berichten Sekundärquellen wie godotlearning.com. [godotlearning](https://godotlearning.com/blog/godot-4-7-whats-new) Für Vier- bis Fünfjährige taugt er aber nur als Option für ältere Kinder.
**Prompt-Formulierung:**
> „Standard-Steuerung ‚Kleine Hände‘: zwei große Halte-Tasten Vor/Zurück (≥ 15 mm, untere Bildschirmecken) und zwei große Lenk-Tasten; Auslösen bei Touch-Down, beliebig viele gleichzeitige Finger erlaubt, ‚Ghost-Touches‘ des Handballens am Rand ignorieren. Optionale Lenkhilfe: Fahrzeug folgt sanft dem nächsten Tor/Weg, Kind gibt nur Gas. Modus ‚Große Hände‘ (ab ~6): VirtualJoystick. Seiten tauschbar (Linkshänder) per Elternmenü. Keine Doppeltipps, kein Pinch, keine Wischgesten für Kernfunktionen. Aussteigen/Einsteigen = ein großes Tür-Symbol, das nur erscheint, wenn es möglich ist.“

### H4 – Android: Mobile-Renderer behalten, aber auf schwachem Gerät testen und Terrain-Texturen begrenzen
**Begründung:**
- Laut der Godot-Doku „Overview of renderers“ läuft Mobile auf alter oder schwacher Hardware, ist dort aber „slower than Compatibility“. [godotengine](https://docs.godotengine.org/en/stable/tutorials/rendering/renderers.html)
- Ein Wechsel auf Compatibility ist mit Terrain3D aber riskant. Issue #768 meldet Shader-Kompilierfehler im Compatibility-Renderer, ein Duplikat betrifft ausdrücklich Android. [github](https://github.com/TokisanGames/Terrain3D/issues/768)
- Laut Terrain3D-Doku ist der Mobile-Renderer „fully supported“. Sie empfiehlt PNG/TGA statt DDS und „ETC2 ASTC“-Import. [readthedocs](https://terrain3d.readthedocs.io/en/stable/docs/platforms.html)
- Terrain3D-Issue #668 zeigt, dass Handys weniger Textur-Array-Ebenen schaffen als gemeldet. Ein Redmi Note 12 Pro meldet 2048, hält aber nur 256–512. [github](https://github.com/TokisanGames/Terrain3D/issues/668)
**Prompt-Formulierung:**
> „Renderer: Mobile (auch für Windows, gleiche Optik). Terrain3D: maximal 8 Boden-Texturen, PNG-Quellen, Import ETC2/ASTC aktiv, Texturgröße ≤ 1024². Zielgerät: ein konkretes Einsteiger-Android (im Repo benannt, z. B. Mali-G52/Adreno-610-Klasse); Fertig-Kriterium: ≥ 30 fps stabil über 5 min Fahrbot-Runde auf diesem Gerät, gemessen per Remote-Debugger. Kein Wechsel auf Compatibility ohne Terrain3D-Test.“

### H5 – Kinderbeiträge: Zeichnungen ja, echte Stimmen und Namen nein (im öffentlichen Repo)
**Begründung:**
- Für ein Offline-Spiel ohne Datenerhebung greift die DSGVO-Einwilligungsregel für Kinder (in Österreich 14 Jahre, Art. 8 DSGVO i. V. m. § 4 Abs. 4 DSG laut Datenschutzbehörde) beim Spielen gar nicht. [lawfinder](https://www.lawfinder.at/glossar/einwilligung-dsgvo) [recordinglaw](https://www.recordinglaw.com/de/world-laws/world-data-privacy-laws/austria-data-privacy-laws/) [dsb](https://www.dsb.gv.at/aufgaben-taetigkeiten/informationen-fur-teens-kids.html) Das ist eine Stärke des Plans.
- Das öffentliche Repo ist der Knackpunkt. Laut EuGH (Lindqvist, C-101/01) ist eine Veröffentlichung im Internet nie „rein familiär“; der OGH hat das in 6 Ob 56/21k übernommen. [noyb](https://noyb.eu/sites/default/files/2021-07/Teilurteil_S47-72_sw_de.pdf) [dr-datenschutz](https://www.dr-datenschutz.de/fotos-von-kindern-und-der-datenschutz/)
- Eine identifizierbare Kinderstimme ist damit ein personenbezogenes Datum. Die Einwilligung der Eltern ist widerrufbar, das Kind hat später ein Löschrecht. [dsb](https://dsb.gv.at/sites/site0344/media/downloads/dsgvo_leitfaden_2022.pdf) [medienrechtsanwaelte](https://www.medienrechtsanwaelte.de/newsreader-38/unerlaubte-nutzung-ki-generierter-stimme-verletzt-persoenlichkeitsrecht.html) [datenschutzbeauftragter-trier](https://datenschutzbeauftragter-trier.de/die-versteckten-risiken-der-voice-technologie-was-sie-ueber-ihre-stimme-und-den-datenschutz-wissen-muessen/)
- Creative Commons dagegen: „CC licenses are not revocable once granted“. [creativecommons](https://creativecommons.org/faq/)
- GitHub warnt: Nach dem Umschreiben der Historie bleiben Commits „in any clones or forks“ und über SHA-Hashes erreichbar. [github](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/removing-sensitive-data-from-a-repository)
- Zeichnungen von Kindern können urheberrechtlich geschützt sein. Urheber ist laut § 10 UrhG, „wer es geschaffen hat“; die Lizenz räumen die Eltern als gesetzliche Vertreter ein. [jusline](https://www.jusline.at/gesetz/urhg/paragraf/10) [rechteasy](https://www.rechteasy.at/wiki/urheberrecht/)
- Ob § 167 Abs. 3 ABGB bei einer unentgeltlichen, unwiderruflichen Lizenz die Zustimmung beider Elternteile verlangt, ist ungeklärt; die Genehmigung des Gerichts ist eher theoretisch. [bka](https://www.ris.bka.gv.at/eli/jgs/1811/946/P167/NOR40146779) Vorsichtshalber sollten beide Elternteile schriftlich zustimmen.
**Prompt-Formulierung:**
> „Kinderbeiträge-Regel: Zeichnungen dürfen (gescannt, ohne Namen/Signatur/Alter in Datei, Metadaten oder Commit-Message) unter CC BY 4.0 mit Pseudonym-Credit ins Repo. Sprachaufnahmen der Kinder kommen NICHT ins öffentliche Repo: entweder (a) nur lokal/privat als Build-Input (Ordner in `.gitignore`, CI nutzt Platzhalter-Sounds) oder (b) stark verfremdet (Pitch-Shift, Effekte) und erst nach Freigabe durch beide Eltern. Pre-commit-Hook: blockiert Audio-Dateien in `assets/kids_voice/` und prüft EXIF/ID3-Metadaten auf Leere. Keine Fotos/Videos der Kinder im Repo.“

### H6 – CI-Export: Secrets, Import-Vorlauf, Manifest-Prüfung
**Begründung:**
- Laut Godot-Doku lassen sich Keystore-Daten per Umgebungsvariablen übergeben (`GODOT_ANDROID_KEYSTORE_RELEASE_PATH/_USER/_PASSWORD`). [github](https://github.com/godotengine/godot-docs/blob/master/tutorials/export/exporting_for_android.rst) Sie stehen damit nicht in `export_presets.cfg`.
- godot-ci verlangt, dass `export_presets.cfg` committet ist. Der Keystore liegt Base64-kodiert als Secret vor. [github](https://github.com/marketplace/actions/godot-ci)
- Auf frischen CI-Runnern fehlen ohne vorherigen `--headless --import` die `class_name`-Registrierungen. Kpicaza beschreibt in „CI-tested GUT for Godot 4: fast, green, and reliable“ (Medium, Godot 4.5.1) daher einen zweistufigen Ablauf aus Import und Tests.
- Positiv für „APK ohne Berechtigungen“: Godots Exporter fügt INTERNET nur bei Remote-Debug-Deploys aus dem Editor ein, nicht bei CLI-Exporten. [github](https://github.com/SharpMox/NO-KINGS/pull/438)
- Genau deshalb sollte das Gate das fertige Manifest prüfen, statt sich auf Annahmen zu verlassen.
**Prompt-Formulierung:**
> „CI-Workflow: Job 1 `godot --headless --import --quit`; Job 2 Tests; Job 3 Export Windows + Android. Release-Keystore als Base64-Secret, Übergabe ausschließlich über `GODOT_ANDROID_KEYSTORE_RELEASE_*`-Env-Variablen. Gate-Schritt nach Export: `aapt2 dump permissions` (bzw. `bundletool dump manifest`) – Build schlägt fehl, wenn irgendeine `uses-permission` enthalten ist. Debug- und Release-Keystore niemals committen; Release-Keystore zusätzlich offline sichern (ohne ihn keine Updates der App).“

## Priorität MITTEL

### M1 – Tests: GUT bleibt, aber versionsgenau und mit Exit-Code-Disziplin
**Begründung:** Ein Projekt-Vergleich auf GitHub (Rubbley, Oktober 2026) hält fest, dass jede GUT-Version an genau eine Godot-Minor-Version gebunden ist (9.7.1 für 4.7). Ohne `-gexit` hängt der Lauf. gdUnit4 kann zwar Touch-Input im Scene-Runner simulieren, verweigert aber `--headless` ohne `--ignoreHeadlessMode` und braucht für Input-Tests xvfb. [github](https://github.com/snackpackgames/Rubbley/issues/31) Laut Kpicazas CI-Bericht auf Medium kann Godot beim Beenden „scary ERROR lines“ ausgeben und „return non-zero even when tests passed“.
**Prompt-Formulierung:**
> „GUT-Version passend zur gepinnten Godot-Minor pinnen. Aufruf immer mit `-gexit` und JUnit-XML-Ausgabe; `GODOT_DISABLE_LEAK_CHECKS=1` im Testjob. Input-Tests nicht über OS-Events, sondern über eine eigene `InputSource`-Abstraktion, die Fahrbot und Touch-UI gleichermaßen speist.“

### M2 – Visuelle und spielerische Abnahme durch Agenten (MCP plus Mensch)
**Begründung:**
- Mehrere Community-MCP-Server für Godot 4 bieten Screenshots, Input-Injektion und Szenenbaum-Abfrage. [github](https://github.com/raising-heart/godot-mcp) [github](https://github.com/slangwald/godot-mcp)
- satelliteoflove/godot-mcp kann zusätzlich die Spielzeit einfrieren und schrittweise vorspulen („deterministic observation“). [skillsllm](https://skillsllm.com/skill/satelliteoflove-godot-mcp) Das ist ideal für reproduzierbare Screenshots.
- Eine nüchterne Warnung dazu (Summer Engine): „A successful command is not proof that a game looks or plays correctly.“ [summerengine](https://www.summerengine.com/blog/claude-for-godot)
- Für das Fahrgefühl ist das der typische Fallstrick KI-generierter Spiele: Tests sind grün, aber das Spiel fühlt sich schwammig an.
**Prompt-Formulierung:**
> „Reviewer-Agent nutzt einen Godot-MCP-Server (fest gepinnte Version, nur lokal) für: 6 feste Kamera-Szenarien als Screenshot-Set pro PR (Golden Images, Pixel-Diff-Toleranz), Fahrbot-Videos (Movie-Maker-Modus) von 3 Referenzhindernissen. Jede Physik-Änderung erzeugt eine Vorher/Nachher-Tabelle der Metriken. Merge von Änderungen an Fahrphysik, Kamera oder Steuerung nur nach ‚Fühlt-sich-gut-an‘-Freigabe des Product Owners (10-Minuten-Probefahrt, Checkliste in `docs/feel-check.md`).“

### M3 – Claude-Code-Worktrees: Regeln dürfen nicht nur in CLAUDE.md stehen
**Begründung:** Laut Claude-Code-Doku bekommt ein Subagent mit `isolation: worktree` eine eigene Kopie des Repos. [claude](https://code.claude.com/docs/en/sub-agents) Liegt der Worktree unter `.claude/worktrees/`, lädt der Subagent CLAUDE.md und `.claude/rules/` der Worktree-Wurzel nicht, „even if those differ on the worktree's branch“. [claude](https://code.claude.com/docs/en/worktrees) Ändert ein Agent also Regeln auf seinem Branch, gelten sie für ihn nicht automatisch. Unveränderte Worktrees werden automatisch aufgeräumt; solche mit Änderungen bleiben liegen. [devtoollab](https://devtoollab.com/blog/claude-code-git-worktrees-parallel-agents-guide)
**Prompt-Formulierung:**
> „Jeder Sub-Agent (`.claude/agents/*.md`) hat `isolation: worktree` und enthält seine nicht verhandelbaren Regeln im eigenen Prompt (Kinder-Regeln, Physik-Konstanten-Ort, Gate-Befehl). Regeländerungen nur durch den Team-Lead auf `main`. Team-Lead merged Worktree-Branches nur nach grünem Gate und löscht sie danach.“

### M4 – Offene Welt: Orientierung ohne Lesen
**Begründung:** Toca-Boca-artige Sandkästen funktionieren für diese Altersgruppe gerade, weil es keinen Punktestand gibt; Mitgründer Björn Jeffery sagte Gulf News: „there are no points, there is no score, it's just play.“ Eine 1×1-km-Welt kann Vierjährige aber verloren wirken lassen. Das ist eine Designwertung, keine Studie.
**Prompt-Formulierung:**
> „Orientierung: Immer sichtbarer ‚Haus‘-Knopf, der eine leuchtende Spur zur Garage zeigt (kein Teleport-Zwang, optional Teleport per Langdruck). Strecken-Eingänge als große, farbige Bögen mit Fahrzeug-Symbol; nächstes Tor pulsiert und hat Klang-Beacon (Stereo-Panning). Welt in 4–5 farblich klar unterscheidbare Zonen (Wald, Steinbruch, Matsch, See, Hügel) mit eigenem Musik-Motiv.“

### M5 – Belohnung, Audio, Barrierefreiheit
**Begründung:**
- Die Sesame-Workshop- und TIDRC-Richtlinien betonen sofortiges Feedback auf jede Berührung. [joanganzcooneycenter](https://joanganzcooneycenter.org/wp-content/uploads/2020/02/SesameWorkshop-2012.pdf)
- Bei Farbsehschwäche dürfen Tor-Farben nie die einzige Information sein. Das ist eine Designregel ohne eigene Quelle.
- Godot 4.7 bringt `DrawableTexture2D` für einfaches Malen auf Texturen. [godotengine](https://godotengine.org/releases/4.7/) Damit können Kinder im Spiel z. B. Fahrzeug-Aufkleber selbst malen, ohne Datei-Import.
**Prompt-Formulierung:**
> „Jede Berührung erzeugt binnen 100 ms Ton + visuelles Feedback. Belohnungen nur kosmetisch und sammelbar (Aufkleber, Hupen-Sounds, Lackfarben), nie verlierbar, kein Countdown, kein ‚Falsch‘-Sound. Tore unterscheiden sich durch Form + Symbol + Farbe (farbsehschwäche-sicher, mit Simulationsfilter im Screenshot-Review prüfen). Lautstärke-Obergrenze im Mixer; Musik und Effekte im Elternmenü getrennt regelbar. Optional: Aufkleber-Malen mit DrawableTexture2D.“

### M6 – Lizenzen trennen
**Begründung:**
- Laut Godot-Doku ist Godot MIT-lizenziert und „Your games do not need to be under the same license“. Weitergegebene Builds müssen den Godot-Lizenztext mitliefern. [godotengine](https://docs.godotengine.org/en/stable/about/complying_with_licenses.html)
- Terrain3D steht ebenfalls unter MIT. [github](https://github.com/TokisanGames/Terrain3D/blob/main/LICENSE.txt)
- Creative Commons empfiehlt seine Lizenzen ausdrücklich nicht für Software. [illinois](https://guides.library.illinois.edu/c.php?g=636811&p=6624271)
- CC BY 4.0 nimmt Persönlichkeitsrechte ausdrücklich aus. [creativecommons](https://creativecommons.org/licenses/by/4.0/legalcode.en) Für Kinderbeiträge ist es deshalb CC0 vorzuziehen.
**Prompt-Formulierung:**
> „`LICENSE` = MIT für Code; `assets/LICENSE` = CC BY 4.0 für eigene Modelle, Texturen, Zeichnungen; `THIRD_PARTY_NOTICES.md` mit Godot-, Terrain3D- und GUT-Lizenztexten, wird in den Build kopiert und ist über das Elternmenü erreichbar. Fremd-Assets nur CC0 mit Herkunfts-URL in `assets/SOURCES.md`.“

### M7 – Blender-Pipeline: headless bleibt, plus Vorschau-Render für Review
**Begründung:** Eine Blender-MCP-Skill-Beschreibung warnt, der MCP-Server laufe bei glTF-Exporten in Timeouts, und empfiehlt dafür den Headless-CLI-Weg. [lobehub](https://lobehub.com/skills/neversight-skills_feed-blender-mcp) [claudemarketplaces](https://claudemarketplaces.com/skills/vladmdgolam/agent-skills/blender-mcp) Das bestätigt den Plan. Was fehlt, ist eine Bild-Rückmeldung zur Asset-Qualität.
**Prompt-Formulierung:**
> „Jedes Blender-Skript rendert zusätzlich eine 512²-Vorschau aus 3 festen Winkeln (`docs/asset-previews/`), die der Reviewer-Agent ansieht. Asset-Budget pro Fahrzeug: ≤ 5 000 Dreiecke, ≤ 2 Materialien, reale Maße in Metern, Ursprung auf Bodenhöhe Achsmitte; Prüfskript validiert das nach dem Export.“

## Priorität NIEDRIG

- **L1 – Play Store später:** Apps für Kinder müssen die Families-Policy erfüllen. Dazu gehören keine Übertragung der Advertising-ID oder weiterer Gerätekennungen, keine präzisen Standortdaten und nur zugelassene SDKs. [google](https://support.google.com/googleplay/android-developer/answer/17517561?hl=en-IN) [google](https://support.google.com/googleplay/android-developer/answer/11043825?hl=en) Kraxl erfüllt das bereits durch das Design. Die Datenschutzerklärung und die Zielgruppen-Angaben in der Play Console wären trotzdem Pflicht.
  *Prompt:* „Keine Drittanbieter-SDKs/Plugins mit Netzwerkzugriff; jede neue Abhängigkeit braucht einen Eintrag in `docs/dependencies.md` mit Prüfung ‚sammelt Daten? nein‘.“
- **L2 – Android-Developer-Verification:** Laut Googles Seite „Android developer verification“ greift die Pflicht seit 30. September 2026 zuerst für Installationen „from participating stores in Brazil, Indonesia, Singapore, and Thailand on certified devices running Android 7+“. Österreich ist noch nicht betroffen, aber Google kündigt an: „Verification capability will be expanded globally for all apps on certified Android devices in 2027.“ Für Sideloading der APK sollte man die Entwicklung beobachten.
- **L3 – Pause-Timer kindgerecht:** Den Timer nicht abrupt enden lassen, sondern als „Auto fährt in die Garage und schläft“-Animation mit Vorwarnung zwei Minuten vorher (Symbol plus Ton). Das ist eine Designwertung.
- **L4 – Elternschutz per Langdruck:** Bei 5 s zu halten, weil Kinder laut TIDRC Tipps bis zu 5 s halten. [ufl](https://init.cise.ufl.edu/wp-content/uploads/sites/378/2019/04/TIDRC-Framework-soni-et-al-IDC19-final.pdf) Besser 3 s Halten plus eine einfache Zweitaufgabe, z. B. zwei Punkte gleichzeitig.

## Was im Plan schon gut ist und so bleiben sollte

- **Eigener Raycast-Rad-Controller statt VehicleBody3D:** Die dokumentierten Hang-Rutsch-Bugs bestätigen das.
- **Jolt Physics:** seit 4.6 Standard und laut Godot-Projekt produktionsreif. [godotengine](https://docs.godotengine.org/en/latest/tutorials/physics/using_jolt_physics.html) [godotengine](https://forum.godotengine.org/t/godot-4-6-release-all-about-your-flow/131705)
- **Mobile-Renderer:** von Terrain3D voll unterstützt. [readthedocs](https://terrain3d.readthedocs.io/en/stable/docs/platforms.html)
- **Fahrphysik-Spike zuerst** mit messbaren Zielen (30-cm-Stufe, 35°-Hang, kein Zittern, Aufstellen < 3 s).
- **Kein Scheitern, keine Werbung, keine Käufe, kein Internet, keine Datenerfassung:** Das entspricht dem Toca-Boca-Prinzip und macht DSGVO- und Families-Fragen beim Spielen gegenstandslos. [screenwiseapp](https://screenwiseapp.com/guides/the-best-toca-boca-games-for-kids-and-creativity) [kidssapiens](https://www.kidssapiens.com/en/blog/toca-boca-world-alternatives-for-kids.html)
- **APK ohne Berechtigungen:** CLI-Exporte setzen kein INTERNET; jetzt nur noch per Gate absichern. [github](https://github.com/SharpMox/NO-KINGS/pull/438)
- **Assets nur per Blender-Python headless:** reproduzierbar und Review-fähig, .glb committet.
- **Sub-Agents in Worktrees, Repo als Gedächtnis, Gate-Skript, Kindertest nach jedem Release, Mensch als Product Owner.**
- **GUT und headless Fahrbot-Tests** als Regressionsschutz für die Physik.
- **Bedienung über Symbole, Elternschutz, optionaler Pause-Timer, eigene Zeichnungen der Kinder:** Ändern sollte sich nur, wie die Stimmen gehandhabt werden (H5).

## Caveats

- Godot 4.7.2 als aktuellste stabile Version stammt aus dem offiziellen Download-Archiv. Die Kompatibilität von Terrain3D mit 4.7 ist dagegen nicht offiziell belegt.
- Die Angaben zum VirtualJoystick-Node in 4.7 und die GUT-Versionszuordnung stammen aus Sekundärquellen.
- Die rechtlichen Einordnungen zu § 167 ABGB und zu Kinderstimmen sind Wertungen ohne einschlägige Rechtsprechung, keine Rechtsberatung. Bei einer Store-Veröffentlichung sollte man kurz anwaltlich prüfen lassen.
- Die Godot-MCP-Server sind Community-Projekte mit uneinheitlicher Reife. Am besten pinnt man einen davon und behandelt ihn als austauschbar.