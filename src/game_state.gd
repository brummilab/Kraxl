class_name GameState
## Szenenübergreifender Zustand: der aktuell gebaute Crawler.
## Gespeichert nur lokal unter user:// (App-eigener Speicher, keine Berechtigung, kein Netz).

const SAVE_PATH := "user://garage/crawler.json"

static var _design: CrawlerDesign


static func design() -> CrawlerDesign:
	if _design == null:
		_design = load_design()
	return _design


static func set_design(value: CrawlerDesign) -> void:
	_design = value
	save_design(value)


static func load_design() -> CrawlerDesign:
	if not FileAccess.file_exists(SAVE_PATH):
		return CrawlerDesign.new()
	var data = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	return CrawlerDesign.from_dict(data) if data is Dictionary else CrawlerDesign.new()


static func save_design(value: CrawlerDesign) -> void:
	DirAccess.make_dir_recursive_absolute(SAVE_PATH.get_base_dir())
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(value.to_dict(), "  "))
