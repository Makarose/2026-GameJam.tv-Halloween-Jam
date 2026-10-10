extends Node

# remembers which difficulty the player picked and which level they're on.
# set up as an autoload named GameState, so every scene can read it.

const LevelConfig = preload("res://Scripts/level_config.gd")

var difficulty: String = "normal"
var level_index: int = 0 # starts at 0, so level 1 is 0
var run_active: bool = false # false when you run the game scene straight from the editor


func start_run(new_difficulty: String) -> void:
	difficulty = new_difficulty
	level_index = 0
	run_active = true


func end_run() -> void:
	run_active = false


# the settings for the level the player is on right now
func current_config() -> LevelConfig:
	return LevelBuilder.build(difficulty, level_index)


func has_next_level() -> bool:
	return level_index + 1 < LevelBuilder.level_count(difficulty)


func advance() -> void:
	level_index += 1

func _ready() -> void:
	start_run("easy") # TEMPORARY TEST, delete after testing
	level_index = 5 # TEMPORARY, jumps to the last easy level
