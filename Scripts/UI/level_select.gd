extends Control

@onready var preview_player: AudioStreamPlayer = %PreviewPlayer

const LEVEL_BUTTON = preload("uid://bocn8w7iidy23")
const HEART_PIP = preload("uid://ckr2thfbbm207")

var file_path: String = "res://Scenes/Levels/"
var levels: Array
var idx: int = 0
var song_tween: Tween
var preview_start: float = 20.0 # in seconds
var preview_length: float = 10.0 # also in seconds

var current_beat: float
var last_beat: int
var bpm: int
var sec_per_beat: float
var preview_time: float
var should_pulse: bool = true

func _ready() -> void:
	var files = Utils.get_files(file_path)
	
	for file in files:
		var level = LEVEL_BUTTON.instantiate()
		level.level = load(file)
		var scene = level.level.instantiate()
		level.text = scene.name
		level.level_id = scene.id
		level.level_difficulty = str(scene.level_difficulty)
		level.notes_file = scene.notes_file
		level.notes = NotesData.load_json(level.notes_file) # array of note dictionaries
		level.bpm = level.notes[0]["tempo"]
		level.song = scene.get_node("%AudioStreamPlayer").stream
		level.song_duration = level.song.get_length()
		level.song_duration_text = "%01d:%02d" % [int(level.song_duration / 60), int(level.song_duration) % 60]
		level.difficulty = scene.difficulty
		level.preview_start = scene.preview_time
		scene.queue_free()
		%"Level List".add_child(level)
		level.focus_entered.connect(_on_button_focus_entered.bind(level))
		level.focus_exited.connect(_on_button_focus_exited.bind(level))
	
	# sort list of levels by difficulty
	levels = %"Level List".get_children()
	levels.sort_custom(func(a, b): return a.difficulty < b.difficulty)
	for i in range(levels.size()):
		%"Level List".move_child(levels[i], i)
	
	# set the top and bottom neighbours for each level button
	for i in range(levels.size()):
		var previous_index = (i - 1 + levels.size()) % levels.size()
		var next_index = (i + 1) % levels.size()
		levels[i].focus_neighbor_top = levels[previous_index].get_path()
		levels[i].focus_neighbor_bottom = levels[next_index].get_path()
	
	levels[0].initial_focus = true
	levels[0].grab_focus()
	levels[0].initial_focus = false

func _process(_delta: float) -> void:
	if preview_player.playing:
		if preview_player.get_playback_position() >= preview_start + preview_length:
			_loop_with_fade(1)
		
		var playback_time = %PreviewPlayer.get_playback_position() \
				+ AudioServer.get_time_since_last_mix() \
				- AudioServer.get_output_latency()
		
		current_beat = playback_time / sec_per_beat
		
		if int(current_beat) != last_beat and should_pulse: # for anything that "pulses" to the beat
			last_beat = int(current_beat)
			SignalBus.pulse.emit(sec_per_beat)

func _loop_with_fade(fade_time: float) -> void:
	# prevent multiple triggers
	if song_tween and song_tween.is_running():
		return
	
	song_tween = create_tween()
	# fade out
	song_tween.tween_property(preview_player, "volume_db", -40, fade_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	song_tween.tween_callback(func():
		preview_player.play()
		preview_player.seek(preview_start)
		var playback_time = %PreviewPlayer.get_playback_position() \
				+ AudioServer.get_time_since_last_mix() \
				- AudioServer.get_output_latency()
		current_beat = playback_time / sec_per_beat
		last_beat = current_beat
	)
	# fade back in
	song_tween.tween_property(preview_player, "volume_db", 0, fade_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _on_button_focus_entered(btn: Button) -> void:
	sec_per_beat = 60.0 / btn.bpm
	%ScrollContainer._center_on(btn)
	load_score(btn.level_id + "_" + btn.level_difficulty)
	set_preview_values(btn)
	preview_start = btn.preview_start
	preview_song(btn.song)

func load_score(song_id: String) -> void:
	var score_data: ScoreData = Save.profile.scores.get(song_id, null)
	if score_data != null:
		%"High Score".text = Utils.format_number_with_commas(score_data.best_score)
		%"Highest Combo".text = Utils.format_number_with_commas(score_data.max_combo)
		%Rank.text = str(score_data.rank)
		%Accuracy.text = str(floori(score_data.accuracy)) + "%"
	else:
		%"High Score".text = "--"
		%"Highest Combo".text = "--"
		%Rank.text = ""
		%Accuracy.text = ""

func _on_button_focus_exited(btn: Button) -> void:
	pass

func preview_song(song: AudioStream) -> void:
	if song_tween and song_tween.is_running():
		song_tween.kill()
	song_tween = create_tween()
	song_tween.tween_callback(func(): should_pulse = false)
	song_tween.tween_property(%PreviewPlayer, "volume_db", -40, 0.5).set_trans(Tween.TRANS_CUBIC)
	song_tween.tween_callback(func():
		if song:
			%PreviewPlayer.stop()
			%PreviewPlayer.stream = song
			%PreviewPlayer.volume_db = -40
			%PreviewPlayer.play()
			%PreviewPlayer.seek(preview_start)
			var playback_time = %PreviewPlayer.get_playback_position() \
					+ AudioServer.get_time_since_last_mix() \
					- AudioServer.get_output_latency()
			current_beat = playback_time / sec_per_beat
			last_beat = current_beat
			should_pulse = true
	)
	song_tween.tween_property(%PreviewPlayer, "volume_db", 0, 0.5).set_trans(Tween.TRANS_CUBIC)

func set_preview_values(btn: Button) -> void:
	%Name.text = btn.text
	%BPM.text = str(btn.bpm) + " BPM"
	%"Song Time".text = btn.song_duration_text
	
	for i in %"Difficulty Pips".get_children(): # clear all hearts
		%"Difficulty Pips".remove_child(i)
		i.queue_free()
	
	for i in range(btn.difficulty):
		var pip = HEART_PIP.instantiate()
		pip.position = Vector2((pip.texture.get_width() - 2) * i, pip.texture.get_height() / 2)
		%"Difficulty Pips".add_child(pip)

func get_difficulty_color(difficulty: int, max: int = 16) -> Color:
	var t: float = float(difficulty) / max  # Normalize 0.0 to 1.0
	
	# define key color stops
	var stops = [
		{ "pos": 0.0, "col": Color("32e332") }, # green
		{ "pos": 0.33, "col": Color("e4b719") }, # orange
		{ "pos": 0.75, "col": Color("b81414") }, # red
		{ "pos": 1.0, "col": Color("6f246f") }  # purple
	]
	
	# find which two stops we're between
	for i in range(stops.size() - 1):
		var a = stops[i]
		var b = stops[i + 1]
		if t >= a.pos and t <= b.pos:
			var segment_t = (t - a.pos) / (b.pos - a.pos)
			return a.col.lerp(b.col, segment_t)
	return stops.back().col

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_move(1)
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_move(-1)

func _move(dir: int) -> void:
	if levels.is_empty(): return
	var focused := _current()
	if focused:
		var i := levels.find(focused)
		if i != -1: idx = i
	idx = (idx + dir + levels.size()) % levels.size()
	levels[idx].grab_focus()

func _current() -> Control:
	for c in levels:
		if c.has_focus():
			return c
	return null
