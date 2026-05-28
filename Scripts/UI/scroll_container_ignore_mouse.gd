extends ScrollContainer

@onready var content = %"Level List"
var tween: Tween

func _gui_input(event: InputEvent) -> void:
	# Ignore mouse wheel completely
	if event is InputEventMouseButton and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
		event.accept()  # consume the event so ScrollContainer doesn't scroll

var virtual_scroll: float = 0.0

func _center_on(ctrl: Control) -> void:
	if tween and tween.is_running():
		tween.kill()
	
	var max_scroll = max(0, content.size.y - size.y)
	if max_scroll <= 0:
		return
	
	var target_v: float = ctrl.position.y + ctrl.size.y / 2 - size.y / 2
	target_v = clampf(target_v, 0, max_scroll)
	
	tween = create_tween()
	tween.tween_property(self, "scroll_vertical", target_v, 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
