extends RayCast3D


signal guess_submitted(character)

var character: CharacterBuilder

@onready var label: Label = $"../../Control/MarginContainer/Label"


func _process(delta: float) -> void:
	if is_colliding():
		var collider = get_collider()
		var current_character = collider.get_parent()
		
		# Check if we hit a new object
		if current_character != character:
			clear_target()
			set_target(current_character)
	else:
		clear_target()
	
	if Input.is_action_just_pressed("select"):
		if character:
			guess_submitted.emit(character)


func set_target(object: Node) -> void:
	# Make sure the object has a method or script to turn on the outline
	if object.has_method("enable_outline"):
		object.enable_outline()
		character = object

func clear_target() -> void:
	if character != null:
		if character.has_method("disable_outline"):
			character.disable_outline()
		character = null
