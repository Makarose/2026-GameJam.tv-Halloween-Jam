## AnyRenderer VFX - 2D showcase for fx_sprite_hit_2d.gdshader.
## Keys: H hit flash, O toggle outline, D dissolve out/in. It also cycles automatically.
extends Node2D

@onready var _flash: ArfxSpriteHit = $Slimes/FlashSlime/ArfxSpriteHit
@onready var _outline: ArfxSpriteHit = $Slimes/OutlineSlime/ArfxSpriteHit
@onready var _dissolve: ArfxSpriteHit = $Slimes/DissolveSlime/ArfxSpriteHit

var _outline_on := true
var _timer := 0.0
# Dissolve loop as a small timer-driven state machine (no awaiting coroutine,
# so nothing is left waiting on a Tween when the scene quits).
var _dissolve_phase := 0
var _dissolve_timer := 0.0
const DISSOLVE_STEPS := [0.9, 0.3, 0.9, 0.5] # out, pause, in, pause


func _ready() -> void:
	_outline.set_outline(2.0, Color(1.0, 0.85, 0.2))
	var method := str(ProjectSettings.get_setting("rendering/renderer/rendering_method", "?"))
	if RenderingServer.has_method("get_current_rendering_method"):
		method = RenderingServer.call("get_current_rendering_method")
	$UI/Info.text = "Sprite Hit FX (canvas_item)  |  renderer: %s\n[H] flash  [O] outline  [D] dissolve" % method
	_dissolve.dissolve_out(DISSOLVE_STEPS[0])


func _process(delta: float) -> void:
	_timer += delta
	if _timer > 0.7:
		_timer = 0.0
		_flash.flash(Color(1, 1, 1) if randf() > 0.3 else Color(1.0, 0.3, 0.3))
	_dissolve_timer += delta
	if _dissolve_timer >= DISSOLVE_STEPS[_dissolve_phase]:
		_dissolve_timer = 0.0
		_dissolve_phase = (_dissolve_phase + 1) % DISSOLVE_STEPS.size()
		if _dissolve_phase == 0:
			_dissolve.dissolve_out(DISSOLVE_STEPS[0])
		elif _dissolve_phase == 2:
			_dissolve.dissolve_in(DISSOLVE_STEPS[2])


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	match (event as InputEventKey).keycode:
		KEY_H: _flash.flash()
		KEY_O:
			_outline_on = not _outline_on
			_outline.set_outline(2.0 if _outline_on else 0.0)
		KEY_D: _dissolve.dissolve_out(0.6)
