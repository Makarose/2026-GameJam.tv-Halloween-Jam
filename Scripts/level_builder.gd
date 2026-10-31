class_name LevelBuilder
extends RefCounted

const LevelConfig = preload("res://Scripts/level_config.gd")

# one smooth line from the first Easy level to the last Hard level.
# change the numbers here and nowhere else.

const ORDER := ["easy", "normal", "hard"]

const CROWD := [25, 300] # first level, last level
const COSTUME := [45, 20] # percent. more costumes is easier, so this falls
const TIME_LIMIT := 120.0

# clue 1 matches a share of the real (non costumed) people, never fewer than MIN_MATCHES
const SHARE_MIN := [0.10, 0.06]
const SHARE_MAX := [0.20, 0.10]
const MIN_MATCHES := 2

const ALL_KEYS := ["hat_", "top_", "pants_", "glasses_", "gloves_", "shoes_", "socks_"]

# levels: how many levels in the tier
# decoys: [first level of the tier, last level of the tier]
# keys: which pieces can be clues
const DIFFICULTIES := {
	"easy": {
		"levels": 6, "decoys": [0, 0],
		"keys": ["hat_", "top_", "pants_"],
	},
	"normal": {
		"levels": 8, "decoys": [0, 1],
		"keys": ["hat_", "top_", "pants_", "gloves_"],
	},
	"hard": {
		"levels": 10, "decoys": [2, 3],
		"keys": ALL_KEYS,
	},
}


static func level_count(difficulty: String) -> int:
	return DIFFICULTIES[difficulty]["levels"]


# every level in the game, all three tiers
static func total_all() -> int:
	var n := 0
	for d in ORDER:
		n += DIFFICULTIES[d]["levels"]
	return n


# how many levels come before this tier starts
static func _offset(difficulty: String) -> int:
	var n := 0
	for d in ORDER:
		if d == difficulty:
			break
		n += DIFFICULTIES[d]["levels"]
	return n


# level_index starts at 0, so the first level is 0
static func build(difficulty: String, level_index: int) -> LevelConfig:
	var d: Dictionary = DIFFICULTIES[difficulty]
	var tier_total: int = d["levels"]

	# t runs 0.0 to 1.0 across the whole game, tt across just this tier
	var t := float(_offset(difficulty) + level_index) / float(total_all() - 1)
	var tt := float(level_index) / float(maxi(tier_total - 1, 1))

	var c := LevelConfig.new()
	c.difficulty = difficulty
	c.level_number = level_index + 1
	c.total_levels = tier_total
	c.time_limit = TIME_LIMIT
	c.is_breather = false

	c.crowd_count = roundi(_blend(CROWD, t))
	c.costume_percent = roundi(_blend(COSTUME, t))

	# costumed people can never be the guest, so clue 1 is a share of everyone else
	var costumed := roundi(c.crowd_count * c.costume_percent / 100.0)
	var candidates := c.crowd_count - costumed
	c.clue1_min = maxi(MIN_MATCHES, roundi(candidates * _blend(SHARE_MIN, t)))
	c.clue1_max = maxi(c.clue1_min + 1, roundi(candidates * _blend(SHARE_MAX, t)))

	c.decoys = roundi(_blend(d["decoys"], tt))
	c.allowed_keys.assign(d["keys"])
	return c


static func _blend(pair: Array, t: float) -> float:
	return lerpf(float(pair[0]), float(pair[1]), t)


# prints every level of every difficulty, for checking the numbers
static func print_all() -> void:
	for difficulty in ORDER:
		for i in level_count(difficulty):
			var c := build(difficulty, i)
			print("%s %d/%d | crowd %d | costumed %d%% | clue 1 pool %d-%d | decoys %d | %d clue types | %ds" % [
				c.difficulty, c.level_number, c.total_levels,
				c.crowd_count, c.costume_percent, c.clue1_min, c.clue1_max,
				c.decoys, c.allowed_keys.size(), int(c.time_limit)])
