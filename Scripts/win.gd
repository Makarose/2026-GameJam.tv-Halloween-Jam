extends Control

# the difficulty select scene, used by the Levels button
@export_file("*.tscn") var levels_scene_path: String

@onready var title_label: Label = %TitleLabel
@onready var reason_label: Label = %ReasonLabel
@onready var progress_label: Label = %ProgressLabel
@onready var levels_button: Button = %LevelsButton


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	levels_button.pressed.connect(_on_levels_button_pressed)

	var n := GameState.ravers_bounced
	if n == 0:
		title_label.text = "You Didn't Catch Any Party Crashers"
	elif n == 1:
		title_label.text = "You Found 1 Party Crasher!"
	else:
		title_label.text = "You Found %d Party Crashers!" % n

	match GameState.end_reason:
		"cleared":
			reason_label.text = "You cleared the whole party!"
			progress_label.visible = false
		"time":
			reason_label.text = "Time's up!"
			progress_label.text = _progress_text()
		"guesses":
			reason_label.text = "Out of guesses!"
			progress_label.text = _progress_text()
		_:
			reason_label.text = ""
			progress_label.visible = false


# where the player got to when they lost, e.g. "You made it to Normal: Level 3 of 8"
func _progress_text() -> String:
	var total := LevelBuilder.level_count(GameState.difficulty)
	return "You made it to %s: Level %d of %d" % [GameState.difficulty.capitalize(), GameState.level_index + 1, total]


func _on_levels_button_pressed() -> void:
	if levels_scene_path.is_empty():
		push_warning("Set Levels Scene Path on the win scene root")
		return
	MusicPlayer.play_menu_music(-12.0)
	get_tree().change_scene_to_file(levels_scene_path)

func _on_main_menu_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/title_page.tscn")


func _on_quit_button_pressed() -> void:
	get_tree().quit()
