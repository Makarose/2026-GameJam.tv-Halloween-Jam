#witch's clue copy of dialog - clues only

extends CanvasLayer

signal text_printed


@export var witch_start_pos: Vector2
@export var witch_end_pos: Vector2
@export var text_box_start_pos: Vector2
@export var text_box_end_pos: Vector2

var pop_in_duration: float = 0.4
var pop_out_duration: float = 0.25
var text_pause_duration: float = 5.0

var skip_locked: bool = false # true while a line must be read

var text_tween: Tween

@onready var text_box: Control = $Control/TextBox
@onready var text_label: Label = $Control/TextBox/TextLabel
@onready var black_witch_portrait: TextureRect = $Control/BlackWitchPortrait
@onready var pause_timer: Timer = $PauseTimer


func _ready() -> void:
	black_witch_portrait.position = witch_start_pos
	text_box.position = text_box_start_pos
	text_label.text = ""
	pause_timer.wait_time = text_pause_duration
	visible = false


func _input(event: InputEvent) -> void:
	if skip_locked:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if not pause_timer.is_stopped():
			pause_timer.stop()
			pause_timer.timeout.emit()
		else: # this one skips the typewriter effect and displays all the text at once
			if text_tween and text_tween.is_running():
				SfxPlayer.play_sfx("church_bell", -8.0)
				text_tween.kill()
				text_label.visible_ratio = 1.0
				_on_text_printed()


# how long a clue stays up after it finishes typing
var clue_pause_duration: float = 3.0

var clue_openers: Array[String] = [
	"Hmm, yes. I'm seeing something . . .",
	"The spirits whisper . . .",
	"Ah, I sense it . . .",
	"The veil parts . . .",
]


func give_clue(clue_text: String, intro_line: String = "") -> void:
	visible = true
	pause_timer.wait_time = clue_pause_duration
	pop_in()
	await get_tree().create_timer(0.5).timeout

	# optional tier announcement, same pop in, no clue opener
	if intro_line != "":
		var words := intro_line.split(" ").size()
		skip_locked = true
		pause_timer.wait_time = maxf(6.0, words * 0.4) # auto moves on if nobody presses a key
		print_text(intro_line)
		await text_printed
		# keys stay locked for a short read time after the typing finishes
		await get_tree().create_timer(maxf(2.5, words * 0.15)).timeout
		skip_locked = false
		await pause_timer.timeout # now any key press skips ahead
		pause_timer.stop()
		pause_timer.wait_time = clue_pause_duration

	print_text(clue_openers.pick_random() + " " + clue_text)
	await text_printed
	await pause_timer.timeout # any key press skips this wait, from his _input
	pause_timer.stop()

	pop_out()
	text_label.text = "" # clear out the text from the clue that was just given
	await get_tree().create_timer(pop_out_duration).timeout
	visible = false


func print_text(_text: String) -> void:
	text_label.text = _text
	text_label.visible_ratio = 0.0
	
	var character_count: int = text_label.get_total_character_count()
	var typewriter_speed: float = character_count / 30.0
	
	text_tween = create_tween()
	await text_tween.tween_property(text_label, "visible_ratio", 1.0, typewriter_speed).finished
	_on_text_printed()


func _on_text_printed() -> void:
	pause_timer.start()
	text_printed.emit()


func pop_in() -> void:
	SfxPlayer.play_sfx("whoosh", 9.0)
	SfxPlayer.play_sfx("frustrated_goblin", -5.0)
	
	var witch_tween = create_tween()
	witch_tween.set_ease(Tween.EASE_OUT)
	witch_tween.set_trans(Tween.TRANS_SPRING)
	
	witch_tween.tween_property(black_witch_portrait, "position", witch_end_pos, pop_in_duration).from(witch_start_pos)
	
	var dialogue_box_tween = create_tween()
	dialogue_box_tween.set_trans(Tween.TRANS_SPRING)
	dialogue_box_tween.set_ease(Tween.EASE_OUT)
	
	dialogue_box_tween.tween_property(text_box, "position", text_box_end_pos, pop_in_duration).from(text_box_start_pos)


func pop_out() -> void:
	SfxPlayer.play_sfx("whoosh", 9.0)
	#SfxPlayer.play_sfx("closing_bell", 3.0)
	SfxPlayer.play_sfx("whoop", -3.0)
	
	var witch_tween = create_tween()
	witch_tween.set_ease(Tween.EASE_OUT)
	witch_tween.set_trans(Tween.TRANS_CUBIC)
	
	witch_tween.tween_property(black_witch_portrait, "position", witch_start_pos, pop_out_duration)
	
	var dialogue_box_tween = create_tween()
	dialogue_box_tween.set_ease(Tween.EASE_OUT)
	dialogue_box_tween.set_trans(Tween.TRANS_CUBIC)
	
	dialogue_box_tween.tween_property(text_box, "position", text_box_start_pos, pop_out_duration)
