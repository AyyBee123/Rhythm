extends Button

var level: PackedScene
var notes_file: String
var initial_focus := false

var notes: Array
var level_id: String
var level_difficulty: String
var bpm: int
var song
var song_duration: float
var song_duration_text: String
var difficulty: int

var focused_once := false

var tween: Tween
var normal_size: Vector2
var focused_size: Vector2

func _ready():
	normal_size = size
	focused_size = Vector2(normal_size.x * 1.1, normal_size.y)

func _on_pressed():
	if focused_once:
		get_tree().change_scene_to_packed(level) # second click → start level

func _on_focus_entered():
	if not focused_once:
		if not initial_focus:
			Game.audio_manager.scroll.play()
		focused_once = true # mark that this button was focused
		accept_event() # prevent Godot from auto-focusing
	if tween and tween.is_running():
		tween.kill()
	tween = create_tween()
	tween.tween_property(self, "size", focused_size, 0.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _on_focus_exited():
	focused_once = false # reset when losing focus
	if tween and tween.is_running():
		tween.kill()
	tween = create_tween()
	tween.tween_property(self, "size", normal_size, 0.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
