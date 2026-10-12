extends Control

func _ready() -> void:
	# play that funky music
	MusicPlayer.play_menu_music(-10.0)
	
	print("TIMING title page ready at: ", Time.get_ticks_msec())
	# 1. Sync the buttons with the global manager settings on startup
	%MusicButton.set_pressed_no_signal(not AudioManager.music_enabled)
	%SFXButton.set_pressed_no_signal(not AudioManager.sfx_enabled)
	
	# Clean out any corrupted editor connections just in case
	if %MusicButton.toggled.is_connected(_on_music_button_toggled):
		%MusicButton.toggled.disconnect(_on_music_button_toggled)
	if %SFXButton.toggled.is_connected(_on_sfx_button_toggled):
		%SFXButton.toggled.disconnect(_on_sfx_button_toggled)
		
	# Force code connection directly to functions
	%MusicButton.toggled.connect(_on_music_button_toggled)
	%SFXButton.toggled.connect(_on_sfx_button_toggled)
	

func _on_music_button_toggled(toggled_on: bool) -> void:
	AudioManager.toggle_music(not toggled_on)

func _on_sfx_button_toggled(toggled_on: bool) -> void:
	AudioManager.toggle_sfx(not toggled_on)


func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/levels.tscn")


func _on_quit_pressed() -> void:
	get_tree().quit()


func _on_credits_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/credits.tscn")
