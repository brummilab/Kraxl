class_name GameState
## Szenenübergreifender Zustand: die gebauten Crawler (einer je Spieler) und die Spielerzahl.
## Gespeichert nur lokal unter user:// (App-eigener Speicher, keine Berechtigung, kein Netz).

const SAVE_PATH := "user://garage/crawler.json"
const SAVE_PATH_PLAYER_2 := "user://garage/crawler_2.json"
const SETTINGS_PATH := "user://garage/spieler.json"
const MAX_PLAYERS := 2
## Von der CI vor dem Export geschrieben (ADR 0012); fehlt bei lokalen Builds.
const VERSION_PATH := "res://data/version.txt"
## Spieler 2 startet mit einer anderen Vorlage, damit man die Crawler sofort unterscheidet.
const PLAYER_2_PRESET := &"gelaendewagen"

static var _designs := {}
static var _players := 0


## Bauplan eines Spielers (0 = Spieler 1).
static func design(player := 0) -> CrawlerDesign:
	if not _designs.has(player):
		_designs[player] = load_design(player)
	return _designs[player]


static func set_design(value: CrawlerDesign, player := 0) -> void:
	_designs[player] = value
	save_design(value, player)


static func player_count() -> int:
	if _players == 0:
		_players = 1
		if FileAccess.file_exists(SETTINGS_PATH):
			var data = JSON.parse_string(FileAccess.get_file_as_string(SETTINGS_PATH))
			if data is Dictionary:
				_players = clampi(int(data.get("spieler", 1)), 1, MAX_PLAYERS)
	return _players


static func set_player_count(count: int) -> void:
	_players = clampi(count, 1, MAX_PLAYERS)
	_write(SETTINGS_PATH, {"spieler": _players})


static func load_design(player := 0) -> CrawlerDesign:
	var path := _path(player)
	if not FileAccess.file_exists(path):
		return _default_design(player)
	var data = JSON.parse_string(FileAccess.get_file_as_string(path))
	return CrawlerDesign.from_dict(data) if data is Dictionary else _default_design(player)


static func save_design(value: CrawlerDesign, player := 0) -> void:
	_write(_path(player), value.to_dict())


## „Build 42 (2b6a8bc, 2026-10-26)“ oder „lokaler Build“ – für die F3-Anzeige.
static func version() -> String:
	if FileAccess.file_exists(VERSION_PATH):
		return FileAccess.get_file_as_string(VERSION_PATH).strip_edges()
	return "lokaler Build"


## Nur für Tests: vergisst den zwischengespeicherten Zustand (Dateien bleiben).
static func forget() -> void:
	_designs.clear()
	_players = 0


static func _default_design(player: int) -> CrawlerDesign:
	if player == 0:
		return CrawlerDesign.new()
	for preset in PartCatalog.PRESETS:
		if preset.id == PLAYER_2_PRESET:
			return CrawlerDesign.from_preset(preset)
	return CrawlerDesign.new()


static func _path(player: int) -> String:
	return SAVE_PATH if player == 0 else SAVE_PATH_PLAYER_2


static func _write(path: String, data: Dictionary) -> void:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "  "))
