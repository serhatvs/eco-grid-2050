extends RefCounted

const GameData = preload("res://scripts/GameData.gd")
const GridSimulation = preload("res://scripts/GridSimulation.gd")

static var _textures: Dictionary = {}
static var _textures_loaded: bool = false

static func _load_texture_file(res_path: String) -> Texture2D:
	if ResourceLoader.exists(res_path):
		var t = load(res_path)
		if t is Texture2D:
			return t
	var global_p: String = ProjectSettings.globalize_path(res_path)
	if FileAccess.file_exists(global_p):
		var img := Image.load_from_file(global_p)
		if img != null:
			return ImageTexture.create_from_image(img)
	return null

static func _ensure_textures() -> void:
	if _textures_loaded:
		return
	_textures_loaded = true
	var building_files := {
		GameData.BuildingType.SOLAR: "res://assets/sprites/building_solar_farm.png",
		GameData.BuildingType.WIND: "res://assets/sprites/building_wind_turbine.png",
		GameData.BuildingType.HOUSING: "res://assets/sprites/building_eco_housing.png",
		GameData.BuildingType.FOREST: "res://assets/sprites/building_urban_forest.png",
		GameData.BuildingType.FARM: "res://assets/sprites/building_vertical_farm.png",
		GameData.BuildingType.COAL_PLANT: "res://assets/sprites/building_coal_plant.png",
		GameData.BuildingType.FOSSIL: "res://assets/sprites/building_coal_plant.png",
		GameData.BuildingType.WATER_PLANT: "res://assets/sprites/building_water_treatment.png",
		GameData.BuildingType.GEOTHERMAL: "res://assets/sprites/building_geothermal.png",
		GameData.BuildingType.CCS: "res://assets/sprites/building_carbon_capture.png",
		GameData.BuildingType.BIOCORRIDOR: "res://assets/sprites/building_bio_corridor.png",
		GameData.BuildingType.RECYCLE: "res://assets/sprites/building_recycling.png",
		GameData.BuildingType.LAKE: "res://assets/sprites/building_natural_lake.png",
		GameData.BuildingType.BATTERY: "res://assets/sprites/building_battery_lvl2.png",
		GameData.BuildingType.COP31: "res://assets/sprites/building_climate_hub_lvl2.png"
	}
	for btype in building_files:
		var tex: Texture2D = _load_texture_file(building_files[btype])
		if tex != null:
			_textures[btype] = tex

	var mega_building_files := {
		GameData.BuildingType.SOLAR: "res://assets/sprites/building_solar_farm_mega.png",
		GameData.BuildingType.WIND: "res://assets/sprites/building_wind_turbine_mega.png",
		GameData.BuildingType.HOUSING: "res://assets/sprites/building_eco_housing_mega.png",
		GameData.BuildingType.FOREST: "res://assets/sprites/building_urban_forest_mega.png",
		GameData.BuildingType.FARM: "res://assets/sprites/building_vertical_farm_mega.png",
		GameData.BuildingType.WATER_PLANT: "res://assets/sprites/building_water_treatment_mega.png",
		GameData.BuildingType.GEOTHERMAL: "res://assets/sprites/building_geothermal_mega.png",
		GameData.BuildingType.CCS: "res://assets/sprites/building_carbon_capture_mega.png",
		GameData.BuildingType.BIOCORRIDOR: "res://assets/sprites/building_bio_corridor_mega.png",
		GameData.BuildingType.RECYCLE: "res://assets/sprites/building_recycling_mega.png",
		GameData.BuildingType.BATTERY: "res://assets/sprites/building_battery_mega.png",
		GameData.BuildingType.COP31: "res://assets/sprites/building_cop31_center.png"
	}
	for btype in mega_building_files:
		var tex: Texture2D = _load_texture_file(mega_building_files[btype])
		if tex != null:
			_textures["mega_%d" % btype] = tex

	var lvl2_building_files := {
		GameData.BuildingType.SOLAR: "res://assets/sprites/building_solar_farm_lvl2.png",
		GameData.BuildingType.WIND: "res://assets/sprites/building_wind_turbine_lvl2.png",
		GameData.BuildingType.HOUSING: "res://assets/sprites/building_eco_housing_lvl2.png",
		GameData.BuildingType.FOREST: "res://assets/sprites/building_urban_forest_lvl2.png",
		GameData.BuildingType.FARM: "res://assets/sprites/building_vertical_farm_lvl2.png",
		GameData.BuildingType.WATER_PLANT: "res://assets/sprites/building_water_treatment_lvl2.png",
		GameData.BuildingType.GEOTHERMAL: "res://assets/sprites/building_geothermal_lvl2.png",
		GameData.BuildingType.CCS: "res://assets/sprites/building_carbon_capture_lvl2.png",
		GameData.BuildingType.BIOCORRIDOR: "res://assets/sprites/building_bio_corridor_lvl2.png",
		GameData.BuildingType.RECYCLE: "res://assets/sprites/building_recycling_lvl2.png",
		GameData.BuildingType.BATTERY: "res://assets/sprites/building_battery_lvl2.png",
		GameData.BuildingType.COP31: "res://assets/sprites/building_climate_hub_lvl2.png"
	}
	for btype in lvl2_building_files:
		var tex: Texture2D = _load_texture_file(lvl2_building_files[btype])
		if tex != null:
			_textures["lvl2_%d" % btype] = tex

	var tile_files := {
		"tile_meadow": "res://assets/sprites/tile_unlocked_meadow.png",
		"tile_grid": "res://assets/sprites/tile_unlocked_grid.png",
		"tile_border": "res://assets/sprites/tile_border_reclamation.png",
		"tile_industrial": "res://assets/sprites/tile_industrial_polluted.png",
		"tile_ocean": "res://assets/sprites/tile_locked_ocean.png",
		"tile_desert": "res://assets/sprites/tile_desert_oasis.png"
	}
	for tkey in tile_files:
		var tex: Texture2D = _load_texture_file(tile_files[tkey])
		if tex != null:
			_textures[tkey] = tex

static func draw_iso_prism(canvas: CanvasItem, gx: int, gy: int, top_col: Color, border_col: Color, height: float, inset: float = 0.0) -> void:
	var p_top: Vector2 = GameData.grid_to_iso(gx + inset, gy + inset)
	var p_right: Vector2 = GameData.grid_to_iso(gx + 1.0 - inset, gy + inset)
	var p_bottom: Vector2 = GameData.grid_to_iso(gx + 1.0 - inset, gy + 1.0 - inset)
	var p_left: Vector2 = GameData.grid_to_iso(gx + inset, gy + 1.0 - inset)
	var h_vec := Vector2(0.0, -height)

	var u_top: Vector2 = p_top + h_vec
	var u_right: Vector2 = p_right + h_vec
	var u_bottom: Vector2 = p_bottom + h_vec
	var u_left: Vector2 = p_left + h_vec

	if height > 0.0:
		var left_face := PackedVector2Array([u_left, u_bottom, p_bottom, p_left])
		var right_face := PackedVector2Array([u_bottom, u_right, p_right, p_bottom])
		canvas.draw_colored_polygon(left_face, top_col.darkened(0.28))
		canvas.draw_colored_polygon(right_face, top_col.darkened(0.42))

	var top_face := PackedVector2Array([u_top, u_right, u_bottom, u_left])
	canvas.draw_colored_polygon(top_face, top_col)
	var outline := PackedVector2Array([u_top, u_right, u_bottom, u_left, u_top])
	canvas.draw_polyline(outline, border_col, 1.5)

