extends Node3D


var animated_sprites = []


func _ready() -> void:
	animated_sprites = get_children()
	for sprite in animated_sprites:
		if sprite is AnimatedSprite3D:
			sprite.play("default")


func _on_animated_sprite_3d_3_animation_finished() -> void:
	queue_free()
