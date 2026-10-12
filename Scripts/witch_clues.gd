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
	if event is InputEventKey and event.pressed and not event.echo:
		if not pause_timer.is_stopped():
			pause_timer.stop()
			pause_timer.timeout.emit()


# how long a clue stays up after it finishes typing
var clue_pause_duration: float = 3.0

var clue_openers: Array[String] = [
	"Hmm, yes. I'm seeing something . . .",
	"The spirits whisper . . .",
	"Ah, I sense it . . .",
	"The veil parts . . .",
]


# pops up, says one clue, and pops back out. game.gd waits for this to finish
func give_clue(clue_text: String) -> void:
	visible = true
	pause_timer.wait_time = clue_pause_duration
	pop_in()
	await get_tree().create_timer(0.5).timeout

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
	
	var tween = create_tween()
	await tween.tween_property(text_label, "visible_ratio", 1.0, typewriter_speed).finished
	pause_timer.start()
	text_printed.emit()


func pop_in() -> void:
	var witch_tween = create_tween()
	witch_tween.set_ease(Tween.EASE_OUT)
	witch_tween.set_trans(Tween.TRANS_SPRING)
	
	witch_tween.tween_property(black_witch_portrait, "position", witch_end_pos, pop_in_duration).from(witch_start_pos)
	
	var text_tween = create_tween()
	text_tween.set_ease(Tween.EASE_OUT)
	text_tween.set_trans(Tween.TRANS_SPRING)
	
	text_tween.tween_property(text_box, "position", text_box_end_pos, pop_in_duration).from(text_box_start_pos)


func pop_out() -> void:
	var witch_tween = create_tween()
	witch_tween.set_ease(Tween.EASE_OUT)
	witch_tween.set_trans(Tween.TRANS_CUBIC)
	
	witch_tween.tween_property(black_witch_portrait, "position", witch_start_pos, pop_out_duration)
	
	var text_tween = create_tween()
	text_tween.set_ease(Tween.EASE_OUT)
	text_tween.set_trans(Tween.TRANS_CUBIC)
	
	text_tween.tween_property(text_box, "position", text_box_start_pos, pop_out_duration)