static func draw_world(
	canvas: CanvasItem,
	sim: GridSimulation,
	game_started: bool,
	anim_time: float,
	hovered_tile: Vector2i,
	selected_hand_index: int,
	floating_texts: Array,
	flash_color: Color,
	flash_alpha: float,
	debris_effects: Array = [],
	upgrade_sparkles: Array = [],
	reclamation_effects: Array = [],
	carbon_lens_active: bool = false,
	dawn_sweep_timer: float = 0.0,
	hovered_hand_index: int = -1,
	synergy_bursts: Array = []
) -> void:
	if not game_started:
		canvas.draw_rect(Rect2(-3000, -2000, 6000, 5000), Color(0.03, 0.07, 0.10), true)
		return

	_ensure_textures()

	var font: Font = ThemeDB.fallback_font
	var c_ratio: float = clampf(float(sim.carbon) / float(GameData.MAX_CARBON), 0.0, 1.0)
	var is_desert: bool = (sim.current_scenario == 2)
	var clean_sky := Color(0.12, 0.09, 0.07) if is_desert else Color(0.04, 0.12, 0.16)
	var polluted_sky := Color(0.26, 0.13, 0.08) if is_desert else Color(0.22, 0.11, 0.09)
	var sky_col: Color = clean_sky.lerp(polluted_sky, c_ratio)
	canvas.draw_rect(Rect2(-3000, -2000, 6000, 5000), sky_col, true)

	# Uzak Ufuk ve Atmosfer Dağ / Rüzgar Türbini Silüetleri (Distant Atmospheric Horizon)
	_draw_atmospheric_horizon(canvas, sim, anim_time, c_ratio, is_desert)

	for x in range(GameData.GRID_SIZE):
		for y in range(GameData.GRID_SIZE):
			var state: int = sim.grid_state[x][y]
			var btype: int = sim.grid_building[x][y]
			var blvl: int = sim.grid_level[x][y]

			var base_col := Color(0.16, 0.18, 0.22)
			var border_col := Color(0.24, 0.28, 0.34)
			var base_height: float = 6.0

			if state == GameData.TileState.BORDER:
				if is_desert:
					base_col = Color(0.42, 0.34, 0.22)
					border_col = Color(0.85, 0.72, 0.38, 0.90)
				else:
					base_col = Color(0.26, 0.30, 0.20)
					border_col = Color(0.72, 0.78, 0.38, 0.90)
				base_height = 9.0
			elif state == GameData.TileState.UNLOCKED:
				if is_desert:
					var has_green_neighbor: bool = false
					for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
						var nx: int = x + d.x
						var ny: int = y + d.y
						if nx >= 0 and nx < GameData.GRID_SIZE and ny >= 0 and ny < GameData.GRID_SIZE:
							var nb: int = sim.grid_building[nx][ny]
							if nb == GameData.BuildingType.FOREST or nb == GameData.BuildingType.LAKE or nb == GameData.BuildingType.BIOCORRIDOR or nb == GameData.BuildingType.WATER_PLANT:
								has_green_neighbor = true
								break
					if has_green_neighbor or btype == GameData.BuildingType.FOREST or btype == GameData.BuildingType.FARM:
						base_col = Color(0.24, 0.42, 0.26)
						border_col = Color(0.45, 0.82, 0.52, 0.92)
					else:
						base_col = Color(0.48, 0.38, 0.24)
						border_col = Color(0.82, 0.68, 0.38, 0.90)
				else:
					base_col = Color(0.18, 0.38, 0.26)
					border_col = Color(0.35, 0.72, 0.48, 0.90)
				base_height = 12.0

			# Kömür Santrali Çevre Kirliliği ve İs Leke Halosu
			var near_coal: bool = false
			if state == GameData.TileState.UNLOCKED and btype != GameData.BuildingType.LAKE:
				for cd in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
					var cx: int = x + cd.x
					var cy: int = y + cd.y
					if cx >= 0 and cx < GameData.GRID_SIZE and cy >= 0 and cy < GameData.GRID_SIZE:
						if sim.grid_building[cx][cy] == GameData.BuildingType.COAL_PLANT or sim.grid_building[cx][cy] == GameData.BuildingType.FOSSIL:
							near_coal = true
							break
				if near_coal and btype != GameData.BuildingType.COAL_PLANT and btype != GameData.BuildingType.FOSSIL:
					base_col = base_col.lerp(Color(0.20, 0.16, 0.15), 0.55)
					border_col = border_col.lerp(Color(0.48, 0.32, 0.28), 0.65)

			if btype == GameData.BuildingType.LAKE:
				base_col = Color(0.14, 0.48, 0.82)
				border_col = Color(0.38, 0.78, 0.98)
				base_height = 5.0

			var tile_tex: Texture2D = null
			if state == GameData.TileState.LOCKED:
				tile_tex = _textures.get("tile_ocean", null)
			elif state == GameData.TileState.BORDER:
				tile_tex = _textures.get("tile_border", null)
			elif state == GameData.TileState.UNLOCKED:
				if btype == GameData.BuildingType.LAKE:
					tile_tex = null
				elif near_coal:
					tile_tex = _textures.get("tile_industrial", null)
				elif is_desert:
					tile_tex = _textures.get("tile_desert", null)
				elif btype == GameData.BuildingType.NONE:
					var use_grid_pattern: bool = ((x + y) % 3 == 0)
					tile_tex = _textures.get("tile_grid", null) if use_grid_pattern else _textures.get("tile_meadow", null)
				else:
					if btype == GameData.BuildingType.FOREST or btype == GameData.BuildingType.BIOCORRIDOR:
						tile_tex = _textures.get("tile_meadow", null)
					else:
						tile_tex = _textures.get("tile_grid", null)

			var tile_center_base: Vector2 = GameData.grid_to_iso(x + 0.5, y + 0.5) + Vector2(0.0, -base_height)

			if tile_tex != null:
				var t_w: float = float(tile_tex.get_width())
				var t_h: float = float(tile_tex.get_height())
				var draw_tw: float = GameData.ISO_W
				var draw_th: float = GameData.ISO_W * (t_h / t_w)
				var dest_rect := Rect2(tile_center_base.x - draw_tw * 0.5, tile_center_base.y - GameData.ISO_H * 0.5, draw_tw, draw_th)
				canvas.draw_texture_rect(tile_tex, dest_rect, false)
			else:
				draw_iso_prism(canvas, x, y, base_col, border_col, base_height, 0.03)

			# Eco-Grid İnşaat Kılavuz Noktası ve Doğal Zemin Detayları
			if state == GameData.TileState.UNLOCKED and btype == GameData.BuildingType.NONE:
				var center_p: Vector2 = tile_center_base
				canvas.draw_circle(center_p, 1.8, Color(0.48, 0.95, 0.65, 0.45))
				if not is_desert:
					# Açık Eko-Çayır Solarpunk Enerji Damarları (Tile 1 Sanatına Uygun)
					var circuit_pulse: float = 0.35 + 0.25 * sin(anim_time * 2.5 + float(x * 2 + y * 3))
					var circuit_col := Color(0.28, 0.95, 0.82, circuit_pulse)
					canvas.draw_line(center_p + Vector2(-12.0, -6.0), center_p + Vector2(-4.0, -2.0), circuit_col, 1.2)
					canvas.draw_line(center_p + Vector2(12.0, 6.0), center_p + Vector2(4.0, 2.0), circuit_col, 1.2)
					# Yaban Kır Çiçekleri
					var h_val: int = int(abs(sin(float(x * 13 + y * 29)) * 1000.0)) % 10
					if h_val < 5:
						var flw_off := Vector2(((h_val % 3) - 1.0) * 8.0, ((h_val / 3) - 0.5) * 5.0)
						var flw_col := Color(0.96, 0.88, 0.42, 0.75) if (h_val % 2 == 0) else Color(0.92, 0.55, 0.75, 0.75)
						canvas.draw_circle(center_p + flw_off, 1.4, flw_col)
				else:
					var h_val: int = int(abs(sin(float(x * 17 + y * 31)) * 1000.0)) % 10
					if h_val < 4:
						var p_off := Vector2(((h_val % 3) - 1.0) * 7.0, ((h_val / 3) - 0.5) * 4.0)
						canvas.draw_circle(center_p + p_off, 1.3, Color(0.72, 0.58, 0.35, 0.80))

			elif state == GameData.TileState.BORDER:
				# Sınır / Islah Karosu: Sarı-Siyah Güvenlik Şeritli Islah İşaret Kazığı (Tile 3 Sanatına Uygun)
				var center_p: Vector2 = tile_center_base
				var b_pulse: float = 0.45 + 0.35 * sin(anim_time * 3.8 + float(x * 4 + y * 3))
				var peg_col := Color(1.0, 0.80, 0.25, b_pulse)
				canvas.draw_line(center_p + Vector2(0.0, -2.0), center_p + Vector2(0.0, -10.0), peg_col, 1.8)
				canvas.draw_circle(center_p + Vector2(0.0, -11.0), 2.0, Color(1.0, 0.95, 0.45, 0.95))

			elif state == GameData.TileState.LOCKED:
				# Kilitli Okyanus / Sis: Kaustik Işık Dalgalanması ve Biyo-Işıma (Tile 5 Sanatına Uygun)
				var center_p: Vector2 = tile_center_base
				var c_time: float = anim_time * 2.2 + float(x * 1.9 + y * 2.7)
				var c_alpha: float = 0.16 + 0.10 * sin(c_time)
				canvas.draw_arc(center_p, 9.0, 0.2 + sin(c_time * 0.6) * 0.5, 2.2, 8, Color(0.40, 0.85, 1.0, c_alpha), 1.2)

			# Seçili veya Vurgulanan Kart İçin Geçerli İnşa / Yükseltme Kılavuz Nabız Halosu
			var active_guide_cid: int = -1
			var is_selected_guide: bool = false
			if selected_hand_index >= 0 and selected_hand_index < sim.hand.size():
				active_guide_cid = sim.hand[selected_hand_index]
				is_selected_guide = true
			elif hovered_hand_index >= 0 and hovered_hand_index < sim.hand.size():
				active_guide_cid = sim.hand[hovered_hand_index]
				is_selected_guide = false

			if active_guide_cid >= 0:
				if sim.is_tile_valid_for_card(Vector2i(x, y), active_guide_cid):
					var tile_c: Vector2 = GameData.grid_to_iso(x + 0.5, y + 0.5) + Vector2(0.0, -base_height)
					var b_pulse: float = 0.5 + 0.5 * sin(anim_time * 5.0 + float(x * 3 + y * 2))
					var is_upgrade: bool = (btype != GameData.BuildingType.NONE and btype == GameData.CARDS[active_guide_cid].get("building", -1))
					var intensity: float = 1.0 if is_selected_guide else 0.55
					var beacon_col := Color(1.0, 0.88, 0.32, 0.80 * b_pulse * intensity) if is_upgrade else Color(0.35, 1.0, 0.58, 0.75 * b_pulse * intensity)
					canvas.draw_circle(tile_c, 2.5 if is_selected_guide else 2.0, beacon_col)
					canvas.draw_arc(tile_c, 6.0 + 3.0 * b_pulse, 0.0, TAU, 14, Color(beacon_col.r, beacon_col.g, beacon_col.b, 0.35 * b_pulse * intensity), 1.2)

			if btype != GameData.BuildingType.NONE:
				var vis: Dictionary = GameData.get_building_visual(btype)
				var anim_scale: float = sim.tile_anim.get(Vector2i(x, y), 1.0)
				var tile_c: Vector2 = GameData.grid_to_iso(x + 0.5, y + 0.5) + Vector2(0.0, -base_height)
				var b_tex: Texture2D = null
				if blvl >= 3 and _textures.has("mega_%d" % btype):
					b_tex = _textures["mega_%d" % btype]
				elif blvl == 2 and _textures.has("lvl2_%d" % btype):
					b_tex = _textures["lvl2_%d" % btype]
				else:
					b_tex = _textures.get(btype, null)
				var roof_pos: Vector2
				var draw_w: float = 70.0
				var draw_h: float = 70.0

				if b_tex != null:
					var target_w: float = 70.0
					match btype:
						GameData.BuildingType.FARM:
							target_w = 64.0 if blvl >= 3 else 46.0
						GameData.BuildingType.WIND:
							target_w = 68.0 if blvl >= 3 else 64.0
						GameData.BuildingType.HOUSING:
							target_w = 72.0 if blvl >= 3 else 68.0
						GameData.BuildingType.COAL_PLANT, GameData.BuildingType.FOSSIL:
							target_w = 72.0
						GameData.BuildingType.LAKE:
							target_w = 68.0
						GameData.BuildingType.BATTERY:
							target_w = 72.0 if blvl >= 3 else 68.0
						GameData.BuildingType.COP31:
							target_w = 76.0 if blvl >= 3 else 70.0
						_:
							target_w = 74.0 if blvl >= 3 else 70.0

					var tw: float = float(b_tex.get_width())
					var th: float = float(b_tex.get_height())
					var aspect: float = th / tw
					var lvl_scale: float = 1.10 if blvl >= 3 else (1.05 if blvl == 2 else 1.0)
					draw_w = target_w * anim_scale * lvl_scale
					draw_h = (target_w * aspect) * anim_scale * lvl_scale
					var anchor_y: float = tile_c.y + (16.0 if btype == GameData.BuildingType.LAKE else 14.0)
					var dest_rect := Rect2(tile_c.x - draw_w * 0.5, anchor_y - draw_h, draw_w, draw_h)

					if blvl >= 3:
						var glow_p: float = 0.6 + 0.4 * sin(anim_time * 5.0)
						canvas.draw_arc(Vector2(tile_c.x, anchor_y - 8.0), draw_w * 0.44, 0.0, TAU, 24, Color(0.28, 0.95, 1.0, 0.65 * glow_p), 2.5)
						canvas.draw_arc(Vector2(tile_c.x, anchor_y - 8.0), draw_w * 0.36, 0.0, TAU, 24, Color(1.0, 0.90, 0.35, 0.55 * glow_p), 1.8)
					elif blvl == 2:
						var glow_p: float = 0.5 + 0.5 * sin(anim_time * 4.0)
						canvas.draw_arc(Vector2(tile_c.x, anchor_y - 8.0), draw_w * 0.38, 0.0, TAU, 20, Color(1.0, 0.88, 0.30, 0.40 * glow_p), 2.0)

					canvas.draw_texture_rect(b_tex, dest_rect, false)
					roof_pos = Vector2(tile_c.x, anchor_y - draw_h)
				else:
					var lvl_bonus_h: float = 16.0 if blvl >= 3 else (10.0 if blvl == 2 else 0.0)
					var b_height: float = (vis["height"] + lvl_bonus_h) * anim_scale
					var top_c: Color = vis["color"].lightened(0.25) if blvl >= 3 else (vis["color"].lightened(0.15) if blvl == 2 else vis["color"])
					var brd_c: Color = Color(0.35, 1.0, 0.9, 0.98) if blvl >= 3 else (Color(1.0, 0.92, 0.35, 0.95) if blvl == 2 else Color(1, 1, 1, 0.65))
					if btype != GameData.BuildingType.LAKE:
						draw_iso_prism(canvas, x, y, top_c, brd_c, base_height + b_height, 0.12 if blvl >= 3 else (0.15 if blvl == 2 else 0.18))
					roof_pos = GameData.grid_to_iso(x + 0.5, y + 0.5) + Vector2(0.0, -(base_height + b_height))

				# Özel Prosedürel Mimari Çizimler ve Efektler
				match btype:
					GameData.BuildingType.WIND:
						if b_tex == null:
							# Türbin direği
							var mast_h: float = 14.0 if blvl == 2 else 11.0
							canvas.draw_line(roof_pos + Vector2(0.0, mast_h), roof_pos, Color(0.85, 0.90, 0.96), 3.2)
							canvas.draw_line(roof_pos + Vector2(0.8, mast_h), roof_pos + Vector2(0.8, 0.0), Color(0.68, 0.74, 0.82), 1.0)

							# Kanat aerodinamik dönüşü ve vorteks hava akımı çizgileri
							var b_len: float = 19.0 if blvl == 2 else 15.5
							var rot_spd: float = 4.0 if blvl == 2 else 3.4
							for blade in range(3):
								var ang: float = anim_time * rot_spd + float(blade) * (TAU / 3.0)
								var tip: Vector2 = roof_pos + Vector2(cos(ang), sin(ang) * 0.55) * b_len
								canvas.draw_line(roof_pos, tip, Color(0.95, 0.98, 1.0, 0.95), 2.4)
								if blvl == 2:
									canvas.draw_line(tip - (tip - roof_pos).normalized() * 4.0, tip, Color(0.28, 0.85, 1.0, 0.95), 2.4)
								var trail_ang: float = ang - 0.38
								var trail_pos: Vector2 = roof_pos + Vector2(cos(trail_ang), sin(trail_ang) * 0.55) * (b_len - 1.0)
								canvas.draw_line(tip, trail_pos, Color(0.65, 0.90, 1.0, 0.40), 1.2)

							var hub_col: Color = Color(0.25, 0.92, 1.0) if blvl == 2 else Color(1.0, 0.85, 0.30)
							canvas.draw_circle(roof_pos, 3.0, hub_col)
							canvas.draw_circle(roof_pos, 1.5, Color(1.0, 1.0, 1.0, 0.95))
						else:
							var hub_pos := Vector2(tile_c.x - 2.0, roof_pos.y + draw_h * 0.30)
							var rot_spd: float = 4.0 if blvl == 2 else 3.4
							for blade in range(3):
								var ang: float = anim_time * rot_spd + float(blade) * (TAU / 3.0)
								var trail_ang: float = ang - 0.35
								var tip: Vector2 = hub_pos + Vector2(cos(ang), sin(ang) * 0.55) * 16.0
								var trail_pos: Vector2 = hub_pos + Vector2(cos(trail_ang), sin(trail_ang) * 0.55) * 15.0
								canvas.draw_line(tip, trail_pos, Color(0.65, 0.92, 1.0, 0.35), 1.2)
							var hub_col: Color = Color(0.25, 0.92, 1.0) if blvl == 2 else Color(1.0, 0.85, 0.30)
							canvas.draw_circle(hub_pos, 2.8, hub_col)
							canvas.draw_circle(hub_pos, 1.2, Color(1.0, 1.0, 1.0, 0.95))

					GameData.BuildingType.SOLAR:
						var p_top_c := (roof_pos + Vector2(0.0, draw_h * 0.50)) if b_tex != null else (roof_pos + Vector2(0.0, -2.0))
						if b_tex == null:
							var p_w: float = 13.5 if blvl == 2 else 11.5
							var p_h: float = 6.8 if blvl == 2 else 5.8
							var panel_poly := PackedVector2Array([
								p_top_c + Vector2(0.0, -p_h),
								p_top_c + Vector2(p_w, 0.0),
								p_top_c + Vector2(0.0, p_h),
								p_top_c + Vector2(-p_w, 0.0)
							])
							var pv_bg := Color(0.10, 0.32, 0.62, 0.92) if blvl == 2 else Color(0.12, 0.35, 0.65, 0.85)
							canvas.draw_colored_polygon(panel_poly, pv_bg)
							var grid_c := Color(0.45, 0.82, 1.0, 0.85)
							canvas.draw_polyline(PackedVector2Array([p_top_c + Vector2(0.0, -p_h), p_top_c + Vector2(0.0, p_h)]), grid_c, 1.0)
							canvas.draw_polyline(PackedVector2Array([p_top_c + Vector2(-p_w, 0.0), p_top_c + Vector2(p_w, 0.0)]), grid_c, 1.0)
							canvas.draw_polyline(panel_poly, Color(0.70, 0.90, 1.0, 0.90), 1.2)

						# Güneş ışığı yansıma parıltısı ve yıldız ışıltısı (Solar Specular Glint)
						var glare_t: float = sin(anim_time * 2.2 + float(x * 3 + y * 2))
						var glare_p := p_top_c + Vector2(glare_t * 9.0, glare_t * 4.0 - 1.0)
						canvas.draw_circle(glare_p, 2.2, Color(1.0, 1.0, 0.92, 0.95))
						canvas.draw_line(glare_p + Vector2(-3.5, 0.0), glare_p + Vector2(3.5, 0.0), Color(1.0, 1.0, 1.0, 0.85), 1.0)
						canvas.draw_line(glare_p + Vector2(0.0, -2.5), glare_p + Vector2(0.0, 2.5), Color(1.0, 1.0, 1.0, 0.85), 1.0)

						# Lv.2★ Güneş Takip Aynaları ve Mikro-İnverter LED
						if blvl == 2:
							if b_tex == null:
								var p_w2: float = 13.5
								var m_l := PackedVector2Array([
									p_top_c + Vector2(-p_w2 - 4.0, -2.0),
									p_top_c + Vector2(-p_w2, 0.0),
									p_top_c + Vector2(-p_w2 - 3.0, 4.0)
								])
								var m_r := PackedVector2Array([
									p_top_c + Vector2(p_w2 + 4.0, 2.0),
									p_top_c + Vector2(p_w2, 0.0),
									p_top_c + Vector2(p_w2 + 3.0, -4.0)
								])
								canvas.draw_colored_polygon(m_l, Color(0.85, 0.95, 1.0, 0.75))
								canvas.draw_colored_polygon(m_r, Color(0.85, 0.95, 1.0, 0.75))
							var led_pos := p_top_c + Vector2(10.0, 6.0)
							var led_pulse: float = 0.75 + 0.25 * sin(anim_time * 4.0)
							canvas.draw_circle(led_pos, 1.6, Color(0.20, 1.0, 0.50, led_pulse * 0.95))

					GameData.BuildingType.FOREST:
						var canopy_pos := (roof_pos + Vector2(0.0, draw_h * 0.45)) if b_tex != null else roof_pos
						# Biyo-Fotosentez Zümrüt Aurası (Bio-Photosynthesis Emerald Aura)
						var photo_pulse: float = 0.5 + 0.5 * sin(anim_time * 2.2 + float(x * 3 + y * 2))
						canvas.draw_arc(canopy_pos + Vector2(0.0, 1.0), 16.0, 0.0, TAU, 20, Color(0.35, 0.95, 0.55, 0.25 * photo_pulse), 1.6)

						# Yükselen Oksijen & Klorofil Baloncukları (Rising Oxygen / Chlorophyll Sparkles)
						for sp_i in range(2):
							var sp_t: float = fmod(anim_time * 0.9 + float(sp_i) * 0.5 + float(x * 4 + y), 1.0)
							var sp_y: float = -6.0 - sp_t * 20.0
							var sp_x: float = sin(sp_t * TAU + float(sp_i)) * 6.0
							var sp_alpha: float = (1.0 - sp_t) * 0.8
							canvas.draw_circle(canopy_pos + Vector2(sp_x, sp_y), 1.4, Color(0.55, 1.0, 0.65, sp_alpha))

						if b_tex == null:
							var sway: float = sin(anim_time * 1.6 + float(x + y)) * 1.5
							var tree_offsets: Array = [Vector2(-7.0, -3.0), Vector2(7.0, -2.0), Vector2(0.0, 4.0)]
							for t_idx in range(tree_offsets.size()):
								var t_pos: Vector2 = canopy_pos + tree_offsets[t_idx] + Vector2(sway, 0.0)
								canvas.draw_circle(t_pos, 7.5, Color(0.12, 0.38, 0.18, 0.95))
								canvas.draw_circle(t_pos + Vector2(1.0, -1.5), 5.5, Color(0.24, 0.60, 0.28, 0.95))
								canvas.draw_circle(t_pos + Vector2(2.0, -3.0), 2.5, Color(0.48, 0.85, 0.42, 0.95))
						if blvl == 2 or sim.carbon <= 25:
							var b_ang: float = anim_time * 2.8 + float(x * 5 + y)
							var b_pos: Vector2 = canopy_pos + Vector2(cos(b_ang) * 11.0, sin(b_ang * 2.0) * 5.0 - 12.0)
							canvas.draw_circle(b_pos, 2.0, Color(1.0, 0.92, 0.45, 0.95))
							canvas.draw_circle(b_pos + Vector2(1.2, 0.0), 1.2, Color(0.95, 0.55, 0.85, 0.90))

					GameData.BuildingType.LAKE:
						var lake_c: Vector2 = GameData.grid_to_iso(x + 0.5, y + 0.5) + Vector2(0.0, -base_height)
						for w_i in range(2):
							var wave_t: float = fmod(anim_time * 0.75 + float(w_i) * 0.5 + float(x + y) * 0.15, 1.0)
							var wave_r: float = 4.0 + wave_t * 14.0
							var wave_alpha: float = (1.0 - wave_t) * 0.55
							canvas.draw_arc(lake_c, wave_r, 0.0, TAU, 18, Color(0.65, 0.92, 1.0, wave_alpha), 1.2)

						# Nilüfer yaprağı ve nilüfer çiçeği (Water Lily & Blossom)
						var pad_pos := lake_c + Vector2(-6.0, 3.0)
						canvas.draw_circle(pad_pos, 3.4, Color(0.18, 0.65, 0.32, 0.90))
						canvas.draw_circle(pad_pos + Vector2(0.8, -0.8), 1.4, Color(0.96, 0.72, 0.88, 0.95))

						# Su üstü güneş parıltısı
						var glint_x: float = sin(anim_time * 3.0 + float(x * 7 + y)) * 8.0
						canvas.draw_circle(lake_c + Vector2(glint_x, -4.0), 1.5, Color(1.0, 1.0, 1.0, 0.75))

						# Kıyı Sazlıkları ve Hasırotları (Lakeside Riparian Reeds & Cattails)
						var reed_offsets := [Vector2(13.0, 1.5), Vector2(11.0, 4.0), Vector2(-12.0, -1.5), Vector2(-10.0, -4.0)]
						for r_i in range(reed_offsets.size()):
							var r_base: Vector2 = lake_c + reed_offsets[r_i]
							var r_sway: float = sin(anim_time * 2.4 + float(r_i) + float(x + y)) * 1.6
							var r_tip: Vector2 = r_base + Vector2(r_sway, -7.5)
							canvas.draw_line(r_base, r_tip, Color(0.24, 0.60, 0.28, 0.92), 1.4)
							canvas.draw_line(r_tip + Vector2(0, 1.6), r_tip, Color(0.48, 0.32, 0.16, 0.95), 2.0)

						# Su Üstü Yusufçuk / Ekolojik Biyo-Canlılık (Skimming Dragonfly)
						var df_ang: float = anim_time * 3.0 + float(x * 4 + y * 3)
						var df_pos: Vector2 = lake_c + Vector2(cos(df_ang) * 9.5, sin(df_ang) * 4.2 - 2.5)
						canvas.draw_circle(df_pos, 1.3, Color(0.35, 0.95, 0.92, 0.95))
						var wing_sway: float = sin(anim_time * 26.0) * 2.2
						canvas.draw_line(df_pos - Vector2(2.0, wing_sway), df_pos + Vector2(2.0, wing_sway), Color(0.88, 0.98, 1.0, 0.75), 1.0)

					GameData.BuildingType.WATER_PLANT:
						var wp_center := (roof_pos + Vector2(0.0, draw_h * 0.40)) if b_tex != null else roof_pos
						if b_tex == null:
							# Dairesel arıtma havuzu gövdesi ve çeperi
							canvas.draw_circle(wp_center, 12.0, Color(0.08, 0.30, 0.50, 0.95))
							canvas.draw_arc(wp_center, 12.0, 0.0, TAU, 24, Color(0.42, 0.78, 0.96, 0.95), 1.8)

						# Merkezden dışa yayılan havalandırma / arıtma su halkaları (Aeration ripples)
						for rip_i in range(2):
							var rip_t: float = fmod(anim_time * 1.1 + float(rip_i) * 0.5 + float(x + y) * 0.2, 1.0)
							var rip_r: float = 2.0 + rip_t * 9.5
							var rip_fade: float = 1.0 - rip_t
							canvas.draw_arc(wp_center, rip_r, 0.0, TAU, 18, Color(0.68, 0.92, 1.0, rip_fade * 0.65), 1.2)

						# Dönen çift taraflı sıyırıcı kol (Dual skimmer arm)
						var arm_ang: float = anim_time * 2.2
						var arm_tip1: Vector2 = wp_center + Vector2(cos(arm_ang), sin(arm_ang) * 0.55) * 10.5
						var arm_tip2: Vector2 = wp_center - Vector2(cos(arm_ang), sin(arm_ang) * 0.55) * 10.5
						canvas.draw_line(arm_tip1, arm_tip2, Color(0.88, 0.96, 1.0, 0.95), 2.2)
						canvas.draw_circle(wp_center, 3.2, Color(0.25, 0.68, 0.95))
						canvas.draw_circle(wp_center, 1.5, Color(1.0, 1.0, 1.0, 0.9))

						# Yeraltı Akifer ve Su Dağıtım Kanalı (Aquifer Hydro-Veins to adjacent Lakes/Farms)
						var wp_base: Vector2 = GameData.grid_to_iso(x + 0.5, y + 0.5) + Vector2(0.0, -base_height)
						for n_dir in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
							var nx: int = x + n_dir.x
							var ny: int = y + n_dir.y
							if nx >= 0 and nx < GameData.GRID_SIZE and ny >= 0 and ny < GameData.GRID_SIZE:
								var n_b: int = sim.grid_building[nx][ny]
								if n_b == GameData.BuildingType.LAKE or n_b == GameData.BuildingType.FARM:
									var n_h: float = 5.0 if n_b == GameData.BuildingType.LAKE else 12.0
									var n_c: Vector2 = GameData.grid_to_iso(nx + 0.5, ny + 0.5) + Vector2(0.0, -n_h)
									canvas.draw_line(wp_base, n_c, Color(0.18, 0.55, 0.88, 0.45), 2.0)
									var flow_t: float = fmod(anim_time * 1.6 + float(x * 3 + y * 5), 1.0)
									var droplet_p: Vector2 = wp_base.lerp(n_c, flow_t)
									canvas.draw_circle(droplet_p, 2.2, Color(0.55, 0.92, 1.0, 0.85))

						# Lv.2 Ek Arıtma Filtresi ve su damlacıkları
						if blvl == 2:
							var drop_ang: float = anim_time * 3.5
							var drop_pos: Vector2 = wp_center + Vector2(cos(drop_ang) * 14.0, sin(drop_ang) * 6.0 - 5.0)
							canvas.draw_circle(drop_pos, 1.8, Color(0.45, 0.88, 1.0, 0.95))

					GameData.BuildingType.GEOTHERMAL:
						var base_iso: Vector2 = GameData.grid_to_iso(x + 0.5, y + 0.5) + Vector2(0.0, -base_height)
						if b_tex == null:
							# Taban magma yarığı ve termal ışıltı (Fissure Heat Glow)
							var magma_pulse: float = 0.70 + 0.30 * sin(anim_time * 3.5 + float(x * 3 + y * 2))
							var fissure_col := Color(1.0, 0.42, 0.12, magma_pulse * 0.85)
							var core_col := Color(1.0, 0.86, 0.28, magma_pulse * 0.95)
							canvas.draw_line(base_iso + Vector2(-10.0, 3.0), base_iso + Vector2(10.0, 5.0), fissure_col, 2.5)
							canvas.draw_line(base_iso + Vector2(-5.0, 1.5), base_iso + Vector2(6.0, 6.5), core_col, 1.5)
							canvas.draw_circle(base_iso + Vector2(1.0, 4.0), 3.2, core_col)

						# Soğutma kulesi buhar püskürmesi (Pressurized Steam Geyser)
						var chimney_count: int = 2 if blvl == 2 else 1
						var geo_ch_y: float = (roof_pos.y + 14.0) if b_tex != null else roof_pos.y
						for ch_i in range(chimney_count):
							var ch_off := Vector2(-6.0 if ch_i == 0 else 6.0, -2.0) if chimney_count == 2 else Vector2.ZERO
							var ch_pos: Vector2 = Vector2(tile_c.x, geo_ch_y) + ch_off
							if b_tex == null:
								# Soğutma kulesi halkası
								canvas.draw_circle(ch_pos, 4.5, Color(0.28, 0.32, 0.38, 0.95))
								canvas.draw_circle(ch_pos, 3.0, Color(0.18, 0.22, 0.26, 0.95))

							for st_i in range(3):
								var st_cycle: float = fmod(anim_time * 0.95 + float(st_i) * 0.33 + float(ch_i) * 0.5, 1.0)
								var st_drift: float = sin(anim_time * 2.8 + float(st_i + ch_i * 2)) * 4.5
								var st_pos: Vector2 = ch_pos + Vector2(st_drift, -st_cycle * 28.0)
								var st_r: float = 3.2 + st_cycle * 6.5
								var st_alpha: float = (1.0 - st_cycle) * (0.65 if blvl == 2 else 0.50)
								# Çift katmanlı termal buhar bulutu
								canvas.draw_circle(st_pos, st_r, Color(0.72, 0.92, 1.0, st_alpha * 0.55))
								canvas.draw_circle(st_pos + Vector2(0.5, -0.5), st_r * 0.65, Color(0.95, 0.98, 1.0, st_alpha * 0.85))

					GameData.BuildingType.FOSSIL, GameData.BuildingType.COAL_PLANT:
						var is_coal: bool = (btype == GameData.BuildingType.COAL_PLANT)
						var puff_count: int = 3 if is_coal else 2
						var ch_origin: Vector2 = Vector2(tile_c.x + 8.0, roof_pos.y + 12.0) if b_tex != null else roof_pos

						if b_tex == null:
							# Baca ağzı uyarısı ve is lekesi
							canvas.draw_circle(ch_origin, 4.2, Color(0.20, 0.20, 0.22, 0.95))
							if is_coal:
								canvas.draw_arc(ch_origin, 4.2, 0.0, TAU, 12, Color(0.95, 0.35, 0.15, 0.85), 1.2)

						# Rüzgarla sürüklenen katmanlı asit & is dumanı
						for p_i in range(puff_count):
							var cycle: float = fmod(anim_time * 0.75 + float(p_i) * (1.0 / float(puff_count)) + float(x * 3 + y) * 0.13, 1.0)
							var drift_x: float = sin(anim_time * 2.2 + float(p_i)) * 4.0 + cycle * 15.0
							var smoke_pos: Vector2 = ch_origin + Vector2(drift_x, -cycle * 32.0)
							var sm_r: float = 3.8 + cycle * 7.5
							var fade: float = 1.0 - cycle

							# Kükürtlü / kirli dış hale
							var halo_col: Color = Color(0.40, 0.36, 0.24, fade * 0.45) if is_coal else Color(0.35, 0.35, 0.38, fade * 0.35)
							canvas.draw_circle(smoke_pos, sm_r, halo_col)
							# İç katran / is çekirdeği
							canvas.draw_circle(smoke_pos + Vector2(0.5, 0.5), sm_r * 0.62, Color(0.16, 0.16, 0.18, fade * 0.75))

						# Kömür santralinden göğe sıçrayan köz kıvılcımları
						if is_coal:
							for em_i in range(3):
								var em_cycle: float = fmod(anim_time * 1.9 + float(em_i) * 0.33, 1.0)
								var em_drift: float = cos(anim_time * 4.5 + float(em_i)) * 5.5 + em_cycle * 12.0
								var em_pos: Vector2 = ch_origin + Vector2(em_drift, -em_cycle * 24.0)
								var em_fade: float = 1.0 - em_cycle
								canvas.draw_circle(em_pos, 1.4, Color(1.0, 0.68, 0.18, em_fade * 0.95))
								canvas.draw_circle(em_pos, 0.7, Color(1.0, 0.92, 0.45, em_fade))

					GameData.BuildingType.CCS:
						var ccs_center := (roof_pos + Vector2(0.0, draw_h * 0.48)) if b_tex != null else roof_pos
						if b_tex == null:
							# Havadan Doğrudan Karbon Yakalama Türbini (Direct Air Capture Turbine)
							canvas.draw_circle(ccs_center, 8.5, Color(0.18, 0.32, 0.44, 0.95))
							canvas.draw_arc(ccs_center, 8.5, 0.0, TAU, 20, Color(0.45, 0.88, 1.0, 0.95), 1.8)

							# Dönen vakum emiş fanı
							var fan_ang: float = anim_time * 6.5
							for f_i in range(4):
								var f_tip: Vector2 = ccs_center + Vector2(cos(fan_ang + float(f_i) * (TAU / 4.0)), sin(fan_ang + float(f_i) * (TAU / 4.0)) * 0.55) * 7.0
								canvas.draw_line(ccs_center, f_tip, Color(0.75, 0.95, 1.0, 0.90), 1.6)
							canvas.draw_circle(ccs_center, 2.4, Color(0.35, 0.92, 1.0))

						# Havadan merkeze çekilen karbon zerreleri (Inward suction carbon particles)
						for suc_i in range(3):
							var in_cycle: float = 1.0 - fmod(anim_time * 1.6 + float(suc_i) * 0.33, 1.0)
							var s_ang: float = anim_time * 2.2 + float(suc_i) * (TAU / 3.0)
							var in_pos: Vector2 = ccs_center + Vector2(cos(s_ang) * in_cycle * 22.0, sin(s_ang) * in_cycle * 11.0 - in_cycle * 14.0)
							canvas.draw_circle(in_pos, 1.5, Color(0.40, 0.88, 1.0, (1.0 - in_cycle) * 0.85))

						# Yeraltı jeolojik mineralizasyon ve enjeksiyon halkası (Deep Geological Sequestration)
						var base_iso: Vector2 = GameData.grid_to_iso(x + 0.5, y + 0.5) + Vector2(0.0, -base_height)
						var seq_t: float = fmod(anim_time * 2.0 + float(x + y) * 0.3, 1.0)
						var seq_y: float = seq_t * 11.0
						canvas.draw_circle(base_iso + Vector2(0.0, 3.0 + seq_y), 2.2, Color(0.28, 0.96, 0.82, (1.0 - seq_t) * 0.9))
						canvas.draw_arc(base_iso + Vector2(0.0, 14.0), 3.5 + seq_t * 8.5, 0.0, TAU, 16, Color(0.22, 0.92, 0.75, (1.0 - seq_t) * 0.65), 1.2)

					GameData.BuildingType.BIOCORRIDOR:
						# Yaban hayatı geçiş kemeri (Wildlife Overpass Arch)
						canvas.draw_arc(roof_pos + Vector2(0.0, 1.0), 9.5, PI, TAU, 18, Color(0.20, 0.68, 0.32, 0.95), 3.0)
						canvas.draw_circle(roof_pos + Vector2(-8.0, 0.5), 2.2, Color(1.0, 0.85, 0.35, 0.95))
						canvas.draw_circle(roof_pos + Vector2(8.0, 0.5), 2.2, Color(0.95, 0.55, 0.78, 0.95))

						# Köprüden geçen minik yaban hayatı silüeti (Micro Wildlife Crossing)
						var cross_t: float = fmod(anim_time * 0.32 + float(x * 5 + y * 2) * 0.22, 1.0)
						var animal_x: float = lerpf(-7.5, 7.5, cross_t)
						var animal_y: float = -sin(cross_t * PI) * 5.2 - 2.0
						var animal_pos: Vector2 = roof_pos + Vector2(animal_x, animal_y)
						canvas.draw_circle(animal_pos, 1.4, Color(0.88, 0.68, 0.45, 0.95))
						canvas.draw_circle(animal_pos + Vector2(0.8, -0.6), 0.8, Color(0.95, 0.82, 0.65, 0.95))

						# Göğe uçuşan biyo-sporlar
						for b_i in range(3):
							var bang: float = anim_time * 2.2 + float(b_i) * (TAU / 3.0)
							var bpos: Vector2 = roof_pos + Vector2(cos(bang) * 12.0, sin(bang * 2.0) * 5.0 - 7.0)
							canvas.draw_circle(bpos, 2.4, Color(0.68, 1.0, 0.45, 0.85))

						# Çift Tozlayıcı Kelebek & Polen (Pollinator Flutter)
						for k_i in range(2):
							var k_ang: float = anim_time * 2.8 + float(k_i) * PI + float(x * 3 + y)
							var k_pos: Vector2 = roof_pos + Vector2(cos(k_ang) * 11.0, sin(k_ang * 2.0) * 4.5 - 11.0)
							var k_col := Color(0.98, 0.78, 0.25, 0.95) if k_i == 0 else Color(0.95, 0.48, 0.80, 0.95)
							canvas.draw_circle(k_pos, 1.4, k_col)
							var wing: float = sin(anim_time * 18.0 + float(k_i)) * 1.4
							canvas.draw_line(k_pos - Vector2(1.2, wing), k_pos + Vector2(1.2, -wing), Color(1.0, 1.0, 1.0, 0.85), 0.9)

						if blvl == 2:
							var bio_pulse: float = 0.75 + 0.25 * sin(anim_time * 3.0)
							canvas.draw_arc(roof_pos + Vector2(0.0, -3.0), 13.5, 0.0, TAU, 20, Color(0.40, 0.95, 0.65, 0.50 * bio_pulse), 1.5)

					GameData.BuildingType.HOUSING:
						# Çok Katmanlı Solarpunk Pencereler ve Gece Işıltısı
						var num_win_rows: int = 4 if blvl >= 3 else (3 if blvl == 2 else 2)
						var win_col_tint := Color(0.35, 0.95, 0.85) if blvl >= 3 else (Color(1.0, 0.90, 0.50) if blvl == 2 else Color(1.0, 0.94, 0.60))
						for w_row in range(num_win_rows):
							var win_y: float = roof_pos.y + 8.0 + float(w_row) * 7.5
							var win_glow: float = 0.72 + 0.28 * sin(anim_time * 1.8 + float(x * 3 + y * 2 + w_row))
							var final_win_col := Color(win_col_tint.r, win_col_tint.g, win_col_tint.b, win_glow * 0.92)
							# Sol ve sağ pencereler
							canvas.draw_rect(Rect2(roof_pos.x - 8.0, win_y, 4.2, 4.8), final_win_col)
							canvas.draw_rect(Rect2(roof_pos.x + 3.8, win_y, 4.2, 4.8), final_win_col)
							# Pencere iç parıltı çekirdeği
							canvas.draw_rect(Rect2(roof_pos.x - 7.0, win_y + 1.0, 2.2, 2.8), Color(1.0, 1.0, 0.95, win_glow * 0.95))
							canvas.draw_rect(Rect2(roof_pos.x + 4.8, win_y + 1.0, 2.2, 2.8), Color(1.0, 1.0, 0.95, win_glow * 0.95))

						# Balkon Eko-Seraları ve Asma Bahçeler
						if blvl >= 2:
							var balc_y: float = roof_pos.y + 14.0
							canvas.draw_line(Vector2(roof_pos.x - 9.0, balc_y), Vector2(roof_pos.x - 3.5, balc_y), Color(0.22, 0.68, 0.35, 0.95), 1.6)
							canvas.draw_line(Vector2(roof_pos.x + 3.5, balc_y), Vector2(roof_pos.x + 9.0, balc_y), Color(0.22, 0.68, 0.35, 0.95), 1.6)
							canvas.draw_circle(Vector2(roof_pos.x - 6.0, balc_y - 1.5), 1.5, Color(1.0, 0.85, 0.30, 0.9))
							canvas.draw_circle(Vector2(roof_pos.x + 6.0, balc_y - 1.5), 1.5, Color(0.95, 0.55, 0.80, 0.9))
						if blvl >= 3:
							# Mega Çatı Bahçesi Işık Şeritleri
							var roof_pulse: float = 0.75 + 0.25 * sin(anim_time * 3.5)
							canvas.draw_arc(roof_pos + Vector2(0.0, -2.0), 9.0, 0.0, TAU, 16, Color(0.35, 1.0, 0.75, roof_pulse * 0.8), 1.5)

						# Taban Güneş Enerjili Sokak Feneri ve Zemin Aydınlatma Havuzu
						var base_iso: Vector2 = GameData.grid_to_iso(x + 0.5, y + 0.5) + Vector2(0.0, -base_height)
						var lantern_pos := base_iso + Vector2(-12.0, 2.0)
						var lantern_glow: float = 0.80 + 0.20 * sin(anim_time * 2.2 + float(x + y))
						# Zemin aydınlatma halosu
						canvas.draw_circle(lantern_pos + Vector2(0.0, 2.0), 9.0, Color(1.0, 0.90, 0.45, lantern_glow * 0.20))
						# Fener direği ve altın LED
						canvas.draw_line(lantern_pos + Vector2(0.0, 3.0), lantern_pos + Vector2(0.0, -5.0), Color(0.35, 0.40, 0.45, 0.9), 1.2)
						canvas.draw_circle(lantern_pos + Vector2(0.0, -5.0), 4.2, Color(1.0, 0.88, 0.40, lantern_glow * 0.45))
						canvas.draw_circle(lantern_pos + Vector2(0.0, -5.0), 2.0, Color(1.0, 0.98, 0.80, lantern_glow * 0.98))

					GameData.BuildingType.FARM:
						var led_phase: float = sin(anim_time * 2.2 + float(x * 2 + y))
						var led_col := Color(0.92, 0.35, 0.95, 0.65 + 0.30 * led_phase)
						for f_row in range(3):
							var f_y: float = roof_pos.y + 10.0 + float(f_row) * 7.0
							canvas.draw_line(Vector2(roof_pos.x - 8.0, f_y), Vector2(roof_pos.x + 8.0, f_y), led_col, 2.0)
							canvas.draw_circle(Vector2(roof_pos.x - 5.0, f_y), 1.5, Color(0.45, 1.0, 0.55, 0.85))
							canvas.draw_circle(Vector2(roof_pos.x + 5.0, f_y), 1.5, Color(0.45, 1.0, 0.55, 0.85))

						# Dikey tarım hasat robotu (Automated Hydroponic Harvester Drone)
						var rob_t: float = sin(anim_time * 1.8 + float(x * 3 + y * 2)) * 0.5 + 0.5
						var rob_y: float = roof_pos.y + 10.0 + rob_t * 14.0
						canvas.draw_line(Vector2(roof_pos.x + 9.5, roof_pos.y + 8.0), Vector2(roof_pos.x + 9.5, roof_pos.y + 26.0), Color(0.35, 0.42, 0.50, 0.8), 1.2)
						canvas.draw_rect(Rect2(roof_pos.x + 8.0, rob_y - 2.0, 3.5, 4.0), Color(0.35, 0.88, 1.0, 0.95))
						canvas.draw_circle(Vector2(roof_pos.x + 9.7, rob_y), 1.0, Color(1.0, 0.95, 0.45, 0.95))

						if blvl == 2:
							var mist_cycle: float = fmod(anim_time * 1.5, 1.0)
							canvas.draw_arc(roof_pos + Vector2(0.0, -4.0), 4.0 + mist_cycle * 8.0, 0.0, TAU, 16, Color(0.45, 0.85, 1.0, (1.0 - mist_cycle) * 0.6), 1.2)

					GameData.BuildingType.RECYCLE:
						# Dönen 3'lü biyo-döngü geri dönüşüm okları
						var rec_ang: float = anim_time * 2.5
						var r_rad: float = 8.0
						for a_i in range(3):
							var ang: float = rec_ang + float(a_i) * (TAU / 3.0)
							var a_p: Vector2 = roof_pos + Vector2(cos(ang) * r_rad, sin(ang) * r_rad * 0.55 - 4.0)
							var col_i := Color(0.35, 0.92, 0.58) if a_i == 0 else (Color(0.38, 0.78, 1.0) if a_i == 1 else Color(1.0, 0.85, 0.35))
							canvas.draw_circle(a_p, 2.5, col_i)
							var next_ang: float = ang + 0.45
							var next_p: Vector2 = roof_pos + Vector2(cos(next_ang) * r_rad, sin(next_ang) * r_rad * 0.55 - 4.0)
							canvas.draw_line(a_p, next_p, Color(col_i.r, col_i.g, col_i.b, 0.8), 1.8)

						# Ayırma konveyörü ve malzeme akışı (Sorting conveyor)
						var base_iso: Vector2 = GameData.grid_to_iso(x + 0.5, y + 0.5) + Vector2(0.0, -base_height)
						canvas.draw_line(base_iso + Vector2(-10.0, 3.0), base_iso + Vector2(10.0, -2.0), Color(0.24, 0.28, 0.34, 0.9), 3.0)
						var conv_t: float = fmod(anim_time * 0.8 + float(x + y) * 0.2, 1.0)
						var item_pos := (base_iso + Vector2(-10.0, 3.0)).lerp(base_iso + Vector2(10.0, -2.0), conv_t)
						canvas.draw_circle(item_pos, 2.0, Color(0.42, 0.95, 0.62, 0.95))

						# Komşu Dikey Tarıma Organik Kompost / Biyo-Gübre Akışı (Organic Compost Drift)
						for n_dir in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
							var nx: int = x + n_dir.x
							var ny: int = y + n_dir.y
							if nx >= 0 and nx < GameData.GRID_SIZE and ny >= 0 and ny < GameData.GRID_SIZE:
								if sim.grid_building[nx][ny] == GameData.BuildingType.FARM:
									var farm_base: Vector2 = GameData.grid_to_iso(nx + 0.5, ny + 0.5) + Vector2(0.0, -12.0)
									for p_i in range(2):
										var comp_t: float = fmod(anim_time * 0.85 + float(p_i) * 0.5 + float(x * 2 + y), 1.0)
										var comp_p: Vector2 = base_iso.lerp(farm_base, comp_t) + Vector2(0.0, -sin(comp_t * PI) * 5.5)
										var comp_alpha: float = sin(comp_t * PI) * 0.85
										canvas.draw_circle(comp_p, 1.8, Color(0.48, 0.92, 0.35, comp_alpha))

					GameData.BuildingType.BATTERY:
						# Akıllı Mega-Batarya: Dikey LED şarj çubukları ve enerji nabzı
						var bat_y_base: float = roof_pos.y + 14.0
						for b_bar in range(4):
							var bar_x: float = roof_pos.x - 9.0 + float(b_bar) * 6.0
							var charge_pulse: float = fmod(anim_time * 2.2 + float(b_bar) * 0.25, 1.0)
							var bar_h: float = 6.0 + charge_pulse * 4.0
							var bar_col := Color(0.25, 0.95, 0.78, 0.85 + 0.15 * sin(anim_time * 6.0))
							canvas.draw_line(Vector2(bar_x, bat_y_base), Vector2(bar_x, bat_y_base - bar_h), bar_col, 2.2)
							canvas.draw_circle(Vector2(bar_x, bat_y_base - bar_h), 1.2, Color(1.0, 1.0, 1.0, 0.95))

						# Şebeke dalgalanma koruma aurası
						var bat_aura: float = 0.5 + 0.5 * sin(anim_time * 3.5)
						canvas.draw_arc(roof_pos + Vector2(0.0, -3.0), 15.0, 0.0, TAU, 22, Color(0.20, 0.88, 0.72, 0.35 * bat_aura), 1.4)

					GameData.BuildingType.COP31:
						# COP31 Diplomasi Merkezi: Geodezik kubbe zirvesinde dönen küresel iklim feneri
						var beacon_ang: float = anim_time * 2.0
						var b_len: float = 16.0
						var beacon_tip := roof_pos + Vector2(cos(beacon_ang) * b_len, sin(beacon_ang) * b_len * 0.45 - 8.0)
						canvas.draw_line(roof_pos + Vector2(0.0, -6.0), beacon_tip, Color(0.45, 0.85, 1.0, 0.75), 1.6)
						canvas.draw_circle(beacon_tip, 2.2, Color(1.0, 0.92, 0.45, 0.95))
						canvas.draw_circle(roof_pos + Vector2(0.0, -6.0), 3.5, Color(0.35, 0.80, 1.0, 0.95))

						# 3 adet Solarpunk diplomasi sancağı / bayrağı
						for f_i in range(3):
							var f_base := roof_pos + Vector2(-12.0 + float(f_i) * 12.0, 18.0)
							var f_sway: float = sin(anim_time * 3.5 + float(f_i)) * 1.8
							canvas.draw_line(f_base, f_base + Vector2(0.0, -9.0), Color(0.85, 0.90, 0.95), 1.2)
							var f_col := Color(0.35, 0.92, 0.65) if f_i == 0 else (Color(0.35, 0.75, 1.0) if f_i == 1 else Color(1.0, 0.88, 0.35))
							canvas.draw_colored_polygon(PackedVector2Array([
								f_base + Vector2(0.0, -9.0),
								f_base + Vector2(4.5 + f_sway, -7.5),
								f_base + Vector2(0.0, -6.0)
							]), f_col)

				if blvl >= 3:
					# Level 3 (★★ Mega): Çift altın yıldız, nabız atan turkuaz/altın çift halka ve ikili yörünge ışık küreleri
					var aura_pulse: float = 0.4 + 0.25 * sin(anim_time * 4.0)
					canvas.draw_arc(roof_pos + Vector2(0.0, -9.0), 16.0, 0.0, TAU, 24, Color(0.28, 0.95, 1.0, aura_pulse), 2.2)
					var halo_ang1: float = anim_time * 3.4
					var halo_ang2: float = halo_ang1 + PI
					var h_pos1: Vector2 = roof_pos + Vector2(cos(halo_ang1) * 16.0, sin(halo_ang1) * 7.0 - 9.0)
					var h_pos2: Vector2 = roof_pos + Vector2(cos(halo_ang2) * 16.0, sin(halo_ang2) * 7.0 - 9.0)
					canvas.draw_circle(h_pos1, 2.8, Color(1.0, 0.90, 0.35, 0.95))
					canvas.draw_circle(h_pos2, 2.8, Color(0.35, 1.0, 0.88, 0.95))
					var star_pulse: float = 0.88 + 0.12 * sin(anim_time * 5.5)
					canvas.draw_string(font, roof_pos + Vector2(-22.0, -5.0), "★★", HORIZONTAL_ALIGNMENT_CENTER, 44.0, 15, Color(1.0, 0.92, 0.35, star_pulse))
				elif blvl == 2:
					var halo_ang: float = anim_time * 2.8
					var halo_pos: Vector2 = roof_pos + Vector2(cos(halo_ang) * 14.0, sin(halo_ang) * 6.0 - 8.0)
					canvas.draw_circle(halo_pos, 2.5, Color(1.0, 0.88, 0.28, 0.95))
					var star_pulse: float = 0.85 + 0.15 * sin(anim_time * 5.0)
					canvas.draw_string(font, roof_pos + Vector2(-15.0, -4.0), "★", HORIZONTAL_ALIGNMENT_CENTER, 30.0, 14, Color(1.0, 0.90, 0.30, star_pulse))
				elif b_tex == null:
					var sym_str: String = vis["symbol"]
					var center_iso: Vector2 = roof_pos + Vector2(-20.0, 6.0)
					canvas.draw_string(font, center_iso, sym_str, HORIZONTAL_ALIGNMENT_CENTER, 40.0, 20)

	# Atmosferik Hava Durumu Partikülleri (Polen vs Smog/Kül vs Kum Fırtınası)
	_draw_weather_particles(canvas, sim, anim_time)

	# Aktif İklim Krizi Atmosferik Efektleri (Sıcak Dalgası, Asit Yağmuru, Kabaran Sular, Şebeke Arkı)
	_draw_active_crisis_effects(canvas, sim, anim_time)

	# Solarpunk Yüksek İrtifa Kargo Dronları ve Göçmen Kuş Sürüsü
	_draw_aerial_traffic(canvas, sim, anim_time)

	# Zemin Mikro Yaşam: Eko-Vatandaşlar, Bisikletliler ve Refakatçi Dronlar
	_draw_micro_citizens(canvas, sim, anim_time)

	if hovered_tile.x >= 0 and hovered_tile.x < GameData.GRID_SIZE and hovered_tile.y >= 0 and hovered_tile.y < GameData.GRID_SIZE:
		var hover_col := Color(1.0, 0.95, 0.35, 0.95)
		var is_hover_upgrade: bool = false
		var synergy_targets: Array[Vector2i] = []
		var active_cid: int = -1
		if selected_hand_index >= 0 and selected_hand_index < sim.hand.size():
			active_cid = sim.hand[selected_hand_index]
		elif hovered_hand_index >= 0 and hovered_hand_index < sim.hand.size():
			active_cid = sim.hand[hovered_hand_index]

		if active_cid >= 0:
			var cid: int = active_cid
			if sim.is_tile_valid_for_card(hovered_tile, cid):
				hover_col = Color(0.35, 1.0, 0.55, 0.95)
				if cid == GameData.CardId.UPGRADE_KIT:
					if sim.grid_building[hovered_tile.x][hovered_tile.y] != GameData.BuildingType.NONE and sim.grid_building[hovered_tile.x][hovered_tile.y] != GameData.BuildingType.LAKE and sim.grid_building[hovered_tile.x][hovered_tile.y] != GameData.BuildingType.COAL_PLANT and sim.grid_level[hovered_tile.x][hovered_tile.y] < 3:
						is_hover_upgrade = true
						hover_col = Color(0.98, 0.85, 0.32, 0.98)
				elif GameData.CARDS[cid].has("building") and GameData.CARDS[cid]["building"] != GameData.BuildingType.NONE:
					var cbtype: int = GameData.CARDS[cid]["building"]
					if sim.grid_building[hovered_tile.x][hovered_tile.y] == cbtype and sim.grid_level[hovered_tile.x][hovered_tile.y] < 3:
						is_hover_upgrade = true
						hover_col = Color(1.0, 0.88, 0.28, 0.98)
					synergy_targets = sim.get_synergy_links(hovered_tile, cbtype)
				elif cid == GameData.CardId.EXPAND:
					for dx in range(-1, 2):
						for dy in range(-1, 2):
							var nx: int = hovered_tile.x + dx
							var ny: int = hovered_tile.y + dy
							if nx >= 0 and nx < GameData.GRID_SIZE and ny >= 0 and ny < GameData.GRID_SIZE:
								var fill_c := Color(0.35, 1.0, 0.55, 0.25)
								var brd_c := Color(0.35, 1.0, 0.55, 0.9)
								draw_iso_prism(canvas, nx, ny, fill_c, brd_c, 14.0, 0.05)
				elif cid == GameData.CardId.ECO_SURVEY:
					var iso_c: Vector2 = GameData.grid_to_iso(hovered_tile.x + 0.5, hovered_tile.y + 0.5)
					var radar_r: float = 24.0 + sin(anim_time * 7.0) * 4.0
					canvas.draw_arc(iso_c, radar_r, 0.0, TAU, 32, Color(0.28, 0.88, 1.0, 0.9), 2.4)
					canvas.draw_arc(iso_c, radar_r * 0.5, 0.0, TAU, 24, Color(0.45, 0.95, 1.0, 0.6), 1.6)
					canvas.draw_line(iso_c + Vector2(-radar_r * 1.3, 0.0), iso_c + Vector2(radar_r * 1.3, 0.0), Color(0.35, 0.90, 1.0, 0.8), 1.5)
					canvas.draw_line(iso_c + Vector2(0.0, -radar_r * 1.3), iso_c + Vector2(0.0, radar_r * 1.3), Color(0.35, 0.90, 1.0, 0.8), 1.5)
					draw_iso_prism(canvas, hovered_tile.x, hovered_tile.y, Color(0.20, 0.75, 1.0, 0.35), Color(0.40, 0.95, 1.0, 0.95), 16.0, 0.08)
			else:
				hover_col = Color(1.0, 0.32, 0.32, 0.95)
		else:
			var existing_b: int = sim.grid_building[hovered_tile.x][hovered_tile.y]
			if existing_b != GameData.BuildingType.NONE and existing_b != GameData.BuildingType.LAKE:
				synergy_targets = sim.get_synergy_links(hovered_tile, existing_b)

		var h_state: int = sim.grid_state[hovered_tile.x][hovered_tile.y]
		var h_height: float = 13.0 if h_state == GameData.TileState.UNLOCKED else (10.0 if h_state == GameData.TileState.BORDER else 7.0)
		draw_iso_prism(canvas, hovered_tile.x, hovered_tile.y, Color(hover_col.r, hover_col.g, hover_col.b, 0.28), hover_col, h_height, 0.02)

		var from_iso: Vector2 = GameData.grid_to_iso(hovered_tile.x + 0.5, hovered_tile.y + 0.5) + Vector2(0.0, -22.0)
		if is_hover_upgrade:
			var target_level: int = sim.grid_level[hovered_tile.x][hovered_tile.y] + 1
			var up_r: float = 20.0 + sin(anim_time * 8.0) * 3.0
			var up_col: Color = Color(0.35, 1.0, 0.92) if target_level >= 3 else Color(1.0, 0.88, 0.28)
			canvas.draw_arc(from_iso, up_r, 0.0, TAU, 28, up_col, 2.4)
			var up_text: String = "★★ SEVİYE 3 MEGA-TESİS YÜKSELT! ★★" if target_level >= 3 else "★ SEVİYE 2'YE YÜKSELT! ★"
			canvas.draw_string(font, from_iso + Vector2(-120.0, -32.0), up_text, HORIZONTAL_ALIGNMENT_CENTER, 240.0, 13, up_col)
		var syn_btype: int = GameData.BuildingType.NONE
		if active_cid >= 0:
			if GameData.CARDS[active_cid].has("building"):
				syn_btype = GameData.CARDS[active_cid]["building"]
		else:
			syn_btype = sim.grid_building[hovered_tile.x][hovered_tile.y]

		var pulse: float = 0.75 + 0.25 * sin(anim_time * 6.0)
		for st in synergy_targets:
			var to_iso: Vector2 = GameData.grid_to_iso(st.x + 0.5, st.y + 0.5) + Vector2(0.0, -22.0)
			var line_col := Color(0.35, 1.0, 0.65)
			var spark_col := Color(1.0, 1.0, 0.55)
			var is_energy: bool = (syn_btype == GameData.BuildingType.SOLAR or syn_btype == GameData.BuildingType.WIND or syn_btype == GameData.BuildingType.GEOTHERMAL)
			var is_water: bool = (syn_btype == GameData.BuildingType.WATER_PLANT or syn_btype == GameData.BuildingType.LAKE)

			if is_energy:
				line_col = Color(0.32, 0.92, 1.0)
				spark_col = Color(1.0, 0.95, 0.45)
			elif is_water:
				line_col = Color(0.38, 0.75, 1.0)
				spark_col = Color(0.75, 0.95, 1.0)
			else:
				line_col = Color(0.42, 1.0, 0.58)
				spark_col = Color(0.92, 1.0, 0.60)

			# Dış neon ışıma hattı
			canvas.draw_line(from_iso, to_iso, Color(line_col.r, line_col.g, line_col.b, 0.35 * pulse), 5.5)
			# İç parlak çekirdek hattı
			canvas.draw_line(from_iso, to_iso, Color(line_col.r, line_col.g, line_col.b, 0.95 * pulse), 2.2)

			# Akan 2 adet enerji/kaynak kıvılcımı
			for sp_i in range(2):
				var dot_t: float = fmod(anim_time * 1.8 + float(sp_i) * 0.5, 1.0)
				var dot_pos: Vector2 = from_iso.lerp(to_iso, dot_t)
				canvas.draw_circle(dot_pos, 3.8, spark_col)
				canvas.draw_circle(dot_pos, 1.8, Color(1.0, 1.0, 1.0, 0.95))

			# Hedef bina tabanında sinerji enerji halkası
			var halo_r: float = 14.0 + sin(anim_time * 7.0) * 2.5
			canvas.draw_arc(to_iso, halo_r, 0.0, TAU, 20, Color(line_col.r, line_col.g, line_col.b, 0.85 * pulse), 1.8)
			canvas.draw_circle(to_iso, 4.5, spark_col)

		if not synergy_targets.is_empty():
			var syn_desc: String = sim.get_synergy_description(hovered_tile, syn_btype)
			if syn_desc.is_empty():
				syn_desc = "✨ Sinerji Bonusu!"
			canvas.draw_string(font, from_iso + Vector2(-120.0, -14.0), syn_desc, HORIZONTAL_ALIGNMENT_CENTER, 240.0, 13, Color(0.55, 1.0, 0.75))

		# Kare İnceleme İpucu (Solarpunk Holographic Floating Inspect Card)
		var b_on_tile: int = sim.grid_building[hovered_tile.x][hovered_tile.y]
		if b_on_tile != GameData.BuildingType.NONE:
			var vis_info: Dictionary = GameData.get_building_visual(b_on_tile)
			var lv: int = sim.grid_level[hovered_tile.x][hovered_tile.y]
			var card_w: float = 330.0
			var card_h: float = 40.0
			var card_pos: Vector2 = from_iso + Vector2(-card_w * 0.5, -68.0)
			var card_rect := Rect2(card_pos, Vector2(card_w, card_h))

			# Glassmorphic Panel
			canvas.draw_rect(card_rect, Color(0.06, 0.11, 0.15, 0.94), true)
			var brd_col: Color = Color(1.0, 0.88, 0.32, 0.95) if lv >= 3 else (Color(0.40, 0.88, 0.95, 0.95) if lv == 2 else Color(0.35, 0.78, 0.65, 0.85))
			canvas.draw_rect(card_rect, brd_col, false, 1.4)

			# Holographic Corner Accents
			var c_len: float = 6.0
			canvas.draw_line(card_pos, card_pos + Vector2(c_len, 0), Color.WHITE, 1.5)
			canvas.draw_line(card_pos, card_pos + Vector2(0, c_len), Color.WHITE, 1.5)
			canvas.draw_line(card_pos + Vector2(card_w, 0), card_pos + Vector2(card_w - c_len, 0), Color.WHITE, 1.5)
			canvas.draw_line(card_pos + Vector2(card_w, 0), card_pos + Vector2(card_w, c_len), Color.WHITE, 1.5)

			# Anchor Pointer to Building Roof
			canvas.draw_line(card_pos + Vector2(card_w * 0.5, card_h), from_iso, Color(brd_col.r, brd_col.g, brd_col.b, 0.55), 1.2)
			canvas.draw_circle(from_iso, 2.2, Color(1.0, 1.0, 1.0, 0.95))

			if b_on_tile == GameData.BuildingType.LAKE:
				canvas.draw_string(font, card_pos + Vector2(8.0, 15.0), "🌊 Doğal Su Akiferi & Göl", HORIZONTAL_ALIGNMENT_LEFT, card_w - 16.0, 12, Color(0.45, 0.88, 1.0))
				canvas.draw_string(font, card_pos + Vector2(8.0, 31.0), "Komşu Tarım, Su Arıtma ve Jeotermal tesislere +2 bonus verir", HORIZONTAL_ALIGNMENT_LEFT, card_w - 16.0, 10, Color(0.85, 0.92, 0.95))
			else:
				var yld: Dictionary = sim.calculate_building_yield(hovered_tile, b_on_tile)
				var lv_str: String = "★★ Mega-Tesis" if lv >= 3 else ("★ Gelişmiş" if lv == 2 else "Temel Tesis")
				var title_str: String = "%s %s [%s]" % [vis_info["symbol"], vis_info["name"], lv_str]
				var title_col := Color(1.0, 0.90, 0.35) if lv >= 3 else (Color(0.45, 0.90, 1.0) if lv == 2 else Color(0.92, 0.98, 0.95))
				canvas.draw_string(font, card_pos + Vector2(8.0, 15.0), title_str, HORIZONTAL_ALIGNMENT_LEFT, card_w - 16.0, 12, title_col)

				var yield_str: String = "Net Üretim: ⚡%+d  🌱%+d  💧%+d  ☣%+d" % [yld["e"], yld["f"], yld["w"], yld["c"]]
				var syn_c: int = sim.get_synergy_links(hovered_tile, b_on_tile).size()
				if syn_c > 0:
					yield_str += "  | ✨ %d Sinerji" % syn_c
				canvas.draw_string(font, card_pos + Vector2(8.0, 31.0), yield_str, HORIZONTAL_ALIGNMENT_LEFT, card_w - 16.0, 11, Color(0.78, 0.94, 0.88))

	# Sinerji Bağlantı Plazma Patlama Efektleri
	_draw_synergy_bursts(canvas, synergy_bursts, anim_time)

	# Yıkım ve Moloz Partikül Efektleri
	_draw_demolition_effects(canvas, debris_effects)

	# Seviye Yükseltme Kıvılcım Efektleri
	_draw_upgrade_sparkles(canvas, upgrade_sparkles, anim_time)

	# Toprak Islahı (Doğaya Dönüş Çiçek & Filiz Efektleri)
	_draw_reclamation_effects(canvas, reclamation_effects, anim_time)

	# Eko-Bölge (Eco-District) Sınır ve Başlık Katmanı
	_draw_districts(canvas, sim, anim_time, font)

	# Yeni Gün Altın Şafak Işığı Dalgası (Golden Dawn Sunlight Wave)
	_draw_dawn_sweep_wave(canvas, dawn_sweep_timer, anim_time)

	# Karbon Emisyon Lensi Katmanı (Heatmap Overlay - [V])
	if carbon_lens_active:
		_draw_carbon_lens_overlay(canvas, sim, anim_time, font)

	for ft in floating_texts:
		var alpha: float = clampf(1.0 - (ft["age"] / ft["duration"]), 0.0, 1.0)
		var col: Color = ft["color"]
		col.a = alpha
		var p: Vector2 = ft["pos"]
		canvas.draw_string(font, p + Vector2(-150.0, 0.0), ft["text"], HORIZONTAL_ALIGNMENT_CENTER, 300.0, 15, col)

	if flash_alpha > 0.01:
		canvas.draw_rect(Rect2(-3000, -2000, 6000, 5000), Color(flash_color.r, flash_color.g, flash_color.b, flash_alpha), true)

	# Kritik Karbon / İklim Tehlike Atmosferik Vinyeti
	if sim.carbon >= 65:
		var c_crit: float = clampf(float(sim.carbon - 65) / 35.0, 0.0, 1.0)
		var pulse: float = 0.65 + 0.35 * sin(anim_time * 4.0)
		var vig_alpha: float = c_crit * 0.38 * pulse
		var center_iso: Vector2 = GameData.grid_to_iso(GameData.GRID_SIZE * 0.5, GameData.GRID_SIZE * 0.5)
		canvas.draw_rect(Rect2(center_iso.x - 900.0, center_iso.y - 650.0, 1800.0, 1300.0), Color(0.48, 0.08, 0.05, vig_alpha), false, 18.0)
		canvas.draw_rect(Rect2(center_iso.x - 880.0, center_iso.y - 630.0, 1760.0, 1260.0), Color(0.65, 0.12, 0.08, vig_alpha * 0.6), false, 12.0)

