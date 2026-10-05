extends Node3D

# spawns a bunch of randomized characters
# gives each one a random spot on the ground
# keeps lists of them so other scripts can pick a target and build clues
# crowd[0] and looks[0] are the same character

const CHARACTER_SCENE := preload("res://Scenes/characters.tscn")

# how many characters to spawn.
@export var count := 30

# how close the characters are allowed to stand to each other
@export var min_spacing := 2.0

# how far the crowd spreads. these are half sizes, so (10, 6) covers 20 units wide by 12 units deep
@export var area := Vector2(10.0, 6.0)

# every spawned character
var crowd: Array[CharacterBuilder] = []

# only the potential UG characters
var guests: Array[CharacterBuilder] = []

# what each character is wearing, in same order as crowd
# looks[i] is crowd[i].look
var looks: Array[Dictionary] = []

# character positions, used to keep characters apart
var positions: Array[Vector3] = []


func _ready() -> void:
	# removes stand in characters used in EditorPreview for camera positioning
	$EditorPreview.queue_free() # this line will cause a crash if EditorPreview is deleted.
	for i in count:
		var character := _make_unique_character()
		character.position = _find_spot()
		character.rotation.y = randf_range(0.0, TAU)
		crowd.append(character)
		looks.append(character.look)
	# once all characters have been generated, sort potential UGs into separate array by weeding out costume characters
	for guest in crowd:
		if not guest.look.has("costume_"):
			guests.append(guest)


# makes one character. re-rolls up to 20 times to avoid characters sharing looks. 
# costume characters (NPCs) are allowed to match
func _make_unique_character() -> CharacterBuilder:
	var character: CharacterBuilder = null
	for attempt in 20:
		if character:
			character.queue_free()
		character = CHARACTER_SCENE.instantiate() as CharacterBuilder
		
		# add_child makes the character dress itself, so look is only filled in after this line
		add_child(character)
		if character.look.has("costume_") or not looks.has(character.look):
			break
	return character

# finds a random spot at least min_spacing away from everyone else	
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
			
	# gives up after 300 tries and shows warning and uses least crowded space which is closer than min_spacing		
	push_warning("No free spot found. Raise Area or lower Min Spacing.")
	positions.append(best)
	return best
