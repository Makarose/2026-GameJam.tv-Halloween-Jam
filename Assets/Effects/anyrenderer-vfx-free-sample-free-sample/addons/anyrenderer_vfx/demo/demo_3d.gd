## AnyRenderer VFX - 3D showcase.
## Keys: 1 slash, 2 shockwave, 3 dissolve, 4 orb on/off (stop() fades it out),
## F spawn one-shot slashes at random spots (independent copies, auto-free),
## G fire a projectile orb (spawn(..., false) = persistent, stop() on "hit").
## The label shows which renderer is running so you can compare
## Forward+ / Mobile / Compatibility.
extends Node3D

@onready var _info: Label = $UI/Info
@onready var _orb: ArfxPlayer = $Effects/GlowOrb

var _slash_scene: PackedScene = preload("res://addons/anyrenderer_vfx/effects/energy_slash.tscn")
var _orb_scene: PackedScene = preload("res://addons/anyrenderer_vfx/effects/glow_orb.tscn")
var _t := 0.0
var _orb_on := true


func _ready() -> void:
	var method := str(ProjectSettings.get_setting("rendering/renderer/rendering_method", "?"))
	if RenderingServer.has_method("get_current_rendering_method"):
		method = RenderingServer.call("get_current_rendering_method")
	# Effects carry their own halo, so WorldEnvironment glow is optional. The
	# scene saves it OFF; turn it on only for Forward+ / Mobile. On Compatibility,
	# Godot 4.2 has no glow and 4.3+ glow brightens the whole background.
	($WorldEnvironment as WorldEnvironment).environment.glow_enabled = method != "gl_compatibility"
	_info.text = "AnyRenderer VFX samples  |  Godot %s  |  renderer: %s\n[1] slash  [2] shockwave  [3] dissolve  [4] orb on/off  [F] one-shot slashes  [G] projectile orb" % [Engine.get_version_info().string, method]


func _process(delta: float) -> void:
	# Move the orb back and forth so its world-space trail is visible.
	_t += delta
	_orb.position.x = 4.5 + sin(_t * 1.6) * 1.2
	_orb.position.y = 1.2 + sin(_t * 3.2) * 0.25


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	match (event as InputEventKey).keycode:
		KEY_1: ($Effects/EnergySlash as ArfxPlayer).play()
		KEY_2: ($Effects/ShockwaveRing as ArfxPlayer).play()
		KEY_3: ($Effects/DissolveDemo as ArfxPlayer).play()
		KEY_4:
			_orb_on = not _orb_on
			if _orb_on:
				_orb.play()
			else:
				_orb.stop() # fades out over the scene's stop_fade (0.3 s)
		KEY_F:
			for i in 3:
				var xf := Transform3D(Basis(Vector3.UP, randf() * TAU), Vector3(randf_range(-4, 4), 1.0, randf_range(-1.5, 1.5)))
				ArfxPlayer.spawn(_slash_scene, self, xf)
		KEY_G:
			_fire_orb()


func _fire_orb() -> void:
	var from := Vector3(-6.0, 1.4, 1.0)
	var to := Vector3(6.0, 1.4, 1.0)
	var orb := ArfxPlayer.spawn(_orb_scene, self, Transform3D(Basis().scaled(Vector3.ONE * 0.8), from), false)
	var tw := create_tween()
	tw.tween_property(orb, "position", to, 1.2)
	tw.tween_callback(orb.stop) # "hit": fade out, then the orb frees itself
