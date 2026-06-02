extends RefCounted
class_name ShopStockEntry

var item: ItemConfig
var quantity: int = 0


func _init(config: ItemConfig = null, initial_quantity: int = 0) -> void:
	item = config
	quantity = max(initial_quantity, 0)
