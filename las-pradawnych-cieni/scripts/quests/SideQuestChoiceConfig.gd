class_name SideQuestChoiceConfig
extends Resource

@export var text: String = ""
@export_multiline var result_text: String = ""

@export_group("Visual Result")
# Opcjonalne tło po wyborze tej decyzji. Jeśli zostanie puste, zostaje tło questa.
@export var result_background: Texture2D = null

# Notatka dla Ciebie: co powinno przedstawiać tło wyniku tej decyzji.
@export_multiline var result_background_note: String = ""

# Opcjonalnie można mocniej/słabiej przyciemnić ekran po wyborze.
# Wartość -1 oznacza: użyj ustawienia z SideQuestConfig.
@export_range(-1.0, 1.0, 0.01) var result_dark_overlay_alpha: float = -1.0

@export_group("Effects")
@export var gold_delta: int = 0
@export var health_delta: int = 0

@export_group("Flow")
@export var ends_quest: bool = true
@export var continue_button_text: String = "Wróć na mapę"


func get_effect_summary() -> String:
	var parts: Array[String] = []

	if gold_delta != 0:
		parts.append("Złoto: %+d" % gold_delta)

	if health_delta != 0:
		parts.append("Zdrowie drużyny: %+d" % health_delta)

	if parts.is_empty():
		return ""

	return ", ".join(parts)
