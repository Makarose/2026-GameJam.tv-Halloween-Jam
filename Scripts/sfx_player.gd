extends Node3D


@export var witch_cackle: AudioStream
@export var fire_spell: AudioStream
@export var ticking_clock: AudioStream
@export var death_clock: AudioStream
@export var wrong_answer: AudioStream
@export var right_answer: AudioStream


func play_sfx(sfx_name: String, volume: float = 0.0) -> void:
	var new_player: AudioStreamPlayer = AudioStreamPlayer.new()
	
	var stream: AudioStream = null
	
	match sfx_name:
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
		_:
			print("Invalid SFX name!")
	
	new_player.stream = stream
	new_player.volume_db = volume
	
	add_child(new_player)
	new_player.play()
	
	# TODO: jsut edit this SFX later to cut out opening space, or find a new one
	if stream == fire_spell:
		new_player.seek(0.20)
	
	new_player.finished.connect(new_player.queue_free)
