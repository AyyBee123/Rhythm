extends Node

var level

func _ready():
	level = get_tree().current_scene

func _input(event):
	if not level.song_started or level.song_ended:
		return
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().paused = not get_tree().paused
		
		# spawn pause menu if paused
		
		# delete pause menu if unpaused