static func _draw_weather_particles(canvas: CanvasItem, sim: GridSimulation, anim_time: float) -> void:
	var center: Vector2 = GameData.grid_to_iso(GameData.GRID_SIZE * 0.5, GameData.GRID_SIZE * 0.5)
	var carbon: int = sim.carbon

	# Çöl Senaryosu (Kurak Vaha) - Altın Kum Rüzgarı ve Vaha Çiçeklenmesi
	if sim.current_scenario == 2:
		var forests: int = sim.count_building(GameData.BuildingType.FOREST)
		var dust_factor: float = clampf(1.0 - float(forests) * 0.22, 0.15, 1.0)
		var sand_count: int = int(34.0 * dust_factor)
		for i in range(sand_count):
			var seed_f: float = float(i) * 31.41
			var speed_x: float = 75.0 + fmod(seed_f * 7.3, 50.0)
			var px: float = center.x - 650.0 + fmod(seed_f * 29.0 + anim_time * speed_x, 1300.0)
			var py: float = center.y - 320.0 + sin(seed_f + anim_time * 1.6) * 260.0 + (px - center.x) * 0.18
			var sand_alpha: float = (0.28 + 0.22 * sin(anim_time * 2.2 + float(i))) * dust_factor
			canvas.draw_circle(Vector2(px, py), 2.2, Color(0.92, 0.82, 0.48, sand_alpha))
			canvas.draw_line(Vector2(px, py), Vector2(px - 14.0, py - 3.2), Color(0.90, 0.76, 0.40, sand_alpha * 0.6), 1.2)

		# Vaha canlanması: Ormanlar kuruldukça beliren yeşil ve turkuaz vaha sporları
		if forests >= 1:
			var blossom_count: int = clampi(forests * 5, 8, 28)
			for i in range(blossom_count):
				var seed_f: float = float(i) * 47.19
				var px: float = center.x + sin(seed_f + anim_time * 0.4) * 460.0
				var py: float = center.y - 220.0 + fmod(seed_f * 15.0 + anim_time * 24.0, 500.0)
				var b_col := Color(0.42, 0.95, 0.62, 0.45) if (i % 2 == 0) else Color(0.45, 0.88, 1.0, 0.45)
				canvas.draw_circle(Vector2(px, py), 2.5, b_col)
		return

	# Standart ve Sanayi Senaryoları
	if carbon <= 28:
		for i in range(22):
			var seed_f: float = float(i) * 37.17
			var px: float = center.x + sin(seed_f + anim_time * 0.35) * 520.0
			var py: float = center.y - 260.0 + fmod(seed_f * 19.0 + anim_time * 24.0, 540.0)
			canvas.draw_circle(Vector2(px, py), 2.4, Color(0.55, 0.98, 0.68, 0.38))

		# Gökyüzünde Süzülen Göçmen Kuş Sürüsü (Solarpunk Migratory Birds)
		var flock_t: float = anim_time * 0.08
		var flock_cx: float = center.x - 650.0 + fmod(anim_time * 38.0, 1300.0)
		var flock_cy: float = center.y - 180.0 + sin(flock_t * TAU) * 28.0
		var bird_offsets := [
			Vector2(0, 0),
			Vector2(-16, -10),
			Vector2(-14, 12),
			Vector2(-32, -18),
			Vector2(-28, 22)
		]
		for b_idx in range(bird_offsets.size()):
			var bp: Vector2 = Vector2(flock_cx, flock_cy) + bird_offsets[b_idx]
			var flap: float = sin(anim_time * 6.5 + float(b_idx) * 0.8) * 3.5
			var wl := bp + Vector2(-3.5, flap)
			var wr := bp + Vector2(3.5, flap)
			var bird_col := Color(0.85, 0.94, 0.98, 0.65)
			canvas.draw_line(wl, bp, bird_col, 1.4)
			canvas.draw_line(bp, wr, bird_col, 1.4)
	elif carbon >= 50:
		for i in range(28):
			var seed_f: float = float(i) * 43.11
			var px: float = center.x + cos(seed_f + anim_time * 0.45) * 540.0
			var py: float = center.y + 280.0 - fmod(seed_f * 23.0 + anim_time * 36.0, 560.0)
			canvas.draw_circle(Vector2(px, py), 3.2, Color(0.32, 0.26, 0.24, 0.42))
			if carbon >= 70:
				canvas.draw_line(Vector2(px, py), Vector2(px - 6.0, py + 14.0), Color(0.75, 0.85, 0.45, 0.28), 1.2)

	# Dinamik Ekolojik Hava Durumu Efektleri (Güneş Hüzmeleri, Bahar Yağmuru, İklim Rüzgarı)
	match sim.current_weather:
		GameData.WeatherType.CLEAR_SUN:
			var gr_col := Color(1.0, 0.92, 0.55, 0.08 + 0.03 * sin(anim_time * 1.6))
			for gr in range(4):
				var ray_x: float = center.x - 420.0 + float(gr) * 260.0 + sin(anim_time * 0.7 + float(gr)) * 25.0
				var p_top := Vector2(ray_x + 320.0, center.y - 650.0)
				var p_bot := Vector2(ray_x - 320.0, center.y + 650.0)
				canvas.draw_line(p_top, p_bot, gr_col, 50.0)
			for sp in range(16):
				var seed_f: float = float(sp) * 41.3
				var sx: float = center.x + sin(seed_f + anim_time * 0.5) * 550.0
				var sy: float = center.y + cos(seed_f * 1.5 + anim_time * 0.8) * 260.0
				var s_alpha: float = 0.35 + 0.25 * sin(anim_time * 4.0 + seed_f)
				canvas.draw_circle(Vector2(sx, sy), 2.2, Color(1.0, 0.92, 0.45, s_alpha))

		GameData.WeatherType.SPRING_RAIN:
			for r_i in range(40):
				var seed_f: float = float(r_i) * 29.31
				var rx: float = center.x - 680.0 + fmod(seed_f * 47.0 + anim_time * 40.0, 1360.0)
				var ry: float = center.y - 380.0 + fmod(seed_f * 33.0 + anim_time * 440.0, 760.0)
				canvas.draw_line(Vector2(rx, ry), Vector2(rx - 7.0, ry + 20.0), Color(0.42, 0.85, 1.0, 0.35), 1.4)

		GameData.WeatherType.FRESH_BREEZE:
			for w_i in range(10):
				var seed_f: float = float(w_i) * 53.19
				var wx: float = center.x - 720.0 + fmod(seed_f * 61.0 + anim_time * 240.0, 1440.0)
				var wy: float = center.y - 280.0 + sin(seed_f + anim_time * 2.0) * 200.0
				var w_len: float = 38.0 + sin(seed_f) * 22.0
				canvas.draw_line(Vector2(wx, wy), Vector2(wx + w_len, wy + 3.5), Color(0.42, 0.96, 0.85, 0.30), 1.6)

