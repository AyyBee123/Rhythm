extends Node2D

# values from the midi file
@export var up_value: int
@export var down_value: int
@export var left_value: int
@export var right_value: int

@export var FALLING_SPEED_SCALE: float = 1.0

@export_range(1, 16) var difficulty: int = 1
@export_file("*.json") var notes_file: String = "" # json notes file path

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

const NOTE_OFFSET := 200
const KEY_OFFSET := 40
const DAMAGE := 2
const HALF_STEP := 0.5
var TIMING_OFFSET := 2.0

var played: bool = false # check to see if the song has played (to prevent looping the song after it finishes)
var note_index := 0 # the index of the next note to be played
var notes := [] # Your loaded notes JSON
var attempts: int # number of times the level was played

var bpm: float
var current_beat := 0.0
var last_beat := 0
var song_duration: float # in seconds
var beat_offset: float
var song_offset: float = 0.1 # in seconds
var beats_before_start = 4  # "3, 2, 1, GO!"
var sec_per_beat: float

var conductor_time := 0.0
var song_start_time := 0.0
var song_started := false
var song_ended := false
var can_press := false
var next_note_spawn_time: float
var practice_mode := false

var song_time_minutes: int: 
	get:
		return clamp(conductor_time, 0, song_duration) as int / 60
var song_time_seconds: int:
	get:
		return clamp(conductor_time, 0, song_duration) as int % 60

var song_duration_minutes: int:
	get:
		return song_duration as int / 60
var song_duration_seconds: int:
	get:
		return song_duration as int % 60

func _ready() -> void:
	notes = NotesData.load_json(notes_file) # Array of note dictionaries
	song_duration = %AudioStreamPlayer.stream.get_length()
	bpm = notes[0]["tempo"]
	next_note_spawn_time = notes[0]["start_time"]
	TIMING_OFFSET = 1.0 / FALLING_SPEED_SCALE
	sec_per_beat = 60.0 / bpm
	conductor_time = -(beats_before_start + 1) * sec_per_beat
	current_beat = conductor_time / sec_per_beat
	last_beat = int(current_beat) + 1 # +1 to prevent a pulse at the very start of the level
	%"Beat Timer".wait_time = sec_per_beat
	%"Beat Timer".start()

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
		last_beat = int(current_beat)
		SignalBus.pulse.emit(sec_per_beat)
	
	%Score.text = Utils.format_number_with_commas(Score.displayed_points)
	%Combo.text = Utils.format_number_with_commas(Score.combo)
	%"Combo Multiplier".text = str(Score.combo_multi)
	%"Combo Multiplier Progress".value = Score.hit_ratio
	%Accuracy.text = str(floori(Score.accuracy)) + "%"
	%Rank.text = Score.rank
	%"Song Duration".text = "%01d:%02d" % [song_time_minutes, song_time_seconds] + " / " \
			+ "%01d:%02d" % [song_duration_minutes, song_duration_seconds]
	%"Song Progress Bar".value = conductor_time / song_duration * %"Song Progress Bar".max_value

func _unhandled_input(event):
	if Input.is_action_just_pressed("quick_restart"):
		Score.reset_score()
		get_tree().reload_current_scene()

func spawn_arrow(arrow):
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

func _on_countdown_timer_timeout():
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

func show_countdown_number(num):
	var text = COUNTDOWN_TEXT.instantiate()
	text.lifetime = sec_per_beat / 2
	text.get_node("%Text").text = str(num)
	add_child(text)
	%"Countdown Sound".play()

func show_go():
	var text = COUNTDOWN_TEXT.instantiate()
	text.lifetime = sec_per_beat / 2
	text.get_node("%Text").text = str("GO!")
	add_child(text)
	%"Go Sound".play()

func _on_audio_stream_player_finished():
	song_ended = true
	Score.save_score(name)
