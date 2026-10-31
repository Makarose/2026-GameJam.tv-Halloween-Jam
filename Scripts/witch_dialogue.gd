extends CanvasLayer


signal text_printed
signal intro_complete

@export var witch_start_pos: Vector2
@export var witch_end_pos: Vector2
@export var text_box_start_pos: Vector2
@export var text_box_end_pos: Vector2

var pop_in_duration: float = 0.4
var pop_out_duration: float = 0.25
var text_pause_duration: float = 5.0

var text_tween: Tween

var start_dialogue: Array[String] = [
	"Why hello there. I bet you're wondering why I've summoned you. I'm having a party tonight, and I have a job for you.",
	
	"I'm having several hundred of my closest friends over for my annual world-famous grave rave. I'm sure you've heard of, it even beyond the veil?",
	
	"No? Well, I guess you probably don't get out much. It doesn't matter. The important thing is, it's a highly exclusive party and there are always crashers.",
	
	"I can't have random wierdos spoiling the vibe. I need you to patrol throughout the night and pick out the uninvited guests. And I need you to do it as quickly as possible.",
	
	"It's a costume party, of course, so there's no way to tell by sight who doesn't belong. You'll have to guess. But don't worry, I will use my prodigious talents as a clairvoyant to give you clues.",
	
	"You'll have a limited amount of time to find the intruders, at which point I will . . . deal with them.",
	
	"But if you don't find them when the time runs out, or use too many guesses, it's back to the nether realms with you. I have no patience for incompetence, especially in the spirit world.",
	
	"Oh, right -- you probably don't have much practice moving around, having just arrived in the earthly dimension. Use your WASD or arrow keys to move forwards, backwards, and side-to-side.",
	
	"Use the mouse to look around. Your right mouse button will zoom in to aid in your search. And when you're ready to make a guess, left-click on the highlighted guest and test your luck.",
	
	"Well, that should just about do it. Do well tonight, and I may even grant you a permanent existence here. Now, let's party."
]

@onready var text_box: Control = $Control/TextBox
@onready var text_label: Label = $Control/TextBox/TextLabel
@onready var skip_label: Label = $Control/SkipLabel
@onready var black_witch_portrait: TextureRect = $Control/BlackWitchPortrait
@onready var pause_timer: Timer = $PauseTimer
@onready var panel: Panel = $Control/Panel


func _ready() -> void:
	black_witch_portrait.position = witch_start_pos
	text_box.position = text_box_start_pos
	text_label.text = ""
	skip_label.modulate.a = 0.0
	panel.modulate.a = 0.0
	pause_timer.wait_time = text_pause_duration
	
	#await get_tree().create_timer(1.0).timeout
	#play_startup()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if Input.is_action_just_pressed("skip"): # this one skips the entire intro
			pop_out()
			skip_label.visible = false
			await fade_out_bg()
			intro_complete.emit()
		elif not pause_timer.is_stopped(): # this one skips to the next line of text if the previous is already finished
			pause_timer.stop()
			pause_timer.timeout.emit()
		else: # this one skips the typewriter effect and displays all the text at once
			if text_tween and text_tween.is_running():
				SfxPlayer.play_sfx("church_bell", -8.0)
				text_tween.kill()
				text_label.visible_ratio = 1.0
				_on_text_printed()


func play_startup(_clue: String = "") -> void:
	#var first_clue_text: String = "Hmm, yes. I'm seeing something . . ." + _clue
	#start_dialogue.append(first_clue_text)
	text_box.show()
	
	var panel_tween = create_tween()
	panel_tween.set_ease(Tween.EASE_OUT)
	panel_tween.set_trans(Tween.TRANS_CUBIC)
	panel_tween.tween_property(panel, "modulate:a", 1.0, 0.5)
	
	pop_in()
	await get_tree().create_timer(0.5).timeout
	
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(skip_label, "modulate:a", 1.0, 2.0)
	
	for line in start_dialogue:
		print_text(line)
		await text_printed
		await pause_timer.timeout
	
	await get_tree().create_timer(1.0).timeout
	pop_out()
	skip_label.visible = false
	await fade_out_bg()
	
	intro_complete.emit()


func fade_out_bg() -> void:
	var panel_tween = create_tween()
	panel_tween.set_ease(Tween.EASE_OUT)
	panel_tween.set_trans(Tween.TRANS_CUBIC)
	await panel_tween.tween_property(panel, "modulate:a", 0.0, 2.0).finished


func print_text(_text: String) -> void:
	text_tween = null
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
	SfxPlayer.play_sfx("door_bell")
	
	var witch_tween = create_tween()
	witch_tween.set_ease(Tween.EASE_OUT)
	witch_tween.set_trans(Tween.TRANS_SPRING)
	
	witch_tween.tween_property(black_witch_portrait, "position", witch_end_pos, pop_in_duration).from(witch_start_pos)
	
	var dialogue_box_tween = create_tween()
	dialogue_box_tween.set_ease(Tween.EASE_OUT)
	dialogue_box_tween.set_trans(Tween.TRANS_SPRING)
	
	dialogue_box_tween.tween_property(text_box, "position", text_box_end_pos, pop_in_duration).from(text_box_start_pos)


func pop_out() -> void:
	MusicPlayer.fade_out(0.5)
	SfxPlayer.play_sfx("whoosh", 9.0)
	SfxPlayer.play_sfx("party_guitar")
	
	var witch_tween = create_tween()
	witch_tween.set_ease(Tween.EASE_OUT)
	witch_tween.set_trans(Tween.TRANS_CUBIC)
	
	witch_tween.tween_property(black_witch_portrait, "position", witch_start_pos, pop_out_duration)
	
	var dialogue_box_tween = create_tween()
	dialogue_box_tween.set_ease(Tween.EASE_OUT)
	dialogue_box_tween.set_trans(Tween.TRANS_CUBIC)
	
	dialogue_box_tween.tween_property(text_box, "position", text_box_start_pos, pop_out_duration)
	dialogue_box_tween.tween_callback(text_box.hide)
