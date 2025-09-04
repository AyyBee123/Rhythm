extends Node

const PAUSE_MENU = preload("res://Scenes/UI/pause_menu.tscn")

var level
var pause_menu

func _ready():
	level = get_tree().current_scene

func _input(event):
	if not level.song_started or level.song_ended:
		return
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().paused = not get_tree().paused
		
		# spawn pause menu if paused
		if get_tree().paused and not pause_menu:
			pause_menu = PAUSE_MENU.instantiate()
			level.add_child(pause_menu)
		
		# delete pause menu if unpaused
		if not get_tree().paused and pause_menu:
			pause_menu.queue_free()
