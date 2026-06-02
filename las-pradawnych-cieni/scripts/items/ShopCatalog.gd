extends RefCounted
class_name ShopCatalog

static func get_items() -> Array[ItemConfig]:
	var items: Array[ItemConfig] = []

	items.append(_create_item(
		"field_bandages",
		"Polowe bandaże",
		"Bandaże",
		"Leczy wybranego bohatera o 8 HP.",
		ItemConfig.ItemKind.HEAL_SINGLE,
		10,
		8,
		"res://assets/ui/shop/items/bandaze_polowe.png"
	))

	items.append(_create_item(
		"herbal_dressing",
		"Ziołowy opatrunek",
		"Opatrunek",
		"Leczy wybranego bohatera o 12 HP.",
		ItemConfig.ItemKind.HEAL_SINGLE,
		14,
		12,
		"res://assets/ui/shop/items/ziolowy_opatrunek.png"
	))

	items.append(_create_item(
		"campfire_brew",
		"Napar ogniskowy",
		"Napar",
		"Leczy całą drużynę o 4 HP.",
		ItemConfig.ItemKind.HEAL_TEAM,
		22,
		4,
		"res://assets/ui/shop/items/napar_ogniskowy.png"
	))

	items.append(_create_item(
		"healer_talisman",
		"Talizman uzdrowiciela",
		"Talizman",
		"Leczy całą drużynę o 6 HP.",
		ItemConfig.ItemKind.HEAL_TEAM,
		28,
		6,
		"res://assets/ui/shop/items/talizman_uzdrowiciela.png"
	))

	items.append(_create_item(
		"rusty_sword",
		"Zardzewiały miecz",
		"Miecz",
		"Kupiony do ekwipunku. Na razie bez wpływu na walkę.",
		ItemConfig.ItemKind.FUTURE_EQUIPMENT,
		18,
		0,
		"res://assets/ui/shop/items/zardzewialy_miecz.png"
	))

	items.append(_create_item(
		"hunter_shield",
		"Tarcza tropiciela",
		"Tarcza",
		"Kupiona do ekwipunku. Efekty obronne pojawią się później.",
		ItemConfig.ItemKind.FUTURE_EQUIPMENT,
		24,
		0,
		"res://assets/ui/shop/items/tarcza_tropiciela.png"
	))

	items.append(_create_item(
		"alchemist_flask",
		"Fiolka alchemika",
		"Fiolka",
		"Kupiona do ekwipunku. Potencjał pod przyszłe mikstury.",
		ItemConfig.ItemKind.FUTURE_EQUIPMENT,
		16,
		0,
		"res://assets/ui/shop/items/fiolka_alchemika.png"
	))

	return items


static func _create_item(
	item_id: String,
	display_name: String,
	short_name: String,
	description: String,
	item_kind: ItemConfig.ItemKind,
	price: int,
	effect_value: int = 0,
	icon_path: String = ""
) -> ItemConfig:
	var item := ItemConfig.new()
	item.item_id = item_id
	item.display_name = display_name
	item.short_name = short_name
	item.description = description
	item.item_kind = item_kind
	item.price = price
	item.effect_value = effect_value
	item.icon_path = icon_path
	return item
