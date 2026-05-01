extends Control
class_name GameTopBar

@export var title_text: String = ""
@export var objective_text: String = ""
@export var show_gold: bool = true

@onready var title_label: Label = $MarginContainer/HBoxContainer/LeftBlock/TitleLabel
@onready var objective_label: Label = $MarginContainer/HBoxContainer/CenterBlock/ObejctiveLabel
@onready var gold_label: Label = $MarginContainer/HBoxContainer/RightBlock/GoldLabel


func _ready() -> void:
	_apply_texts()


func setup(title: String, objective: String, gold: int = -1) -> void:
	title_text = title
	objective_text = objective

	if gold >= 0:
		show_gold = true
		gold_label.text = "Złoto: " + str(gold)

	_apply_texts()


func _apply_texts() -> void:
	title_label.text = title_text
	objective_label.text = objective_text

	gold_label.visible = show_gold

	if show_gold:
		gold_label.text = "Złoto: " + str(0);
