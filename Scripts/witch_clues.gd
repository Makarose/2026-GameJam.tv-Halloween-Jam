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

var start_dialogue: Array[String] = [
	"Why hello there. I bet you're wondering why I've summoned you. I'm having a party tonight, and I have a job for you.",
	
	"I'm having several hundred of my closest friends over for my annual world-famous grave rave. I'm sure you've heard of, it even beyond the veil?",
	
	"No? Well, I guess you probably don't get out much. It doesn't matter. The important thing is, it's a highly exclusive party and there are always crashers.",
	
	"I can't have random wierdos spoiling the vibe. I need you to patrol throughout the night and pick out the uninvited guests. And I need you to do it as quickly as possible.",
	
	"It's a costume party, of course, so there's no way to tell by sight who doesn't belong. You'll have to guess. But don't worry, I will use my prodigious talents as a clairvoyant to give you clues.",
	
	"You'll have a limited amount of time to find the intruders, at which point I will . . . deal with them.",
	
	"But if you don't find them when the time runs out, it's back to the nether realms with you. I have no patience for incompetence, especially in the spirit world.",
	
	"Oh, right -- you probably don't have much practice moving around, having just arrived in the earthly dimension. Use your WASD or arrows keys to move forwards, backwards, and side-to-side.",
	
	"Use the mouse to look around. Your left mouse button will zoom in to aid in your search. And when you're ready to make a guess, right-click on the highlighted guest and test your luck.",
	
	"Well, that should just about do it. Do well tonight, and I may just grant you a permanent existence here. Now, to get you started . . . here's your first clue:"
]

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
