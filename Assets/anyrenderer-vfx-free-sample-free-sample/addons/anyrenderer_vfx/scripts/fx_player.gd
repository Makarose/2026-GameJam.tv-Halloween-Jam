## AnyRenderer VFX - ArfxPlayer
## Root script for every 3D effect scene in this pack.
##
## * Drives the shader parameter `progress` on its mesh children.
##   Convention for every effect: progress 0 = start, 1 = finished / invisible.
##   Each instance gets its own shallow copy of the material on ready, so
##   copies of one effect never fight over a shared material. (`instance
##   uniform` would be nicer, but Godot 4.2 Compatibility does not support it.)
## * Restarts CPUParticles3D children on play().
## * Scaling: meshes and local-space particles follow the node scale by
##   themselves. For world-space particles (local_coords = false) Godot already
##   applies the global transform to emission position and velocity, but not to
##   particle size, so ArfxPlayer sets scale_amount_min/max = original x global
##   scale. It recomputes this from the stored originals whenever the global
##   scale changes (before/after add_child, spawn() with a scaled transform, or
##   scaling at runtime), so it never multiplies twice.
## * One-shot effects can free themselves when done; persistent effects
##   (projectiles, auras) hold at `hold_progress` until stop().
##
## Usage from code:
##     var fx := ArfxPlayer.spawn(preload("res://addons/anyrenderer_vfx/effects/energy_slash.tscn"), self, global_transform)
##     fx.finished.connect(func(): print("slash done"))
##     # A projectile that stays alive until you stop it (fades out, then frees itself):
##     var orb := ArfxPlayer.spawn(preload("res://addons/anyrenderer_vfx/effects/glow_orb.tscn"), self, xform, false)
##     ...
##     orb.stop()
class_name ArfxPlayer
extends Node3D

## Emitted every time a play-through reaches progress = 1.
signal finished

## Seconds for progress to go from 0 to 1.
@export var duration: float = 0.6
## Start playing as soon as the node enters the tree (in game, not in the editor).
@export var autoplay: bool = true
## Play again after `loop_delay` seconds when done.
@export var loop: bool = false
@export var loop_delay: float = 0.5
## Free this node when a non-looping play-through ends (fire-and-forget effects),
## or after stop() has faded it out.
@export var free_when_done: bool = false
## Persistent mode (projectiles, auras, charge-ups): progress stops at
## `hold_progress` and stays there until stop() is called.
@export var persistent: bool = false
@export_range(0.0, 1.0) var hold_progress: float = 0.5
## Default fade-out time of stop() in seconds (progress -> 1). 0 = instant.
@export var stop_fade: float = 0.0
## Where a stop() fade starts: max(current progress, this). Set it to the start
## of the effect's fade-out part (Glow Orb: 0.7) so stopping never replays the
## middle of the effect. -1 = from the current progress.
@export_range(-1.0, 1.0) var stop_from_progress: float = -1.0
## Optional remap of time -> progress (x and y in 0..1). Leave empty for linear.
@export var progress_curve: Curve
## Give every instance a different noise pattern.
@export var randomize_seed: bool = true

var _time: float = -1.0
var _progress: float = 0.0
var _wait: float = 0.0
var _stopping: bool = false
var _stop_from: float = 0.0
var _stop_t: float = 0.0
var _stop_len: float = 0.0
var _mats: Array[ShaderMaterial] = []
var _particles: Array[CPUParticles3D] = []
var _base_scale := {} # world-space CPUParticles3D -> Vector2(scale_amount_min, scale_amount_max) as authored
var _applied_scale: float = -1.0


## Instantiate an effect scene under `parent` at the global transform `xform`
## and play it. one_shot = true: plays once and frees itself.
## one_shot = false: persistent; holds until you call stop(), then fades out and frees itself.
static func spawn(scene: PackedScene, parent: Node, xform: Transform3D, one_shot: bool = true) -> ArfxPlayer:
	var fx := scene.instantiate() as ArfxPlayer
	fx.loop = false
	fx.free_when_done = true
	fx.persistent = not one_shot
	fx.autoplay = true
	# Set the transform BEFORE entering the tree, so _ready already sees the final scale.
	if parent is Node3D and (parent as Node3D).is_inside_tree():
		fx.transform = (parent as Node3D).global_transform.affine_inverse() * xform
	else:
		fx.transform = xform
	parent.add_child(fx)
	return fx


func _ready() -> void:
	_collect(self)
	for p in _particles:
		if not p.local_coords:
			_base_scale[p] = Vector2(p.scale_amount_min, p.scale_amount_max)
	# Local changes (scaling this node) notify immediately; parent changes
	# arrive with the next transform update.
	set_notify_transform(not _base_scale.is_empty())
	set_notify_local_transform(not _base_scale.is_empty())
	_update_particle_scale()
	if randomize_seed:
		var s := randf() * 100.0
		for m in _mats:
			m.set_shader_parameter("seed", s)
	_set_progress(0.0)
	set_process(false)
	if autoplay and not Engine.is_editor_hint():
		play()


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED or what == NOTIFICATION_LOCAL_TRANSFORM_CHANGED:
		_update_particle_scale()


