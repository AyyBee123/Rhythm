extends Control

const LEVEL_SELECT = preload("uid://bsmraarf5bk6q")

func _ready():
	var first_button = %Buttons.get_child(0)
	first_button.initial_focus = true
	first_button.grab_focus()
	first_button.initial_focus = false

func _on_play_pressed():
	get_tree().change_scene_to_packed(LEVEL_SELECT)

func _on_settings_pressed():
	pass

func _on_quit_pressed():
	get_tree().quit()
