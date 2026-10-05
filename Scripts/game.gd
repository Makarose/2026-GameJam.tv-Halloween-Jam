extends Node3D


var uninvited_guest: CharacterBuilder
var clues: Array[String] = []

@onready var crowd_scene: Node3D = $Crowd
@onready var player: Player = $Player

@onready var label: Label = $CanvasLayer/Control/MarginContainer/Label


func _ready() -> void:
	player.ray_cast_3d.guess_submitted.connect(_on_guess_submitted)
	set_uninvited_guest()


func set_uninvited_guest() -> void:
	uninvited_guest = crowd_scene.guests.pick_random()
	uninvited_guest.ug_label.visible = true
	
	if uninvited_guest.look.has("glasses_"):
		pass
		# clean dictionary entry and add to clue text "The uninvited guest is wearing "
		# note: will have to do this manually for each entry, because each item's name is formatted differently
		# (or else rename meshes, but that seems like a pain in the balls)


func _on_guess_submitted(character: CharacterBuilder) -> void:
	if character == uninvited_guest:
		label.text = "CORRECT!"
	else:
		label.text = "WRONG!"
	
	await get_tree().create_timer(1.0).timeout
	label.text = ""
