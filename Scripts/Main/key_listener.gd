extends AnimatedSprite2D

@export var on_beat_frame := 1 # the frame that syncs with the music's beat

@onready var level = get_tree().current_scene

const HIT_TEXT = preload("uid://b8ldvl62w53uf")

func _ready():
	%Up.position = Vector2.UP * level.KEY_OFFSET
	%Down.position = Vector2.DOWN * level.KEY_OFFSET
	%Left.position = Vector2.LEFT * level.KEY_OFFSET
	%Right.position = Vector2.RIGHT * level.KEY_OFFSET
	
	SignalBus.note_hit.connect(spawn_text)

func _process(delta):
	var frames = sprite_frames.get_frame_count("Idle")
	var _frame = int(fposmod(level.current_beat * frames + (frames + on_beat_frame), frames))
	frame = _frame

func spawn_text(text: String):
	var hit = HIT_TEXT.instantiate()
	hit.get_node("%Text").text = text
	get_tree().current_scene.add_child(hit)

## set the core's color to red for a brief time when taking damage (bad/miss notes)
func change_color():
	material.set("shader_parameter/tint_factor", 0.85)
	await get_tree().create_timer(0.05, false).timeout
	material.set("shader_parameter/tint_factor", 0.0)
