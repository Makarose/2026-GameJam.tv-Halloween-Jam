extends Node3D

const texture_colors: Array[String] = ["black", "brown", "green", "blue", "orange", "pink", "purple", "red", "white", "yellow"]

var uninvited_guest: CharacterBuilder
var clues: Array[String] = []
var num_guesses: int = 0
var clock_is_ticking: bool = false

@export var max_guesses: int = 3
@export var level_duration: float = 120.0
@export var poof_effect: PackedScene

@onready var crowd_scene: Node3D = $Crowd
@onready var player: Player = $Player
@onready var level_timer: Timer = $LevelTimer
@onready var timer_label: Label = $CanvasLayer/Control/MarginContainer/VBoxContainer/TimerLabel
@onready var label: Label = $CanvasLayer/Control/MarginContainer/VBoxContainer/Label
@export var clue_labels: Array[Label]


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
	uninvited_guest = crowd_scene.guests.pick_random()
	uninvited_guest.ug_label.visible = true


func generate_clues() -> void:
	for key in uninvited_guest.look:
		var key_name := str(key)
		if key_name.ends_with("_texture"):
			continue # these hold color numbers, not pieces

		# pieces with a texture entry (pants, tops) get their color added
		var color := ""
		var texture_key := key_name + "texture"
		if uninvited_guest.look.has(texture_key):
			color = texture_colors[uninvited_guest.look[texture_key]]

		var phrase := ClueText.describe(str(uninvited_guest.look[key]), color)
		if not phrase.is_empty():
			clues.append("This person is wearing %s." % phrase)


func show_clue() -> void:
	if clues.is_empty():	#addeed during new func generate_clues
		return
	if num_guesses < max_guesses:
		var next_clue = clues.pick_random()
		clue_labels[num_guesses].text = next_clue
		clues.erase(next_clue)
	else:
		label.text = "NO MORE CLUES!"


func _on_guess_submitted(character: CharacterBuilder) -> void:
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
		label.text = "WRONG!"
		SfxPlayer.play_sfx("wrong_answer")
		num_guesses += 1
		show_clue()
	
	await get_tree().create_timer(1.0).timeout
	label.text = ""


func _on_level_timer_timeout() -> void:
	label.text = "TIME'S UP!"
	SfxPlayer.play_sfx("death_clock", 3.0)
	MusicPlayer.stop()
