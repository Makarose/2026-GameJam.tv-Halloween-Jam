extends RefCounted

# the settings for one level. LevelBuilder fills these in.

var difficulty: String = "normal"
var level_number: int = 1 # starts at 1, for showing "Level 3 of 8"
var total_levels: int = 1
var crowd_count: int = 100
var costume_percent: int = 30
var clue1_min: int = 4 # how many people should match clue 1 (the guest included)
var clue1_max: int = 8
var time_limit: float = 120.0
var is_breather: bool = false # not used any more, kept so older scripts don't break

# how many other people still fit after clue 2 (the decoys). clue 3 always leaves only the guest
var decoys: int = 0
# which pieces can be used as clues on this level
var allowed_keys: Array[String] = ["hat_", "top_", "pants_", "glasses_", "gloves_", "shoes_", "socks_"]
