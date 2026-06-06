extends Node

var player_team: Team


func _ready() -> void:
	reset_game()


func reset_game() -> void:
	player_team = Team.new()


func export_state() -> Dictionary:
	ensure_team_exists()
	return player_team.to_dict()


func import_state(data: Dictionary) -> void:
	player_team = Team.from_dict(data)


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


func buy_shop_item(item: ItemConfig, target_hero_index: int = -1) -> Dictionary:
	var result := {
		"success": false,
		"message": "Nie udało się kupić przedmiotu.",
		"spent": 0,
		"healed": 0
	}

	if item == null:
		result.message = "Nie znaleziono przedmiotu."
		return result

	ensure_team_exists()

	if item.price < 0:
		result.message = "Nieprawidłowa cena przedmiotu."
		return result

	if not spend_money(item.price):
		result.message = "Brak wystarczającej ilości złota."
		return result

	result.spent = item.price
	result.success = true

	match item.item_kind:
		ItemConfig.ItemKind.HEAL_TEAM:
			var healed_team: int = player_team.heal_all(item.effect_value)
			if healed_team <= 0:
				add_money(item.price)
				result.success = false
				result.spent = 0
				result.message = "Drużyna ma pełne HP."
				return result
			result.healed = healed_team
			result.message = "Drużyna odzyskała %d HP." % healed_team
		ItemConfig.ItemKind.HEAL_SINGLE:
			if target_hero_index < 0 or target_hero_index >= player_team.characters.size():
				add_money(item.price)
				result.success = false
				result.spent = 0
				result.message = "Wybierz bohatera do leczenia."
				return result

			var healed_single: int = player_team.heal_character(target_hero_index, item.effect_value)
			if healed_single <= 0:
				add_money(item.price)
				result.success = false
				result.spent = 0
				result.message = "Bohater ma pełne HP."
				return result
			result.healed = healed_single
			result.message = "Bohater odzyskał %d HP." % healed_single
		ItemConfig.ItemKind.FUTURE_EQUIPMENT:
			player_team.add_item_to_inventory(item.item_id)
			result.message = "Kupiono: %s (bez wpływu na walkę w tej wersji)." % item.display_name
		_:
			result.message = "Kupiono przedmiot."

	return result
