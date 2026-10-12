extends Control

# right-click your title page scene in the FileSystem dock and choose Copy Path
const TITLE_SCENE := "res://Scenes/title_page.tscn"

func _ready() -> void:
	pass



func _on_enter_button_pressed() -> void:
	get_tree().change_scene_to_file(TITLE_SCENE)
