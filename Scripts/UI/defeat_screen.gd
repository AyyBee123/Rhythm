extends Control

func _ready() -> void:
	var first_button = %Buttons.get_child(0)
	first_button.initial_focus = true
	first_button.grab_focus()
	first_button.initial_focus = false

func _on_retry_pressed() -> void:
	get_tree().reload_current_scene()

func _on_menu_pressed() -> void:
	get_tree().change_scene_to_file("uid://bsmraarf5bk6q")
