extends Control

# the game scene, started when a difficulty is picked
@export_file("*.tscn") var game_scene_path: String

@onready var easy_button: Button = %EasyButton
@onready var normal_button: Button = %NormalButton
@onready var hard_button: Button = %HardButton

@onready var witch_dialogue: CanvasLayer = $WitchDialogue

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#witch_dialogue.intro_complete.connect() # so we know when intro dialogue is skipped or completed
	
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE # the game scene hides the mouse

	easy_button.pressed.connect(_start_run.bind("easy"))
	normal_button.pressed.connect(_start_run.bind("normal"))
	hard_button.pressed.connect(_start_run.bind("hard"))


func _start_run(difficulty: String) -> void:
	#await play_witch_intro() # play the intro dialogue from this scene, then load game when complete
	
	print("TIMING click at: ", Time.get_ticks_msec())
	if game_scene_path.is_empty():
		push_warning("Set Game Scene Path on the Levels scene root")
		return
	GameState.start_run(difficulty)
	get_tree().change_scene_to_file(game_scene_path)

func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/title_page.tscn")


func play_witch_intro() -> void:
	witch_dialogue.play_startup()
	await witch_dialogue.intro_complete
