extends Control

# the game scene, started when a difficulty is picked
@export_file("*.tscn") var game_scene_path: String

@onready var easy_button: Button = %EasyButton
@onready var normal_button: Button = %NormalButton
@onready var hard_button: Button = %HardButton

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE # the game scene hides the mouse

	easy_button.pressed.connect(_start_run.bind("easy"))
	normal_button.pressed.connect(_start_run.bind("normal"))
	hard_button.pressed.connect(_start_run.bind("hard"))


func _start_run(difficulty: String) -> void:
	if game_scene_path.is_empty():
		push_warning("Set Game Scene Path on the Levels scene root")
		return
	GameState.start_run(difficulty)
	get_tree().change_scene_to_file(game_scene_path)

func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/title_page.tscn")
