extends Node2D

var lifetime := 0.0
var tween

func _ready():
	match %Text.text:
		"3":
			modulate = "b31919"
		"2":
			modulate = "dfb41e"
		"1":
			modulate = "3edf1e"
		_:
			modulate = "41e581"
	
	tween = get_tree().create_tween()
	tween.tween_property(self, "scale", Vector2.ONE * 1.15, lifetime * 0.1)
	tween.tween_property(self, "scale", Vector2.ONE, lifetime * 0.1)
	tween.tween_property(self, "scale", Vector2.ONE * 0.25, lifetime * 0.8)
	tween.tween_callback(queue_free)

func _exit_tree():
	if tween:
		tween.kill()
