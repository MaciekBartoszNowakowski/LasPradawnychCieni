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
	_connect_team()
	_refresh_gold()


func setup(title: String, objective: String) -> void:
	title_text = title
	objective_text = objective
	_apply_texts()
	_refresh_gold()


func _apply_texts() -> void:
	title_label.text = title_text
	objective_label.text = objective_text
	gold_label.visible = show_gold


func _connect_team() -> void:
	if GameState.player_team == null:
		return
	
	if not GameState.player_team.money_changed.is_connected(_on_team_money_changed):
		GameState.player_team.money_changed.connect(_on_team_money_changed)


func _refresh_gold() -> void:
	if not show_gold:
		return
	
	if GameState.player_team == null:
		gold_label.text = "Złoto: 0"
		return
	
	gold_label.text = "Złoto: " + str(GameState.player_team.money)


func _on_team_money_changed(new_money: int) -> void:
	if show_gold:
		gold_label.text = "Złoto: " + str(new_money)
