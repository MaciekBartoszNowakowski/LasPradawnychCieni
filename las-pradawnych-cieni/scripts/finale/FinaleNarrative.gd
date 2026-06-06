class_name FinaleNarrative
extends RefCounted

const RESOLUTION_PEOPLE_DESTROY := &"people_destroy"
const RESOLUTION_PEOPLE_CONFESSION := &"people_confession"
const RESOLUTION_PEOPLE_SILENCE := &"people_silence"
const RESOLUTION_FOREST_RESTORE := &"forest_restore"
const RESOLUTION_FOREST_PURGE := &"forest_purge"
const RESOLUTION_AMBIGUOUS_BATTLE := &"ambiguous_battle"
const RESOLUTION_AMBIGUOUS_LEAVE := &"ambiguous_leave"

const _FINALE_BG := "res://assets/ui/finale/backgrounds/"

# Pliki PNG — nazwy numerowane; poniżej mapowanie wg treści kadru.
const BG_TUNNEL := _FINALE_BG + "finale_01_heart_arrival.png" # tunel korzeni, wejście w głąb
const BG_SHADOW := _FINALE_BG + "finale_02_shadow_revelation.png" # Cień pod łukiem, runy
const BG_ALTAR_PEOPLE := _FINALE_BG + "finale_03_confront_people.png" # ołtarz, pieczęć, wieś
const BG_FOREST_CONFRONT := _FINALE_BG + "finale_04_confront_forest.png" # opcjonalny — brak pliku
const BG_FORK_BRIDGE := _FINALE_BG + "finale_05_confront_ambiguous.png" # rozstajnie, most
const BG_BOSS := _FINALE_BG + "finale_06_result_battle.png" # monstrum / kulminacja walki
const BG_SHRINE_PEACE := _FINALE_BG + "finale_07_result_peace.png" # kapliczka, odnowa paktu

const BG_NONE := "" # czarne BaseTint w Finale.tscn

const BG_FALLBACK_HEART := "res://assets/ui/checkpoints/oath_stone/cp_005_intro.png"
const BG_FALLBACK_FOREST := "res://assets/ui/checkpoints/ancient_camp/cp_003_intro.png"
const BG_FALLBACK_LEDGER := "res://assets/ui/checkpoints/soltys_ledger/cp_004_intro.png"
const BG_FALLBACK_BRIDGE := "res://assets/ui/checkpoints/broken_bridge/cp_002_intro.png"


static func _bg(primary: String, fallback: String) -> String:
	if ResourceLoader.exists(primary):
		return primary
	return fallback


static func _bg_forest_confront() -> String:
	if ResourceLoader.exists(BG_FOREST_CONFRONT):
		return BG_FOREST_CONFRONT
	return BG_NONE


static func build_steps() -> Array:
	var steps: Array = []

	steps.append({
		"title": "Serce lasu",
		"description": build_arrival_text(),
		"background": _bg(BG_TUNNEL, BG_FALLBACK_HEART),
		"mode": "continue",
		"continue_text": "Wejdź głębiej",
	})

	steps.append({
		"title": "Cień na granicy",
		"description": build_revelation_text(),
		"background": _bg(BG_SHADOW, BG_FALLBACK_HEART),
		"mode": "continue",
		"continue_text": "Stań przed nim",
	})

	steps.append(_build_confrontation_step())
	return steps


