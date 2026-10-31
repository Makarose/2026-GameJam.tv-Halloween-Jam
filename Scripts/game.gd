extends Node3D

# the pieces a player can spot from across the crowd. shoes and socks are too low and get hidden,
# so they can only be clue 2 or 3.
const VISIBLE_KEYS: Array[String] = ["hat_", "top_", "pants_", "glasses_", "gloves_"]

# how many random guests to test before giving up on a perfect clue set
const MAX_TRIES := 60
const RELAX_PAIR_AFTER := 20 # after this many tries, clue 2 is allowed to leave only the guest
const RELAX_RANGE_AFTER := 40 # after this many tries, clue 1 can match anywhere from 1 to 40 people

var uninvited_guest: CharacterBuilder
var clues: Array[String] = []
var num_guesses: int = 0
var clock_is_ticking: bool = false

#clue system variables
var funnel_keys: Array[String] = [] # which pieces the clues are about, in the order they're shown
var suspect_phrases: Array[Dictionary] = [] # what every character in the crowd is wearing
var wrong_guesses: Array[CharacterBuilder] = []
var _check_texture: ImageTexture

var level_over: bool = false # true once the level is won or lost, so nothing else counts

# the scene shown after the last level of a difficulty
@export_file("*.tscn") var win_scene_path: String

@export var max_guesses: int = 3
@export var level_duration: float = 120.0
@export var wrong_guess_pause: float = 2.5
@export var poof_effect: PackedScene

@onready var level_label: Label = %LevelLabel

@onready var crowd_scene: Node3D = $Crowd
@onready var player: Player = $Player
@onready var level_timer: Timer = $LevelTimer
@onready var timer_label: Label = $CanvasLayer/Control/MarginContainer/VBoxContainer/TimerLabel
@onready var label: Label = $CanvasLayer/Control/MarginContainer/VBoxContainer/Label


#witch clue vars
@onready var witch = %WitchClues # no type on purpose, her script has no class name

# turn this on in the Inspector to test levels without the witch talking
@export var skip_witch_clues: bool = false

var witch_busy: bool = false # true while the witch is talking


@export var clue_labels: Array[Label]

@export var clue_icon_rects: Array[TextureRect]

# folder with the clue pictures, change this to wherever yours are saved
const CLUE_ICON_DIR := "res://assets/item photos/"

# mesh name and color for each clue, same order as clues
var clue_icons: Array[Dictionary] = []

@export var clue_panels: Array[Control]

# how many people should match clue 1 (the guest included). the level system will set these later
@export var clue1_min: int = 8
@export var clue1_max: int = 15

# icon that floats over wrong guesses. leave empty for the built in check mark,
# or drop an invitation image in here later
@export var guess_marker_texture: Texture2D
@export var marker_height: float = 2.6
# size in the world = image width in pixels times this number
@export var marker_pixel_size: float = 0.01


func _ready() -> void:
	print("TIMING game _ready at: ", Time.get_ticks_msec())
	level_label.text = ""

	# Force the AudioServer to match the AudioManager values right now
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Music"), not AudioManager.music_enabled)
	AudioServer.set_bus_mute(AudioServer.get_bus_index("SFX"), not AudioManager.sfx_enabled)
	
	
	# during a run, the level decides the clue 1 range and the time limit.
	# running the scene straight from the editor uses the Inspector values instead
	if GameState.run_active:
		var cfg = GameState.current_config()
		clue1_min = cfg.clue1_min
		clue1_max = cfg.clue1_max
		level_duration = cfg.time_limit
		level_label.text = "%s: Level %d of %d" % [cfg.difficulty.capitalize(), cfg.level_number, cfg.total_levels]

	player.ray_cast_3d.guess_submitted.connect(_on_guess_submitted)

	label.text = ""
	for clue_label in clue_labels:
		clue_label.text = ""
	for rect in clue_icon_rects:
		rect.texture = null
	for panel in clue_panels:
		panel.visible = false

	var t1: int = Time.get_ticks_msec()
	set_uninvited_guest()
	
	print("TIMING set_uninvited_guest: ", Time.get_ticks_msec() - t1, "ms")
	t1 = Time.get_ticks_msec()
	generate_clues()
	print("TIMING generate_clues: ", Time.get_ticks_msec() - t1, "ms")

	var t2: int = Time.get_ticks_msec()
	MusicPlayer.shuffle_play(-10.0)
	print("TIMING music start: ", Time.get_ticks_msec() - t2, "ms")

	level_timer.wait_time = level_duration
	level_timer.start()
	
	show_clue()

	await get_tree().process_frame
	await get_tree().process_frame
	%LoadingOverlay.hide()

