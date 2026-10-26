class_name PartCatalog
## Alle Baukasten-Teile des Crawlers (ADR 0008). Neben vehicle_constants.gd der einzige Ort
## für Physik-Werte. Jede Kombination muss die Pflicht-Metriken des Fahrbots bestehen
## (Szenario „baukasten“), damit kein Kind einen Crawler bauen kann, der nicht hält.
##
## Masse in kg, Längen in m. -Z ist vorne. Faktoren beziehen sich auf den Standard-Crawler
## (mittel / mittel / normale Achsen / stollen / normal / normal), der den Werten aus ADR 0002 entspricht.
## Vorbilder: echte RC-Crawler (Portalachsen, Ketten, 6×6, Abschlepper), siehe docs/referenzen.md.
## Keine Marken- oder Modellnamen im Spiel.

const CATEGORIES: Array[StringName] = [
	&"fahrgestell", &"raeder", &"achsen", &"reifen", &"federung", &"motor", &"lenkung", &"aufbau", &"farbe", &"extras",
]

## Kategorien, in denen mehrere Teile gleichzeitig gewählt werden dürfen.
const MULTI_SELECT: Array[StringName] = [&"extras"]

const PARTS := {
	&"fahrgestell": [
		{"id": &"mittel", "achsen": [-0.9, 0.9], "spur": 1.5, "groesse": Vector3(1.4, 0.6, 2.4), "masse": 340.0},
		{"id": &"kurz", "achsen": [-0.7, 0.7], "spur": 1.4, "groesse": Vector3(1.3, 0.6, 1.9), "masse": 280.0},
		{"id": &"lang", "achsen": [-1.2, 1.2], "spur": 1.5, "groesse": Vector3(1.4, 0.6, 3.0), "masse": 400.0},
		{"id": &"breit", "achsen": [-0.9, 0.9], "spur": 1.9, "groesse": Vector3(1.8, 0.6, 2.4), "masse": 400.0},
		{"id": &"sechsrad", "achsen": [-1.35, 0.0, 1.35], "spur": 1.5, "groesse": Vector3(1.4, 0.6, 3.3), "masse": 470.0},
	],
	&"raeder": [
		{"id": &"mittel", "radius": 0.4, "breite": 0.3, "masse": 15.0},
		{"id": &"klein", "radius": 0.3, "breite": 0.25, "masse": 10.0},
		{"id": &"gross", "radius": 0.5, "breite": 0.35, "masse": 22.0},
		{"id": &"monster", "radius": 0.65, "breite": 0.45, "masse": 35.0},
	],
	&"achsen": [
		# Portalachsen (wie bei echten Crawlern): Rad hängt tiefer -> mehr Bodenfreiheit, dazu breitere Spur.
		{"id": &"normal", "tiefer": 0.0, "spur_plus": 0.0, "masse": 0.0},
		{"id": &"portal", "tiefer": 0.12, "spur_plus": 0.08, "masse": 12.0},
	],
	&"reifen": [
		{"id": &"stollen", "reibung": 1.1, "rollwiderstand": 0.03, "breite_faktor": 1.0},
		{"id": &"glatt", "reibung": 0.95, "rollwiderstand": 0.02, "breite_faktor": 0.85},
		{"id": &"matsch", "reibung": 1.25, "rollwiderstand": 0.05, "breite_faktor": 1.3},
		# Ketten-Laufwerke statt Reifen: am meisten Grip, dafür gemächlich.
		{"id": &"ketten", "reibung": 1.35, "rollwiderstand": 0.08, "breite_faktor": 1.4, "tempo_faktor": 0.7},
	],
	&"federung": [
		{"id": &"normal", "federrate": 1.0, "weg": 0.35},
		{"id": &"weich", "federrate": 0.7, "weg": 0.4},
		{"id": &"hart", "federrate": 1.5, "weg": 0.25},
		{"id": &"hoch", "federrate": 1.0, "weg": 0.5},
	],
	&"motor": [
		{"id": &"normal", "kraft": 1.0, "tempo": 6.0},
		{"id": &"gemuetlich", "kraft": 0.7, "tempo": 4.0},
		{"id": &"stark", "kraft": 1.6, "tempo": 6.0},
	],
	&"lenkung": [
		# Lenkfaktor der Hinterachse: 0 = nur vorne, negativ = Allrad (enger Wendekreis),
		# positiv = Krebsgang (fährt schräg seitwärts).
		{"id": &"vorne", "hinten": 0.0},
		{"id": &"allrad", "hinten": -0.6},
		{"id": &"krebs", "hinten": 0.6},
	],
	&"aufbau": [
		# kabine: Größe der Fahrerkabine (auch Kollision), kabine_z: Lage längs, schwerpunkt: Anhebung.
		{"id": &"jeep", "masse": 0.0, "kabine": Vector3(1.2, 0.6, 1.0), "kabine_z": 0.2, "schwerpunkt": 0.0},
		{"id": &"pickup", "masse": 10.0, "kabine": Vector3(1.3, 0.6, 0.9), "kabine_z": -0.3, "schwerpunkt": 0.0},
		{"id": &"traktor", "masse": 30.0, "kabine": Vector3(1.0, 0.9, 0.9), "kabine_z": 0.4, "schwerpunkt": 0.08},
		{"id": &"buggy", "masse": -20.0, "kabine": Vector3(1.2, 0.55, 1.3), "kabine_z": 0.1, "schwerpunkt": -0.03},
		{"id": &"kipper", "masse": 40.0, "kabine": Vector3(1.3, 0.7, 0.8), "kabine_z": -0.7, "schwerpunkt": 0.05},
		{"id": &"feuerwehr", "masse": 50.0, "kabine": Vector3(1.3, 0.8, 1.8), "kabine_z": 0.1, "schwerpunkt": 0.08},
		{"id": &"abschlepper", "masse": 45.0, "kabine": Vector3(1.3, 0.7, 0.8), "kabine_z": -0.7, "schwerpunkt": 0.06},
		# Mit Werkzeug-Taste: Bagger-Arm bzw. Schaufel heben und senken (nur Optik).
		{"id": &"bagger", "masse": 70.0, "kabine": Vector3(1.25, 0.9, 1.3), "kabine_z": 0.3, "schwerpunkt": 0.1},
		{"id": &"radlader", "masse": 55.0, "kabine": Vector3(1.1, 0.9, 0.9), "kabine_z": 0.3, "schwerpunkt": 0.07},
		# Kein Crawler: im Gelände fliegt ein KraxlPlane (ADR 0013). Räder, Federung usw. zählen dann nicht.
		{"id": &"flieger", "masse": 0.0, "kabine": Vector3(1.2, 0.6, 1.0), "kabine_z": 0.0, "schwerpunkt": 0.0, "flieger": true},
	],
	&"farbe": [
		{"id": &"orange", "farbe": Color(1.0, 0.5, 0.05)},
		{"id": &"rot", "farbe": Color(0.92, 0.12, 0.12)},
		{"id": &"gelb", "farbe": Color(1.0, 0.85, 0.05)},
		{"id": &"hellgruen", "farbe": Color(0.55, 0.9, 0.15)},
		{"id": &"gruen", "farbe": Color(0.12, 0.7, 0.25)},
		{"id": &"tuerkis", "farbe": Color(0.05, 0.8, 0.78)},
		{"id": &"himmelblau", "farbe": Color(0.3, 0.7, 1.0)},
		{"id": &"blau", "farbe": Color(0.12, 0.35, 0.95)},
		{"id": &"lila", "farbe": Color(0.6, 0.22, 0.92)},
		{"id": &"pink", "farbe": Color(1.0, 0.2, 0.6)},
		{"id": &"rosa", "farbe": Color(1.0, 0.6, 0.78)},
		{"id": &"weiss", "farbe": Color(0.95, 0.95, 0.92)},
		# Regenbogen: Farbe hier nur für Garage-Symbole; der Lack selbst kommt aus Paint.
		{"id": &"regenbogen", "farbe": Color(0.95, 0.35, 0.75), "regenbogen": true},
	],
	&"extras": [
		{"id": &"licht", "masse": 2.0},
		{"id": &"rammschutz", "masse": 12.0},
		{"id": &"seilwinde", "masse": 15.0},
		{"id": &"dachtraeger", "masse": 8.0},
		{"id": &"fahne", "masse": 1.0},
		{"id": &"auspuff", "masse": 4.0},
	],
}


