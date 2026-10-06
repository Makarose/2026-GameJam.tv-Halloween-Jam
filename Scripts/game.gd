extends Node3D

const texture_colors: Array[String] = ["black", "brown", "green", "blue", "orange", "pink", "purple", "red", "white", "yellow"]

var uninvited_guest: CharacterBuilder
var clues: Array[String] = []
var num_guesses: int = 0

@export var max_guesses: int = 3

@onready var crowd_scene: Node3D = $Crowd
@onready var player: Player = $Player

@onready var label: Label = $CanvasLayer/Control/MarginContainer/Label
@export var clue_labels: Array[Label]


func _ready() -> void:
	player.ray_cast_3d.guess_submitted.connect(_on_guess_submitted)
	set_uninvited_guest()
	
	


func set_uninvited_guest() -> void:
	uninvited_guest = crowd_scene.guests.pick_random()
	print(uninvited_guest.look)
	uninvited_guest.ug_label.visible = true
	
	generate_clues()


func generate_clues() -> void:
	for key in uninvited_guest.look:
		var new_value: String = str(uninvited_guest.look[key])
		var new_clue: String = ""
		
		match key:
			"glasses_":
				new_clue = "This person is wearing {} {}.".format([new_value.replace("glasses_", "").replace("_", " "), "glasses"], "{}")
			"gloves_":
				new_clue = "This person is wearing {} {}.".format([new_value.replace("gloves_", "").replace("_", " "), "gloves"], "{}")
			"hat_":
				new_clue = "This person is wearing a {} {}.".format([new_value.replace("hat_", "").replace("_", " "), "hat"], "{}")
			"pants_":
				var color = texture_colors[uninvited_guest.look["pants_texture"]]
				new_clue = "This person is wearing {} {} {}.".format([color, new_value.replace("pants_", ""), "pants"], "{}")
			"shoes_":
				new_clue = "This person is wearing {} {}.".format([new_value.get_slice("_", 2), new_value.get_slice("_", 1)], "{}")
			"socks_":
				new_clue = "This person is wearing {} {}.".format([new_value.replace("socks_", ""), "socks"], "{}")
			"top_":
				var color = texture_colors[uninvited_guest.look["top_texture"]]
				new_clue = "This person is wearing a {} {}.".format([color, new_value.replace("top_", "")], "{}")
		
		if !new_clue.is_empty():
			clues.append(new_clue)
	
	print(clues)
	show_clue()


func show_clue() -> void:
	if num_guesses < max_guesses:
		var next_clue = clues.pick_random()
		clue_labels[num_guesses].text = next_clue
		clues.erase(next_clue)
	else:
		label.text = "NO MORE CLUES!"


func _on_guess_submitted(character: CharacterBuilder) -> void:
	if character == uninvited_guest:
		label.text = "CORRECT!"
	else:
		label.text = "WRONG!"
		num_guesses += 1
		show_clue()
	
	await get_tree().create_timer(1.0).timeout
	label.text = ""
