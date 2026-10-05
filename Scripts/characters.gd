class_name CharacterBuilder
extends Node3D

# creates one character. when it spawns it deletes every clothing piece it isn't wearing,
# then plays a random animation. check the `look` dictionary to see what it ended up wearing.

# categories of clothing pieces and accessories. 
const CATEGORIES := ["hat_", "shoes_", "glasses_", "gloves_", "pants_", "top_", "socks_", "face_", "costume_"]

# pieces to skip that aren't real accessories. ignores imported files from blender that are not needed but were throwing debug errors.  
const SKIP := [&"Body", &"Custom", &"Faces", &"Glasses", &"Gloves", &"Hats", &"Pants", &"Shoes", &"Socks", &"Top"]

# categories that are allowed when character is also wearing a full costume.
const COSTUME_KEEPS := ["costume_", "face_"]

# exported var for changing percentage of population that is wearing full costumes (the NPCs)
@export_range(0, 100, 1, "suffix:%") var costume_percent := 40

# exported var for animations available to population
@export var animation_keywords: Array[String] = ["claps", "idle", "wave", "cheers", "dance", "jump"]

#textures randomlky assigned to the kept tops and pants
@export var top_textures: Array[Texture2D] = []
@export var pants_textures: Array[Texture2D] = []

@onready var anim: AnimationPlayer = $AnimationPlayer

# creates an empty dictionary of the character's generated outfit, fills when spawned, listing their accessories.
# use to build clues
# NOTE: costumed characters only have "costume_" and "face_" in here, so check look.has("hat_") before reading look["hat_"] or it will crash.
var look := {}

# reference to debug label, can be deleted before publishing
@onready var ug_label: Label3D = $UGLabel


func _ready() -> void:
	randomize_look() # dress the character
	play_random()    # start a random animation


func randomize_look() -> void:
	var skeleton := find_child("Skeleton3D", true, false) as Skeleton3D # find all the clothing pieces
	var groups := {} # empty dictionary for piles of clothes
	
	# sort the pieces into their piles
	for node in skeleton.get_children():
		if not node is MeshInstance3D or SKIP.has(node.name):
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
	
	# keep one piece of clothing for each pile and deletes the rest. if wearing costume deletes all but "costume_" and "face_".
	for prefix in groups:
		var options: Array = groups[prefix]
		var keep: Node = options.pick_random()
		if prefix == "costume_" and not costume:
			keep = null
		elif costume and not COSTUME_KEEPS.has(prefix):
			keep = null
		for piece in options:
			if piece != keep:
				piece.queue_free()
				
		# remembers what was kept to use in other scripts
		if keep:
			look[prefix] = String(keep.name)
			if prefix == "top_":
				_apply_texture(keep, top_textures, "top_texture")
			elif prefix == "pants_":
				_apply_texture(keep, pants_textures, "pants_texture")

# gives a piece a random texture from the list and records which one in look
func _apply_texture(piece: Node, textures: Array[Texture2D], key: String) -> void:
	if textures.is_empty():
		return
	var index := randi() % textures.size()
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = textures[index]
	(piece as MeshInstance3D).material_override = mat
	look[key] = index

# finds a random animation to play from the list
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
	
	# can't loop imported animations in editor so looped here
	anim.get_animation(chosen).loop_mode = Animation.LOOP_LINEAR
	anim.play(chosen)
	
	# starts animations at different times so crowd doesn't move in sync.
	anim.seek(randf() * anim.current_animation_length)
	anim.speed_scale = randf_range(0.85, 1.15)
