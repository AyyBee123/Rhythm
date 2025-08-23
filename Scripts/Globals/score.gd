extends Node

var points := 0
var displayed_points := 0
var combo := 0
enum TimingJudgement { MISS, BAD, OK, GOOD, PERFECT }

func _process(delta: float) -> void:
	update_displayed_points()

func update_points(type: TimingJudgement):
	match(type):
		TimingJudgement.MISS:
			points += 0
			combo = 0
		TimingJudgement.BAD:
			points += 0
			combo = 0
		TimingJudgement.OK:
			points += 10
			combo += 1
		TimingJudgement.GOOD:
			points += 12
			combo += 1
		TimingJudgement.PERFECT:
			points += 15
			combo += 1

func update_displayed_points() -> void:
	var difference = abs(points - displayed_points)
	# Determine the step size dynamically
	var step = max(1, difference * 0.2)
	if displayed_points < points:
		displayed_points =  min(displayed_points + step, points)
	elif displayed_points > points:
		displayed_points = max(displayed_points - step,points)
	
	displayed_points = int(displayed_points)
