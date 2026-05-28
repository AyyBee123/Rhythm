extends Node

func load_json(path: String) -> Variant:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("Failed to open JSON file: " + path)
		return null
	
	var content: String = file.get_as_text()
	file.close()
	
	var result = JSON.parse_string(content)
	if result == null:
		push_error("Failed to parse JSON at: " + path)
		return null
	
	return result
