extends Node3D

@onready var items_root: Node3D = $SubViewport/Characters/character_grp/character_rig/Skeleton3D
@onready var vp: SubViewport = $SubViewport

const OUTPUT_SIZE := 512
const PADDING := 0.15
const FORCE_SMOOTH_FILTER := true
const TEXTURE_PREFIXES := ["top_", "pants_"]

# Change this to the folder with your shirt and pants textures
@export var texture_folder := "res://Assets/Textures/"

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute("res://Assets//Item Photos")

	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.transparent_bg = true
	vp.size = Vector2i(4096, 4096)
	vp.msaa_3d = Viewport.MSAA_4X

	# Show every hidden parent above the skeleton
	var n: Node = items_root
	while n != null and n != vp:
		if n is Node3D and not n.visible:
			n.visible = true
		n = n.get_parent()

	var textures := load_textures(texture_folder)
	print("textures found: ", textures.size())

	var children := items_root.get_children()
	print("children found: ", children.size())

	for c in children:
		if c is Node3D:
			c.visible = false

	for item in children:
		if not item is Node3D:
			continue

		if FORCE_SMOOTH_FILTER:
			make_smooth(item)

		# Plain version of every item
		await capture(item, item.name)

		# One picture per texture for tops and pants
		if is_texture_item(item.name) and item is MeshInstance3D:
			for tex_name in textures:
				apply_texture(item, textures[tex_name])
				await capture(item, "%s_%s" % [item.name, tex_name])
			item.material_override = null

	print("Done")
	get_tree().quit()

func is_texture_item(item_name: String) -> bool:
	for prefix in TEXTURE_PREFIXES:
		if item_name.begins_with(prefix):
			return true
	return false

func load_textures(folder: String) -> Dictionary:
	var result := {}
	for f in DirAccess.get_files_at(folder):
		var ext := f.get_extension().to_lower()
		if ext in ["png", "jpg", "jpeg", "webp"]:
			var tex = load(folder.path_join(f))
			if tex is Texture2D:
				result[f.get_basename()] = tex
	for d in DirAccess.get_directories_at(folder):
		result.merge(load_textures(folder.path_join(d)))
	print("looked in ", folder, " found ", result.size())
	return result

func apply_texture(item: MeshInstance3D, tex: Texture2D) -> void:
	var base := item.get_active_material(0)
	if base is BaseMaterial3D:
		var mat := base.duplicate() as BaseMaterial3D
		mat.albedo_texture = tex
		if FORCE_SMOOTH_FILTER:
			mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
		item.material_override = mat
	else:
		print("WARNING: ", item.name, " does not use a standard material, texture not applied")

func make_smooth(item: Node) -> void:
	var meshes := item.find_children("*", "MeshInstance3D", true, false)
	if item is MeshInstance3D:
		meshes.append(item)
	for node in meshes:
		var m := node as MeshInstance3D
		if m == null:
			continue
		for i in m.get_surface_override_material_count():
			var mat: Material = m.get_active_material(i)
			if mat is BaseMaterial3D:
				mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC

func capture(item: Node3D, file_name: String) -> void:
	item.visible = true

	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw

	var img := vp.get_texture().get_image()
	img.convert(Image.FORMAT_RGBA8)
	var rect := img.get_used_rect()

	if rect.size == Vector2i.ZERO:
		print("nothing visible for ", file_name)
		item.visible = false
		return

	var side := maxi(rect.size.x, rect.size.y)
	if side < OUTPUT_SIZE:
		print("WARNING: ", file_name, " crop is ", side, "px, will be upscaled and look soft")

	var pad := int(side * PADDING)
	var canvas_size := side + pad * 2
	var canvas := Image.create(canvas_size, canvas_size, false, Image.FORMAT_RGBA8)
	canvas.fill(Color(0, 0, 0, 0))

	var offset := Vector2i(
		int((canvas_size - rect.size.x) / 2.0),
		int((canvas_size - rect.size.y) / 2.0)
	)
	canvas.blit_rect(img, rect, offset)
	canvas.resize(OUTPUT_SIZE, OUTPUT_SIZE, Image.INTERPOLATE_LANCZOS)

	var err := canvas.save_png("res://Assets//Item Photos/%s.png" % file_name)
	print("saved ", file_name, " result: ", err)
	item.visible = false
