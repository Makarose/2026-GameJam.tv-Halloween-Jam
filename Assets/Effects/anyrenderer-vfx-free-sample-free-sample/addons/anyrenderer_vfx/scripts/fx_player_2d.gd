## AnyRenderer VFX - ArfxPlayer2D
## 2D counterpart of ArfxPlayer, used as the root of every 2D effect scene.
##
## * Drives shader parameters on descendant CanvasItems from one 0 -> 1
##   `progress` value (0 = start, 1 = finished / invisible). By default it sets
##   a parameter called `progress`; use `param_curves` (parameter name -> Curve)
##   to drive any other parameters, e.g. {"flash_amount": <Curve>, "dissolve": <Curve>}.
## * Every instance owns shallow copies of its materials, so copies never
##   animate in sync by accident.
## * Restarts CPUParticles2D children; world-space ones (local_coords = false)
##   get their particle size recomputed from the authored values x global scale.
## * Loops, frees itself, or holds (persistent) exactly like ArfxPlayer.
class_name ArfxPlayer2D
extends Node2D

signal finished

@export var duration: float = 0.8
@export var autoplay: bool = true
@export var loop: bool = false
@export var loop_delay: float = 0.5
@export var free_when_done: bool = false
## Persistent mode: progress stops at `hold_progress` until stop().
@export var persistent: bool = false
@export_range(0.0, 1.0) var hold_progress: float = 0.5
## Default fade-out time of stop() in seconds. 0 = instant.
@export var stop_fade: float = 0.0
## Where a stop() fade starts: max(current progress, this). -1 = current progress.
@export_range(-1.0, 1.0) var stop_from_progress: float = -1.0
## Optional: shader parameter name -> Curve sampled with progress (x 0..1).
## Leave empty to drive a parameter named `progress` linearly.
@export var param_curves: Dictionary = {}

var _time: float = -1.0
var _wait: float = 0.0
var _progress: float = 0.0
var _stopping: bool = false
var _stop_from: float = 0.0
var _stop_t: float = 0.0
var _stop_len: float = 0.0
var _mats: Array[ShaderMaterial] = []
var _particles: Array[CPUParticles2D] = []
var _base_scale := {}
var _applied_scale: float = -1.0


## Instantiate a 2D effect scene under `parent` at the global transform `xform`
## and play it. one_shot = false keeps it alive until stop().
static func spawn(scene: PackedScene, parent: Node, xform: Transform2D, one_shot: bool = true) -> ArfxPlayer2D:
	var fx := scene.instantiate() as ArfxPlayer2D
	fx.loop = false
	fx.free_when_done = true
	fx.persistent = not one_shot
	fx.autoplay = true
	if parent is Node2D and (parent as Node2D).is_inside_tree():
		fx.transform = (parent as Node2D).global_transform.affine_inverse() * xform
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
	_set_progress(0.0)
	set_process(false)
	if autoplay and not Engine.is_editor_hint():
		play()


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED or what == NOTIFICATION_LOCAL_TRANSFORM_CHANGED:
		_update_particle_scale()


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


## Stop: progress -> 1 (invisible) instantly or over `fade` seconds
## (default `stop_fade`); frees the node afterwards if free_when_done.
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
		_wait -= delta
		if _wait <= 0.0:
			play()
		return
	_time += delta
	var t := clampf(_time / maxf(duration, 0.0001), 0.0, 1.0)
	if persistent and t >= hold_progress:
		_set_progress(hold_progress)
		set_process(false)
		return
	_set_progress(t)
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
		if param_curves.is_empty():
			m.set_shader_parameter("progress", value)
		else:
			for param in param_curves:
				var c: Curve = param_curves[param]
				if c:
					m.set_shader_parameter(param, c.sample_baked(value))


func _update_particle_scale() -> void:
	if _base_scale.is_empty() or not is_inside_tree():
		return
	var s := global_transform.get_scale().abs()
	var avg := (s.x + s.y) * 0.5
	if is_equal_approx(avg, _applied_scale):
		return
	_applied_scale = avg
	for p in _base_scale:
		var base: Vector2 = _base_scale[p]
		(p as CPUParticles2D).scale_amount_min = base.x * avg
		(p as CPUParticles2D).scale_amount_max = base.y * avg


func _collect(node: Node) -> void:
	for child in node.get_children():
		if child is CPUParticles2D:
			_particles.append(child)
		elif child is CanvasItem and (child as CanvasItem).material is ShaderMaterial:
			var unique := ((child as CanvasItem).material as ShaderMaterial).duplicate() as ShaderMaterial
			(child as CanvasItem).material = unique
			_mats.append(unique)
		if child.get_child_count() > 0 and not (child is ArfxPlayer2D):
			_collect(child)
