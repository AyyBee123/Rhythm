extends AnimatedSprite2D

@export var input_value: String

@onready var level = get_tree().current_scene

var current_note: Node2D = null
var queue: Array # if a note enters while there is another note already in the key, add it here
var perfect: bool = false
var good: bool = false
var ok: bool = false

func _input(event):
	if not level.song_started or level.song_ended:
		return
	if Input.is_action_just_pressed(input_value):
		play("Pressed")
		if current_note:
			if perfect: # perfect hit
				Score.update_points(Score.TimingJudgement.PERFECT)
			elif good: # good hit
				Score.update_points(Score.TimingJudgement.GOOD)
			elif ok: # ok hit
				Score.update_points(Score.TimingJudgement.OK)
			
			current_note.get_parent().destroy()
		else: # not hitting a note
			Score.update_points(Score.TimingJudgement.BAD)

func _on_ok_area_area_entered(area):
	if current_note:
		queue.append(area)
		return
	ok = true
	current_note = area
	current_note.get_parent().destroyed.connect(key_destroyed)

func _on_ok_area_area_exited(area):
	if queue.size() > 0:
		current_note = queue.pop_front()
		current_note.get_parent().destroyed.connect(key_destroyed)
		return
	
	ok = false
	current_note = null

func _on_good_area_area_entered(area):
	good = true

func _on_good_area_area_exited(area):
	good = false

func _on_perfect_area_area_entered(area):
	perfect = true

func _on_perfect_area_area_exited(area):
	perfect = false

func key_destroyed():
	if queue.size() > 0:
		current_note = queue.pop_front()
		current_note.get_parent().destroyed.connect(key_destroyed)
	elif current_note:
		current_note = null

func _on_animation_finished():
	if animation == "Pressed":
		play("Unpressed")
