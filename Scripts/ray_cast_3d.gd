extends RayCast3D


var character: CharacterBuilder

@onready var label: Label = $"../../Control/MarginContainer/Label"


func _process(delta: float) -> void:
	var collider = get_collider()
	if is_colliding():
		character = collider.get_parent()
	else:
		character = null
	
	update_label()


func update_label() -> void:
	if character:
		label.text = str(character.look)
	else:
		label.text = "None"
