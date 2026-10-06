extends Node3D

const texture_colors: Array[String] = ["black", "brown", "green", "blue", "orange", "pink", "purple", "red", "white", "yellow"]

var uninvited_guest: CharacterBuilder
var clues: Array[String] = []
var num_guesses: int = 0

@export var max_guesses: int = 3
@export var poof_effect: PackedScene

@onready var crowd_scene: Node3D = $Crowd
@onready var player: Player = $Player

@onready var label: Label = $CanvasLayer/Control/MarginContainer/Label
@export var clue_labels: Array[Label]


func _ready() -> void:
	player.ray_cast_3d.guess_submitted.connect(_on_guess_submitted)
	set_uninvited_guest()
	generate_clues()
	show_clue()
	MusicPlayer.shuffle_play()
	MusicPlayer.set_volume(-10.0)


func set_uninvited_guest() -> void:
	uninvited_guest = crowd_scene.guests.pick_random()
	print(uninvited_guest.look)
	uninvited_guest.ug_label.visible = true


func generate_clues() -> void:
	for key in uninvited_guest.look:
		var key_name := str(key)
		if key_name.ends_with("_texture"):
			continue # these hold color numbers, not pieces

		# pieces with a texture entry (pants, tops) get their color added
		var color := ""
		var texture_key := key_name + "texture"
		if uninvited_guest.look.has(texture_key):
			color = texture_colors[uninvited_guest.look[texture_key]]

		var phrase := ClueText.describe(str(uninvited_guest.look[key]), color)
		if not phrase.is_empty():
			clues.append("This person is wearing %s." % phrase)


func show_clue() -> void:
	if clues.is_empty():	#addeed during new func generate_clues
		return
	if num_guesses < max_guesses:
		var next_clue = clues.pick_random()
		clue_labels[num_guesses].text = next_clue
		clues.erase(next_clue)
	else:
		label.text = "NO MORE CLUES!"


func _on_guess_submitted(character: CharacterBuilder) -> void:
	if character == uninvited_guest:
		label.text = "CORRECT!"
		var new_effect = poof_effect.instantiate()
		add_child(new_effect)
		new_effect.global_position = character.global_position
		character.queue_free()
	else:
		label.text = "WRONG!"
		num_guesses += 1
		show_clue()
	
	await get_tree().create_timer(1.0).timeout
	label.text = ""
