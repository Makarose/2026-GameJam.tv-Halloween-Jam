extends CanvasLayer


@export var witch_start_pos: Vector2
@export var witch_end_pos: Vector2
@export var text_box_start_pos: Vector2
@export var text_box_end_pos: Vector2

var pop_in_duration: float = 0.4
var pop_out_duration: float = 0.25

@onready var text_box: Control = $Control/TextBox
@onready var text_label: Label = $Control/TextBox/TextLabel
@onready var black_witch_portrait: TextureRect = $Control/BlackWitchPortrait


func _ready() -> void:
	pop_in()
	await get_tree().create_timer(1.0).timeout
	pop_out()


func _process(delta: float) -> void:
	pass


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
