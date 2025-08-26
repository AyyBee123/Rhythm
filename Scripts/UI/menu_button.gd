extends Button

var focused_once := false
var initial_focus := false

func _ready():
	mouse_entered.connect(_on_mouse_entered)
	focus_entered.connect(_focus_entered)

func _on_mouse_entered():
	grab_focus()

func _focus_entered():
	if initial_focus:
		return
	Game.audio_manager.scroll.play()
