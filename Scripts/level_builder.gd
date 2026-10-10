class_name LevelBuilder
extends RefCounted

const LevelConfig = preload("res://Scripts/level_config.gd")

# turns a difficulty and a level number into a LevelConfig.
# all the tuning lives in DIFFICULTIES, so this is the only place to change numbers.

# every 4th level (never the last one) is a breather: smaller crowd, more costumes
const BREATHER_EVERY := 4
const BREATHER_EASE := 0.15 # how far the crowd and clue pools step back on a breather
const BREATHER_COSTUME_BONUS := 15 # extra percent of costumes on a breather
const MAX_COSTUME_PERCENT := 80

# each setting is [value on the first level, value on the last level].
# the levels in between are worked out evenly.
const DIFFICULTIES := {
	"easy": {
		"levels": 6, "time": 150.0,
		"crowd": [100, 200], "costume": [40, 30], "pool_min": [3, 5], "pool_max": [6, 10],
	},
	"normal": {
		"levels": 8, "time": 120.0,
		"crowd": [150, 300], "costume": [35, 25], "pool_min": [4, 9], "pool_max": [8, 16],
	},
	"hard": {
		"levels": 10, "time": 100.0,
		"crowd": [250, 400], "costume": [30, 20], "pool_min": [8, 14], "pool_max": [14, 24],
	},
}


static func level_count(difficulty: String) -> int:
	return DIFFICULTIES[difficulty]["levels"]


# level_index starts at 0, so the first level is 0
static func build(difficulty: String, level_index: int) -> LevelConfig:
	var d: Dictionary = DIFFICULTIES[difficulty]
	var total: int = d["levels"]
	var last := total - 1
	var t := float(level_index) / float(last) # 0.0 on the first level, 1.0 on the last

	var c := LevelConfig.new()
	c.difficulty = difficulty
	c.level_number = level_index + 1
	c.total_levels = total
	c.time_limit = d["time"]
	c.is_breather = (level_index + 1) % BREATHER_EVERY == 0 and level_index != last

	# on a breather the crowd and clue pools act like they're a little earlier in the ramp
	var pressure_t := clampf(t - BREATHER_EASE, 0.0, 1.0) if c.is_breather else t

	c.crowd_count = roundi(_blend(d["crowd"], pressure_t))
	c.clue1_min = maxi(1, roundi(_blend(d["pool_min"], pressure_t)))
	c.clue1_max = maxi(c.clue1_min, roundi(_blend(d["pool_max"], pressure_t)))
	c.costume_percent = roundi(_blend(d["costume"], t))
	if c.is_breather:
		c.costume_percent = mini(c.costume_percent + BREATHER_COSTUME_BONUS, MAX_COSTUME_PERCENT)
	return c


static func _blend(pair: Array, t: float) -> float:
	return lerpf(float(pair[0]), float(pair[1]), t)


# prints every level of every difficulty, for checking the numbers
static func print_all() -> void:
	for difficulty in DIFFICULTIES:
		for i in level_count(difficulty):
			var c := build(difficulty, i)
			print("%s %d/%d%s | crowd %d | costumed %d%% | clue 1 pool %d-%d | %ds" % [
				c.difficulty, c.level_number, c.total_levels,
				" (breather)" if c.is_breather else "",
				c.crowd_count, c.costume_percent, c.clue1_min, c.clue1_max, int(c.time_limit)])
