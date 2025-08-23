extends Node2D

# values from the midi file
@export var up_value: int
@export var down_value: int
@export var left_value: int
@export var right_value: int

@export var FALLING_SPEED_SCALE: float = 0.5

@export_file("*.mid") var file: String = "" # midi file path

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

const NOTE_OFFSET := 340
const KEY_OFFSET := 48
const DAMAGE := 2
var TIMING_OFFSET := 2.0

var played: bool = false # check to see if the song has played (to prevent looping the song after it finishes)
var note_index := 0 # the index of the next note to be played
var notes := [] # Your loaded notes JSON

var bpm: float
var current_beat := 0.0
var current_step := 0.0 # = current_beat x 4
var song_duration: float # in seconds
var beat_offset: float
var song_offset: float = 0.1 # in seconds
var beats_before_start = 4  # "3, 2, 1, GO!"
var sec_per_beat: float

var conductor_time := 0.0
var song_start_time := 0.0
var song_started := false
var song_ended := false
var next_note_spawn_time: float
var practice_mode := false

func _ready() -> void:
	notes = NotesData.load_json(file.get_basename() + "_notes.json") # Array of note dictionaries
	if notes.size() > 0:
		bpm = notes[0]["tempo"]
		song_duration = notes[0]["song_duration"]
		next_note_spawn_time = notes[0]["start_time"]
	TIMING_OFFSET = 1.0 / FALLING_SPEED_SCALE
	sec_per_beat = 60.0 / bpm
	conductor_time = -(beats_before_start + 1) * sec_per_beat
	%"Beat Timer".wait_time = sec_per_beat
	%"Beat Timer".start()
	SignalBus.take_damage.connect(take_damage)
	# Load the data

func _process(delta) -> void:
	if song_started and not song_ended and not %AudioStreamPlayer.playing: # song ended
		song_ended = true
		$"Song End Timer".start()
	
	if not song_started:
		# Countdown time (negative song time)
		conductor_time += delta
	else:
		# Actual music time, synced with AudioStreamPlayer
		var playback_time = %AudioStreamPlayer.get_playback_position() \
			+ AudioServer.get_time_since_last_mix() \
			- AudioServer.get_output_latency()
		conductor_time = playback_time + song_start_time
	
	var travel_time = TIMING_OFFSET
	
	if conductor_time >= next_note_spawn_time - travel_time and note_index < notes.size():
		spawn_arrow(notes[note_index])
	
	current_beat = conductor_time / sec_per_beat
	
	%Score.text = str(Score.displayed_points)
	%Combo.text = str(Score.combo)

func spawn_arrow(arrow):
	var note_data = arrows[int(arrow["key"])]
	var note = ARROW.instantiate()
	note.global_position = note_data["position"] * (NOTE_OFFSET + KEY_OFFSET)
	note.direction = -note_data["position"]
	note.rotation = note_data["rotation"]
	note.key = note_data["key"]
	note.speed = NOTE_OFFSET * FALLING_SPEED_SCALE
	#note.expected_time = delta_sum + TIMING_OFFSET
	note.is_hold_note = notes[note_index]["hold"]
	note.hold_duration = notes[note_index]["duration"]
	note.core = core
	add_child(note)
	note_index += 1
	if note_index < notes.size():
		next_note_spawn_time = notes[note_index]["start_time"]

func take_damage() -> void:
	print("ouch")

func _on_countdown_timer_timeout():
	beats_before_start -= 1
	if beats_before_start > 0:
		show_countdown_number(beats_before_start) # 3, 2, 1
	elif beats_before_start == 0:
		show_go() # GO!
	elif beats_before_start == -1:
		%AudioStreamPlayer.play() # song starts here
		song_start_time = conductor_time # align conductor time
		song_started = true
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

func _on_song_end_timer_timeout():
	print("Victory!")