static func _build_confrontation_step() -> Dictionary:
	var choices: Array = []
	var background := _bg(BG_TUNNEL, BG_FALLBACK_HEART)
	var description := "Cień czeka. Każda odpowiedź zmieni los wsi i lasu."

	if MapState.final_alignment == MapState.ALIGNMENT_PEOPLE:
		background = _bg(BG_ALTAR_PEOPLE, BG_FALLBACK_LEDGER)
		description = (
			"Obiecaliście chronić ludzi. Cień pulsuje słabiej, gdy myślicie o osadzie — "
			+ "ale wymaga rozstrzygnięcia: siła, prawda albo układ."
		)
		choices.append(_choice(
			"Rozbij manifestację mieczem",
			RESOLUTION_PEOPLE_DESTROY,
			true
		))
		if MapState.knows_mayor_truth():
			choices.append(_choice(
				"Zmusz sołtysa do wyznania przed wsią",
				RESOLUTION_PEOPLE_CONFESSION,
				false
			))
		else:
			choices.append(_choice(
				"Ucisz las — wieś ma żyć dalej w milczeniu",
				RESOLUTION_PEOPLE_SILENCE,
				false
			))
	elif MapState.final_alignment == MapState.ALIGNMENT_FOREST:
		background = _bg_forest_confront()
		description = (
			"Obiecaliście naprawić pakt. Cień nie jest wrogiem — jest raną. "
			+ "Możecie ją zszyć albo wyciąć bez znieczulenia."
		)
		choices.append(_choice(
			"Odnów daninę ciszy i zamknij ranę",
			RESOLUTION_FOREST_RESTORE,
			false
		))
		choices.append(_choice(
			"Wyciąć korzenie serca lasu",
			RESOLUTION_FOREST_PURGE,
			true
		))
	else:
		background = _bg(BG_FORK_BRIDGE, BG_FALLBACK_BRIDGE)
		description = (
			"Nie złożyliście przysięgi na kamieniu — las nie wie, komu macie służyć. "
			+ "Cień patrzy bez oczu, czekając na wasz wybór."
		)
		choices.append(_choice(
			"Zaatakuj, zanim on pierwszy się odezwie",
			RESOLUTION_AMBIGUOUS_BATTLE,
			true
		))
		choices.append(_choice(
			"Odejdź i pozwól wsi samej ponieść koszt",
			RESOLUTION_AMBIGUOUS_LEAVE,
			false
		))

	return {
		"title": "Ostatnia decyzja",
		"description": description,
		"background": background,
		"mode": "choices",
		"choices": choices,
	}


static func _choice(text: String, resolution_id: StringName, needs_battle: bool) -> Dictionary:
	return {
		"text": text,
		"resolution_id": resolution_id,
		"needs_battle": needs_battle,
		"result_text": get_resolution_climax_text(resolution_id),
		"result_background": get_resolution_background(resolution_id),
	}


static func get_resolution_background(resolution_id: StringName) -> String:
	if resolution_id == RESOLUTION_PEOPLE_DESTROY:
		return _bg(BG_BOSS, BG_FALLBACK_HEART)
	if resolution_id == RESOLUTION_AMBIGUOUS_BATTLE:
		return _bg(BG_BOSS, BG_FALLBACK_HEART)
	if resolution_id == RESOLUTION_FOREST_PURGE:
		return _bg(BG_BOSS, BG_FALLBACK_HEART)
	if resolution_id == RESOLUTION_PEOPLE_CONFESSION:
		return _bg(BG_SHRINE_PEACE, BG_FALLBACK_LEDGER)
	if resolution_id == RESOLUTION_PEOPLE_SILENCE:
		return _bg(BG_SHADOW, BG_FALLBACK_HEART)
	if resolution_id == RESOLUTION_FOREST_RESTORE:
		return _bg(BG_SHRINE_PEACE, BG_FALLBACK_FOREST)
	if resolution_id == RESOLUTION_AMBIGUOUS_LEAVE:
		return _bg(BG_TUNNEL, BG_FALLBACK_BRIDGE)
	return _bg(BG_TUNNEL, BG_FALLBACK_HEART)


static func get_resolution_climax_text(resolution_id: StringName) -> String:
	if resolution_id == RESOLUTION_PEOPLE_DESTROY:
		return (
			"Cień składa się z głosów zaginionych. Miecze przecinają mgłę, "
			+ "a las na moment milknie — jakby wstrzymywał oddech przed kolejną raną."
		)
	if resolution_id == RESOLUTION_PEOPLE_CONFESSION:
		return (
			"Wypowiadacie na głos wszystko, co znaleźliście. Pieczęć sołtysa pęka w powietrzu. "
			+ "Cień cofa się, lecz nie znika — czeka, aż wieś sama wybierze, komu wierzyć."
		)
	if resolution_id == RESOLUTION_PEOPLE_SILENCE:
		return (
			"Zamykacie usta na prawdę. Cień słucha i ustępuje — "
			+ "lecz w korzeniach zostaje pytanie, które kiedyś wróci głośniej."
		)
	if resolution_id == RESOLUTION_FOREST_RESTORE:
		return (
			"Składacie daninę ciszy, jak dawniej. Cień rozprasza się powoli, "
			+ "a ścieżki znowu pachną mokrą korą zamiast rdzą."
		)
	if resolution_id == RESOLUTION_FOREST_PURGE:
		return (
			"Brniecie przez korzenie do samego serca. Coś jęczy pod ziemią — "
			+ "nie bestia, lecz rana, którą zaraz otworzycie na oślep."
		)
	if resolution_id == RESOLUTION_AMBIGUOUS_BATTLE:
		return "Bez przysięgi rzucacie się w wir. Cień odpowiada natychmiast — bez litości."
	if resolution_id == RESOLUTION_AMBIGUOUS_LEAVE:
		return "Odwracacie się. Za plecami Cień nie rusza — tylko zapamiętuje wasz krok."
	return "Decyzja zapadła. Las i wieś czekają na skutek."


