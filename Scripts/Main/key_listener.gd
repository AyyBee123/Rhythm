extends AnimatedSprite2D

@onready var level = get_tree().current_scene

func _ready():
	%Up.position = Vector2.UP * level.KEY_OFFSET
	%Down.position = Vector2.DOWN * level.KEY_OFFSET
	%Left.position = Vector2.LEFT * level.KEY_OFFSET
	%Right.position = Vector2.RIGHT * level.KEY_OFFSET
