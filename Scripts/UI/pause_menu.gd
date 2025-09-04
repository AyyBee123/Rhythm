extends Control

func _ready():
	var first_button = %Buttons.get_child(0)
	first_button.initial_focus = true
	first_button.grab_focus()
	first_button.initial_focus = false

func _on_resume_pressed():
	queue_free()

func _on_retry_pressed():
	get_tree().reload_current_scene()

func _on_menu_pressed():
	get_tree().change_scene_to_file("uid://bsmraarf5bk6q")

func _on_difficulty_pressed():
	pass

func _exit_tree():
	get_tree().paused = false
