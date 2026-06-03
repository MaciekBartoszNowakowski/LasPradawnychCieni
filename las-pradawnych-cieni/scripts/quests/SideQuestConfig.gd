class_name SideQuestConfig
extends Resource

@export var quest_id: StringName
@export var title: String = ""
@export_multiline var description: String = ""

# Na razie używamy jednej sceny SideQuest.tscn.
# To pole zostaje jako furtka, gdyby pojedynczy quest miał kiedyś dostać własną scenę.
@export var scene_override: PackedScene = null

@export_group("Visuals")
# Główne tło questa. Jeśli zostanie puste, scena użyje fallback_background z SideQuest.tscn
# albo ciemnego, neutralnego tła.
@export var background: Texture2D = null

# Opcjonalna notatka widoczna w Inspectorze. Pomaga pamiętać, jakie tło trzeba wygenerować.
@export_multiline var background_note: String = ""

# Pozwala dopasować przyciemnienie do konkretnego tła bez grzebania w scenie.
# 0.0 = brak przyciemnienia, 1.0 = pełna czerń.
@export_range(0.0, 1.0, 0.01) var dark_overlay_alpha: float = 0.30

# Dodatkowa winieta wzmacniająca klimat i czytelność UI.
@export_range(0.0, 1.0, 0.01) var vignette_alpha: float = 0.45

# Pozycja panelu tekstowego. Przydatne, jeśli ważny element tła znajduje się po prawej/lewej stronie.
@export_enum("left", "center", "right") var panel_side: String = "right"

# Array[Resource] ułatwia ręczne tworzenie .tres z sub-resource'ami.
# W praktyce elementami powinny być SideQuestChoiceConfig.
@export var choices: Array[Resource] = []

@export_group("Generation")
@export var weight: int = 1
@export var unique_per_run: bool = true
@export var allowed_acts: PackedInt32Array = PackedInt32Array()


func get_choices() -> Array[SideQuestChoiceConfig]:
	var result: Array[SideQuestChoiceConfig] = []

	for raw_choice in choices:
		var choice := raw_choice as SideQuestChoiceConfig
		if choice != null:
			result.append(choice)

	return result


func is_allowed_in_act(act_index: int) -> bool:
	if allowed_acts.is_empty():
		return true

	return allowed_acts.has(act_index)
