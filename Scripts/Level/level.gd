extends Node2D

# values from the midi file
@export var up_value: int
@export var down_value: int
@export var left_value: int
@export var right_value: int

@export var FALLING_SPEED_SCALE: float = 0.5

@export_file("*.png", "*.jpg", "*.jpeg") var arrow_texture: String = ""
@export_file("*.mid") var file: String = "" # midi file path
@export_file("*.ogg") var music_file: String = "" # music file path

@onready var notes: Dictionary = {
	up_value: {
		"key": "up", # key matches the key name in the project settings
		"rotation": 0, # default rotation of the arrow is pointing up
		"position": Vector2(0, -1), # the normalized position the arrow spawns in
		"queue": []
	},
	down_value: {
		"key": "down",
		"rotation": PI,
		"position": Vector2(0, 1),
		"queue": []
	},
	left_value: {
		"key": "left",
		"rotation": 3 * PI/2,
		"position": Vector2(-1, 0),
		"queue": []
	},
	right_value: {
		"key": "right",
		"rotation": PI/2,
		"position": Vector2(1, 0),
		"queue": []
	}
}

@onready var core = $Core
@onready var score = %Score

const ARROW = preload("uid://bpxatk686jj0s")

const NOTE_OFFSET := 340
const KEY_OFFSET := 40
const DAMAGE := 2
var TIMING_OFFSET := 1.0 / FALLING_SPEED_SCALE

var delta_sum := 0.0
var played: bool = false # check to see if the song has played (to prevent looping the song after it finishes)

func _ready() -> void:
	%AudioStreamPlayer.stream = load(music_file)
	%MidiPlayer.file = file
	%MidiPlayer.play()
	SignalBus.take_damage.connect(take_damage)

func _process(delta) -> void:
	_check_input()
	_check_missed_notes()
	
	delta_sum += delta
	
	if delta_sum >= TIMING_OFFSET and not played:
		played = true
		%AudioStreamPlayer.play()
	
	%Score.text = str(Highscore.displayed_points)

func _check_input() -> void:
	for note_data in notes.values():
		if Input.is_action_just_pressed(note_data["key"]):
			_check_note_hit(note_data)

func _check_note_hit(note_data: Dictionary) -> void:
	if not note_data["queue"].is_empty():
		var next_note: Node2D = note_data["queue"].front()
		if next_note.test_hit(delta_sum):
			note_data["queue"].pop_front().hit(delta_sum)
		else:
			# too early
			take_damage()
			Highscore.update_points(Highscore.TimingJudgement.WHAT)
	else:
		# no notes in the queue
		take_damage()
		Highscore.update_points(Highscore.TimingJudgement.WHAT)

func _check_missed_notes() -> void:
	for note_data in notes.values():
		if not note_data["queue"].is_empty():
			if note_data["queue"].front().test_miss(delta_sum):
				note_data["queue"].pop_front().miss()

func take_damage() -> void:
	print("ouch")

func _on_midi_player_midi_event(channel: Variant, event: Variant) -> void:
	if event.type == SMF.MIDIEventType.note_on:
		if OS.has_feature("editor"):
			print(event.note)
		
		var note_data = notes.get(event.note)
		if note_data:
			var note = ARROW.instantiate()
			note.global_position = note_data["position"] * (NOTE_OFFSET + KEY_OFFSET)
			note.direction = -note_data["position"]
			note.rotation = note_data["rotation"]
			note.key = note_data["key"]
			note.texture = load(arrow_texture)
			note.speed = NOTE_OFFSET * FALLING_SPEED_SCALE
			note.expected_time = delta_sum + TIMING_OFFSET
			note.core = core
			note_data["queue"].push_back(note)
			add_child(note)
