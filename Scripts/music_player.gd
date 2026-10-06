extends Node3D


@export var music_playlist: Array[AudioStream]

@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer


func shuffle_play(volume: float = 0.0) -> void:
	var current_track: AudioStream = music_playlist.pick_random()
	audio_stream_player.stream = current_track
	audio_stream_player.volume_db = volume
	audio_stream_player.play()
