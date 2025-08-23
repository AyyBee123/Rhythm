extends Sprite2D

signal destroyed

var speed: float = 100.0
var direction: Vector2
var key: String
var core: Node2D
var expected_time: float = 0.0

var hold_duration: float
var is_hold_note: bool

const HOLD_LINE = preload("res://Scenes/Main/hold_line.tscn")

const TIME_TOLERANCE := {
	"PERFECT": 0.02,
	"GOOD": 0.05,
	"OK": 0.08
}

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

func test_hit(time: float) -> bool:
	return abs(expected_time - time) <= TIME_TOLERANCE.OK

# Note Node
func test_miss(time: float) -> bool:
	return time > expected_time + TIME_TOLERANCE.OK
 
func miss() -> void:
	Score.update_points(Score.TimingJudgement.MISS)
	SignalBus.take_damage.emit()

func hit(time: float) -> void:
	var time_difference: float = abs(expected_time - time)
 
	if time_difference < TIME_TOLERANCE.PERFECT:
		Score.update_points(Score.TimingJudgement.PERFECT)
	elif time_difference < TIME_TOLERANCE.GOOD:
		Score.update_points(Score.TimingJudgement.GOOD)
	else:
		Score.update_points(Score.TimingJudgement.OK)

func destroy():
	destroyed.emit()
	queue_free()

func _on_note_area_area_entered(area):
	destroy()
