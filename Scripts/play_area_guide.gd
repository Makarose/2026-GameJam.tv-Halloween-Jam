@tool
extends MeshInstance3D

# draws the play area as circles. visible while editing props.tscn, removed when the game runs.

# green: where the characters can stand (Crowd: Radius)
@export var crowd_radius: float = 40.0:
	set(value):
		crowd_radius = value
		_rebuild()

# yellow: where the tree ring starts and ends (radius + ring gaps)
@export var tree_ring_inner: float = 3.0:
	set(value):
		tree_ring_inner = value
		_rebuild()

@export var tree_ring_outer: float = 50.0:
	set(value):
		tree_ring_outer = value
		_rebuild()

# red: how far the player can walk (Player: Max Distance)
@export var player_limit: float = 40.0:
	set(value):
		player_limit = value
		_rebuild()


func _ready() -> void:
	if not Engine.is_editor_hint():
		queue_free()
		return
	_rebuild()


func _rebuild() -> void:
	if not is_inside_tree():
		return

	var im := ImmediateMesh.new()
	_add_circle(im, crowd_radius, Color.GREEN)
	_add_circle(im, tree_ring_inner, Color.YELLOW)
	_add_circle(im, tree_ring_outer, Color.YELLOW)
	_add_circle(im, player_limit, Color.RED)
	mesh = im


func _add_circle(im: ImmediateMesh, r: float, color: Color) -> void:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = color
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED

	im.surface_begin(Mesh.PRIMITIVE_LINE_STRIP, mat)
	for i in 65:
		var angle := TAU * i / 64.0
		im.surface_add_vertex(Vector3(cos(angle) * r, 0.05, sin(angle) * r))
	im.surface_end()