## Fertige Crawler zum Sofort-Losfahren oder Umbauen (wie Fertigmodelle im Modellbau).
## Nicht genannte Kategorien bleiben beim Standard.
const PRESETS := [
	{"id": &"gelaendewagen", "fahrgestell": &"mittel", "raeder": &"gross", "achsen": &"portal", "aufbau": &"jeep",
		"farbe": &"gruen", "extras": [&"licht", &"dachtraeger", &"seilwinde"]},
	{"id": &"hochbeiner", "fahrgestell": &"lang", "raeder": &"monster", "federung": &"hoch", "aufbau": &"pickup",
		"farbe": &"blau", "extras": [&"licht", &"auspuff"]},
	{"id": &"sechsrad_riese", "fahrgestell": &"sechsrad", "raeder": &"gross", "achsen": &"portal", "aufbau": &"pickup",
		"lenkung": &"allrad", "farbe": &"weiss", "extras": [&"licht", &"rammschutz"]},
	{"id": &"kettenfahrer", "fahrgestell": &"mittel", "reifen": &"ketten", "motor": &"stark", "aufbau": &"buggy",
		"farbe": &"orange", "extras": [&"licht", &"dachtraeger"]},
	{"id": &"mini_krabbler", "fahrgestell": &"kurz", "raeder": &"klein", "aufbau": &"jeep", "motor": &"gemuetlich",
		"farbe": &"gelb", "extras": [&"fahne"]},
	{"id": &"abschlepper", "fahrgestell": &"lang", "raeder": &"gross", "aufbau": &"abschlepper", "motor": &"stark",
		"farbe": &"rot", "extras": [&"licht", &"seilwinde"]},
	{"id": &"bagger", "fahrgestell": &"mittel", "reifen": &"ketten", "aufbau": &"bagger", "motor": &"gemuetlich",
		"farbe": &"gelb", "extras": [&"licht"]},
	{"id": &"radlader", "fahrgestell": &"mittel", "raeder": &"gross", "reifen": &"matsch", "aufbau": &"radlader",
		"lenkung": &"allrad", "farbe": &"gelb", "extras": [&"licht"]},
	{"id": &"flieger", "aufbau": &"flieger", "farbe": &"rot"},
]
## Kategorien, die beim Flieger etwas bewirken (die Garage blendet die übrigen aus).
const PLANE_CATEGORIES: Array[StringName] = [&"aufbau", &"farbe"]


static func parts(category: StringName) -> Array:
	return PARTS[category]


static func part(category: StringName, id: StringName) -> Dictionary:
	for p in PARTS[category]:
		if p.id == id:
			return p
	return PARTS[category][0]


static func default_id(category: StringName) -> StringName:
	return PARTS[category][0].id


static func has_part(category: StringName, id: StringName) -> bool:
	return PARTS.has(category) and PARTS[category].any(func(p): return p.id == id)
