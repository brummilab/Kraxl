class_name CrawlerDesign
extends RefCounted
## Bauplan eines Crawlers: je Kategorie die gewählte Teil-ID (ADR 0008).
## Wird als JSON lokal gespeichert (user://, keine Berechtigung nötig, nichts verlässt das Gerät).

## Kategorie -> Teil-ID; bei Mehrfachauswahl (extras) Kategorie -> Array[StringName].
var choices := {}


func _init() -> void:
	for category in PartCatalog.CATEGORIES:
		choices[category] = [] if category in PartCatalog.MULTI_SELECT else PartCatalog.default_id(category)


func get_part(category: StringName) -> Dictionary:
	return PartCatalog.part(category, choices[category])


## Aufbau „flieger“: im Gelände ein KraxlPlane statt eines Crawlers.
func is_plane() -> bool:
	return get_part(&"aufbau").get("flieger", false)


func selected_extras() -> Array:
	return choices[&"extras"]


func is_selected(category: StringName, id: StringName) -> bool:
	if category in PartCatalog.MULTI_SELECT:
		return id in choices[category]
	return choices[category] == id


## Wählt ein Teil; bei Mehrfachauswahl wird es an- bzw. abgewählt.
func select(category: StringName, id: StringName) -> void:
	if not PartCatalog.has_part(category, id):
		return
	if category in PartCatalog.MULTI_SELECT:
		var list: Array = choices[category]
		if id in list:
			list.erase(id)
		else:
			list.append(id)
	else:
		choices[category] = id


## Bauplan aus einer Vorlage (PartCatalog.PRESETS).
static func from_preset(preset: Dictionary) -> CrawlerDesign:
	var design := CrawlerDesign.new()
	for category in PartCatalog.CATEGORIES:
		if preset.has(String(category)):
			var value = preset[String(category)]
			design.choices[category] = value.duplicate() if value is Array else value
	return design


## Gleicht der Bauplan exakt der Vorlage? (Für den Haken auf der Vorlagen-Karte.)
func matches(preset: Dictionary) -> bool:
	var other := CrawlerDesign.from_preset(preset)
	for category in PartCatalog.CATEGORIES:
		var a = choices[category]
		var b = other.choices[category]
		if a is Array:
			if a.size() != b.size() or a.any(func(x): return not x in b):
				return false
		elif a != b:
			return false
	return true


func duplicate_design() -> CrawlerDesign:
	return CrawlerDesign.from_dict(to_dict())


## Zufälliger Crawler für den Würfel-Knopf in der Garage.
static func random(rng: RandomNumberGenerator) -> CrawlerDesign:
	var design := CrawlerDesign.new()
	for category in PartCatalog.CATEGORIES:
		var options: Array = PartCatalog.parts(category)
		if category in PartCatalog.MULTI_SELECT:
			for p in options:
				if rng.randf() < 0.35:
					design.choices[category].append(p.id)
		else:
			design.choices[category] = options[rng.randi_range(0, options.size() - 1)].id
	return design


func to_dict() -> Dictionary:
	var out := {}
	for category in choices:
		var value = choices[category]
		out[String(category)] = value.map(func(v): return String(v)) if value is Array else String(value)
	return out


## Unbekannte Kategorien oder Teile (z. B. aus älteren Spielständen) fallen auf den Standard zurück.
static func from_dict(data: Dictionary) -> CrawlerDesign:
	var design := CrawlerDesign.new()
	for category in PartCatalog.CATEGORIES:
		var value = data.get(String(category))
		if value == null:
			continue
		if category in PartCatalog.MULTI_SELECT:
			if value is Array:
				for id in value:
					if PartCatalog.has_part(category, StringName(id)) and not StringName(id) in design.choices[category]:
						design.choices[category].append(StringName(id))
		elif PartCatalog.has_part(category, StringName(str(value))):
			design.choices[category] = StringName(str(value))
	return design
