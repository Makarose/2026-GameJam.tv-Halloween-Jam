@tool
extends EditorScript

const CHARACTER_SCENE := "res://Scenes/characters.tscn"

# tops and pants get a color from the texture, so this one is used as an example
const EXAMPLE_COLOR := "orange"

const SKIP := [&"Body", &"Custom", &"Faces", &"Glasses", &"Gloves", &"Hats", &"Pants", &"Shoes", &"Socks", &"Top"]

func _run() -> void:
	var scene := load(CHARACTER_SCENE) as PackedScene
	if scene == null:
		push_error("Could not load " + CHARACTER_SCENE)
		return

	# instantiated but never added to the tree, so the character's _ready() doesn't run
	var root: Node = scene.instantiate()
	var skeleton: Node = root.find_child("Skeleton3D", true, false)
	if skeleton == null:
		push_error("No Skeleton3D found")
		root.free()
		return

	var names: Array[String] = []
	for node in skeleton.get_children():
		if node is MeshInstance3D and not SKIP.has(node.name):
			names.append(String(node.name).to_lower())
	names.sort()

	print("---- clue preview ----")
	for piece_name in names:
		var color := ""
		if piece_name.begins_with("top_") or piece_name.begins_with("pants_"):
			color = EXAMPLE_COLOR
		var phrase: String = ClueText.describe(piece_name, color)
		if phrase == "":
			phrase = "(no clue)"
		print(piece_name, "  ->  ", phrase)

	root.free()
