extends Node

func format_number_with_commas(n: int) -> String:
	var s = str(n)
	var result = ""
	var count = 0
	for i in range(s.length() - 1, -1, -1):
		result = s[i] + result
		count += 1
		if count % 3 == 0 and i != 0:
			result = "," + result
	return result

func get_files(folder_path: String) -> Array:
	var files := []
	
	var dir := DirAccess.open(folder_path)
	if dir == null:
		push_error("Failed to open folder: " + folder_path)
		return files
	
	dir.list_dir_begin()
	while true:
		var file_name := dir.get_next()
		if file_name == "":
			break
		if not dir.current_is_dir():
			# Proper path concatenation
			files.append(folder_path + "/" + file_name)
	dir.list_dir_end()
	
	return files
