extends RefCounted
class_name ShopCatalog

static func get_items() -> Array[ItemConfig]:
	var entries := get_stock_entries()
	var items: Array[ItemConfig] = []
	for entry: ShopStockEntry in entries:
		if entry.item != null:
			items.append(entry.item)
	return items


static func get_stock_entries() -> Array[ShopStockEntry]:
	var entries: Array[ShopStockEntry] = []

	entries.append(_create_stock_entry(
		"field_bandages",
		"Polowe bandaże",
		"Bandaże",
		"Leczy wybranego bohatera o 8 HP.",
		ItemConfig.ItemKind.HEAL_SINGLE,
		10,
		8,
		"res://assets/ui/shop/items/bandaze_polowe.png",
		3
	))

	entries.append(_create_stock_entry(
		"herbal_dressing",
		"Ziołowy opatrunek",
		"Opatrunek",
		"Leczy wybranego bohatera o 12 HP.",
		ItemConfig.ItemKind.HEAL_SINGLE,
		14,
		12,
		"res://assets/ui/shop/items/ziolowy_opatrunek.png",
		2
	))

	entries.append(_create_stock_entry(
		"campfire_brew",
		"Napar ogniskowy",
		"Napar",
		"Leczy całą drużynę o 4 HP.",
		ItemConfig.ItemKind.HEAL_TEAM,
		22,
		4,
		"res://assets/ui/shop/items/napar_ogniskowy.png",
		2
	))

	entries.append(_create_stock_entry(
		"healer_talisman",
		"Talizman uzdrowiciela",
		"Talizman",
		"Leczy całą drużynę o 6 HP.",
		ItemConfig.ItemKind.HEAL_TEAM,
		28,
		6,
		"res://assets/ui/shop/items/talizman_uzdrowiciela.png",
		1
	))

	entries.append(_create_stock_entry(
		"rusty_sword",
		"Zardzewiały miecz",
		"Miecz",
		"Wybrany bohater otrzymuje +1 do siły i obrażeń akcji.",
		ItemConfig.ItemKind.STRENGTH_EQUIPMENT,
		18,
		1,
		"res://assets/ui/shop/items/zardzewialy_miecz.png",
		1
	))

	entries.append(_create_stock_entry(
		"hunter_shield",
		"Tarcza tropiciela",
		"Tarcza",
		"Wybrany bohater otrzymuje +1 do pancerza.",
		ItemConfig.ItemKind.ARMOUR_EQUIPMENT,
		24,
		1,
		"res://assets/ui/shop/items/tarcza_tropiciela.png",
		1
	))

	entries.append(_create_stock_entry(
		"alchemist_flask",
		"Fiolka wskrzeszenia",
		"Fiolka",
		"Przywraca pierwszego poległego bohatera z 40% maksymalnego HP.",
		ItemConfig.ItemKind.REVIVE,
		16,
		40,
		"res://assets/ui/shop/items/fiolka_alchemika.png",
		1
	))

	return entries


static func _create_stock_entry(
	item_id: String,
	display_name: String,
	short_name: String,
	description: String,
	item_kind: ItemConfig.ItemKind,
	price: int,
	effect_value: int,
	icon_path: String,
	default_stock: int
) -> ShopStockEntry:
	var item := _create_item(
		item_id,
		display_name,
		short_name,
		description,
		item_kind,
		price,
		effect_value,
		icon_path
	)
	return ShopStockEntry.new(item, default_stock)


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