static func build_arrival_text() -> String:
	var parts: PackedStringArray = []
	parts.append(
		"Korzenie rozstępują się jak brama. Za nimi nie ma bestii z legend wsi — "
		+ "lecz coś starszego: rana paktu, którą ktoś celowo pogłębił."
	)

	if MapState.knows_mayor_truth():
		parts.append(
			"Pieczęć sołtysa wisi w powietrzu jak rdzawa plama. "
			+ "Las nie żąda krwi dla samej krwi — domaga się prawdy albo kolejnej ofiary."
		)
	elif MapState.get_discovered_lore_count() >= 3:
		parts.append(
			"Zebrane dowody układają się w jeden obraz: zło nie obudziło się samo. "
			+ "Ktoś z osady zerwał to, co miało chronić wszystkich."
		)
	else:
		parts.append(
			"Mimo luk w śledztwie czujecie, że źródłem nie jest wyłącznie las. "
			+ "Ktoś z ludzi uciekł przed ceną własnej decyzji."
		)

	if MapState.final_alignment == MapState.ALIGNMENT_PEOPLE:
		parts.append("Przysięga ciąży jak obietnica: osada ma przetrwać — nawet jeśli las zapłaci.")
	elif MapState.final_alignment == MapState.ALIGNMENT_FOREST:
		parts.append("Przysięga szeptała inaczej: najpierw naprawić złamaną umowę — potem osądzać.")

	return "\n\n".join(parts)


static func build_revelation_text() -> String:
	if MapState.knows_mayor_truth():
		return (
			"Z ciemności wyłania się Cień — nie korpus bestii, lecz suma złamanych obietnic. "
			+ "W jego rytmie słychać imiona z rejestru, szloch mostu i kłamstwo sołtysowej pieczęci.\n\n"
			+ "To nie on jest waszym wrogiem. To echo tego, co wieś zrobiła, by milczeć."
		)

	if MapState.has_lore_tag(&"camp_chronicle") or MapState.has_lore_tag(&"camp_echo"):
		return (
			"Las pokazuje dawnych strażników — nie jako duchy zemsty, lecz jako świadków. "
			+ "Mówią jednym głosem: rytuał został przerwany w pół słowa, a cierń wypełnił pustkę."
		)

	return (
		"Coś materializuje się między drzewami: Cień Pradawnego Lasu. "
		+ "Nie atakuje od razu — czeka, by zobaczyć, czy przyjdziecie z mieczem, czy z rozsądkiem."
	)


static func get_epilogue(resolution_id: StringName) -> Dictionary:
	var title := "Koniec wyprawy"
	var subtitle := ""
	var body := ""

	if resolution_id == RESOLUTION_PEOPLE_DESTROY:
		title = "Cień rozproszony"
		subtitle = "Ludzie przetrwali — las pamięta"
		body = _people_destroy_body()
	elif resolution_id == RESOLUTION_PEOPLE_CONFESSION:
		title = "Prawda przed bramą wsi"
		subtitle = "Cena uczciwości"
		body = _people_confession_body()
	elif resolution_id == RESOLUTION_PEOPLE_SILENCE:
		title = "Milczenie za bramą"
		subtitle = "Spokój kupiony kłamstwem"
		body = _people_silence_body()
	elif resolution_id == RESOLUTION_FOREST_RESTORE:
		title = "Pakt odnowiony"
		subtitle = "Las oddycha spokojniej"
		body = _forest_restore_body()
	elif resolution_id == RESOLUTION_FOREST_PURGE:
		title = "Rana wycięta"
		subtitle = "Las ucichł — na chwilę"
		body = _forest_purge_body()
	elif resolution_id == RESOLUTION_AMBIGUOUS_BATTLE:
		title = "Zwycięstwo bez odpowiedzi"
		subtitle = "Cień zgasł, pytania zostały"
		body = _ambiguous_battle_body()
	elif resolution_id == RESOLUTION_AMBIGUOUS_LEAVE:
		title = "Sprawa niedomknięta"
		subtitle = "Las czeka na innych"
		body = _ambiguous_leave_body()
	else:
		subtitle = "Nieznany los"
		body = "Drużyna wraca do wsi, niepewna, czy zło naprawdę ustało."

	return {
		"title": title,
		"subtitle": subtitle,
		"body": body,
		"summary": build_run_summary_line(),
	}


