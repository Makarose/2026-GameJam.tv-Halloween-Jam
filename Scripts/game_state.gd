extends Node

# remembers which difficulty the player picked, which level they're on, and how the run is going.
# set up as an autoload named GameState, so every scene can read it.

const LevelConfig = preload("res://Scripts/level_config.gd")

# the order the difficulties follow when a run keeps going
const DIFFICULTY_ORDER: Array[String] = ["easy", "normal", "hard"]

var difficulty: String = "normal"
var level_index: int = 0 # starts at 0, so level 1 is 0
var run_active: bool = false # false when you run the game scene straight from the editor
var ravers_bounced: int = 0 # how many ravers the player has caught this run

# how the last run ended: "cleared", "time", or "guesses". empty if the player quit to the Levels scene
var end_reason: String = ""


func start_run(new_difficulty: String) -> void:
	difficulty = new_difficulty
	level_index = 0
	ravers_bounced = 0
	end_reason = ""
	run_active = true


func end_run(reason: String = "") -> void:
	run_active = false
	end_reason = reason


# the settings for the level the player is on right now
func current_config() -> LevelConfig:
	return LevelBuilder.build(difficulty, level_index)


func has_next_level() -> bool:
	if level_index + 1 < LevelBuilder.level_count(difficulty):
		return true
	# last level of this difficulty, so there's more only if a harder one exists
	return DIFFICULTY_ORDER.find(difficulty) < DIFFICULTY_ORDER.size() - 1


func advance() -> void:
	if level_index + 1 < LevelBuilder.level_count(difficulty):
		level_index += 1
		return
	# finished this difficulty, so move up to the next one
	difficulty = DIFFICULTY_ORDER[DIFFICULTY_ORDER.find(difficulty) + 1]
	level_index = 0


# how many levels a run has if it starts on this difficulty
func levels_from(start_difficulty: String) -> int:
	var total := 0
	var i := DIFFICULTY_ORDER.find(start_difficulty)
	while i < DIFFICULTY_ORDER.size():
		total += LevelBuilder.level_count(DIFFICULTY_ORDER[i])
		i += 1
	return total
