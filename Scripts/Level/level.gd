extends Node2D

@export var id: String # id to access stats from the level select and save file
@export_enum("Easy", "Normal", "Hard") var level_difficulty = 0

# values from the midi file
@export var up_value: int
@export var down_value: int
@export var left_value: int
@export var right_value: int

@export var FALLING_SPEED_SCALE: float = 1.0

@export_range(1, 16) var difficulty: int = 1
@export_file("*.json") var notes_file: String = "" # json notes file path
@export var preview_time: float = 20.0

@onready var arrows: Dictionary = {
	up_value: {
		"key": "up", # key matches the key name in the project settings
		"rotation": 0, # default rotation of the arrow is pointing up
		"position": Vector2(0, -1) # the normalized position the arrow spawns in
	},
	down_value: {
		"key": "down",
		"rotation": PI,
		"position": Vector2(0, 1)
	},
	left_value: {
		"key": "left",
		"rotation": 3 * PI/2,
		"position": Vector2(-1, 0)
	},
	right_value: {
		"key": "right",
		"rotation": PI/2,
		"position": Vector2(1, 0)
	}
}

@onready var core = %Core
@onready var score = %Score

const ARROW = preload("uid://bpxatk686jj0s")
const COUNTDOWN_TEXT = preload("uid://dn4kj3f0rfxhx")
const DEFEAT_SCREEN = preload("uid://ct0irb1dbg0yo")

const NOTE_OFFSET: int = 200
const KEY_OFFSET: int = 40
const DAMAGE: int = 2
const HALF_STEP: float = 0.5
var TIMING_OFFSET: float = 2.0

var played: bool = false # check to see if the song has played (to prevent looping the song after it finishes)
var note_index: int = 0 # the index of the next note to be played
var notes: Array = [] # loaded notes JSON
var attempts: int # number of times the level was played

var bpm: float
var current_beat: float = 0.0
var last_beat: int = -8
var song_duration: float # in seconds
var beat_offset: float
var song_offset: float = 0.1 # in seconds
var beats_before_start: int = 4 # "3, 2, 1, GO!"
var sec_per_beat: float

var conductor_time: float = 0.0
var song_start_time: float = 0.0
var song_started: bool = false
var song_ended: bool = false
var can_press: bool = false
var next_note_spawn_time: float
var practice_mode: bool = false
var tween: Tween
var lost: bool = false

var song_time_minutes: int: 
	get:
		return (clamp(conductor_time, 0, song_duration) / 60) as int
var song_time_seconds: int:
	get:
		return clamp(conductor_time, 0, song_duration) as int % 60

var song_duration_minutes: int:
	get:
		return (song_duration / 60) as int
var song_duration_seconds: int:
	get:
		return song_duration as int % 60

func _ready() -> void:
	Score.reset_score()
	notes = NotesData.load_json(notes_file) # Array of note dictionaries
	song_duration = %AudioStreamPlayer.stream.get_length()
	bpm = notes[0]["tempo"]
	next_note_spawn_time = notes[0]["start_time"]
	TIMING_OFFSET = 1.0 / FALLING_SPEED_SCALE
	sec_per_beat = 60.0 / bpm
	conductor_time = -(beats_before_start + 1) * sec_per_beat
	%"Beat Timer".wait_time = sec_per_beat
	%"Beat Timer".start()
	
	SignalBus.note_hit.connect(note_hit)
	SignalBus.defeat.connect(on_defeat)

