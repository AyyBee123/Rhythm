extends AnimatedSprite2D

@onready var level = get_tree().current_scene

const HIT_TEXT = preload("res://Scenes/Main/hit_text.tscn")

func _ready():
	%Up.position = Vector2.UP * level.KEY_OFFSET
	%Down.position = Vector2.DOWN * level.KEY_OFFSET
	%Left.position = Vector2.LEFT * level.KEY_OFFSET
	%Right.position = Vector2.RIGHT * level.KEY_OFFSET
	
	SignalBus.note_hit.connect(spawn_text)

func spawn_text(text: String):
	var hit = HIT_TEXT.instantiate()
	hit.get_node("%Text").text = text
	get_tree().current_scene.add_child(hit)