## Start (or restart) the effect from progress = 0.
func play() -> void:
	_time = 0.0
	_wait = 0.0
	_stopping = false
	_update_particle_scale()
	for p in _particles:
		p.restart()
		p.emitting = true
	_set_progress(0.0)
	set_process(true)


## Stop the effect. Particles stop emitting (live ones finish naturally) and
## progress goes to 1 (= invisible) instantly, or over `fade` seconds
## (default: the `stop_fade` property). If free_when_done is set, the node is
## freed afterwards.
func stop(fade: float = -1.0) -> void:
	if fade < 0.0:
		fade = stop_fade
	for p in _particles:
		p.emitting = false
	if fade <= 0.0 or not is_inside_tree():
		_end_stop()
		return
	_stopping = true
	_stop_from = maxf(_progress, stop_from_progress)
	_set_progress(_stop_from)
	_stop_t = 0.0
	_stop_len = fade
	set_process(true)


## Current progress (0..1). Used by tests and tools.
func get_progress() -> float:
	return _progress


func _process(delta: float) -> void:
	if _stopping:
		_stop_t += delta
		var k := clampf(_stop_t / _stop_len, 0.0, 1.0)
		_set_progress(lerpf(_stop_from, 1.0, k))
		if k >= 1.0:
			_end_stop()
		return
	if _time < 0.0:
		# Waiting between loops.
		_wait -= delta
		if _wait <= 0.0:
			play()
		return
	_time += delta
	var t := clampf(_time / maxf(duration, 0.0001), 0.0, 1.0)
	if persistent and t >= hold_progress:
		# Hold until stop(); keep processing off to cost nothing.
		_set_progress(progress_curve.sample_baked(hold_progress) if progress_curve else hold_progress)
		set_process(false)
		return
	_set_progress(progress_curve.sample_baked(t) if progress_curve else t)
	if t >= 1.0:
		finished.emit()
		if not loop:
			for p in _particles:
				if not p.one_shot:
					p.emitting = false # continuous emitters (trails) stop with the effect
		if loop:
			_time = -1.0
			_wait = loop_delay
		elif free_when_done:
			_free_after_particles()
		else:
			set_process(false)


func _end_stop() -> void:
	_stopping = false
	_time = -1.0
	set_process(false)
	_set_progress(1.0)
	if free_when_done and is_inside_tree():
		_free_after_particles()


func _free_after_particles() -> void:
	# Let particles that are still alive finish before freeing.
	set_process(false)
	var tail := 0.0
	for p in _particles:
		tail = maxf(tail, p.lifetime)
	if tail > 0.0:
		await get_tree().create_timer(tail).timeout
	if is_instance_valid(self):
		queue_free()


func _set_progress(value: float) -> void:
	_progress = value
	for m in _mats:
		m.set_shader_parameter("progress", value)


func _update_particle_scale() -> void:
	if _base_scale.is_empty() or not is_inside_tree():
		return
	var b := global_transform.basis
	var s := (b.x.length() + b.y.length() + b.z.length()) / 3.0
	if is_equal_approx(s, _applied_scale):
		return
	_applied_scale = s
	for p in _base_scale:
		var base: Vector2 = _base_scale[p]
		# Always from the authored values, never from the current ones.
		(p as CPUParticles3D).scale_amount_min = base.x * s
		(p as CPUParticles3D).scale_amount_max = base.y * s


func _collect(node: Node) -> void:
	for child in node.get_children():
		if child is CPUParticles3D:
			_particles.append(child)
		elif child is GeometryInstance3D:
			_take_unique_material(child)
		if child.get_child_count() > 0 and not (child is ArfxPlayer):
			_collect(child)


func _take_unique_material(g: GeometryInstance3D) -> void:
	var mat: Material = g.material_override
	if mat == null and g is MeshInstance3D and (g as MeshInstance3D).mesh:
		mat = (g as MeshInstance3D).mesh.surface_get_material(0)
	if not (mat is ShaderMaterial) or (mat as ShaderMaterial).shader == null:
		return
	var has_progress := false
	for u in (mat as ShaderMaterial).shader.get_shader_uniform_list():
		if u.get("name", "") == "progress":
			has_progress = true
			break
	if not has_progress:
		return
	# Shallow duplicate: shares the compiled shader, owns its parameter values.
	var unique := (mat as ShaderMaterial).duplicate() as ShaderMaterial
	g.material_override = unique
	_mats.append(unique)
