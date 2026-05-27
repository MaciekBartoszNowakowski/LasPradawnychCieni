extends Node

var player_team: Team


func _ready() -> void:
	reset_game()


func reset_game() -> void:
	player_team = Team.new()


func ensure_team_exists() -> void:
	if player_team == null:
		player_team = Team.new()


func apply_sidequest_choice(choice: SideQuestChoiceConfig) -> void:
	if choice == null:
		return

	ensure_team_exists()

	add_money(choice.gold_delta)
	apply_team_life_delta(choice.health_delta)


func add_money(amount: int) -> void:
	ensure_team_exists()
	player_team.add_money(amount)


func spend_money(amount: int) -> bool:
	ensure_team_exists()
	return player_team.spend_money(amount)


func apply_team_life_delta(amount: int) -> int:
	ensure_team_exists()
	return player_team.apply_life_delta_to_all(amount)


func heal_team(amount: int) -> int:
	ensure_team_exists()
	return player_team.heal_all(amount)


func damage_team(amount: int) -> int:
	ensure_team_exists()
	return player_team.damage_all(amount)


func heal_team_missing_percent(percent: float) -> int:
	ensure_team_exists()
	return player_team.heal_all_missing_percent(percent)