var _first_frame_done: bool = false

func _process(delta: float) -> void:
	if not _first_frame_done:
		_first_frame_done = true
		print("TIMING first frame at: ", Time.get_ticks_msec())
	update_timer_display()


func update_timer_display() -> void:
	var time_left: float = level_timer.time_left
	timer_label.text = format_time(time_left)
	
	if time_left <= 12.1 and !clock_is_ticking:
		SfxPlayer.play_sfx("ticking_clock", 1.5)
		clock_is_ticking = true


func format_time(seconds: float) -> String:
	var minutes: int = floori(seconds / 60.0)
	var secs: int = int(seconds) % 60
	return "%d:%02d" % [minutes, secs]


func set_uninvited_guest() -> void:
	_build_phrase_table()

	var min1 := clue1_min
	var max1 := clue1_max
	var min_pool2 := 2
	var guest: CharacterBuilder = null
	var funnel: Array[String] = []

	for attempt in MAX_TRIES:
		if attempt == RELAX_PAIR_AFTER:
			min_pool2 = 1
		if attempt == RELAX_RANGE_AFTER:
			min1 = 1
			max1 = 40
		var idx: int = randi() % crowd_scene.guests.size()
		funnel = _find_funnel(idx, min1, max1, min_pool2)
		if not funnel.is_empty():
			guest = crowd_scene.guests[idx]
			if OS.is_debug_build():
				print("fair clues found on try ", attempt + 1)
			break

	if guest == null:
		push_warning("No fair clue set found, using fallback clues")
		guest = _pick_any_dressed_guest()
		funnel = _fallback_funnel(guest)

	uninvited_guest = guest
	funnel_keys = funnel
	crowd_scene.relocate(uninvited_guest)
	#uninvited_guest.ug_label.visible = true


func _matching(pool: Array, key, value) -> Array:
	var out: Array = []
	for i in pool:
		if suspect_phrases[i].get(key, "") == value:
			out.append(i)
	return out


func generate_clues() -> void:
	clues.clear()
	clue_icons.clear()
	var phrases := ClueText.phrases_for(uninvited_guest.look)
	for i in mini(funnel_keys.size(), max_guesses):
		var key: String = funnel_keys[i]
		clues.append(phrases[key])
		clue_icons.append(_icon_info_for(key))
	if OS.is_debug_build():
		_print_clue_debug(phrases)


func show_clue(delay: float = 0.0) -> void:
	if clues.is_empty():
		return
	if num_guesses < max_guesses:
		var phrase: String = clues.pop_front()
		var icon_info: Dictionary = clue_icons.pop_front()
		var index: int = num_guesses

		# this runs after the witch is done, not right away
		var reveal := func() -> void:
			clue_labels[index].text = "Clue #%d:" % (index + 1)
			if index < clue_panels.size():
				clue_panels[index].visible = true
			if index < clue_icon_rects.size():
				clue_icon_rects[index].texture = _get_clue_icon(icon_info["mesh"], icon_info["color"])

		_say_clue("This person is wearing %s." % phrase, delay, reveal)
	else:
		label.text = "NO MORE CLUES!"
		

