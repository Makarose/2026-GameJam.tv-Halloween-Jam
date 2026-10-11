extends Node3D

const CHARACTER_SCENE := preload("res://Scenes/characters.tscn")

@export var per_side := 2 # dancers in each group
@export var spacing := 2.5 # distance between dancers in the same group
@export var side_offset := 5.0 # how far each group stands from the middle


func _ready() -> void:
	_spawn_group(-side_offset)
	_spawn_group(side_offset)


func _spawn_group(center_x: float) -> void:
	for i in per_side:
		var character := CHARACTER_SCENE.instantiate() as CharacterBuilder
		# these must be set BEFORE add_child, because the character dresses itself and picks its animation there
		character.force_costume = 1
		character.animation_keywords.assign(["dance"])
		add_child(character)
		# spreads each group evenly around its own center point
		character.position = Vector3(center_x + (i - (per_side - 1) / 2.0) * spacing, 0.0, 0.0)
