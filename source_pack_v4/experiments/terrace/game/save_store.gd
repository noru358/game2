extends RefCounted

const PATH := "user://first_trail_v2.json"

static func write(data: Dictionary, path: String = PATH) -> Error:
	if not valid(data): return ERR_INVALID_DATA
	var f := FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if f == null:
		return FileAccess.get_open_error()
	f.store_string(JSON.stringify(data))
	f.flush()
	var write_error := f.get_error()
	f.close()
	if write_error != OK: return write_error
	if read_one(path + ".tmp").is_empty(): return ERR_INVALID_DATA
	# A fallback-loaded run must never rotate the corrupt primary over its good backup.
	if not read_one(path).is_empty():
		var backup := DirAccess.copy_absolute(path, path + ".bak")
		if backup != OK:
			return backup
	return DirAccess.rename_absolute(path + ".tmp", path)

static func read_one(path: String) -> Dictionary:
	if not FileAccess.file_exists(path): return {}
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path)) != OK: return {}
	return parser.data if valid(parser.data) else {}

static func read_data(path: String = PATH) -> Dictionary:
	for candidate in [path, path + ".bak"]:
		var data := read_one(candidate)
		if not data.is_empty(): return data
	return {}

static func valid(data: Variant) -> bool:
	if not data is Dictionary or data.get("schema", 0) != 2:
		return false
	if not vector_valid(data.get("player")) or not data.get("enemies") is Array:
		return false
	for entry in data.enemies:
		if not entry is Dictionary or not vector_valid(entry.get("p")) or not entry.get("id") is String:
			return false
	return true

static func vector_valid(value: Variant) -> bool:
	if not value is Array or value.size() != 3:
		return false
	for n in value:
		if not (n is float or n is int) or not is_finite(float(n)):
			return false
	return true
