extends Node3D


@export var witch_cackle: AudioStream
@export var fire_spell: AudioStream
@export var ticking_clock: AudioStream
@export var death_clock: AudioStream
@export var wrong_answer: AudioStream
@export var right_answer: AudioStream
@export var buttons: AudioStream
@export var door_bell: AudioStream
@export var church_bell: AudioStream
@export var closing_bell: AudioStream
@export var whoop: AudioStream
@export var creature: AudioStream
@export var frustrated_goblin: AudioStream
@export var party_guitar: AudioStream
@export var whoosh: AudioStream

func _ready() -> void:
	# connect any button the moment it enters any scene
	get_tree().node_added.connect(_on_node_added)


func _on_node_added(node: Node) -> void:
	if node is BaseButton:
		if not node.pressed.is_connected(_on_any_button_pressed):
			node.pressed.connect(_on_any_button_pressed)


func _on_any_button_pressed() -> void:
	play_sfx("buttons", -6.0)


func stop_sfx(sfx_name: String) -> void:
	var current_stream: AudioStream = convert_string_to_stream(sfx_name)
	var players = get_children()
	for player in players:
		if player is AudioStreamPlayer and player.stream == current_stream:
			player.stop()


func play_sfx(sfx_name: String, volume: float = 0.0) -> void:
	var new_player: AudioStreamPlayer = AudioStreamPlayer.new()
	
	new_player.bus = "SFX"
	
	var stream: AudioStream = convert_string_to_stream(sfx_name)
	
	if stream == null:
		print("SFX '", sfx_name, "' has no stream assigned")
		new_player.free()
		return 
	
	new_player.stream = stream
	new_player.volume_db = volume
	
	add_child(new_player)
	new_player.play()
	
	# TODO: jsut edit this SFX later to cut out opening space, or find a new one
	if stream == fire_spell:
		new_player.seek(0.20)
	
	new_player.finished.connect(new_player.queue_free)


func convert_string_to_stream(_string: String) -> AudioStream:
	var stream: AudioStream
	
	match _string:
		"witch_cackle":
			stream = witch_cackle
		"fire_spell":
			stream = fire_spell
		"ticking_clock":
			stream = ticking_clock
		"death_clock":
			stream = death_clock
		"wrong_answer":
			stream = wrong_answer
		"right_answer":
			stream = right_answer
		"buttons":
			stream = buttons
		"door_bell":
			stream = door_bell
		"church_bell":
			stream = church_bell
		"closing_bell":
			stream = closing_bell
		"whoop":
			stream = whoop
		"creature":
			stream = creature
		"frustrated_goblin":
			stream = frustrated_goblin
		"party_guitar":
			stream = party_guitar
		"whoosh":
			stream = whoosh
		_:
			stream = null
			print("Invalid SFX name!")
	
	return stream
