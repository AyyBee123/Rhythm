extends Node2D

@onready var sprite = %Sprite
@onready var level = get_tree().current_scene

const BASE_SIZE = 16

var FINAL_SIZE: float

var arrow: Node2D
var hold_duration: float
var is_held := false
var key
var button
var hold_time := 0.0

var speed: float
var direction: Vector2

func _ready():
	# (base_size_in_px) x (whatever) x (pixels_per_beat) x (hold_duration_in_beats)
	%Sprite.size.y = BASE_SIZE * 3.6 * (level.FALLING_SPEED_SCALE / level.sec_per_beat) * (hold_duration / level.sec_per_beat)
	FINAL_SIZE = %Sprite.size.y

func _process(delta):
	if not is_held:
		position += direction * speed * delta
	elif button:
		global_position = button.global_position
		%Sprite.size.y -= speed * delta
		hold_time += delta
		
		if %Sprite.size.y <= 8:
			Score.update_hold_note_points(Score.TimingJudgement.PERFECT)
			queue_free()
	if not is_instance_valid(arrow) and not is_held:
		Score.update_hold_note_points(Score.TimingJudgement.MISS)
		queue_free()

func hold():
	is_held = true

func _unhandled_input(event):
	if Input.is_action_just_released(key) and is_held:
		if %Sprite.size.y <= clamp(16, 24 * level.FALLING_SPEED_SCALE, 32):
			Score.update_hold_note_points(Score.TimingJudgement.PERFECT)
		else:
			Score.update_hold_note_points(Score.TimingJudgement.MISS)
		queue_free() # for now
