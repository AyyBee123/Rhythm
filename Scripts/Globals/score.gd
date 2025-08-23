extends Node

var points := 0
var displayed_points := 0
var combo := 0
var combo_multi := 1

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

func _process(delta: float) -> void:
	update_displayed_points()

func update_points(type: TimingJudgement):
	match type:
		TimingJudgement.MISS:
			Game.audio_manager.miss.play()
			SignalBus.note_hit.emit("Miss")
			points += 0
			combo = 0
			miss_count += 1
		TimingJudgement.BAD:
			Game.audio_manager.miss.play()
			SignalBus.note_hit.emit("Bad")
			points += 0
			combo = 0
			bad_count += 1
		TimingJudgement.OK:
			Game.audio_manager.hit.play()
			SignalBus.note_hit.emit("Okay")
			points += 10
			combo += 1
			ok_count += 1
		TimingJudgement.GOOD:
			Game.audio_manager.hit.play()
			SignalBus.note_hit.emit("Good")
			points += 12
			combo += 1
			good_count += 1
		TimingJudgement.PERFECT:
			Game.audio_manager.hit.play()
			SignalBus.note_hit.emit("Perfect")
			points += 15
			combo += 1
			perfect_count += 1

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
