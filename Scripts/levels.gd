extends Control

# the game scene, started when a difficulty is picked
@export_file("*.tscn") var game_scene_path: String

@onready var easy_button: Button = %EasyButton
@onready var normal_button: Button = %NormalButton
@onready var hard_button: Button = %HardButton
@onready var back_button: Button = %BackButton

@onready var witch_dialogue: CanvasLayer = $WitchDialogue

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE # the game scene hides the mouse

	easy_button.pressed.connect(_start_run.bind("easy"))
	normal_button.pressed.connect(_start_run.bind("normal"))
	hard_button.pressed.connect(_start_run.bind("hard"))


var _starting: bool = false

func _start_run(difficulty: String) -> void:
	if _starting:
		return
	if game_scene_path.is_empty():
		push_warning("Set Game Scene Path on the Levels scene root")
		return
	_starting = true
	easy_button.disabled = true
	normal_button.disabled = true
	hard_button.disabled = true
	back_button.disabled = true
	%Label.hide()
	%VBoxContainer.hide()

	var tree := get_tree()
	await play_witch_intro()

	%LoadingOverlay.show()
	await MusicPlayer.fade_out(1.5) # fade out that funky menu music before game scene loads
	await tree.process_frame
	await tree.process_frame

	if not is_inside_tree():
		return
	GameState.start_run(difficulty)
	tree.change_scene_to_file(game_scene_path)

func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/title_page.tscn")


func play_witch_intro() -> void:
	witch_dialogue.play_startup()
	await witch_dialogue.intro_complete