static func build_run_summary_line() -> String:
	var alignment_label := "bez przysięgi"
	if MapState.final_alignment == MapState.ALIGNMENT_PEOPLE:
		alignment_label = "przysięga: ochrona ludzi"
	elif MapState.final_alignment == MapState.ALIGNMENT_FOREST:
		alignment_label = "przysięga: pakt z lasem"

	var lore_count: int = MapState.get_discovered_lore_count()
	var truth := "tak" if MapState.knows_mayor_truth() else "nie"

	return (
		"Śledztwo: %d wskazówek · Prawda o sołtysie: %s · %s"
		% [lore_count, truth, alignment_label]
	)


static func _people_destroy_body() -> String:
	var extra := ""
	if MapState.knows_mayor_truth():
		extra = "\n\nSołtys wita was jak bohaterów, lecz w jego oczach widać ulgę, nie wdzięczność."
	return (
		"Cień rozpadł się pod waszymi ciosami. Zwierzęta powoli wracają, a noce są cichsze — "
		+ "lecz korzenie wciąż pulsują słabiej niż dawniej, jakby las czekał na coś więcej niż zwycięstwo."
		+ extra
		+ "\n\nWieś ma czas. Prawda może jeszcze poczekać — albo nigdy nie wyjść na jaw."
	)


static func _people_confession_body() -> String:
	return (
		"Zmuszacie Cień do wycofania się, odsłaniając przed nim wszystko, co znaleźliście. "
		+ "Gdy wracacie, sołtys bladuje — wie, że jego pieczęć już was nie osłoni.\n\n"
		+ "Część mieszkańców chce słuchać. Inni domagają się waszego odejścia. "
		+ "Na tablicy pojawia się nowe ogłoszenie — tym razem bez podpisu sołtysa."
	)


static func _people_silence_body() -> String:
	return (
		"Wybieracie spokój osady ponad prawdę. Las cofa się, lecz nie wybacza — "
		+ "szepty wrócą, gdy ktoś znów przerwie rytuał.\n\n"
		+ "Sołtys uśmiecha się z ulgą. Drużyna dostaje zapłatę i ostrzeżenie, "
		+ "by nigdy nie mówić o tym, co widzieliście w sercu lasu."
	)


static func _forest_restore_body() -> String:
	return (
		"Składacie obietnicę, którą wieś złamała. Cień rozprasza się jak mgła o poranku, "
		+ "a korzenie układają się z powrotem nad ścieżkami.\n\n"
		+ "W osadzie przestają znikać ludzie. Sołtys milczy — wie, że jego władza kończy się tam, "
		+ "gdzie zaczyna się granica lasu."
	)


static func _forest_purge_body() -> String:
	return (
		"Wycinacie serce korzeni. Las krzyczy jednym, przeciągłym echem — potem zapada cisza, "
		+ "nie ta kojąca, lecz pusta.\n\n"
		+ "Wieś jest bezpieczna przez sezony. Lecz myśliwi mówią, że drzewa już nie sypią żołędziami, "
		+ "a studnie smakują rdzą."
	)


static func _ambiguous_battle_body() -> String:
	return (
		"Bez przysięgi i bez pełnego obrazu rzucacie się na Cień. Pada — lecz nie wiecie, "
		+ "czy pokonaliście zło, czy tylko jego objawienie.\n\n"
		+ "Wieś świętuje. Wam zostaje wątpliwość, która będzie gryźć przy każdym kolejnym zmroku."
	)


static func _ambiguous_leave_body() -> String:
	return (
		"Odchodzicie, nie domykając sprawy. Las pozwala wam odejść — jakby czekał na kogoś mądrzejszego.\n\n"
		+ "Po tygodniu znów znikają dzieciaki idące po drewno. Na tablicy kołysze się świeże ogłoszenie."
	)
