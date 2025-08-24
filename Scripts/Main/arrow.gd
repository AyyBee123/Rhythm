extends Sprite2D

signal destroyed

var speed: float = 100.0
var direction: Vector2
var key: String
var core: Node2D
var expected_time: float = 0.0
var points_earned := 0

var hold_duration: float
var is_hold_note: bool

const HOLD_LINE = preload("uid://dxbeljxnd4150")

func _ready():
	if is_hold_note:
		var line = HOLD_LINE.instantiate()
		line.speed = speed
		line.direction = direction
		line.global_position = %"Hold Line Position".global_position
		line.arrow = self
		line.rotation = rotation
		#get_tree().current_scene.add_child(line)

func _process(delta):
	position += direction * speed * delta

func destroy():
	destroyed.emit()
	SignalBus.arrow_destroyed.emit(points_earned)
	queue_free()

func _on_note_area_area_entered(area):
	Score.update_points(Score.TimingJudgement.MISS)
	destroy()
