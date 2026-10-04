extends Node3D

const CHARACTER_SCENE := preload("res://Scenes/characters.tscn")

@export var count := 30
@export var area := Vector2(10.0, 6.0)

var crowd: Array[CharacterBuilder] = []
var looks: Array[Dictionary] = []


func _ready() -> void:
	for i in count:
		var character := _make_unique_character()
		character.position = Vector3(
			randf_range(-area.x, area.x), 0.0, randf_range(-area.y, area.y))
		character.rotation.y = randf_range(0.0, TAU)
		crowd.append(character)
		looks.append(character.look)


# Re-rolls up to 20 times so no two characters share the exact same look
func _make_unique_character() -> CharacterBuilder:
	var character: CharacterBuilder = null
	for attempt in 20:
		if character:
			character.queue_free()
		character = CHARACTER_SCENE.instantiate() as CharacterBuilder
		add_child(character)
		if not looks.has(character.look):
			break
	return character
