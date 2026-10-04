class_name CharacterBuilder
extends Node3D

const CATEGORIES := ["hat_", "shoes_", "glasses_", "gloves_", "pants_", "top_", "socks_", "face_", "costume_"]
@export_range(0, 100, 1, "suffix:%") var costume_percent := 40
@export var animation_keywords: Array[String] = ["claps", "idle", "wave", "cheers", "dance", "jump"]

@onready var anim: AnimationPlayer = $AnimationPlayer

var look := {}  # category prefix -> piece name, read by the clue system


func _ready() -> void:
	randomize_look()
	play_random()


func randomize_look() -> void:
	var skeleton := find_child("Skeleton3D", true, false) as Skeleton3D
	var groups := {}
	for node in skeleton.get_children():
		if not node is MeshInstance3D or node.name == &"Body":
			continue
		var matched := false
		for prefix in CATEGORIES:
			if String(node.name).to_lower().begins_with(prefix):
				groups.get_or_add(prefix, []).append(node)
				matched = true
				break
		if not matched:
			push_warning("Unsorted piece: " + String(node.name))

	var costume := randf() * 100.0 < costume_percent
	for prefix in groups:
		var options: Array = groups[prefix]
		var keep: Node = options.pick_random()
		if prefix == "costume_" and not costume:
			keep = null
		elif costume and (prefix == "top_" or prefix == "pants_"):
			keep = null
		for piece in options:
			if piece != keep:
				piece.queue_free()
		if keep:
			look[prefix] = String(keep.name)


func play_random() -> void:
	var options := []
	for clip in anim.get_animation_list():
		var clip_name := String(clip).to_lower()
		for keyword in animation_keywords:
			if clip_name.contains(keyword.to_lower()):
				options.append(clip)
				break
	if options.is_empty():
		push_warning("No animations match: " + str(animation_keywords))
		return
	var chosen: StringName = options.pick_random()
	anim.get_animation(chosen).loop_mode = Animation.LOOP_LINEAR
	anim.play(chosen)
	anim.seek(randf() * anim.current_animation_length)
	anim.speed_scale = randf_range(0.85, 1.15)
