extends Button

var focused_once: bool = false
var initial_focus: bool = false

func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	focus_entered.connect(_focus_entered)

func _on_mouse_entered() -> void:
	grab_focus()

func _focus_entered() -> void:
	if initial_focus:
		return
	Game.audio_manager.scroll.play()