# gets the mesh name and texture color for one of the guest's pieces
func _icon_info_for(key: String) -> Dictionary:
	var look: Dictionary = uninvited_guest.look
	var color := ""
	var tex: int = look.get(key + "texture", -1)
	if tex >= 0 and tex < ClueText.TEXTURE_COLORS.size():
		color = ClueText.TEXTURE_COLORS[tex]
	return {"mesh": str(look[key]).to_lower(), "color": color}


# the game's color word on the left, how your files spell it on the right
# (anything not listed here just gets capitalized, so "green" becomes "Green")
const COLOR_FILE_NAMES := {"blue": "LightBlue"}


func _get_clue_icon(mesh: String, color: String) -> Texture2D:
	var paths: Array[String] = []
	if color != "":
		var color_name: String = COLOR_FILE_NAMES.get(color, color.capitalize())
		paths.append("%s%s_%s_texture.png" % [CLUE_ICON_DIR, mesh, color_name])
	paths.append("%s%s.png" % [CLUE_ICON_DIR, mesh])
	for path in paths:
		if ResourceLoader.exists(path):
			return load(path)
	push_warning("No clue icon found for: " + mesh)
	return null


func _on_guess_submitted(character: CharacterBuilder) -> void:
	if level_over or witch_busy:
		return

	# already picked this person, so it doesn't cost a guess
	if wrong_guesses.has(character):
		label.text = "ALREADY GUESSED!"
		await get_tree().create_timer(1.0).timeout
		if not level_over:
			label.text = ""
		return

	if character == uninvited_guest:
		level_over = true
		_freeze_player()
		GameState.ravers_bounced += 1
		level_timer.paused = true
		SfxPlayer.stop_sfx("ticking_clock")
		MusicPlayer.stop()

		label.text = "CAUGHT THEM!"
		SfxPlayer.play_sfx("right_answer", 2.0)
		await get_tree().create_timer(1.5).timeout

		var new_effect = poof_effect.instantiate()
		add_child(new_effect)
		new_effect.global_position = character.global_position
		character.queue_free()

		SfxPlayer.play_sfx("witch_cackle", 5.0)
		SfxPlayer.play_sfx("fire_spell", -1.0)

		# straight on to the next level (or the end screen after the last one)
		await get_tree().create_timer(2.0).timeout
		_finish_level_won()
		return

	wrong_guesses.append(character)
	add_guess_marker(character)
	label.text = "Hey! I was invited!"
	SfxPlayer.play_sfx("wrong_answer")
	num_guesses += 1

	# that was the last guess
	if num_guesses >= max_guesses:
		_lose_level("OUT OF GUESSES!", "guesses")
		return

	show_clue(wrong_guess_pause)
	await get_tree().create_timer(wrong_guess_pause).timeout
	if not level_over:
		label.text = ""

# works out what everyone in the crowd is wearing, once
func _build_phrase_table() -> void:
	suspect_phrases.clear()
	for g in crowd_scene.guests:
		suspect_phrases.append(ClueText.phrases_for(g.look))


# how many people (the guest included) match every phrase in wanted
func _pool_size(wanted: Dictionary) -> int:
	var n := 0
	for phrases in suspect_phrases:
		var all_match := true
		for key in wanted:
			if phrases.get(key, "") != wanted[key]:
				all_match = false
				break
		if all_match:
			n += 1
	return n


# looks for three clues for this guest where
#   clue 1 is easy to see and matches between min1 and max1 people
#   clue 2 shrinks that group but (normally) doesn't finish it
#   clue 3 leaves only the guest
# returns the keys in order, or an empty list if this guest can't do it
func _find_funnel(idx: int, min1: int, max1: int, min_pool2: int) -> Array[String]:
	var result: Array[String] = []
	var options: Dictionary = suspect_phrases[idx]
	var keys := options.keys()
	var everyone: Array = range(suspect_phrases.size())

	for k1 in keys:
		if not VISIBLE_KEYS.has(str(k1)):
			continue
		var pool1 := _matching(everyone, k1, options[k1])
		var size1 := pool1.size()
		if size1 < min1 or size1 > max1:
			continue

		for k2 in keys:
			if k2 == k1:
				continue
			var pool2 := _matching(pool1, k2, options[k2])
			var size2 := pool2.size()
			if size2 < min_pool2 or size2 >= size1:
				continue

			for k3 in keys:
				if k3 == k1 or k3 == k2:
					continue
				if _matching(pool2, k3, options[k3]).size() == 1:
					result.append(str(k1))
					result.append(str(k2))
					result.append(str(k3))
					return result
	return result