static func _draw_active_crisis_effects(canvas: CanvasItem, sim: GridSimulation, anim_time: float) -> void:
	if sim.active_crisis_type < 0:
		return

	var center: Vector2 = GameData.grid_to_iso(GameData.GRID_SIZE * 0.5, GameData.GRID_SIZE * 0.5)

	# Kriz Tehlike Çevre Çizgisi ve Uyarı Şeritleri (Crisis Hazard Perimeter Warning)
	var p_pulse: float = 0.5 + 0.5 * sin(anim_time * 6.0)
	var hazard_col := Color(1.0, 0.32, 0.22, 0.45 + 0.40 * p_pulse)
	var top_c := GameData.grid_to_iso(0.0, 0.0) + Vector2(0.0, -12.0)
	var right_c := GameData.grid_to_iso(float(GameData.GRID_SIZE), 0.0) + Vector2(0.0, -12.0)
	var bottom_c := GameData.grid_to_iso(float(GameData.GRID_SIZE), float(GameData.GRID_SIZE)) + Vector2(0.0, -12.0)
	var left_c := GameData.grid_to_iso(0.0, float(GameData.GRID_SIZE)) + Vector2(0.0, -12.0)
	var perim := [top_c, right_c, bottom_c, left_c, top_c]
	for i in range(4):
		canvas.draw_line(perim[i], perim[i + 1], hazard_col, 3.2)
		for seg in range(1, 10):
			var seg_t: float = float(seg) / 10.0
			var seg_p: Vector2 = perim[i].lerp(perim[i + 1], seg_t)
			var tick_dir: Vector2 = (perim[i + 1] - perim[i]).normalized().orthogonal() * 6.0
			canvas.draw_line(seg_p - tick_dir, seg_p + tick_dir, hazard_col, 1.8)

	match sim.active_crisis_type:
		0, 4: # Sıcak Hava Dalgası / Kuraklık (Heatwave & Drought)
			var shimmer: float = sin(anim_time * 3.5) * 8.0
			var haze_col := Color(1.0, 0.65, 0.25, 0.18 + 0.08 * sin(anim_time * 2.0))
			for i in range(5):
				var h_y: float = center.y + float(i - 2) * 90.0 + shimmer
				var p_start := Vector2(center.x - 550.0, h_y)
				var p_mid := Vector2(center.x, h_y - 20.0 - sin(anim_time * 4.0 + float(i)) * 12.0)
				var p_end := Vector2(center.x + 550.0, h_y)
				canvas.draw_line(p_start, p_mid, haze_col, 2.5)
				canvas.draw_line(p_mid, p_end, haze_col, 2.5)
			for sp in range(16):
				var seed_f: float = float(sp) * 41.5
				var sx: float = center.x + sin(seed_f + anim_time * 0.6) * 480.0
				var sy: float = center.y + 200.0 - fmod(seed_f * 23.0 + anim_time * 45.0, 450.0)
				canvas.draw_circle(Vector2(sx, sy), 2.2, Color(1.0, 0.75, 0.35, 0.45))

		1: # Asit Yağmuru (Acid Rain)
			for r in range(40):
				var seed_f: float = float(r) * 23.7
				var rx: float = center.x - 500.0 + fmod(seed_f * 43.0 + anim_time * 20.0, 1000.0)
				var ry: float = center.y - 320.0 + fmod(seed_f * 31.0 + anim_time * 380.0, 640.0)
				var p1 := Vector2(rx, ry)
				var p2 := Vector2(rx - 7.0, ry + 18.0)
				canvas.draw_line(p1, p2, Color(0.72, 0.95, 0.38, 0.42), 1.4)
				if fmod(ry, 120.0) < 16.0:
					canvas.draw_arc(p2, 3.5, 0.0, TAU, 12, Color(0.78, 1.0, 0.45, 0.35), 1.0)

		2: # Yükselen Deniz Seviyesi (Rising Sea Level / Flood)
			var wave_r: float = 380.0 + sin(anim_time * 3.0) * 18.0
			canvas.draw_arc(center + Vector2(0.0, 20.0), wave_r, 0.0, TAU, 48, Color(0.25, 0.65, 0.95, 0.38), 3.0)
			canvas.draw_arc(center + Vector2(0.0, 20.0), wave_r + 25.0, 0.0, TAU, 48, Color(0.45, 0.82, 1.0, 0.22), 2.0)

		3: # Şebeke Çöküşü (Grid Power Surge & Electric Sparks)
			for el in range(8):
				var seed_f: float = float(el) * 51.3
				var ex: float = center.x + sin(seed_f + anim_time * 5.0) * 420.0
				var ey: float = center.y + cos(seed_f * 1.7) * 220.0
				var p_arc1 := Vector2(ex, ey)
				var p_arc2 := p_arc1 + Vector2(randf_range(-18.0, 18.0), randf_range(-14.0, 14.0))
				var p_arc3 := p_arc2 + Vector2(randf_range(-18.0, 18.0), randf_range(-14.0, 14.0))
				canvas.draw_line(p_arc1, p_arc2, Color(1.0, 0.92, 0.35, 0.75), 1.8)
				canvas.draw_line(p_arc2, p_arc3, Color(0.45, 0.90, 1.0, 0.85), 1.5)
				canvas.draw_circle(p_arc3, 3.0, Color(1.0, 1.0, 1.0, 0.9))