func _process(delta) -> void:
	if not song_started:
		# countdown time (negative song time)
		conductor_time += delta
	elif song_started and not song_ended:
		# Actual music time, synced with AudioStreamPlayer
		var playback_time = %AudioStreamPlayer.get_playback_position() \
				+ AudioServer.get_time_since_last_mix() \
				- AudioServer.get_output_latency()
		conductor_time = playback_time + song_start_time
	else:
		# go back to delta time (for objects that sync with the beat)
		conductor_time += delta
	
	var travel_time = TIMING_OFFSET
	
	if conductor_time >= next_note_spawn_time - travel_time and note_index < notes.size():
		spawn_arrow(notes[note_index])
	
	current_beat = conductor_time / sec_per_beat
	
	if int(current_beat) != last_beat: # for anything that "pulses" to the beat
		last_beat = int(floor(current_beat))
		SignalBus.pulse.emit(sec_per_beat)
	
	%Score.text = Utils.format_number_with_commas(Score.displayed_points)
	%Combo.text = Utils.format_number_with_commas(Score.combo)
	%"Combo Multiplier".text = str(Score.combo_multi)
	%Accuracy.text = str(floori(Score.accuracy)) + "%"
	%Rank.text = Score.rank
	%"Song Duration".text = "%01d:%02d" % [song_time_minutes, song_time_seconds] + " / " \
			+ "%01d:%02d" % [song_duration_minutes, song_duration_seconds]
	%"Song Progress Bar".value = conductor_time / song_duration * %"Song Progress Bar".max_value

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("quick_restart"):
		Score.reset_score()
		get_tree().reload_current_scene()

func spawn_arrow(arrow) -> void:
	if not arrows.has(int(arrow["key"])):
		note_index += 1
		if note_index < notes.size():
			next_note_spawn_time = notes[note_index]["start_time"]
			bpm = notes[note_index]["tempo"]
			sec_per_beat = 60.0 / bpm
		return
	var note_data = arrows[int(arrow["key"])]
	var note = ARROW.instantiate()
	note.global_position = note_data["position"] * (NOTE_OFFSET + KEY_OFFSET)
	note.direction = -note_data["position"]
	note.rotation = note_data["rotation"]
	note.key = note_data["key"]
	note.speed = NOTE_OFFSET * FALLING_SPEED_SCALE
	note.is_hold_note = notes[note_index]["hold"]
	note.hold_duration = notes[note_index]["duration"]
	note.core = core
	add_child(note)
	note_index += 1
	if note_index < notes.size():
		next_note_spawn_time = notes[note_index]["start_time"]
		bpm = notes[note_index]["tempo"]
		sec_per_beat = 60.0 / bpm

func _on_countdown_timer_timeout() -> void:
	beats_before_start -= 1
	if beats_before_start > 0:
		show_countdown_number(beats_before_start) # 3, 2, 1
	elif beats_before_start == 0:
		show_go() # GO!
		can_press = true
	elif beats_before_start == -1:
		song_started = true
		%AudioStreamPlayer.play() # song starts here
		song_start_time = conductor_time # align conductor time
	else:
		%"Beat Timer".stop()

func show_countdown_number(num) -> void:
	var text = COUNTDOWN_TEXT.instantiate()
	text.lifetime = sec_per_beat / 2
	text.get_node("%Text").text = str(num)
	add_child(text)
	%"Countdown Sound".play()

func show_go() -> void:
	var text = COUNTDOWN_TEXT.instantiate()
	text.lifetime = sec_per_beat / 2
	text.get_node("%Text").text = str("GO!")
	add_child(text)
	%"Go Sound".play()

func _on_audio_stream_player_finished() -> void:
	song_ended = true
	Score.save_score(id + "_" + str(level_difficulty))

func note_hit(type: String) -> void:
	if type == "Miss" or type == "Bad":
		return
	pulse(%"Combo Multiplier")

func pulse(node) -> void:
	if tween and tween.is_running():
		tween.kill()
	var time = sec_per_beat / 4
	tween = create_tween()
	tween.tween_callback(func(): node.scale = Vector2.ONE * 1.08)
	tween.tween_property(node, "scale", Vector2.ONE, time)

func on_defeat() -> void:
	lost = true
	%AudioStreamPlayer.stop()
	add_child(DEFEAT_SCREEN.instantiate())
