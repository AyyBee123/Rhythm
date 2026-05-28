extends Node2D

var size: float = 1.0
var tween

func _ready() -> void:
	set_color()
	play_animation()

func play_animation() -> void:
	tween = get_tree().create_tween()
	tween.tween_callback(func(): scale = Vector2.ONE * 0.5)
	tween.tween_callback(func(): modulate.a = 0.75)
	tween.tween_property(self, "scale", Vector2.ONE * 1.2, 0.0333)
	tween.tween_property(self, "scale", Vector2.ONE * 0.85, 0.0334)
	tween.tween_property(self, "position:y", -25, 0.2666)
	tween.parallel().tween_property(self, "modulate:a", 0, 0.2666)
	tween.tween_callback(queue_free)

func set_color() -> void:
	match %Text.text:
		"Perfect":
			modulate = "43cfeb"
		"Great":
			modulate = "29e849"
		"Good":
			modulate = "e4b719"
		"Bad":
			modulate = "b81414"
		"Miss":
			modulate = "6f246f"

func _exit_tree() -> void:
	if tween:
		tween.kill()