static func _draw_aerial_traffic(canvas: CanvasItem, sim: GridSimulation, anim_time: float) -> void:
	var center: Vector2 = GameData.grid_to_iso(GameData.GRID_SIZE * 0.5, GameData.GRID_SIZE * 0.5)

	# 1. Solarpunk Kargo & İklim Gözlem Dronları (Sleek Quad-Rotor Drones)
	for d_idx in range(2):
		var speed: float = 0.045 if d_idx == 0 else 0.038
		var path_t: float = fmod(anim_time * speed + float(d_idx) * 0.55, 1.0)
		var start_p: Vector2 = center + (Vector2(-650.0, -120.0) if d_idx == 0 else Vector2(580.0, -220.0))
		var end_p: Vector2 = center + (Vector2(650.0, 180.0) if d_idx == 0 else Vector2(-580.0, 240.0))
		var ground_pos: Vector2 = start_p.lerp(end_p, path_t)
		var altitude: float = 145.0 + sin(anim_time * 2.0 + float(d_idx)) * 8.0
		var drone_pos: Vector2 = ground_pos + Vector2(0.0, -altitude)

		# Zemin gölgesi (hafif eliptik)
		var shadow_col := Color(0.02, 0.08, 0.06, 0.22)
		canvas.draw_set_transform(ground_pos, 0.0, Vector2(1.0, 0.5))
		canvas.draw_circle(Vector2.ZERO, 9.0, shadow_col)
		canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

		# Sensör tarama ışını
		var scan_pulse: float = 0.5 + 0.5 * sin(anim_time * 4.0 + float(d_idx))
		var scan_col := Color(0.25, 0.95, 0.82, 0.08 * scan_pulse)
		canvas.draw_line(drone_pos, ground_pos, scan_col, 1.5)

		# Gövde
		canvas.draw_circle(drone_pos, 4.2, Color(0.92, 0.96, 1.0, 0.95))
		canvas.draw_circle(drone_pos, 2.4, Color(0.18, 0.78, 0.95, 0.95))

		# 4 Dönen Pervane Kolu
		var rotor_dist: float = 7.5
		var arm_dirs := [Vector2(-1, -0.6), Vector2(1, -0.6), Vector2(-1, 0.6), Vector2(1, 0.6)]
		for arm in arm_dirs:
			var arm_end: Vector2 = drone_pos + arm * rotor_dist
			canvas.draw_line(drone_pos, arm_end, Color(0.35, 0.40, 0.48, 0.9), 1.2)
			var r_angle: float = anim_time * 28.0 + arm.x * 2.0
			var r_offset: Vector2 = Vector2(cos(r_angle) * 3.8, sin(r_angle) * 1.5)
			canvas.draw_line(arm_end - r_offset, arm_end + r_offset, Color(0.40, 0.92, 1.0, 0.65), 1.2)
			canvas.draw_circle(arm_end, 1.2, Color(1.0, 1.0, 1.0, 0.9))

		# Strobe LED (Yeşil / Turkuaz)
		var strobe_on: bool = fmod(anim_time * 3.0 + float(d_idx), 1.0) < 0.2
		var strobe_col := Color(0.3, 1.0, 0.5, 0.95) if strobe_on else Color(0.1, 0.4, 0.2, 0.4)
		canvas.draw_circle(drone_pos + Vector2(0.0, -3.0), 1.6, strobe_col)

	# 2. Göçmen Kuş Sürüsü (Migrating Solarpunk Flock - V-Formation)
	var bird_speed: float = 0.026
	var flock_t: float = fmod(anim_time * bird_speed, 1.0)
	var flock_start := center + Vector2(-750.0, 260.0)
	var flock_end := center + Vector2(750.0, -360.0)
	var flock_apex: Vector2 = flock_start.lerp(flock_end, flock_t)

	var v_offsets := [
		Vector2(0, 0),
		Vector2(-14, 10), Vector2(-28, 20), Vector2(-42, 30),
		Vector2(10, 12), Vector2(22, 24), Vector2(34, 36)
	]
	var bird_col := Color(0.16, 0.22, 0.25, 0.72)
	for b_i in range(v_offsets.size()):
		var b_pos: Vector2 = flock_apex + v_offsets[b_i]
		var wing_flap: float = sin(anim_time * 9.0 + float(b_i) * 0.45) * 3.5
		var left_wing := b_pos + Vector2(-3.5, wing_flap - 1.0)
		var right_wing := b_pos + Vector2(3.5, wing_flap - 1.0)
		canvas.draw_line(b_pos, left_wing, bird_col, 1.4)
		canvas.draw_line(b_pos, right_wing, bird_col, 1.4)

