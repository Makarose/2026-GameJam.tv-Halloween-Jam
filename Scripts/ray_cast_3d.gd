extends RayCast3D


signal guess_submitted(character)

var character: CharacterBuilder

@onready var label: Label = $"../../Control/MarginContainer/Label"


func _process(delta: float) -> void:
	var collider = get_collider()
	if is_colliding():
		character = collider.get_parent()
	else:
		character = null
	
	if Input.is_action_just_pressed("select"):
		if character:
			guess_submitted.emit(character)
	
	#update_label()


func update_label() -> void:
	if character:
		label.text = str(character.look)
	else:
		label.text = ""
