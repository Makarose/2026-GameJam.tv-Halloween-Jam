extends Node3D

# spawns a bunch of randomized characters
# gives each one a random spot on the ground
# keeps lists of them so other scripts can pick a target and build clues
# crowd[0] and looks[0] are the same character

const CHARACTER_SCENE := preload("res://Scenes/characters.tscn")

# how many characters to spawn.
@export var count := 30

# percent of the crowd wearing costumes. at least one character is always left without a costume
@export_range(0, 100, 1, "suffix:%") var costume_percent := 40

# how close the characters are allowed to stand to each other
@export var min_spacing := 2.0

# how far the crowd spreads from the center. 10 covers a circle 20 units across
@export var radius := 10.0

# rings variable to spawn trees outside crowd
@export var ring_assets: Array[PackedScene] = []
@export var ring_count := 24
@export var ring_inner_gap := 2.0
@export var ring_outer_gap := 5.0
@export var ring_scale_min := 0.8
@export var ring_scale_max := 1.2
@export var ring_face_center := true

# how much empty space to keep around each prop
@export var prop_clearance := 3.0

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
	# during a run, the level decides the crowd size and costume percent.
	# if no run is active (running this scene from the editor), the Inspector values are used
	if GameState.run_active:
		var cfg = GameState.current_config()
		count = cfg.crowd_count
		costume_percent = cfg.costume_percent
	print("crowd: ", count, " characters, ", costume_percent, "% costumed")
	
	# removes stand in characters used in EditorPreview for camera positioning
	if has_node("EditorPreview"):
		$EditorPreview.queue_free()

	# decide who wears a costume before anyone spawns.
	# clamped to count - 1 so there is always at least one possible uninvited guest
	var costume_total := clampi(roundi(count * costume_percent / 100.0), 0, count - 1)
	var costume_flags: Array[bool] = []
	for i in count:
		costume_flags.append(i < costume_total)
	costume_flags.shuffle()

	for i in count:
		var character := _make_unique_character(costume_flags[i])
		character.position = _find_spot()
		character.rotation.y = randf_range(0.0, TAU)
		crowd.append(character)
		looks.append(character.look)

	# once all characters have been generated, sort potential UGs into separate array by weeding out costume characters
	for guest in crowd:
		if not guest.look.has("costume_"):
			guests.append(guest)
	
	_spawn_ring_assets()

# creates background assets outside play area
# creates background assets outside play area
func _spawn_ring_assets() -> void:
	if ring_assets.is_empty():
		return

	for i in ring_count:
		# try a few spots for this tree, skipping any that are too close to a prop
		var pos := Vector3.ZERO
		var found := false
		for attempt in 10:
			var angle := (float(i) / ring_count) * TAU + randf_range(-0.1, 0.1) * (attempt + 1)
			var dist := radius + randf_range(ring_inner_gap, ring_outer_gap)
			pos = Vector3(cos(angle) * dist, 0.0, sin(angle) * dist)
			if not _is_blocked(pos):
				found = true
				break

		# no clear spot after 10 tries, so skip this tree
		if not found:
			continue

		var asset: Node3D = ring_assets.pick_random().instantiate()
		add_child(asset)
		asset.position = pos

		if ring_face_center:
			asset.look_at(global_position + Vector3.UP * asset.global_position.y, Vector3.UP)
		else:
			asset.rotation.y = randf() * TAU

		asset.scale = Vector3.ONE * randf_range(ring_scale_min, ring_scale_max)

# true if a spot is inside (or within prop_clearance of) any prop's footprint
func _is_blocked(pos: Vector3) -> bool:
	var world_pos := to_global(pos)
	for root in get_tree().get_nodes_in_group("prop_area"):
		for prop in root.get_children():
			if not prop is Node3D or prop.name == &"PlayAreaGuide":
				continue

			# the prop itself plus every mesh inside it
			var visuals: Array = prop.find_children("*", "VisualInstance3D", true, false)
			if prop is VisualInstance3D:
				visuals.append(prop)

			for vis in visuals:
				var box: AABB = vis.global_transform * vis.get_aabb()
				box = box.grow(prop_clearance)
				if world_pos.x >= box.position.x and world_pos.x <= box.end.x \
				and world_pos.z >= box.position.z and world_pos.z <= box.end.z:
					return true
	return false


# makes one character. re-rolls up to 20 times to avoid characters sharing looks. 
# costume characters (NPCs) are allowed to match
func _make_unique_character(wears_costume: bool) -> CharacterBuilder:
	var character: CharacterBuilder = null
	for attempt in 20:
		if character:
			character.queue_free()
		character = CHARACTER_SCENE.instantiate() as CharacterBuilder

		# same costume decision on every re-roll, so the totals stay exact
		character.force_costume = 1 if wears_costume else 0

		# add_child makes the character dress itself, so look is only filled in after this line
		add_child(character)
		if character.look.has("costume_") or not looks.has(character.look):
			break
	return character
	
# uniformly random point inside the circle.
# sqrt keeps the points evenly spread instead of bunching up in the center
func _random_point() -> Vector3:
	var angle := randf() * TAU
	var dist := radius * sqrt(randf())
	return Vector3(cos(angle) * dist, 0.0, sin(angle) * dist)
	
# puts a character at a uniformly random spot anywhere in the area,
# then moves any other character that is now too close
func relocate(character: CharacterBuilder) -> void:
	positions.erase(character.position)

	var pos := _random_point()
	for attempt in 50:
		if not _is_blocked(pos):
			break
		pos = _random_point()
	character.position = pos
	positions.append(pos)

	# anyone crowding the new spot gets re-placed somewhere else
	for other in crowd:
		if other == character:
			continue
		if other.position.distance_to(pos) < min_spacing:
			positions.erase(other.position)
			other.position = _find_spot()


# finds a random spot at least min_spacing away from everyone else	
func _find_spot() -> Vector3:
	var best := Vector3.ZERO
	var best_dist := -1.0
	for attempt in 300:
		var pos := _random_point()
		if _is_blocked(pos):
			continue
		
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
	push_warning("No free spot found. Raise Radius or lower Min Spacing.")
	positions.append(best)
	return best
