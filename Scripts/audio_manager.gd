extends Node

@onready var music_bus_idx: int = AudioServer.get_bus_index("Music")
@onready var sfx_bus_idx: int = AudioServer.get_bus_index("SFX")

var music_enabled: bool = true
var sfx_enabled: bool = true

func toggle_music(enabled: bool) -> void:
	music_enabled = enabled
	AudioServer.set_bus_mute(music_bus_idx, not enabled)
	print("--- MUSIC TOGGLE DETECTED ---")
	print("Bus Index: ", music_bus_idx)
	print("Button says enabled: ", enabled, " | AudioServer Muted: ", not enabled)

func toggle_sfx(enabled: bool) -> void:
	sfx_enabled = enabled
	AudioServer.set_bus_mute(sfx_bus_idx, not enabled)
