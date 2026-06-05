class_name BattleMapLayouts

# All layouts fit the 20x9 grid (columns 0-19, rows 0-8).
# Player spawns at x=1 rows 1,3,5.  Enemy spawns in the x=12-19 area.
# All maps use base_map.png as background (loaded in BattleMap._load_map_layout).

static func get_random_layout() -> Dictionary:
	var layouts := _all_layouts()
	return layouts[randi() % layouts.size()]

static func _all_layouts() -> Array:
	var B := "res://assets/ui/map/map_obstacles/"
	var bush   := B + "bush.png"
	var rock_t := B + "full_rock_1_connection_at_bottom.png"
	var rock_m := B + "full_rock_2_connection_at_top_and_bottom.png"
	var rock_b := B + "full_rock_3_at_top.png"
	var tree_t := B + "full_tree_1_at_bottom.png"
	var tree_b := B + "full_tree_2_at_bottom.png"
	var fall_l := B + "fallen_tree_connection_on_right.png"  # left cell of horizontal pair
	var fall_r := B + "fallen_tree_connection_on_left.png"   # right cell of horizontal pair
	var riv_t  := B + "full_river_1_connection_at_bottom.png"
	var riv_m  := B + "full_river_2_faded_connection_at_bottom_and_top.png"
	var riv_b  := B + "full_river_3_faded_connection_at_top.png"

	return [
		# 0 — Scattered: stone wall + rocks for cover, one long river from top
		{
			"obstacle_textures": {"stone": rock_m, "tree_log": bush, "river": riv_m},
			"stones": [
				Vector2i(5, 1), Vector2i(5, 2), Vector2i(5, 3),
				Vector2i(10, 4), Vector2i(10, 5),
				Vector2i(15, 2), Vector2i(15, 3),
				Vector2i(3, 4), Vector2i(3, 5)
			],
			"trees": [
				Vector2i(7, 1), Vector2i(8, 1),
				Vector2i(12, 4), Vector2i(12, 5),
				Vector2i(18, 6)
			],
			"rivers": [
				Vector2i(13, 0), Vector2i(13, 1),
				Vector2i(13, 2), Vector2i(13, 3), Vector2i(13, 4), Vector2i(13, 5)
			],
			"cell_textures": {
				# stones — vertical triples / pairs
				Vector2i(5, 1): rock_t, Vector2i(5, 2): rock_m, Vector2i(5, 3): rock_b,
				Vector2i(10, 4): rock_t, Vector2i(10, 5): rock_b,
				Vector2i(15, 2): rock_t, Vector2i(15, 3): rock_b,
				Vector2i(3, 4): rock_t, Vector2i(3, 5): rock_b,
				# trees — horizontal pair + vertical pair + isolated
				Vector2i(7, 1): fall_l, Vector2i(8, 1): fall_r,
				Vector2i(12, 4): tree_t, Vector2i(12, 5): tree_b,
				Vector2i(18, 6): bush,
				# rivers — 6-cell vertical chain
				Vector2i(13, 0): riv_t,
				Vector2i(13, 1): riv_m, Vector2i(13, 2): riv_m,
				Vector2i(13, 3): riv_m, Vector2i(13, 4): riv_m,
				Vector2i(13, 5): riv_b,
			}
		},
		# 1 — Dense forest: diagonal tree walls + 2 extra scattered trees
		{
			"obstacle_textures": {"stone": rock_m, "tree_log": bush, "river": riv_m},
			"stones": [
				Vector2i(4, 5), Vector2i(5, 5)
			],
			"trees": [
				Vector2i(3, 2), Vector2i(4, 3), Vector2i(5, 4), Vector2i(6, 5), Vector2i(7, 6), Vector2i(7, 7),
				Vector2i(9, 1), Vector2i(10, 2), Vector2i(11, 3), Vector2i(11, 4), Vector2i(12, 5),
				Vector2i(15, 1), Vector2i(16, 2), Vector2i(17, 3), Vector2i(18, 4),
				Vector2i(19, 2),
				Vector2i(17, 7)
			],
			"rivers": [
				Vector2i(14, 6), Vector2i(14, 7)
			],
			"cell_textures": {
				# stones — horizontal pair, no vertical connection
				Vector2i(4, 5): rock_m, Vector2i(5, 5): rock_m,
				# trees — (7,6)+(7,7) vertical pair, (11,3)+(11,4) vertical pair, rest isolated
				Vector2i(3, 2): bush, Vector2i(4, 3): bush, Vector2i(5, 4): bush, Vector2i(6, 5): bush,
				Vector2i(7, 6): tree_t, Vector2i(7, 7): tree_b,
				Vector2i(9, 1): bush, Vector2i(10, 2): bush,
				Vector2i(11, 3): tree_t, Vector2i(11, 4): tree_b,
				Vector2i(12, 5): bush,
				Vector2i(15, 1): bush, Vector2i(16, 2): bush, Vector2i(17, 3): bush, Vector2i(18, 4): bush,
				Vector2i(19, 2): bush, Vector2i(17, 7): bush,
				# rivers — 2-cell vertical pair
				Vector2i(14, 6): riv_t, Vector2i(14, 7): riv_b,
			}
		},
		# 2 — Rocky terrain: stone clusters + extra rocks in bottom rows
		{
			"obstacle_textures": {"stone": rock_m, "tree_log": bush, "river": riv_m},
			"stones": [
				Vector2i(3, 2), Vector2i(3, 3), Vector2i(4, 2),
				Vector2i(7, 1), Vector2i(7, 2), Vector2i(8, 1),
				Vector2i(11, 4), Vector2i(11, 5), Vector2i(12, 4),
				Vector2i(15, 3), Vector2i(15, 4), Vector2i(16, 3),
				Vector2i(18, 6), Vector2i(19, 6), Vector2i(19, 7),
				Vector2i(3, 7), Vector2i(4, 7),
				Vector2i(10, 8), Vector2i(11, 8)
			],
			"trees": [
				Vector2i(6, 6), Vector2i(14, 2), Vector2i(19, 4)
			],
			"rivers": [],
			"cell_textures": {
				# L-shaped clusters: vertical pair + isolated horizontal neighbor
				Vector2i(3, 2): rock_t, Vector2i(3, 3): rock_b,
				Vector2i(4, 2): rock_m,
				Vector2i(7, 1): rock_t, Vector2i(7, 2): rock_b,
				Vector2i(8, 1): rock_m,
				Vector2i(11, 4): rock_t, Vector2i(11, 5): rock_b,
				Vector2i(12, 4): rock_m,
				Vector2i(15, 3): rock_t, Vector2i(15, 4): rock_b,
				Vector2i(16, 3): rock_m,
				# isolated + vertical pair at right edge
				Vector2i(18, 6): rock_m,
				Vector2i(19, 6): rock_t, Vector2i(19, 7): rock_b,
				# bottom row horizontal pairs — no vertical connections
				Vector2i(3, 7): rock_m, Vector2i(4, 7): rock_m,
				Vector2i(10, 8): rock_m, Vector2i(11, 8): rock_m,
				# trees — all isolated
				Vector2i(6, 6): bush, Vector2i(14, 2): bush, Vector2i(19, 4): bush,
			}
		},
		# 3 — River crossing: 2-cell-wide vertical river through the middle,
		#     two 1-cell-wide passages (row 2 col 10 open, row 6 col 9 open)
		{
			"obstacle_textures": {"stone": rock_m, "tree_log": bush, "river": riv_m},
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
			],
			"cell_textures": {
				# stones — all vertical pairs
				Vector2i(4, 2): rock_t, Vector2i(4, 3): rock_b,
				Vector2i(7, 6): rock_t, Vector2i(7, 7): rock_b,
				Vector2i(12, 2): rock_t, Vector2i(12, 3): rock_b,
				Vector2i(16, 5): rock_t, Vector2i(16, 6): rock_b,
				# trees — all isolated
				Vector2i(2, 6): bush, Vector2i(6, 1): bush,
				Vector2i(13, 7): bush, Vector2i(17, 1): bush,
				# rivers — col 9: three separate segments
				Vector2i(9, 0): riv_t, Vector2i(9, 1): riv_b,
				Vector2i(9, 3): riv_t, Vector2i(9, 4): riv_m, Vector2i(9, 5): riv_b,
				Vector2i(9, 7): riv_t, Vector2i(9, 8): riv_b,
				# rivers — col 10: three separate segments
				Vector2i(10, 0): riv_t, Vector2i(10, 1): riv_b,
				Vector2i(10, 3): riv_t, Vector2i(10, 4): riv_m, Vector2i(10, 5): riv_b,
				Vector2i(10, 7): riv_t, Vector2i(10, 8): riv_b,
			}
		},
		# 4 — Open field: left stone pair at rows 3-4, right pair moved lower to rows 5-6
		{
			"obstacle_textures": {"stone": rock_m, "tree_log": bush, "river": riv_m},
			"stones": [
				Vector2i(7, 3), Vector2i(7, 4),
				Vector2i(14, 5), Vector2i(14, 6)
			],
			"trees": [
				Vector2i(5, 6), Vector2i(17, 1)
			],
			"rivers": [
				Vector2i(11, 1), Vector2i(11, 7)
			],
			"cell_textures": {
				# stones — vertical pairs
				Vector2i(7, 3): rock_t, Vector2i(7, 4): rock_b,
				Vector2i(14, 5): rock_t, Vector2i(14, 6): rock_b,
				# trees — both isolated
				Vector2i(5, 6): bush, Vector2i(17, 1): bush,
				# rivers — both isolated single cells
				Vector2i(11, 1): riv_m, Vector2i(11, 7): riv_m,
			}
		}
	]