static func _draw_micro_citizens(canvas: CanvasItem, sim: GridSimulation, anim_time: float) -> void:
	if sim == null:
		return
	var housing_tiles: Array[Vector2i] = []
	for x in range(GameData.GRID_SIZE):
		for y in range(GameData.GRID_SIZE):
			if sim.grid_building[x][y] == GameData.BuildingType.HOUSING:
				housing_tiles.append(Vector2i(x, y))

	# Eğer hiç konut yoksa başlangıç merkezinde sembolik vatandaşlar dolaşsın
	if housing_tiles.is_empty():
		housing_tiles.append(Vector2i(9, 9))

	var dirs: Array[Vector2i] = [Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1)]

	for h_idx in range(mini(housing_tiles.size(), 6)):
		var h_pos: Vector2i = housing_tiles[h_idx]
		var h_iso: Vector2 = GameData.grid_to_iso(h_pos.x + 0.5, h_pos.y + 0.5) + Vector2(0.0, -12.0)

		# Uygun komşu yol/kare ara
		var target_pos: Vector2i = h_pos
		for d in dirs:
			var nx: int = h_pos.x + d.x
			var ny: int = h_pos.y + d.y
			if nx >= 0 and nx < GameData.GRID_SIZE and ny >= 0 and ny < GameData.GRID_SIZE:
				if sim.grid_state[nx][ny] == GameData.TileState.UNLOCKED:
					target_pos = Vector2i(nx, ny)
					break

		var t_iso: Vector2 = GameData.grid_to_iso(target_pos.x + 0.5, target_pos.y + 0.5) + Vector2(0.0, -12.0)
		if target_pos == h_pos:
			t_iso = h_iso + Vector2(16.0, 8.0)

		# 1. Yürüyen Solarpunk Vatandaş (Pedestrian with bobbing animation & shadow)
		var p_spd: float = 0.22 + float(h_idx % 3) * 0.05
		var p_t: float = fmod(anim_time * p_spd + float(h_idx) * 0.35, 1.0)
		var p_cur: Vector2 = h_iso.lerp(t_iso, p_t)
		var bob: float = -abs(sin(p_t * TAU * 3.5)) * 1.6

		# Zemin gölgesi
		canvas.draw_circle(p_cur + Vector2(0.0, 1.5), 2.2, Color(0.02, 0.06, 0.04, 0.32))
		# Beden ve kafa
		var outfit_col := Color(0.24, 0.75, 0.65) if (h_idx % 2 == 0) else Color(0.92, 0.65, 0.25)
		canvas.draw_line(p_cur + Vector2(0.0, bob), p_cur + Vector2(0.0, bob - 4.5), outfit_col, 1.6)
		canvas.draw_circle(p_cur + Vector2(0.0, bob - 5.5), 1.3, Color(0.96, 0.88, 0.78))
		# Sırt çantası / omuz paketi
		canvas.draw_circle(p_cur + Vector2(-1.2, bob - 3.2), 0.9, Color(0.18, 0.32, 0.25))

		# Minik eko-drone / evcil robot refakatçisi (Micro Companion Drone)
		if h_idx % 2 == 0:
			var d_bob: float = sin(anim_time * 5.0 + float(h_idx)) * 1.5
			var d_pos: Vector2 = p_cur + Vector2(-4.5, bob - 6.0 + d_bob)
			canvas.draw_circle(d_pos, 1.1, Color(0.40, 0.92, 1.0, 0.95))
			canvas.draw_circle(d_pos, 0.5, Color.WHITE)

		# 2. Solarpunk Hızlı Bisikletli (Bicyclist with spinning wheels & posture)
		if h_idx % 2 == 1 or housing_tiles.size() <= 2:
			var b_spd: float = 0.42
			var b_t: float = fmod(anim_time * b_spd + float(h_idx) * 0.5 + 0.3, 1.0)
			var b_cur: Vector2 = t_iso.lerp(h_iso, b_t)
			var b_dir: Vector2 = (h_iso - t_iso).normalized()
			if b_dir.length_squared() < 0.01:
				b_dir = Vector2(1, 0.5).normalized()

			# Bisiklet zemin gölgesi
			canvas.draw_line(b_cur - b_dir * 4.5 + Vector2(0, 1.0), b_cur + b_dir * 4.5 + Vector2(0, 1.0), Color(0.02, 0.06, 0.04, 0.35), 1.5)

			# İki tekerlek
			var w_back: Vector2 = b_cur - b_dir * 3.5
			var w_front: Vector2 = b_cur + b_dir * 3.5
			canvas.draw_circle(w_back, 1.4, Color(0.18, 0.22, 0.25))
			canvas.draw_circle(w_front, 1.4, Color(0.18, 0.22, 0.25))
			canvas.draw_circle(w_back, 0.6, Color(0.45, 0.90, 1.0))
			canvas.draw_circle(w_front, 0.6, Color(0.45, 0.90, 1.0))

			# Şasi ve bisikletçi
			canvas.draw_line(w_back, w_front, Color(0.20, 0.85, 0.55), 1.2)
			var saddle_pos: Vector2 = b_cur + Vector2(0.0, -2.8)
			canvas.draw_line(w_back, saddle_pos, Color(0.20, 0.85, 0.55), 1.0)
			# Sürücü
			canvas.draw_line(saddle_pos, saddle_pos + b_dir * 2.5 + Vector2(0.0, -3.2), Color(0.35, 0.65, 0.95), 1.6)
			canvas.draw_circle(saddle_pos + b_dir * 2.5 + Vector2(0.0, -4.6), 1.3, Color(1.0, 0.92, 0.40))

