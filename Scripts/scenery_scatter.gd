@tool
extends Node3D

@export var items: Array[PackedScene] = []
@export var count := 40
@export var area := Vector2(14.0, 9.0)
@export var min_spacing := 1.5
@export var scale_range := Vector2(0.9, 1.2)
@export var regenerate_on_play := false
@export var scatter_now := false:
	set(value):
		if value and is_inside_tree():
			scatter()
		scatter_now = false


func _ready() -> void:
	if not Engine.is_editor_hint() and regenerate_on_play:
		scatter()


func scatter() -> void:
	if items.is_empty():
		push_warning("Add some scenes to Items first")
		return

	for child in get_children():
		child.free()

	var placed: Array[Vector3] = []
	var tries := 0
	while placed.size() < count and tries < count * 20:
		tries += 1
		var pos := Vector3(
			randf_range(-area.x, area.x), 0.0, randf_range(-area.y, area.y))
		if _too_close(pos, placed):
			continue
		var item := items.pick_random().instantiate() as Node3D
		add_child(item)
		if Engine.is_editor_hint():
			item.owner = get_tree().edited_scene_root  # makes it save with the scene
		item.position = pos
		item.rotation.y = randf_range(0.0, TAU)
		item.scale = Vector3.ONE * randf_range(scale_range.x, scale_range.y)
		placed.append(pos)


func _too_close(pos: Vector3, placed: Array[Vector3]) -> bool:
	for other in placed:
		if pos.distance_to(other) < min_spacing:
			return true
	return false
