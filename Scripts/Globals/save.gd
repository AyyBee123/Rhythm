extends Node

var path: String = "user://profile.res"
var profile: PlayerProfile

var rank_order = {
	"L": 0,
	"D": 1,
	"C": 2,
	"B": 3,
	"A": 4,
	"S": 5,
	"SS": 6,
	"P": 7,
}

func _ready() -> void:
	profile = load_profile()  # load profile at start

func save_score(song_id: String, score: int, accuracy: float, rank: String, combo: int, full_combo: bool, cleared: bool) -> void:
	# load existing profile or create new
	if ResourceLoader.exists(path):
		profile = ResourceLoader.load(path) as PlayerProfile
		if profile == null:
			profile = PlayerProfile.new()
	else:
		profile = PlayerProfile.new()

	# make sure a ScoreData exists for this song
	if not profile.scores.has(song_id):
		profile.scores[song_id] = ScoreData.new()

	var entry: ScoreData = profile.scores[song_id] as ScoreData
	entry.best_score = max(entry.best_score, score)
	entry.accuracy = max(entry.accuracy, accuracy)
	if rank_order[rank] > rank_order[entry.rank]: entry.rank = rank # only override if the new rank is higher
	entry.max_combo = max(entry.max_combo, combo)
	entry.full_combo = entry.full_combo or full_combo # if full combo was achieved previously, it stays that way
	entry.cleared = entry.cleared or cleared # if the level was cleared previously, it stays that way

	# save
	var err: Error = ResourceSaver.save(profile, path)
	if err != OK:
		push_error("Failed to save profile.res: %s" % err)
	
	if OS.has_feature("editor"):
		ResourceSaver.save(profile, path.get_basename() + ".tres")

func load_profile() -> PlayerProfile:
	if ResourceLoader.exists(path):
		return ResourceLoader.load(path) as PlayerProfile
	return PlayerProfile.new()
