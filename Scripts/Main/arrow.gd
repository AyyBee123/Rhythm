extends Sprite2D

var speed: float = 100.0
var direction: Vector2
var key: String
var core: Node2D
var expected_time: float = 0.0

const TIME_TOLERANCE := {
	"PERFECT": 0.02,
	"GOOD": 0.05,
	"OK": 0.08
}

func _ready():
	pass

func _process(delta):
	position += direction * speed * delta

func test_hit(time: float) -> bool:
	return abs(expected_time - time) <= TIME_TOLERANCE.OK

# Note Node
func test_miss(time: float) -> bool:
	return time > expected_time + TIME_TOLERANCE.OK
 
func miss() -> void:
	Highscore.update_points(Highscore.TimingJudgement.MISS)
	SignalBus.take_damage.emit()
	queue_free()

func hit(time: float) -> void:
	var time_difference: float = abs(expected_time - time)
 
	if time_difference < TIME_TOLERANCE.PERFECT:
		Highscore.update_points(Highscore.TimingJudgement.PERFECT)
	elif time_difference < TIME_TOLERANCE.GOOD:
		Highscore.update_points(Highscore.TimingJudgement.GOOD)
	else:
		Highscore.update_points(Highscore.TimingJudgement.OK)
	queue_free()
