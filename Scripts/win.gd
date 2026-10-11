extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _on_main_menu_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/title_page.tscn")



func _on_quit_button_pressed() -> void:
	get_tree().quit()
