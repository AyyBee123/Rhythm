extends Sprite2D

signal destroyed

var speed: float = 100.0
var direction: Vector2
var key: String
var button: Node2D
var core: Node2D
var points_earned := 0

var hold_duration: float
var is_hold_note: bool
var hold_line

const HOLD_LINE = preload("uid://dxbeljxnd4150")

func _ready():
	if is_hold_note:
		var line = HOLD_LINE.instantiate()
		hold_line = line
		line.speed = speed
		line.direction = direction
		line.global_position = %"Hold Line Position".global_position
		line.arrow = self
		line.rotation = rotation
		line.key = key
		line.hold_duration = hold_duration
		get_tree().current_scene.add_child(line)
	SignalBus.defeat.connect(queue_free) # destroy all existing arrows if the player loses

func _process(delta):
	position += direction * speed * delta

func destroy():
	destroyed.emit()
	SignalBus.arrow_destroyed.emit(points_earned)
	if is_hold_note:
		if points_earned > 0: # hit
			hold_line.button = button
			hold_line.hold()
	queue_free()

func _on_note_area_area_entered(area):
	Score.update_points(Score.TimingJudgement.MISS)
	destroy()