func _pick_any_dressed_guest() -> CharacterBuilder:
	var order: Array = range(crowd_scene.guests.size())
	order.shuffle()
	for i in order:
		if not suspect_phrases[i].is_empty():
			return crowd_scene.guests[i]
	return crowd_scene.guests[order[0]]


# plain backup: visible pieces first, then the rest, no promise it narrows fairly
func _fallback_funnel(guest: CharacterBuilder) -> Array[String]:
	var options := ClueText.phrases_for(guest.look)
	var visible: Array[String] = []
	var rest: Array[String] = []
	for key in options:
		if VISIBLE_KEYS.has(str(key)):
			visible.append(str(key))
		else:
			rest.append(str(key))
	visible.shuffle()
	rest.shuffle()
	var out: Array[String] = []
	out.append_array(visible)
	out.append_array(rest)
	return out


# shows how many people match after each clue, so you can check the levels while playtesting
func _print_clue_debug(phrases: Dictionary) -> void:
	var wanted := {}
	var steps: Array[String] = []
	for i in mini(funnel_keys.size(), max_guesses):
		wanted[funnel_keys[i]] = phrases[funnel_keys[i]]
		steps.append("%s = %d left" % [phrases[funnel_keys[i]], _pool_size(wanted)])
	print("clue funnel: ", "  |  ".join(PackedStringArray(steps)))

func add_guess_marker(character: CharacterBuilder) -> void:
	if guess_marker_texture == null and _check_texture == null:
		_check_texture = _make_check_texture()

	var marker := Sprite3D.new()
	marker.texture = guess_marker_texture if guess_marker_texture != null else _check_texture
	marker.billboard = BaseMaterial3D.BILLBOARD_ENABLED # always faces the player
	marker.pixel_size = marker_pixel_size
	marker.no_depth_test = true # still visible when other characters stand in front
	marker.shaded = false
	character.add_child(marker)
	marker.global_position = character.global_position + Vector3.UP * marker_height


# draws a green check mark so no image file is needed
func _make_check_texture() -> ImageTexture:
	var size := 128
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var p1 := Vector2(24, 68)
	var p2 := Vector2(52, 98)
	var p3 := Vector2(104, 30)
	_draw_thick_line(img, p1, p2, 9.0)
	_draw_thick_line(img, p2, p3, 9.0)
	return ImageTexture.create_from_image(img)


func _draw_thick_line(img: Image, a: Vector2, b: Vector2, radius: float) -> void:
	for y in img.get_height():
		for x in img.get_width():
			var p := Vector2(x, y)
			var closest := Geometry2D.get_closest_point_to_segment(p, a, b)
			var alpha := clampf(radius + 1.0 - p.distance_to(closest), 0.0, 1.0)
			if alpha > img.get_pixel(x, y).a:
				img.set_pixel(x, y, Color(0.2, 0.85, 0.3, alpha))


func _on_level_timer_timeout() -> void:
	_lose_level("TIME'S UP!", "time")


# the second line shown under the message, depending on how you lost
const FAIL_LINES := {
	"guesses": "They crashed your party!",
	"time": "The party's been crashed!",
}

