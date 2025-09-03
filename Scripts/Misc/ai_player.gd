extends Node

var level
var core

var up
var down
var left
var right

const BAD_CHANCE = 0.75

var judgments := [
	{"label": "Perfect", "chance": 0.92},
	{"label": "Great",   "chance": 0.05},
	{"label": "Good",    "chance": 0.03},
	{"label": "Miss",    "chance": 0.0},
]

var hit_type

func _ready():
	randomize()
	level = get_tree().current_scene
	core = level.get_node("%Core")
	
	up = core.get_node("%Up")
	down = core.get_node("%Down")
	left = core.get_node("%Left")
	right = core.get_node("%Right")
	
	up.get_node("Good Area").area_entered.connect(up_good)
	up.get_node("Great Area").area_entered.connect(up_great)
	up.get_node("Perfect Area").area_entered.connect(up_perfect)
	up.get_node("Good Area").area_exited.connect(up_exit)
	
	down.get_node("Good Area").area_entered.connect(down_good)
	down.get_node("Great Area").area_entered.connect(down_great)
	down.get_node("Perfect Area").area_entered.connect(down_perfect)
	down.get_node("Good Area").area_exited.connect(down_exit)
	
	left.get_node("Good Area").area_entered.connect(left_good)
	left.get_node("Great Area").area_entered.connect(left_great)
	left.get_node("Perfect Area").area_entered.connect(left_perfect)
	left.get_node("Good Area").area_exited.connect(left_exit)
	
	right.get_node("Good Area").area_entered.connect(right_good)
	right.get_node("Great Area").area_entered.connect(right_great)
	right.get_node("Perfect Area").area_entered.connect(right_perfect)
	right.get_node("Good Area").area_exited.connect(right_exit)


func up_perfect(area):
	if hit_type != "Perfect":
		return
	hit(up, area)

func up_great(area):
	if hit_type != "Great":
		return
	hit(up, area)

func up_good(area):
	hit_type = get_judgment()
	if hit_type != "Good":
		return
	hit(up, area)


func down_perfect(area):
	if hit_type != "Perfect":
		return
	hit(down, area)

func down_great(area):
	if hit_type != "Great":
		return
	hit(down, area)

func down_good(area):
	hit_type = get_judgment()
	if hit_type != "Good":
		return
	hit(down, area)


func left_perfect(area):
	if hit_type != "Perfect":
		return
	hit(left, area)

func left_great(area):
	if hit_type != "Great":
		return
	hit(left, area)

func left_good(area):
	hit_type = get_judgment()
	if hit_type != "Good":
		return
	hit(left, area)


func right_perfect(area):
	if hit_type != "Perfect":
		return
	hit(right, area)

func right_great(area):
	if hit_type != "Great":
		return
	hit(right, area)

func right_good(area):
	hit_type = get_judgment()
	if hit_type != "Good":
		return
	hit(right, area)


func up_exit(area):
	if randf() < BAD_CHANCE:
		hit(up, area)

func down_exit(area):
	if randf() < BAD_CHANCE:
		hit(down, area)

func left_exit(area):
	if randf() < BAD_CHANCE:
		hit(left, area)

func right_exit(area):
	if randf() < BAD_CHANCE:
		hit(right, area)


func hit(key, area):
	await get_tree().process_frame
	if is_instance_valid(area):
		key.hit()

func get_judgment() -> String:
	var roll := randf()
	var cumulative := 0.0
	for j in judgments:
		cumulative += j.chance
		if roll < cumulative:
			return j.label
	return "Miss"  # fallback
