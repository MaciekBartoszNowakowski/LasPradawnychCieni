class_name BattleMapLayouts

# All layouts fit the 20x9 grid (columns 0-19, rows 0-8).
# Player spawns at x=1 rows 1,3,5.  Enemy spawns in the x=12-19 area.

static func get_random_layout() -> Dictionary:
	var layouts := _all_layouts()
	return layouts[randi() % layouts.size()]

static func _all_layouts() -> Array:
	return [
		# 0 — Scattered: stone wall + rocks for cover, one long river from top
		{
			"stones": [
				Vector2i(5, 1), Vector2i(5, 2), Vector2i(5, 3),
				Vector2i(10, 4), Vector2i(10, 5),
				Vector2i(15, 2), Vector2i(15, 3),
				Vector2i(3, 4), Vector2i(3, 5)   # rocks replacing the old small river
			],
			"trees": [
				Vector2i(7, 1), Vector2i(8, 1),
				Vector2i(12, 4), Vector2i(12, 5),
				Vector2i(18, 6)
			],
			"rivers": [
				# Single river from row 0 down to row 5
				Vector2i(13, 0), Vector2i(13, 1),
				Vector2i(13, 2), Vector2i(13, 3), Vector2i(13, 4), Vector2i(13, 5)
			]
		},
		# 1 — Dense forest: diagonal tree walls + 2 extra scattered trees
		{
			"stones": [
				Vector2i(4, 5), Vector2i(5, 5)
			],
			"trees": [
				Vector2i(3, 2), Vector2i(4, 3), Vector2i(5, 4), Vector2i(6, 5), Vector2i(7, 6), Vector2i(7, 7),
				Vector2i(9, 1), Vector2i(10, 2), Vector2i(11, 3), Vector2i(11, 4), Vector2i(12, 5),
				Vector2i(15, 1), Vector2i(16, 2), Vector2i(17, 3), Vector2i(18, 4),
				Vector2i(19, 2),  # extra: top-right open area
				Vector2i(17, 7)   # extra: bottom-right open area
			],
			"rivers": [
				Vector2i(14, 6), Vector2i(14, 7)
			]
		},
		# 2 — Rocky terrain: stone clusters + extra rocks in bottom rows
		{
			"stones": [
				Vector2i(3, 2), Vector2i(3, 3), Vector2i(4, 2),
				Vector2i(7, 1), Vector2i(7, 2), Vector2i(8, 1),
				Vector2i(11, 4), Vector2i(11, 5), Vector2i(12, 4),
				Vector2i(15, 3), Vector2i(15, 4), Vector2i(16, 3),
				Vector2i(18, 6), Vector2i(19, 6), Vector2i(19, 7),
				Vector2i(3, 7), Vector2i(4, 7),   # extra: bottom-left
				Vector2i(10, 8), Vector2i(11, 8)  # extra: bottom-middle
			],
			"trees": [
				Vector2i(6, 6), Vector2i(14, 2), Vector2i(19, 4)
			],
			"rivers": []
		},
		# 3 — River crossing: 2-cell-wide vertical river through the middle,
		#     two 1-cell-wide passages (row 2 col 10 open, row 6 col 9 open)
		{
			"stones": [
				Vector2i(4, 2), Vector2i(4, 3),
				Vector2i(7, 6), Vector2i(7, 7),
				Vector2i(12, 2), Vector2i(12, 3),
				Vector2i(16, 5), Vector2i(16, 6)
			],
			"trees": [
				Vector2i(2, 6), Vector2i(6, 1),
				Vector2i(13, 7), Vector2i(17, 1)
			],
			"rivers": [
				Vector2i(9, 0), Vector2i(10, 0),
				Vector2i(9, 1), Vector2i(10, 1),
				# row 2: both cols open — full passage 1
				Vector2i(9, 3), Vector2i(10, 3),
				Vector2i(9, 4), Vector2i(10, 4),
				Vector2i(9, 5), Vector2i(10, 5),
				# row 6: both cols open — full passage 2
				Vector2i(9, 7), Vector2i(10, 7),
				Vector2i(9, 8), Vector2i(10, 8)
			]
		},
		# 4 — Open field: left stone pair at rows 3-4, right pair moved lower to rows 5-6
		{
			"stones": [
				Vector2i(7, 3), Vector2i(7, 4),
				Vector2i(14, 5), Vector2i(14, 6)   # moved down from rows 3-4
			],
			"trees": [
				Vector2i(5, 6), Vector2i(17, 1)
			],
			"rivers": [
				Vector2i(11, 1), Vector2i(11, 7)
			]
		}
	]
