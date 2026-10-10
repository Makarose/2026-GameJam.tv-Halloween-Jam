extends Label


@export var typing_speed: float = 30.0  # Characters per second

var elapsed_time: float = 0.0
var total_characters: int = 0
var is_typing: bool = false


func _ready() -> void:
	# Store full text and hide characters initially
	total_characters = text.length()
	visible_characters = 0
	#is_typing = true


func _process(delta: float) -> void:
	if not is_typing:
		return

	elapsed_time += delta
	visible_characters = int(elapsed_time * typing_speed)

	# Stop typing when all characters are visible
	if visible_characters >= total_characters:
		visible_characters = total_characters
		is_typing = false
