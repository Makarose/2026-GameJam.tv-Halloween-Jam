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
	
	"I can't have random wierdos spoiling the vibe. I need you to patrol throughout the night and pick out the uninvited. And I need you to do it as quickly as possible.",
	
	"It's a costume party, of course, so there's no way to tell by sight who doesn't belong. You'll have to guess. But don't worry, I will use my prodigious talents as a clairvoyant to give you clues.",
	
	"You'll have a limited amount of time to find the intruder, at which point I will . . . deal with them.",
	
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
	
	await get_tree().create_timer(1.0).timeout
	play_startup("This person is wearing hot pink leather chaps.")


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if not pause_timer.is_stopped():
			pause_timer.stop()
			pause_timer.timeout.emit()


# this should be called via the game script at the start of the game. _clue argument should be the
# first element in the clues array, so that it's the same as the first one to show on screen during game
func play_startup(_clue: String) -> void:
	var first_clue_text: String = "Hmm, yes. I'm seeing something . . ." + _clue
	start_dialogue.append(first_clue_text)
	
	pop_in()
	await get_tree().create_timer(0.5).timeout
	
	for line in start_dialogue:
		print_text(line)
		await text_printed
		await pause_timer.timeout
	
	await get_tree().create_timer(1.0).timeout
	pop_out()


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
