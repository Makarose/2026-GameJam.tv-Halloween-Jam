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

@export var max_guesses: int = 3
@export var level_duration: float = 120.0
@export var poof_effect: PackedScene



@onready var crowd_scene: Node3D = $Crowd
@onready var player: Player = $Player
@onready var level_timer: Timer = $LevelTimer
@onready var timer_label: Label = $CanvasLayer/Control/MarginContainer/VBoxContainer/TimerLabel
@onready var label: Label = $CanvasLayer/Control/MarginContainer/VBoxContainer/Label
@export var clue_labels: Array[Label]

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
	player.ray_cast_3d.guess_submitted.connect(_on_guess_submitted)
	
	label.text = ""
	for clue_label in clue_labels:
		clue_label.text = ""
	
	set_uninvited_guest()
	generate_clues()
	show_clue()
	
	MusicPlayer.shuffle_play(-10.0)
	
	level_timer.wait_time = level_duration
	level_timer.start()


func _process(delta: float) -> void:
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
	return "%02d:%02d" % [minutes, secs]


func set_uninvited_guest() -> void:
	_build_phrase_table()

	var min1 := clue1_min
	var max1 := clue1_max
	var min_pool2 := 2
	var guest: CharacterBuilder = null
	var funnel: Array[String] = []

	# keep testing random guests until one has clues that narrow the crowd down fairly
	for attempt in MAX_TRIES:
		if attempt == RELAX_PAIR_AFTER:
			min_pool2 = 1
		if attempt == RELAX_RANGE_AFTER:
			min1 = 1
			max1 = 40
		var candidate: CharacterBuilder = crowd_scene.guests.pick_random()
		funnel = _find_funnel(candidate, min1, max1, min_pool2)
		if not funnel.is_empty():
			guest = candidate
			print("fair clues found on try ", attempt + 1)
			break

	# nothing fair was found, so the level still starts with plain clues
	if guest == null:
		push_warning("No fair clue set found, using fallback clues")
		guest = _pick_any_dressed_guest()
		funnel = _fallback_funnel(guest)

	uninvited_guest = guest
	funnel_keys = funnel
	crowd_scene.relocate(uninvited_guest)
	uninvited_guest.ug_label.visible = true


func generate_clues() -> void:
	clues.clear()
	var phrases := ClueText.phrases_for(uninvited_guest.look)
	for i in mini(funnel_keys.size(), max_guesses):
		clues.append("This person is wearing %s." % phrases[funnel_keys[i]])
	_print_clue_debug(phrases)


func show_clue() -> void:
	if clues.is_empty():	#addeed during new func generate_clues
		return
	if num_guesses < max_guesses:
				clue_labels[num_guesses].text = clues.pop_front()
	else:
		label.text = "NO MORE CLUES!"


func _on_guess_submitted(character: CharacterBuilder) -> void:
	# already picked this person, so it doesn't cost a guess
	if wrong_guesses.has(character):
		label.text = "ALREADY GUESSED!"
		await get_tree().create_timer(1.0).timeout
		label.text = ""
		return
		
	if character == uninvited_guest:
		level_timer.paused = true
		MusicPlayer.stop()
		
		label.text = "CORRECT!"
		SfxPlayer.play_sfx("right_answer", 2.0)
		await get_tree().create_timer(1.5).timeout
		
		var new_effect = poof_effect.instantiate()
		add_child(new_effect)
		new_effect.global_position = character.global_position
		character.queue_free()
		
		SfxPlayer.play_sfx("witch_cackle", 5.0)
		SfxPlayer.play_sfx("fire_spell", -1.0)
	else:
		wrong_guesses.append(character)
		add_guess_marker(character)
		label.text = "WRONG!"
		SfxPlayer.play_sfx("wrong_answer")
		num_guesses += 1
		show_clue()
	
	await get_tree().create_timer(1.0).timeout
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
func _find_funnel(guest: CharacterBuilder, min1: int, max1: int, min_pool2: int) -> Array[String]:
	var result: Array[String] = []
	var options := ClueText.phrases_for(guest.look)
	var keys := options.keys()

	for k1 in keys:
		if not VISIBLE_KEYS.has(str(k1)):
			continue
		var first := {k1: options[k1]}
		var pool1 := _pool_size(first)
		if pool1 < min1 or pool1 > max1:
			continue

		for k2 in keys:
			if k2 == k1:
				continue
			var second := first.duplicate()
			second[k2] = options[k2]
			var pool2 := _pool_size(second)
			if pool2 < min_pool2 or pool2 >= pool1:
				continue

			for k3 in keys:
				if k3 == k1 or k3 == k2:
					continue
				var third := second.duplicate()
				third[k3] = options[k3]
				if _pool_size(third) == 1:
					result.append(str(k1))
					result.append(str(k2))
					result.append(str(k3))
					return result
	return result


func _pick_any_dressed_guest() -> CharacterBuilder:
	var pool: Array = crowd_scene.guests.duplicate()
	pool.shuffle()
	for g in pool:
		if not ClueText.phrases_for(g.look).is_empty():
			return g
	return pool[0]


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
	marker.position = Vector3(0.0, marker_height, 0.0)
	character.add_child(marker)


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
	label.text = "TIME'S UP!"
	SfxPlayer.play_sfx("death_clock", 3.0)
	MusicPlayer.stop()