static func _draw_synergy_bursts(canvas: CanvasItem, bursts: Array, anim_time: float) -> void:
	for b in bursts:
		var t: float = clampf(b["age"] / b["duration"], 0.0, 1.0)
		var fade: float = sin(t * PI)
		if fade <= 0.01:
			continue
		var from_p: Vector2 = b["from"]
		var to_p: Vector2 = b["to"]
		var arc_col := Color(0.35, 1.0, 0.75, 0.85 * fade)
		var core_col := Color(1.0, 1.0, 0.90, 0.95 * fade)

		# Genişleyen neon bağlantı hattı
		canvas.draw_line(from_p, to_p, arc_col, 3.8 * fade)
		canvas.draw_line(from_p, to_p, core_col, 1.6 * fade)

		# Hat boyunca akan yüksek hızlı enerji plazması
		var spark_pos: Vector2 = from_p.lerp(to_p, t) + Vector2(0.0, -sin(t * PI) * 18.0)
		canvas.draw_circle(spark_pos, 4.5 * fade, arc_col)
		canvas.draw_circle(spark_pos, 2.2 * fade, Color.WHITE)

		# Kaynak ve hedefte nabız atan enerji şok halkaları
		canvas.draw_arc(from_p, 12.0 * (1.0 + t), 0.0, TAU, 16, arc_col, 1.5 * fade)
		canvas.draw_arc(to_p, 14.0 * (1.0 + t), 0.0, TAU, 16, arc_col, 1.5 * fade)

static func _draw_demolition_effects(canvas: CanvasItem, debris_effects: Array) -> void:
	for db in debris_effects:
		var t: float = clampf(db["age"] / db["duration"], 0.0, 1.0)
		var fade: float = 1.0 - t
		var p: Vector2 = db["pos"] + Vector2(0.0, -10.0)
		var is_coal: bool = db.get("is_coal", false)

		# Genişleyen şok dalgası / toz halkası
		var shock_r: float = 10.0 + t * 42.0
		var ring_col := Color(0.35, 0.35, 0.38, fade * 0.75) if is_coal else Color(0.72, 0.75, 0.70, fade * 0.65)
		canvas.draw_arc(p, shock_r, 0.0, TAU, 28, ring_col, 2.2 * fade)

		# İç enerji / yangın sönümlenme halkası
		if is_coal:
			var fire_r: float = 6.0 + t * 24.0
			canvas.draw_arc(p, fire_r, 0.0, TAU, 20, Color(1.0, 0.65, 0.2, fade * 0.85), 1.8 * fade)

		# Dışarı saçılan moloz ve kıvılcım parçacıkları
		var num_particles: int = 10 if is_coal else 7
		for i in range(num_particles):
			var ang: float = float(i) * (TAU / float(num_particles)) + float(i) * 0.45
			var spd: float = 28.0 + float(i % 4) * 8.0
			var part_offset := Vector2(cos(ang) * spd * t, sin(ang) * spd * 0.65 * t - (sin(t * PI) * 14.0))
			var part_pos: Vector2 = p + part_offset
			var part_r: float = maxf(1.0, (3.5 - t * 2.0))
			var p_col := Color(0.25, 0.25, 0.25, fade * 0.9) if (i % 2 == 0) else (Color(1.0, 0.7, 0.25, fade) if is_coal else Color(0.65, 0.68, 0.62, fade * 0.8))
			canvas.draw_circle(part_pos, part_r, p_col)

static func _draw_upgrade_sparkles(canvas: CanvasItem, upgrade_sparkles: Array, anim_time: float) -> void:
	for up in upgrade_sparkles:
		var t: float = clampf(up["age"] / up["duration"], 0.0, 1.0)
		var fade: float = 1.0 - t
		var p: Vector2 = up["pos"] + Vector2(0.0, -26.0)

		# Göğe doğru genişleyen altın ışık sütun halkası
		var ring_r: float = 8.0 + t * 28.0
		var ring_y: float = -t * 36.0
		canvas.draw_arc(p + Vector2(0.0, ring_y), ring_r, 0.0, TAU, 24, Color(1.0, 0.88, 0.28, fade * 0.85), 2.0 * fade)

		# 8 adet yukarı uçuşan altın yıldız / parıltı parçacığı
		for i in range(8):
			var ang: float = float(i) * (TAU / 8.0) + anim_time * 4.0
			var rad: float = 12.0 + sin(t * 8.0 + float(i)) * 6.0
			var spark_pos := p + Vector2(cos(ang) * rad, sin(ang) * rad * 0.5 - t * 44.0 - float(i) * 3.0)
			var spark_r: float = maxf(1.2, 3.6 * fade)
			canvas.draw_circle(spark_pos, spark_r, Color(1.0, 0.95, 0.45, fade))
			canvas.draw_circle(spark_pos, spark_r * 0.5, Color(1.0, 1.0, 1.0, fade))

static func _draw_reclamation_effects(canvas: CanvasItem, reclamation_effects: Array, anim_time: float) -> void:
	for rec in reclamation_effects:
		var t: float = clampf(rec["age"] / rec["duration"], 0.0, 1.0)
		var fade: float = 1.0 - t
		var p: Vector2 = rec["pos"] + Vector2(0.0, -8.0)

		if rec.get("is_radar", false):
			# Yüksek irtifa uydu radar tarama ışını (Orbital Satellite Scanning Beam)
			var beam_top: Vector2 = p + Vector2(0.0, -450.0)
			var beam_w: float = 3.6 * fade
			canvas.draw_line(beam_top, p, Color(0.40, 0.95, 1.0, fade * 0.90), beam_w)
			canvas.draw_line(beam_top, p, Color(1.0, 1.0, 1.0, fade * 0.95), beam_w * 0.35)
			# Genişleyen neon turkuaz radar sonar dalgası
			var radar_r: float = 12.0 + t * 55.0
			canvas.draw_arc(p, radar_r, 0.0, TAU, 32, Color(0.28, 0.88, 1.0, fade * 0.92), 2.5 * fade)
			canvas.draw_arc(p, radar_r * 0.55, 0.0, TAU, 24, Color(0.65, 0.98, 1.0, fade * 0.70), 1.6 * fade)
			# 8 adet dijital telemetri parçacığı
			for i in range(8):
				var ang: float = float(i) * (TAU / 8.0) + anim_time * 2.0
				var dist: float = radar_r * 0.9
				var p_dot: Vector2 = p + Vector2(cos(ang) * dist, sin(ang) * dist * 0.55)
				canvas.draw_rect(Rect2(p_dot.x - 2.0, p_dot.y - 2.0, 4.0, 4.0), Color(0.45, 1.0, 1.0, fade), true)
		else:
			# Genişleyen 3x3 zümrüt biyo-canlanma halkası
			var bio_r: float = 12.0 + t * 65.0
			canvas.draw_arc(p, bio_r, 0.0, TAU, 32, Color(0.35, 1.0, 0.68, fade * 0.85), 2.4 * fade)
			canvas.draw_arc(p, bio_r * 0.65, 0.0, TAU, 24, Color(0.75, 1.0, 0.45, fade * 0.65), 1.6 * fade)

			# 12 adet uçuşan yaprak, filiz ve kır çiçeği tohumu
			for i in range(12):
				var ang: float = float(i) * (TAU / 12.0) + float(i) * 0.25
				var spd: float = 38.0 + float(i % 3) * 14.0
				var leaf_offset := Vector2(cos(ang) * spd * t, sin(ang) * spd * 0.55 * t - (sin(t * PI) * 22.0))
				var leaf_pos: Vector2 = p + leaf_offset
				var leaf_r: float = maxf(1.2, 3.8 * fade)
				var leaf_col: Color
				if i % 3 == 0:
					leaf_col = Color(0.32, 0.95, 0.52, fade) # Parlak zümrüt filiz
				elif i % 3 == 1:
					leaf_col = Color(1.0, 0.88, 0.35, fade) # Sarı kır çiçeği
				else:
					leaf_col = Color(0.95, 0.55, 0.75, fade) # Pembe polen
				canvas.draw_circle(leaf_pos, leaf_r, leaf_col)

