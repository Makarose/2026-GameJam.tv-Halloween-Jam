extends Node3D

const CHARACTER_SCENE := preload("res://Scenes/characters.tscn")

@export var count := 30
@export var min_spacing := 2.0
@export var area := Vector2(10.0, 6.0)

var crowd: Array[CharacterBuilder] = []
var looks: Array[Dictionary] = []
var positions: Array[Vector3] = []


func _ready() -> void:
	$EditorPreview.queue_free()
	for i in count:
		var character := _make_unique_character()
		character.position = _find_spot()
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
		if character.look.has("costume_") or not looks.has(character.look):
			break
	return character
	
func _find_spot() -> Vector3:
	var best := Vector3.ZERO
	var best_dist := -1.0
	for attempt in 300:
		var pos := Vector3(
			randf_range(-area.x, area.x), 0.0, randf_range(-area.y, area.y))
		var nearest := INF
		for other in positions:
			nearest = minf(nearest, pos.distance_to(other))
		if nearest >= min_spacing:
			positions.append(pos)
			return pos
		if nearest > best_dist:
			best_dist = nearest
			best = pos
	push_warning("No free spot found. Raise Area or lower Min Spacing.")
	positions.append(best)
	return best
