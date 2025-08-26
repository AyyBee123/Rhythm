extends Node

var path := "user://profile.res"
var profile: PlayerProfile

func _ready():
	profile = load_profile()  # load profile at start

func save_score(song_id: String, score: int, accuracy: float, rank: String, combo: int, cleared: bool) -> void:
	# Load existing profile or create new
	if ResourceLoader.exists(path):
		profile = ResourceLoader.load(path) as PlayerProfile
		if profile == null:
			profile = PlayerProfile.new()
	else:
		profile = PlayerProfile.new()

	# Ensure a ScoreData exists for this song
	if not profile.scores.has(song_id):
		profile.scores[song_id] = ScoreData.new()

	var entry: ScoreData = profile.scores[song_id] as ScoreData
	entry.best_score = max(entry.best_score, score)
	entry.accuracy = max(entry.accuracy, accuracy)
	if entry.rank == "PP":
		# never override
		pass
	elif entry.rank == "P":
		if rank == "PP":
			entry.rank = "PP"  # allow upgrade
	else:
		entry.rank = rank
	entry.max_combo = max(entry.max_combo, combo)
	entry.cleared = entry.cleared or cleared
	entry.attempts += 1

	# SAVE (note: path first, resource second)
	var err := ResourceSaver.save(profile, path)
	if err != OK:
		push_error("Failed to save profile.res: %s" % err)
	
	if OS.has_feature("editor"):
		ResourceSaver.save(profile, path.get_basename() + ".tres")

func load_profile() -> PlayerProfile:
	var path := "user://profile.res"
	if ResourceLoader.exists(path):
		return ResourceLoader.load(path) as PlayerProfile
	return PlayerProfile.new()
