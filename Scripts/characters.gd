class_name CharacterBuilder
extends Node3D

# creates one character. when it spawns it deletes every clothing piece it isn't wearing,
# then plays a random animation. check the `look` dictionary to see what it ended up wearing.

# categories of clothing pieces and accessories. 
const CATEGORIES := ["hat_", "shoes_", "glasses_", "gloves_", "pants_", "top_", "socks_", "face_", "costume_"]

# pieces to skip that aren't real accessories. ignores imported files from blender that are not needed but were throwing debug errors.  
const SKIP := [&"Body", &"Custom", &"Faces", &"Glasses", &"Gloves", &"Hats", &"Pants", &"Shoes", &"Socks", &"Top"]

# categories that are allowed when character is also wearing a full costume.
const COSTUME_KEEPS := ["costume_", "face_", "shoes_"]

# costumes that don't get shoes
const NO_SHOES_COSTUMES := [&"costume_cool_banana",&"costume_pink_shark"]

# any shoes starting with this cover the ankles, so socks can't be seen
const HIGH_TOP_PREFIX := "shoes_hightop"

# exported var for animations available to population
@export var animation_keywords: Array[String] = ["claps", "idle", "wave", "cheers", "dance", "jump"]

#textures randomlky assigned to the kept tops and pants
@export var top_textures: Array[Texture2D] = []
@export var pants_textures: Array[Texture2D] = []

@export var outline_shader: ShaderMaterial

@onready var anim: AnimationPlayer = $AnimationPlayer

# creates an empty dictionary of the character's generated outfit, fills when spawned, listing their accessories.
# use to build clues
# NOTE: costumed characters only have "costume_" , "face_" and "shoes_" in here, so check look.has("hat_") before reading look["hat_"] or it will crash.
var look := {}

# set by crowd.gd before add_child. -1 = roll randomly, 0 = never costume, 1 = always costume
var force_costume := -1

# keep an array of the final selected meshes for each character to use when enabling/disabling outline shader
var meshes: Array[Node]

# reference to debug label, can be deleted before publishing
@onready var ug_label: Label3D = $UGLabel


func _ready() -> void:
	randomize_look() # dress the character
	add_outline_material() # add the outline shader material to all meshes, to be enabled by RayCast3D on Player
	play_random()    # start a random animation


func add_outline_material() -> void:
	var skeleton := find_child("Skeleton3D", true, false) as Skeleton3D
	meshes = skeleton.get_children()
	for mesh in meshes:
		if not mesh.material_overlay:
			mesh.material_overlay = outline_shader


func enable_outline() -> void:
	for mesh in meshes:
		if is_instance_valid(mesh):
			mesh.material_overlay.set_shader_parameter("thickness", 0.03)


func disable_outline() -> void:
	for mesh in meshes:
		if is_instance_valid(mesh):
			mesh.material_overlay.set_shader_parameter("thickness", 0.0)


func randomize_look() -> void:
	var skeleton := find_child("Skeleton3D", true, false) as Skeleton3D # find all the clothing pieces
	var groups := {} # empty dictionary for piles of clothes
	var kept := {} # remembers the actual node kept for each category
	
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

	# the crowd decides who wears a costume by setting force_costume to 1 before spawning
	var costume := force_costume == 1

	# pick the costume first, so the other categories know which one it is
	var costume_piece: Node = null
	if costume and groups.has("costume_"):
		costume_piece = groups["costume_"].pick_random()

	# keep one piece of clothing for each pile and deletes the rest.
	# if wearing a costume, deletes everything except what COSTUME_KEEPS allows,
	# shoes are deleted if the costume is on NO_SHOES_COSTUMES.
	for prefix in groups:
		var options: Array = groups[prefix]
		var keep: Node = options.pick_random()
		if prefix == "costume_":
			keep = costume_piece # null if no costume was rolled
		elif costume and not COSTUME_KEEPS.has(prefix):
			keep = null
		elif costume and prefix == "shoes_" and costume_piece != null and NO_SHOES_COSTUMES.has(costume_piece.name):
			keep = null
		for piece in options:
			if piece != keep:
				piece.queue_free()
				
		# remembers what was kept to use in other scripts
		if keep:
			kept[prefix] = keep
			look[prefix] = String(keep.name)
			if prefix == "top_":
				_apply_texture(keep, top_textures, "top_texture")
			elif prefix == "pants_":
				_apply_texture(keep, pants_textures, "pants_texture")

	# removes socks from the model and from look if wearing high tops.
	# done after the loop because the shoes and socks piles can be sorted in any order.
	if look.has("shoes_") and String(look["shoes_"]).begins_with(HIGH_TOP_PREFIX) and kept.has("socks_"):
		kept["socks_"].queue_free()
		look.erase("socks_")

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
