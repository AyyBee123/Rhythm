extends Node2D

@onready var sprite = %Sprite
@onready var level = get_tree().current_scene

const ARROW_LIGHT = preload("res://Scenes/Misc/arrow_light.tscn")

const BASE_SIZE = 16

var FINAL_SIZE: float

var arrow: Node2D
var hold_duration: float
var is_held: bool = false
var key: String
var button
var hold_time: float = 0.0

var speed: float
var direction: Vector2

func _ready() -> void:
	# (base_size_in_px) x (whatever) x (pixels_per_beat) x (hold_duration_in_beats)
	%Sprite.size.y = BASE_SIZE * 3 * (level.FALLING_SPEED_SCALE / level.sec_per_beat) * (hold_duration / level.sec_per_beat)

func _process(delta: float) -> void:
	if not is_held: # basically following the arrow as it goes towards the key
		position += direction * speed * delta
	elif button: # the arrow was hit by the key
		global_position = button.global_position
		%Sprite.size.y -= speed * delta
		
		if %Sprite.size.y <= 8:
			Score.update_hold_note_points(Score.TimingJudgement.PERFECT)
			queue_free()
	if not is_instance_valid(arrow) and not is_held: # the arrow was missed
		Score.update_hold_note_points(Score.TimingJudgement.MISS)
		queue_free()

func hold() -> void:
	add_child(ARROW_LIGHT.instantiate())
	is_held = true

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_released(key) and is_held:
		if %Sprite.size.y <= clamp(16, 24 * level.FALLING_SPEED_SCALE, 32):
			Score.update_hold_note_points(Score.TimingJudgement.PERFECT)
		else:
			Score.update_hold_note_points(Score.TimingJudgement.MISS)
		queue_free()