func _lose_level(message: String, reason: String) -> void:
	if level_over:
		return
	level_over = true
	_freeze_player()
	level_timer.paused = true # using pause instead of stop() to avoid ticking clock sfx playing when not actual countdown
	MusicPlayer.stop()

	if reason == "guesses":
		# "Hey! I was invited!" and the envelope are already showing, so let them be seen first
		await get_tree().create_timer(1.8).timeout
	else:
		label.text = message
		SfxPlayer.play_sfx("death_clock", 3.0)
		await get_tree().create_timer(1.0).timeout

	label.text = message
	if reason == "guesses":
		SfxPlayer.play_sfx("death_clock", 3.0)

	await _zoom_to_guest()
	_highlight_guest()
	label.text = message + "\n" + FAIL_LINES.get(reason, "You failed!")

	await get_tree().create_timer(3.0).timeout
	_go_to_end_screen(reason)


func _finish_level_won() -> void:
	# not in a run (scene started from the editor), so just start over
	if not GameState.run_active:
		get_tree().reload_current_scene()
		return

	if GameState.has_next_level():
		GameState.advance()
		var tree := get_tree()
		%LoadingOverlay.show()
		await tree.process_frame
		await tree.process_frame
		tree.reload_current_scene()
		return

	# that was the last level of the last difficulty
	_go_to_end_screen("cleared")


# the one place a run ends: "cleared", "time", or "guesses"
func _go_to_end_screen(reason: String) -> void:
	GameState.end_run(reason)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE # the end screen has buttons to click
	if win_scene_path.is_empty():
		push_warning("Set Win Scene Path on the Game node")
		return

	var tree := get_tree()
	%LoadingOverlay.show()
	await tree.process_frame
	await tree.process_frame
	tree.change_scene_to_file(win_scene_path)

# the witch says a clue while the clock is held and the player can't move or guess
func _say_clue(text: String, delay: float = 0.0, on_reveal: Callable = Callable()) -> void:
	if skip_witch_clues:
		if on_reveal.is_valid():
			on_reveal.call()
		return

	witch_busy = true
	level_timer.paused = true
	_freeze_player()

	if delay > 0.0:
		await get_tree().create_timer(delay).timeout

	await witch.give_clue(text)

	if on_reveal.is_valid():
		on_reveal.call()

	witch_busy = false
	if not level_over:
		level_timer.paused = false
		_unfreeze_player()


func _freeze_player() -> void:
	player.set_physics_process(false) # stops walking and looking around
	player.set_process(false) # stops zooming
	player.ray_cast_3d.set_process(false) # stops the highlight and selecting


func _unfreeze_player() -> void:
	player.mouse_motion = Vector2.ZERO # drops any mouse movement stored while frozen
	player.set_physics_process(true)
	player.set_process(true)
	player.ray_cast_3d.set_process(true)
	
func _highlight_guest() -> void:
	player.ray_cast_3d.clear_target()
	if is_instance_valid(uninvited_guest):
		uninvited_guest.enable_outline()

# which way the character models face. try false if you end up looking at the back of their head
const GUEST_FACES_NEG_Z := false


func _zoom_to_guest(duration: float = 1.5) -> void:
	var cam := get_viewport().get_camera_3d()
	if cam == null or not is_instance_valid(uninvited_guest):
		return

	var start_xform: Transform3D = cam.global_transform
	var start_fov: float = cam.fov

	var zoom_cam := Camera3D.new()
	add_child(zoom_cam)
	zoom_cam.global_transform = start_xform
	zoom_cam.fov = start_fov
	zoom_cam.make_current()

	var step := func(t: float) -> void:
		if not is_instance_valid(uninvited_guest):
			return
		var front: Vector3 = uninvited_guest.global_basis.z
		if GUEST_FACES_NEG_Z:
			front = -front
		front.y = 0.0
		front = front.normalized()

		var target: Vector3 = uninvited_guest.global_position + Vector3.UP * 1.0
		var end_pos: Vector3 = target + front * 4.0 + Vector3.UP * 0.3
		var end_xform := Transform3D(Basis(), end_pos).looking_at(target, Vector3.UP)

		zoom_cam.global_transform = start_xform.interpolate_with(end_xform, t)
		zoom_cam.fov = lerpf(start_fov, 45.0, t)

	var tween := create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_method(step, 0.0, 1.0, duration)
	await tween.finished
