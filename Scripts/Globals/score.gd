extends Node

var points := 0
var displayed_points := 0
var combo := 0
var hit_count := 0
var combo_multi := 1
var current_total_points := 0 # the total amount of points that could be gotten
var current_rank := 0
var current_accuracy_points := 0.0
var max_accuracy_points := 0.0
var accuracy := 100.0: get = get_accuracy
var rank := "SS": get = get_rank
var full_combo := true

# counts the amount of hit types (and misses)
var perfect_count := 0
var good_count := 0
var ok_count := 0
var bad_count := 0
var miss_count := 0

enum TimingJudgement {
	MISS,
	BAD,
	OK,
	GOOD,
	PERFECT
}

enum Ranks {
	P,
	SS,
	S,
	A,
	B,
	C,
	D
}

const COMBO_MULTIPLIERS = [1, 2, 4, 8]
const COMBO_THRESHOLDS = [0, 2, 4, 8]

func _ready():
	SignalBus.arrow_destroyed.connect(get_accuracy_points)

func _process(delta: float) -> void:
	update_displayed_points()

func update_points(type: TimingJudgement):
	match type:
		TimingJudgement.MISS:
			SignalBus.note_hit.emit("Miss")
			SignalBus.health_changed.emit(-4)
			combo = 0
			miss_count += 1
			full_combo = false
			decrease_combo_multiplier()
		TimingJudgement.BAD:
			Game.audio_manager.miss.play()
			SignalBus.note_hit.emit("Bad")
			SignalBus.health_changed.emit(-4)
			combo = 0
			bad_count += 1
			full_combo = false
			decrease_combo_multiplier()
		TimingJudgement.OK:
			Game.audio_manager.hit.play()
			SignalBus.note_hit.emit("Okay")
			points += 10 * combo_multi
			combo += 1
			ok_count += 1
			hit_count += 1
			update_combo_multipier()
		TimingJudgement.GOOD:
			Game.audio_manager.hit.play()
			SignalBus.note_hit.emit("Good")
			SignalBus.health_changed.emit(1)
			points += 12 * combo_multi
			combo += 1
			good_count += 1
			hit_count += 1
			update_combo_multipier()
		TimingJudgement.PERFECT:
			Game.audio_manager.hit.play()
			SignalBus.note_hit.emit("Perfect")
			SignalBus.health_changed.emit(2)
			points += 15 * combo_multi
			combo += 1
			perfect_count += 1
			hit_count += 1
			update_combo_multipier()

func update_combo_multipier():
	if combo_multi == COMBO_MULTIPLIERS[-1]: # max combo reached
		return
	var index = COMBO_MULTIPLIERS.find(combo_multi)
	var hit_threshold = COMBO_THRESHOLDS[index + 1] # get the next threshold needed to reach the next combo multiplier tier
	if hit_count >= hit_threshold:
		hit_count = 0 # reset hits needed to reach next combo multiplier tier
		combo_multi = COMBO_MULTIPLIERS[index + 1] # increase combo multiplier by one step

func decrease_combo_multiplier():
	if combo_multi == COMBO_MULTIPLIERS[0]: # already at minimum combo
		return
	hit_count = 0 # reset hits needed to reach next combo multiplier tier
	var index = COMBO_MULTIPLIERS.find(combo_multi)
	combo_multi = COMBO_MULTIPLIERS[index - 1] # decrease combo multiplier by one step

func get_accuracy_points(points):
	max_accuracy_points += Score.TimingJudgement.PERFECT
	current_accuracy_points += points
	get_accuracy()

func get_accuracy() -> float:
	if max_accuracy_points == 0:
		return 100.0
	return float(current_accuracy_points) / float(max_accuracy_points) * 100

func get_rank() -> String:
	if accuracy >= 95.0:
		if full_combo:
			return "P"
		else:
			return "SS"
	elif accuracy >= 90.0:
		return "S"
	elif accuracy >= 80.0:
		return "A"
	elif accuracy >= 70.0:
		return "B"
	elif accuracy >= 60.0:
		return "C"
	elif accuracy >= 50.0:
		return "D"
	else:
		return "E"

## updates the points dynamically, in a step-by-step manner, rather than instantly
func update_displayed_points() -> void:
	var difference = abs(points - displayed_points)
	# determine the step size dynamically
	var step = max(1, difference * 0.2)
	if displayed_points < points:
		displayed_points =  min(displayed_points + step, points)
	elif displayed_points > points:
		displayed_points = max(displayed_points - step,points)
	displayed_points = int(displayed_points)
