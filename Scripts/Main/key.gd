extends Node2D

@export var input_value: String

@onready var level = get_tree().current_scene

const ARROW_FADE = preload("uid://bmoi138j7c3te")

var current_note: Node2D = null
var queue: Array # if a note enters while there is another note already in the key, add it here
var perfect: bool = false
var great: bool = false
var good: bool = false
var tween: Tween

func _ready() -> void:
	SignalBus.pulse.connect(pulse)

func _unhandled_input(event: InputEvent) -> void:
	if not level.can_press or level.song_ended or level.lost:
		return
	if event.is_action_pressed(input_value):
		hit()

func hit() -> void:
	%AnimatedSprite2D.play("Pressed")
	if current_note:
		current_note.get_parent().key = input_value
		current_note.get_parent().button = self
		
		if perfect: # perfect hit
			Score.update_points(Score.TimingJudgement.PERFECT)
			current_note.get_parent().points_earned = Score.TimingJudgement.PERFECT
		elif great: # great hit
			Score.update_points(Score.TimingJudgement.GREAT)
			current_note.get_parent().points_earned = Score.TimingJudgement.GREAT
		elif good: # good hit
			Score.update_points(Score.TimingJudgement.GOOD)
			current_note.get_parent().points_earned = Score.TimingJudgement.GOOD
		
		var fade = ARROW_FADE.instantiate()
		fade.global_position = global_position
		fade.rotation = rotation
		%AnimationPlayer.play("Pulse")
		get_tree().current_scene.add_child(fade)
		current_note.get_parent().destroy()
	else: # not hitting a note
		Score.update_points(Score.TimingJudgement.BAD)

func pulse(sec_per_beat: float) -> void:
	if tween and tween.is_running():
		tween.kill()
	var time = sec_per_beat / 4
	tween = create_tween()
	tween.tween_callback(func(): scale = Vector2.ONE * 1.08)
	tween.tween_property(self, "scale", Vector2.ONE, time)

func _on_good_area_area_entered(area: Area2D) -> void:
	if current_note:
		queue.append(area)
		return
	good = true
	current_note = area
	current_note.get_parent().destroyed.connect(key_destroyed)

func _on_good_area_area_exited(_area: Area2D) -> void:
	if queue.size() > 0:
		current_note = queue.pop_front()
		current_note.get_parent().destroyed.connect(key_destroyed)
		return
	
	good = false
	current_note = null

func _on_great_area_area_entered(_area: Area2D) -> void:
	great = true

func _on_great_area_area_exited(_area: Area2D) -> void:
	great = false

func _on_perfect_area_area_entered(_area: Area2D) -> void:
	perfect = true

func _on_perfect_area_area_exited(_area: Area2D) -> void:
	perfect = false

func key_destroyed() -> void:
	if queue.size() > 0:
		current_note = queue.pop_front()
		current_note.get_parent().destroyed.connect(key_destroyed)
	elif current_note:
		current_note = null

func _on_animated_sprite_2d_animation_finished() -> void:
	if %AnimatedSprite2D.animation == "Pressed":
		%AnimatedSprite2D.play("Unpressed")