static func _draw_districts(canvas: CanvasItem, sim: GridSimulation, anim_time: float, font: Font) -> void:
	var dists := sim.detect_active_districts()
	for d in dists:
		var coords: Array[Vector2i] = d["coords"]
		var col: Color = d["color"]
		var pulse: float = 0.6 + 0.4 * sin(anim_time * 3.2 + float(coords.size()))
		var center_sum := Vector2.ZERO

		for c in coords:
			var base_iso: Vector2 = GameData.grid_to_iso(c.x + 0.5, c.y + 0.5)
			center_sum += base_iso
			var ring_r: float = 16.0 + 2.0 * sin(anim_time * 4.0 + float(c.x + c.y))
			canvas.draw_arc(base_iso + Vector2(0.0, -10.0), ring_r, 0.0, TAU, 18, Color(col.r, col.g, col.b, 0.35 * pulse), 1.6)

		var district_center: Vector2 = center_sum / float(coords.size()) + Vector2(0.0, -42.0)
		var pill_w: float = 240.0
		var pill_h: float = 20.0
		var pill_rect := Rect2(district_center - Vector2(pill_w * 0.5, pill_h * 0.5), Vector2(pill_w, pill_h))

		canvas.draw_rect(pill_rect, Color(0.06, 0.10, 0.14, 0.88), true)
		canvas.draw_rect(pill_rect, Color(col.r, col.g, col.b, 0.75 * pulse), false, 1.2)
		var label_str: String = "%s (%s)" % [d["title"], d["bonus_text"]]
		canvas.draw_string(font, district_center + Vector2(-pill_w * 0.5 + 4.0, 4.0), label_str, HORIZONTAL_ALIGNMENT_CENTER, pill_w - 8.0, 10, Color(col.r, col.g, col.b, 0.95))

static func _draw_dawn_sweep_wave(canvas: CanvasItem, dawn_sweep_timer: float, anim_time: float) -> void:
	if dawn_sweep_timer <= 0.001:
		return
	var t: float = clampf(1.0 - (dawn_sweep_timer / 1.0), 0.0, 1.0)
	var sweep_alpha: float = sin(t * PI)
	var start_p: Vector2 = GameData.grid_to_iso(0.0, 0.0)
	var end_p: Vector2 = GameData.grid_to_iso(float(GameData.GRID_SIZE), float(GameData.GRID_SIZE))
	var wave_center: Vector2 = start_p.lerp(end_p, t)

	var p1 := wave_center + Vector2(-650.0, -200.0)
	var p2 := wave_center + Vector2(650.0, 200.0)
	var p3 := wave_center + Vector2(700.0, 270.0)
	var p4 := wave_center + Vector2(-600.0, -130.0)
	canvas.draw_colored_polygon(PackedVector2Array([p1, p2, p3, p4]), Color(1.0, 0.94, 0.65, 0.22 * sweep_alpha))
	canvas.draw_line(wave_center + Vector2(-750.0, -230.0), wave_center + Vector2(750.0, 230.0), Color(1.0, 0.98, 0.85, 0.45 * sweep_alpha), 3.5)

	for i in range(16):
		var fi: float = float(i)
		var off_t: float = (fi / 16.0) - 0.5
		var spark_p: Vector2 = wave_center + Vector2(off_t * 850.0, off_t * 260.0) + Vector2(sin(fi * 3.7 + anim_time * 5.0) * 40.0, -t * 85.0 - fi * 4.0)
		var sp_alpha: float = sweep_alpha * (0.6 + 0.4 * sin(fi * 2.1 + anim_time * 8.0))
		canvas.draw_circle(spark_p, 2.6, Color(1.0, 0.96, 0.70, sp_alpha))
		canvas.draw_line(spark_p + Vector2(-3.5, 0.0), spark_p + Vector2(3.5, 0.0), Color(1.0, 1.0, 1.0, sp_alpha * 0.8), 1.0)

static func _draw_carbon_lens_overlay(canvas: CanvasItem, sim: GridSimulation, anim_time: float, font: Font) -> void:
	# Karbon Lensi atmosferik arka plan hafif karartma perdesi
	var center_iso: Vector2 = GameData.grid_to_iso(GameData.GRID_SIZE * 0.5, GameData.GRID_SIZE * 0.5)
	canvas.draw_rect(Rect2(center_iso.x - 1400.0, center_iso.y - 1000.0, 2800.0, 2000.0), Color(0.01, 0.03, 0.06, 0.38), true)

	for x in range(GameData.GRID_SIZE):
		for y in range(GameData.GRID_SIZE):
			var btype: int = sim.grid_building[x][y]
			if btype == GameData.BuildingType.NONE:
				continue

			if btype == GameData.BuildingType.LAKE:
				var lake_iso: Vector2 = GameData.grid_to_iso(x + 0.5, y + 0.5) + Vector2(0.0, -5.0)
				var l_pulse: float = 0.75 + 0.25 * sin(anim_time * 3.5 + float(x * 2 + y))
				canvas.draw_arc(lake_iso + Vector2(0.0, 2.0), 22.0, 0.0, TAU, 20, Color(0.25, 0.75, 1.0, 0.55 * l_pulse), 1.6)
				var lake_badge := Rect2(lake_iso.x - 32.0, lake_iso.y - 22.0, 64.0, 18.0)
				canvas.draw_rect(lake_badge, Color(0.04, 0.14, 0.22, 0.95), true)
				canvas.draw_rect(lake_badge, Color(0.35, 0.80, 1.0, 0.85), false, 1.2)
				canvas.draw_string(font, lake_badge.position + Vector2(0.0, 13.0), "💧 -4°C ❄", HORIZONTAL_ALIGNMENT_CENTER, 64.0, 11, Color(0.65, 0.92, 1.0))
				continue

			var blvl: int = sim.grid_level[x][y]
			var vis: Dictionary = GameData.get_building_visual(btype)
			var base_height: float = 12.0
			var lvl_bonus_h: float = 16.0 if blvl >= 3 else (10.0 if blvl == 2 else 0.0)
			var b_height: float = vis["height"] + lvl_bonus_h
			var base_iso: Vector2 = GameData.grid_to_iso(x + 0.5, y + 0.5) + Vector2(0.0, -base_height)
			var roof_pos: Vector2 = base_iso + Vector2(0.0, -b_height)

			var yld: Dictionary = sim.calculate_building_yield(Vector2i(x, y), btype)
			var c_val: int = yld["c"]
			var col: Color
			var badge_bg: Color
			var pulse: float = 0.75 + 0.25 * sin(anim_time * 4.0 + float(x * 2 + y))

			var is_forest: bool = (btype == GameData.BuildingType.FOREST or btype == GameData.BuildingType.BIOCORRIDOR)
			var is_polluter: bool = (btype == GameData.BuildingType.COAL_PLANT or btype == GameData.BuildingType.FOSSIL)

			if c_val < 0:
				# Karbon Yutağı (Yeşil)
				col = Color(0.35, 1.0, 0.55)
				badge_bg = Color(0.05, 0.22, 0.12, 0.95)
			elif c_val > 0:
				# Kirletici Emisyon (Kırmızı / Turuncu)
				col = Color(1.0, 0.35, 0.25)
				badge_bg = Color(0.28, 0.08, 0.06, 0.95)
			else:
				# Karbon Nötr (Mavi / Turkuaz)
				col = Color(0.40, 0.85, 1.0)
				badge_bg = Color(0.06, 0.16, 0.24, 0.95)

			# Zemin emisyon halkası
			canvas.draw_arc(base_iso + Vector2(0.0, 4.0), 16.0, 0.0, TAU, 20, Color(col.r, col.g, col.b, 0.65 * pulse), 2.2)

			# Kentsel Isı Adası Termal Dalga Efekti (Urban Heat Island & Microclimate Cooling Halo)
			if is_forest:
				canvas.draw_arc(base_iso + Vector2(0.0, 4.0), 26.0, 0.0, TAU, 24, Color(0.25, 0.85, 0.95, 0.38 * pulse), 1.5)
			elif is_polluter:
				canvas.draw_arc(base_iso + Vector2(0.0, 4.0), 28.0, 0.0, TAU, 24, Color(1.0, 0.30, 0.15, 0.38 * pulse), 1.5)

			# Çatı üstü karbon rozeti
			var b_text: String
			if is_forest:
				b_text = "%+d ☣ ❄" % c_val
			elif is_polluter:
				b_text = "%+d ☣ 🔥" % c_val
			elif c_val != 0:
				b_text = "%+d ☣" % c_val
			else:
				b_text = "0 ☣"

			var badge_w: float = 62.0 if (is_forest or is_polluter) else 56.0
			var badge_h: float = 20.0
			var badge_rect := Rect2(roof_pos.x - badge_w * 0.5, roof_pos.y - 24.0, badge_w, badge_h)
			canvas.draw_rect(badge_rect, badge_bg, true)
			canvas.draw_rect(badge_rect, Color(col.r, col.g, col.b, 0.9 * pulse), false, 1.5)
			canvas.draw_string(font, badge_rect.position + Vector2(0.0, 14.0), b_text, HORIZONTAL_ALIGNMENT_CENTER, badge_w, 11 if (is_forest or is_polluter) else 12, col)

static func _draw_atmospheric_horizon(canvas: CanvasItem, sim: GridSimulation, anim_time: float, c_ratio: float, is_desert: bool) -> void:
	var golden_dawn_factor: float = 0.0
	if sim != null:
		if sim.zero_carbon_streak >= 3 or sim.carbon == 0:
			golden_dawn_factor = 1.0
		elif sim.zero_carbon_streak >= 1 or sim.carbon <= 5:
			golden_dawn_factor = 0.70
		elif sim.carbon <= 12:
			golden_dawn_factor = 0.35

	# 1. Gökyüzü Atmosferik Güneş / Işık Halosu (Atmospheric Sun Disk & Radiant Glow)
	var sun_pos := Vector2(0.0, -15.0)
	var sun_halo := Color(1.0, 0.78, 0.35, 0.28) if not is_desert else Color(1.0, 0.62, 0.25, 0.32)
	var sun_core := Color(1.0, 0.95, 0.75, 0.90)
	if c_ratio > 0.6:
		sun_halo = Color(0.85, 0.40, 0.20, 0.20)
		sun_core = Color(0.95, 0.60, 0.35, 0.75)

	# Işık ışınları / halolar
	canvas.draw_circle(sun_pos, 72.0, sun_halo)
	canvas.draw_circle(sun_pos, 38.0, sun_halo.lightened(0.25))
	canvas.draw_circle(sun_pos, 16.0, sun_core)
	# Güneş tacı ışıltısı
	var ray_pulse: float = 0.85 + 0.15 * sin(anim_time * 2.5)
	canvas.draw_arc(sun_pos, 24.0 * ray_pulse, 0.0, TAU, 16, Color(sun_core.r, sun_core.g, sun_core.b, 0.45), 1.5)

	# 2. Uzak Dağ / Sıra Tepeler Silüeti (Distant Mountain Ridges framing the grid)
	var mtn_col1: Color
	var mtn_col2: Color
	var ridge_rim1: Color
	var ridge_rim2: Color
	if is_desert:
		mtn_col1 = Color(0.24, 0.14, 0.09).lerp(Color(0.20, 0.12, 0.10), c_ratio)
		mtn_col2 = Color(0.34, 0.20, 0.13).lerp(Color(0.26, 0.15, 0.12), c_ratio)
		ridge_rim1 = Color(0.55, 0.35, 0.22, 0.70)
		ridge_rim2 = Color(0.70, 0.45, 0.26, 0.80)
	else:
		mtn_col1 = Color(0.07, 0.18, 0.24).lerp(Color(0.12, 0.14, 0.16), c_ratio)
		mtn_col2 = Color(0.11, 0.26, 0.32).lerp(Color(0.16, 0.18, 0.18), c_ratio)
		ridge_rim1 = Color(0.25, 0.50, 0.60, 0.75)
		ridge_rim2 = Color(0.35, 0.65, 0.75, 0.85)

	if golden_dawn_factor > 0.0:
		ridge_rim1 = ridge_rim1.lerp(Color(1.0, 0.88, 0.45, 0.95), 0.55 * golden_dawn_factor)
		ridge_rim2 = ridge_rim2.lerp(Color(1.0, 0.92, 0.55, 1.0), 0.60 * golden_dawn_factor)

	# Arka Dağ Sırası (Far Ridge Layer)
	var pts1 := PackedVector2Array([
		Vector2(-950, 350),
		Vector2(-950, 100),
		Vector2(-720, 40),
		Vector2(-520, 80),
		Vector2(-340, 5),
		Vector2(-160, 35),
		Vector2(0, -10),
		Vector2(170, 30),
		Vector2(360, 10),
		Vector2(540, 75),
		Vector2(730, 35),
		Vector2(950, 90),
		Vector2(950, 350)
	])
	canvas.draw_colored_polygon(pts1, mtn_col1)
	for p_i in range(1, 11):
		canvas.draw_line(pts1[p_i], pts1[p_i + 1], ridge_rim1, 1.4)

	# Ön Sıra Tepeler (Near Ridge Layer)
	var pts2 := PackedVector2Array([
		Vector2(-950, 450),
		Vector2(-950, 170),
		Vector2(-680, 105),
		Vector2(-480, 140),
		Vector2(-260, 65),
		Vector2(-90, 95),
		Vector2(0, 55),
		Vector2(100, 90),
		Vector2(280, 55),
		Vector2(490, 130),
		Vector2(690, 95),
		Vector2(950, 150),
		Vector2(950, 450)
	])
	canvas.draw_colored_polygon(pts2, mtn_col2)
	for p_i in range(1, 11):
		canvas.draw_line(pts2[p_i], pts2[p_i + 1], ridge_rim2, 1.6)

	# 3. Minyatür Dönen Uzak Rüzgar Türbinleri (Distant Horizon Wind Turbines)
	if not is_desert or c_ratio < 0.7:
		var turbine_locs := [
			Vector2(-580, 70),
			Vector2(-340, 5),
			Vector2(360, 10),
			Vector2(610, 65)
		]
		for t_idx in range(turbine_locs.size()):
			var tp: Vector2 = turbine_locs[t_idx]
			canvas.draw_line(tp + Vector2(0, 16), tp, Color(0.80, 0.92, 0.98, 0.75), 1.8)
			var rot: float = anim_time * 2.6 + float(t_idx) * 1.4
			for b in range(3):
				var b_ang: float = rot + float(b) * (TAU / 3.0)
				var b_end: Vector2 = tp + Vector2(cos(b_ang), sin(b_ang) * 0.65) * 9.5
				canvas.draw_line(tp, b_end, Color(0.92, 0.97, 1.0, 0.85), 1.4)

	# 4. Solarpunk 0-Karbon Altın Şafak Işınları (Crepuscular God-Rays cascading over ridges)
	if golden_dawn_factor > 0.0:
		var solarpunk_halo := Color(0.40, 0.95, 0.65, 0.28 * golden_dawn_factor)
		canvas.draw_circle(sun_pos, 110.0, solarpunk_halo)
		canvas.draw_arc(sun_pos, 52.0, 0.0, TAU, 32, Color(1.0, 0.88, 0.35, 0.65 * golden_dawn_factor), 2.0)

		var ray_angles := [-0.96, -0.70, -0.42, -0.15, 0.15, 0.42, 0.70, 0.96]
		for i in range(ray_angles.size()):
			var r_ang: float = ray_angles[i] + sin(anim_time * 0.7 + float(i)) * 0.03
			var r_width: float = 0.08 + sin(anim_time * 1.1 + float(i * 2)) * 0.02
			var r_len: float = 680.0
			var p0: Vector2 = sun_pos
			var p1: Vector2 = sun_pos + Vector2(sin(r_ang - r_width), cos(r_ang - r_width)) * r_len
			var p2: Vector2 = sun_pos + Vector2(sin(r_ang + r_width), cos(r_ang + r_width)) * r_len
			var r_alpha: float = (0.16 + 0.06 * sin(anim_time * 1.5 + float(i))) * golden_dawn_factor
			canvas.draw_colored_polygon(PackedVector2Array([p0, p1, p2]), Color(1.0, 0.92, 0.45, r_alpha))

