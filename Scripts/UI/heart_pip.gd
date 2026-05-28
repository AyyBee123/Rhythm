extends Sprite2D

var tween: Tween
var time

func _ready() -> void:
	SignalBus.pulse.connect(pulse)

func pulse(sec_per_beat: float) -> void:
	if tween and tween.is_running():
		tween.kill()
	var time = sec_per_beat / 4
	tween = create_tween()
	tween.tween_callback(func(): scale = Vector2.ONE * 1.4)
	tween.tween_property(self, "scale", Vector2.ONE, time)
