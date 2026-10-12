extends Node3D


@export var music_playlist: Array[AudioStream]
@export var menu_music: AudioStream

@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer


func shuffle_play(volume: float = 0.0) -> void:
	var current_track: AudioStream = music_playlist.pick_random()
	audio_stream_player.stream = current_track
	audio_stream_player.volume_db = volume
	audio_stream_player.play()


func play_menu_music(volume: float = 0.0) -> void:
	var track: AudioStream = menu_music
	audio_stream_player.stream = track
	audio_stream_player.volume_db = volume
	audio_stream_player.play()


func fade_out(duration: float = 1.0) -> void:
	var tween = create_tween()
	await tween.tween_property(audio_stream_player, "volume_db", -80.0, duration).finished
	audio_stream_player.stop()
	tween.kill()


func stop() -> void:
	audio_stream_player.stop()
