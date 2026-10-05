extends Node3D


var uninvited_guest: CharacterBuilder
var clues: Array[String] = []

@onready var crowd_scene: Node3D = $Crowd


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	set_uninvited_guest()


func set_uninvited_guest() -> void:
	uninvited_guest = crowd_scene.guests.pick_random()
	print(uninvited_guest.look)
	
	if uninvited_guest.look.has("glasses_"):
		pass
		# clean dictionary entry and add to clue text "The uninvited guest is wearing "
		# note: will have to do this manually for each entry, because each item's name is formatted differently
		# (or else rename meshes, but that seems like a pain in the balls)
