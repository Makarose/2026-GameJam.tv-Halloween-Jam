## AnyRenderer VFX - ArfxSpriteHit
## Attach to any CanvasItem (Sprite2D, AnimatedSprite2D, TextureRect...) that
## uses fx_sprite_hit_2d.gdshader. Makes the material unique per node (canvas
## shaders have no instance uniforms in Godot 4.2) and offers tween helpers.
class_name ArfxSpriteHit
extends Node

## The CanvasItem to drive. Defaults to the parent node.
@export var target: CanvasItem

var _mat: ShaderMaterial
var _flash_tween: Tween
var _dissolve_tween: Tween


func _ready() -> void:
	if target == null:
		target = get_parent() as CanvasItem
	if target and target.material is ShaderMaterial:
		_mat = (target.material as ShaderMaterial).duplicate() as ShaderMaterial
		target.material = _mat
	else:
		push_warning("ArfxSpriteHit: target has no ShaderMaterial using fx_sprite_hit_2d.gdshader")


## Quick white (or any colour) flash, e.g. when taking damage.
func flash(color: Color = Color.WHITE, time: float = 0.12) -> void:
	if _mat == null:
		return
	if _flash_tween:
		_flash_tween.kill()
	_mat.set_shader_parameter("flash_color", color)
	_mat.set_shader_parameter("flash_amount", 1.0)
	_flash_tween = create_tween()
	_flash_tween.tween_method(func(v: float): _mat.set_shader_parameter("flash_amount", v), 1.0, 0.0, time)


## Show / hide an outline (selection, interaction prompt, buff...).
func set_outline(width_px: float, color: Color = Color(1.0, 0.85, 0.2)) -> void:
	if _mat == null:
		return
	_mat.set_shader_parameter("outline_px", width_px)
	_mat.set_shader_parameter("outline_color", color)


## Dissolve away over `time` seconds. Returns the tween so you can await it.
## Starts from the current dissolve value and interrupts a running dissolve.
func dissolve_out(time: float = 0.8) -> Tween:
	return _dissolve_to(1.0, time)


## Reverse of dissolve_out (spawn / teleport in).
func dissolve_in(time: float = 0.8) -> Tween:
	return _dissolve_to(0.0, time)


func _dissolve_to(target_value: float, time: float) -> Tween:
	if _dissolve_tween:
		_dissolve_tween.kill()
	_dissolve_tween = create_tween()
	if _mat:
		var cur = _mat.get_shader_parameter("dissolve")
		var from: float = cur if cur != null else 0.0
		_dissolve_tween.tween_method(func(v: float): _mat.set_shader_parameter("dissolve", v), from, target_value, time)
	else:
		_dissolve_tween.tween_interval(0.0)
	return _dissolve_tween
