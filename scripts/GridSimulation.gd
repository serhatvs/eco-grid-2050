extends RefCounted

const GameData = preload("res://scripts/GameData.gd")

var grid_state: Array = []
var grid_building: Array = []
var grid_level: Array = []
var tile_anim: Dictionary = {}

var energy: int = 10
var food: int = 10
var water: int = 10
var carbon: int = 20
var day: int = 1
var zero_carbon_streak: int = 0
var upcoming_crisis_id: int = -1
var active_crisis_type: int = -1
var current_scenario: int = 0
var current_weather: int = 0

var stats_forests_planted: int = 0
var stats_coal_demolished: int = 0
var coal_demolished_count: int:
	get:
		return stats_coal_demolished
var stats_upgrades_done: int = 0
var stats_clean_energy_built: int = 0
var stats_cards_played: int = 0
var max_resilience_tier_reached: int = 0
var carbon_history: Array[int] = []
var energy_history: Array[int] = []
var food_history: Array[int] = []
var water_history: Array[int] = []

var deck: Array = []
var discard_pile: Array[int] = []
var hand: Array = []
var active_perks: Array = []
var event_log: Array[String] = []

func log_event(entry: String) -> void:
	event_log.append(entry)
	if event_log.size() > 50:
		event_log.remove_at(0)

var quests_completed: Dictionary = {
	"coal": false,
	"forest": false,
	"upgrade": false,
	"mega": false
}

var undo_available: bool = false
var undo_remaining_today: int = 1
var undo_snapshot: Dictionary = {}

func reset_for_new_game(scenario: int) -> void:
	current_scenario = scenario
	if scenario == 3:
		energy = 14
		food = 14
		water = 14
		carbon = 25
	elif scenario == 2:
		energy = 16
		food = 10
		water = 5
		carbon = 16
	elif scenario == 1:
		energy = 12
		food = 10
		water = 10
		carbon = 42
	else:
		energy = 10
		food = 10
		water = 10
		carbon = 20
	day = 1
	zero_carbon_streak = 0
	upcoming_crisis_id = randi() % 5
	active_crisis_type = -1
	current_weather = GameData.WeatherType.MODERATE
	stats_forests_planted = 0
	stats_coal_demolished = 0
	stats_upgrades_done = 0
	stats_clean_energy_built = 0
	stats_cards_played = 0
	max_resilience_tier_reached = 0
	carbon_history.clear()
	carbon_history.append(carbon)
	energy_history.clear()
	energy_history.append(energy)
	food_history.clear()
	food_history.append(food)
	water_history.clear()
	water_history.append(water)
	active_perks.clear()
	event_log.clear()
	discard_pile.clear()
	var s_name: String = "Sonsuz Sandbox" if scenario == 3 else ("Kuraklık Vahası" if scenario == 2 else ("Sanayi Mirası" if scenario == 1 else "Standart Ekoloji"))
	log_event("📅 Gün 1: Şehir yönetimi başladı (%s). Net-sıfır ve iklim direnci hedefleri belirlendi." % s_name)
	if scenario == 3:
		log_event("🎯 COP31 SONSUZ MOD: Gün sınırı yok; prosedürel haritada ekosisteminizi serbestçe genişletin ve iklim direncinizi test edin!")
	else:
		log_event("🎯 COP31 HEDEFİ: Karbon emisyonunu üst üste 5 gün 0'da tutarak veya 25 gün krizlere direnerek zafere ulaşın.")
	hand.clear()
	tile_anim.clear()
	quests_completed = {"coal": false, "forest": false, "upgrade": false, "mega": false}
	undo_available = false
	undo_remaining_today = 1
	undo_snapshot.clear()

	deck = [
		GameData.CardId.SOLAR, GameData.CardId.SOLAR,
		GameData.CardId.WIND,
		GameData.CardId.HOUSING, GameData.CardId.HOUSING,
		GameData.CardId.FARM, GameData.CardId.FARM,
		GameData.CardId.FOREST, GameData.CardId.FOREST,
		GameData.CardId.RECYCLE,
		GameData.CardId.WATER_PLANT, GameData.CardId.WATER_PLANT,
		GameData.CardId.FOSSIL,
		GameData.CardId.EXPAND, GameData.CardId.EXPAND,
		GameData.CardId.DEMOLISH,
		GameData.CardId.GEOTHERMAL,
		GameData.CardId.CCS,
		GameData.CardId.BIOCORRIDOR,
		GameData.CardId.UPGRADE_KIT,
		GameData.CardId.ECO_SURVEY
	]
	if current_scenario == 2:
		deck.append(GameData.CardId.WATER_PLANT)
		deck.append(GameData.CardId.RECYCLE)
	elif current_scenario == 3:
		deck.append(GameData.CardId.ECO_SURVEY)
		deck.append(GameData.CardId.UPGRADE_KIT)
		deck.append(GameData.CardId.GEOTHERMAL)

	grid_state.clear()
	grid_building.clear()
	grid_level.clear()
	for x in range(GameData.GRID_SIZE):
		var state_col: Array = []
		var build_col: Array = []
		var lvl_col: Array = []
		for y in range(GameData.GRID_SIZE):
			if x >= 7 and x <= 11 and y >= 7 and y <= 11:
				state_col.append(GameData.TileState.UNLOCKED)
			else:
				state_col.append(GameData.TileState.LOCKED)
			build_col.append(GameData.BuildingType.NONE)
			lvl_col.append(1)
		grid_state.append(state_col)
		grid_building.append(build_col)
		grid_level.append(lvl_col)

	_spawn_special_map_features()
	recalculate_borders()
	if current_scenario == 2:
		hand.append(GameData.CardId.WATER_PLANT)
	draw_cards_for_day_start()

func save_undo_snapshot() -> void:
	if undo_remaining_today <= 0:
		undo_available = false
		return
	var st_copy: Array = []
	var bd_copy: Array = []
	var lv_copy: Array = []
	for x in range(GameData.GRID_SIZE):
		st_copy.append(grid_state[x].duplicate())
		bd_copy.append(grid_building[x].duplicate())
		lv_copy.append(grid_level[x].duplicate())

	undo_snapshot = {
		"grid_state": st_copy,
		"grid_building": bd_copy,
		"grid_level": lv_copy,
		"energy": energy,
		"food": food,
		"water": water,
		"carbon": carbon,
		"hand": hand.duplicate(),
		"discard_pile": discard_pile.duplicate(),
		"stats_forests_planted": stats_forests_planted,
		"stats_coal_demolished": stats_coal_demolished,
		"stats_upgrades_done": stats_upgrades_done,
		"stats_clean_energy_built": stats_clean_energy_built,
		"stats_cards_played": stats_cards_played,
		"max_resilience_tier": max_resilience_tier_reached,
		"carbon_history": carbon_history.duplicate(),
		"energy_history": energy_history.duplicate(),
		"food_history": food_history.duplicate(),
		"water_history": water_history.duplicate(),
		"quests_completed": quests_completed.duplicate(),
		"event_log": event_log.duplicate()
	}
	undo_available = true

func restore_undo_snapshot() -> bool:
	if not undo_available or undo_remaining_today <= 0 or undo_snapshot.is_empty():
		return false
	for x in range(GameData.GRID_SIZE):
		grid_state[x] = undo_snapshot["grid_state"][x].duplicate()
		grid_building[x] = undo_snapshot["grid_building"][x].duplicate()
		grid_level[x] = undo_snapshot["grid_level"][x].duplicate()
	energy = undo_snapshot["energy"]
	food = undo_snapshot["food"]
	water = undo_snapshot["water"]
	carbon = undo_snapshot["carbon"]
	hand = undo_snapshot["hand"].duplicate()
	if undo_snapshot.has("discard_pile"):
		discard_pile = Array(undo_snapshot["discard_pile"], TYPE_INT, "", null)
	stats_forests_planted = undo_snapshot["stats_forests_planted"]
	stats_coal_demolished = undo_snapshot["stats_coal_demolished"]
	stats_upgrades_done = undo_snapshot["stats_upgrades_done"]
	stats_clean_energy_built = undo_snapshot["stats_clean_energy_built"]
	stats_cards_played = undo_snapshot["stats_cards_played"]
	max_resilience_tier_reached = undo_snapshot.get("max_resilience_tier", 0)
	if undo_snapshot.has("carbon_history"):
		carbon_history = undo_snapshot["carbon_history"].duplicate()
	if undo_snapshot.has("energy_history"):
		energy_history = undo_snapshot["energy_history"].duplicate()
	if undo_snapshot.has("food_history"):
		food_history = undo_snapshot["food_history"].duplicate()
	if undo_snapshot.has("water_history"):
		water_history = undo_snapshot["water_history"].duplicate()
	quests_completed = undo_snapshot["quests_completed"].duplicate()
	if undo_snapshot.has("event_log"):
		event_log = undo_snapshot["event_log"].duplicate()
	log_event("↩ Gün %d: Son kart hamlesi geri alındı." % day)
	undo_available = false
	undo_remaining_today -= 1
	undo_snapshot.clear()
	return true

func reset_daily_undo() -> void:
	undo_available = false
	undo_remaining_today = 1
	undo_snapshot.clear()

func check_and_claim_quests() -> Array[String]:
	var notifications: Array[String] = []
	if not quests_completed["coal"] and stats_coal_demolished >= 1:
		quests_completed["coal"] = true
		energy += 4
		water += 4
		notifications.append("🎯 GÖREV TAMAMLANDI (Kömürden Çıkış): Ödül ⚡+4, 💧+4!")
	if not quests_completed["forest"] and stats_forests_planted >= 3:
		quests_completed["forest"] = true
		carbon = clampi(carbon - 8, 0, GameData.MAX_CARBON)
		notifications.append("🎯 GÖREV TAMAMLANDI (Yeşil Kuşak - 3 Orman): Ödül ☣-8 Karbon!")
	if not quests_completed["upgrade"] and stats_upgrades_done >= 2:
		quests_completed["upgrade"] = true
		food += 5
		energy += 3
		notifications.append("🎯 GÖREV TAMAMLANDI (Dikey Mimari - 2x Lv.2★): Ödül 🌱+5, ⚡+3!")

	var has_mega: bool = false
	for x in range(GameData.GRID_SIZE):
		for y in range(GameData.GRID_SIZE):
			if grid_level[x][y] >= 3:
				has_mega = true
				break
		if has_mega:
			break
	if not quests_completed.get("mega", false) and has_mega:
		quests_completed["mega"] = true
		energy += 6
		water += 6
		food += 6
		carbon = clampi(carbon - 10, 0, GameData.MAX_CARBON)
		notifications.append("🎯 GÖREV TAMAMLANDI (Mega Mühendislik - 1x Lv.3★★): Ödül ⚡+6, 💧+6, 🌱+6, ☣-10 Karbon!")
	return notifications

func _spawn_special_map_features() -> void:
	if current_scenario == 3:
		# Prosedürel Sonsuz Sandbox Haritası
		var lake_center_x: int = randi_range(8, 10)
		var lake_center_y: int = randi_range(8, 10)
		grid_building[lake_center_x][lake_center_y] = GameData.BuildingType.LAKE

		var locked_coords: Array[Vector2i] = []
		for x in range(2, GameData.GRID_SIZE - 2):
			for y in range(2, GameData.GRID_SIZE - 2):
				if grid_state[x][y] == GameData.TileState.LOCKED and grid_building[x][y] == GameData.BuildingType.NONE:
					locked_coords.append(Vector2i(x, y))
		locked_coords.shuffle()

		# 2-3 Doğal Göl
		for i in range(mini(3, locked_coords.size())):
			grid_building[locked_coords[i].x][locked_coords[i].y] = GameData.BuildingType.LAKE
		# 2 Jeotermal Kaplıca
		if locked_coords.size() >= 5:
			grid_building[locked_coords[3].x][locked_coords[3].y] = GameData.BuildingType.GEOTHERMAL
			grid_building[locked_coords[4].x][locked_coords[4].y] = GameData.BuildingType.GEOTHERMAL
		# 2-3 Kömür Kalıntısı
		if locked_coords.size() >= 8:
			grid_building[locked_coords[5].x][locked_coords[5].y] = GameData.BuildingType.COAL_PLANT
			grid_building[locked_coords[6].x][locked_coords[6].y] = GameData.BuildingType.COAL_PLANT
			grid_building[locked_coords[7].x][locked_coords[7].y] = GameData.BuildingType.COAL_PLANT
		return

	if current_scenario == 2:
		grid_building[9][9] = GameData.BuildingType.LAKE
		grid_building[5][5] = GameData.BuildingType.COAL_PLANT
	else:
		grid_building[6][9] = GameData.BuildingType.LAKE
		grid_building[10][12] = GameData.BuildingType.LAKE
		grid_building[7][7] = GameData.BuildingType.COAL_PLANT
		grid_building[13][11] = GameData.BuildingType.COAL_PLANT
		if current_scenario == 1:
			grid_building[11][11] = GameData.BuildingType.COAL_PLANT

	var locked_coords: Array[Vector2i] = []
	for x in range(2, GameData.GRID_SIZE - 2):
		for y in range(2, GameData.GRID_SIZE - 2):
			if grid_state[x][y] == GameData.TileState.LOCKED and grid_building[x][y] == GameData.BuildingType.NONE:
				locked_coords.append(Vector2i(x, y))
	locked_coords.shuffle()
	if locked_coords.size() >= 5:
		if current_scenario != 2:
			grid_building[locked_coords[0].x][locked_coords[0].y] = GameData.BuildingType.LAKE
			grid_building[locked_coords[1].x][locked_coords[1].y] = GameData.BuildingType.LAKE
			grid_building[locked_coords[2].x][locked_coords[2].y] = GameData.BuildingType.LAKE
		grid_building[locked_coords[3].x][locked_coords[3].y] = GameData.BuildingType.COAL_PLANT
		grid_building[locked_coords[4].x][locked_coords[4].y] = GameData.BuildingType.COAL_PLANT

func recalculate_borders() -> void:
	for x in range(GameData.GRID_SIZE):
		for y in range(GameData.GRID_SIZE):
			if grid_state[x][y] != GameData.TileState.UNLOCKED:
				grid_state[x][y] = GameData.TileState.LOCKED

	for x in range(GameData.GRID_SIZE):
		for y in range(GameData.GRID_SIZE):
			if grid_state[x][y] == GameData.TileState.LOCKED:
				for n in get_orthogonal_neighbors(Vector2i(x, y)):
					if grid_state[n.x][n.y] == GameData.TileState.UNLOCKED:
						grid_state[x][y] = GameData.TileState.BORDER
						break

func get_orthogonal_neighbors(coord: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var dirs: Array[Vector2i] = [
		Vector2i(0, -1),
		Vector2i(0, 1),
		Vector2i(-1, 0),
		Vector2i(1, 0)
	]
	for d in dirs:
		var nx: int = coord.x + d.x
		var ny: int = coord.y + d.y
		if nx >= 0 and nx < GameData.GRID_SIZE and ny >= 0 and ny < GameData.GRID_SIZE:
			result.append(Vector2i(nx, ny))
	return result

func draw_cards_for_day_start() -> void:
	var draw_count: int = (4 - hand.size()) if hand.size() < 4 else 2
	for i in range(draw_count):
		var pick: int = deck[randi() % deck.size()]
		hand.append(pick)

func roll_daily_weather(next_day: int) -> int:
	if next_day in [4, 9, 14, 19]:
		current_weather = GameData.WeatherType.HEATWAVE_WARNING
	elif next_day in [5, 10, 15, 20]:
		current_weather = GameData.WeatherType.MODERATE
	else:
		var r: float = randf()
		if r < 0.28:
			current_weather = GameData.WeatherType.CLEAR_SUN
		elif r < 0.54:
			current_weather = GameData.WeatherType.SPRING_RAIN
		elif r < 0.80:
			current_weather = GameData.WeatherType.FRESH_BREEZE
		else:
			current_weather = GameData.WeatherType.MODERATE
	return current_weather

func can_afford_card(card_id: int) -> bool:
	if card_id == GameData.CardId.EXPAND:
		return energy > 2 and water > 2
	elif card_id == GameData.CardId.DEMOLISH:
		var e_cost: int = 0 if active_perks.has("coal_phaseout") else 1
		return energy > e_cost
	elif card_id == GameData.CardId.UPGRADE_KIT:
		return energy > 2 and water > 1
	elif card_id == GameData.CardId.ECO_SURVEY:
		return energy > 3 and water > 1
	else:
		var btype: int = GameData.CARDS[card_id]["building"]
		match btype:
			GameData.BuildingType.WIND:
				return water > 2
			GameData.BuildingType.SOLAR:
				return water > 1
			GameData.BuildingType.FARM:
				return energy > 1 and water > 1
			GameData.BuildingType.FOREST:
				return water > 1
			GameData.BuildingType.RECYCLE:
				return energy > 1
			GameData.BuildingType.WATER_PLANT:
				return energy > 1
			GameData.BuildingType.HOUSING:
				return energy > 1
			GameData.BuildingType.GEOTHERMAL:
				return water > 2
			GameData.BuildingType.CCS:
				return energy > 3
			GameData.BuildingType.BATTERY:
				return water > 1
			GameData.BuildingType.COP31:
				return energy > 2 and water > 2
			_:
				return true

func get_card_unaffordable_reason(card_id: int) -> String:
	var req_e: int = 0
	var req_w: int = 0
	if card_id == GameData.CardId.EXPAND:
		req_e = 2
		req_w = 2
	elif card_id == GameData.CardId.DEMOLISH:
		req_e = 0 if active_perks.has("coal_phaseout") else 1
	elif card_id == GameData.CardId.UPGRADE_KIT:
		req_e = 2
		req_w = 1
	elif card_id == GameData.CardId.ECO_SURVEY:
		req_e = 3
		req_w = 1
	elif GameData.CARDS[card_id].has("building"):
		var btype: int = GameData.CARDS[card_id]["building"]
		match btype:
			GameData.BuildingType.WIND:
				req_w = 2
			GameData.BuildingType.SOLAR:
				req_w = 1
			GameData.BuildingType.FARM:
				req_e = 1
				req_w = 1
			GameData.BuildingType.FOREST:
				req_w = 1
			GameData.BuildingType.RECYCLE:
				req_e = 1
			GameData.BuildingType.WATER_PLANT:
				req_e = 1
			GameData.BuildingType.HOUSING:
				req_e = 1
			GameData.BuildingType.GEOTHERMAL:
				req_w = 2
			GameData.BuildingType.CCS:
				req_e = 3
			GameData.BuildingType.BATTERY:
				req_w = 1
			GameData.BuildingType.COP31:
				req_e = 2
				req_w = 2

	var lack_e: bool = (energy <= req_e) and req_e > 0
	var lack_w: bool = (water <= req_w) and req_w > 0
	if lack_e and lack_w:
		return "⚠ ⚡ ve 💧 Yetersiz"
	elif lack_e:
		return "⚠ ⚡ Enerji Yetersiz"
	elif lack_w:
		return "⚠ 💧 Su Yetersiz"
	return ""

func is_tile_valid_for_card(coord: Vector2i, card_id: int) -> bool:
	if coord.x < 0 or coord.x >= GameData.GRID_SIZE or coord.y < 0 or coord.y >= GameData.GRID_SIZE:
		return false
	var target_mode: String = GameData.CARDS[card_id]["target"]
	var state: int = grid_state[coord.x][coord.y]
	var btype: int = grid_building[coord.x][coord.y]
	var blvl: int = grid_level[coord.x][coord.y]

	if card_id == GameData.CardId.UPGRADE_KIT or target_mode == "UPGRADEABLE":
		return state == GameData.TileState.UNLOCKED and btype != GameData.BuildingType.NONE and btype != GameData.BuildingType.LAKE and btype != GameData.BuildingType.COAL_PLANT and blvl < 3

	if target_mode == "EMPTY":
		var card_btype: int = GameData.CARDS[card_id]["building"]
		if state != GameData.TileState.UNLOCKED:
			return false
		if btype == GameData.BuildingType.NONE:
			return true
		if btype == card_btype and blvl < 3:
			return true
		return false
	elif target_mode == "BORDER":
		return state == GameData.TileState.BORDER
	elif target_mode == "LOCKED":
		return state == GameData.TileState.LOCKED or state == GameData.TileState.BORDER
	elif target_mode == "OCCUPIED":
		return state == GameData.TileState.UNLOCKED and btype != GameData.BuildingType.NONE and btype != GameData.BuildingType.LAKE
	return false

func get_synergy_links(coord: Vector2i, btype: int) -> Array[Vector2i]:
	var links: Array[Vector2i] = []
	var neighbors: Array[Vector2i] = get_orthogonal_neighbors(coord)
	match btype:
		GameData.BuildingType.SOLAR:
			for n in neighbors:
				if grid_building[n.x][n.y] == GameData.BuildingType.HOUSING:
					links.append(n)
		GameData.BuildingType.WIND:
			if neighbors.size() == 4:
				var all_empty: bool = true
				for n in neighbors:
					if grid_building[n.x][n.y] != GameData.BuildingType.NONE:
						all_empty = false
						break
				if all_empty:
					for n in neighbors:
						links.append(n)
		GameData.BuildingType.HOUSING:
			for n in neighbors:
				var nb: int = grid_building[n.x][n.y]
				if nb == GameData.BuildingType.FOREST or nb == GameData.BuildingType.BATTERY:
					links.append(n)
		GameData.BuildingType.FARM:
			for n in neighbors:
				var nb: int = grid_building[n.x][n.y]
				if nb == GameData.BuildingType.WATER_PLANT or nb == GameData.BuildingType.LAKE or nb == GameData.BuildingType.BIOCORRIDOR or nb == GameData.BuildingType.BATTERY:
					links.append(n)
		GameData.BuildingType.FOREST:
			for n in neighbors:
				var nb: int = grid_building[n.x][n.y]
				if nb == GameData.BuildingType.HOUSING or nb == GameData.BuildingType.FOSSIL or nb == GameData.BuildingType.COAL_PLANT or nb == GameData.BuildingType.BIOCORRIDOR or nb == GameData.BuildingType.COP31:
					links.append(n)
		GameData.BuildingType.RECYCLE:
			for n in neighbors:
				if grid_building[n.x][n.y] == GameData.BuildingType.HOUSING:
					links.append(n)
		GameData.BuildingType.WATER_PLANT:
			for n in neighbors:
				var nb: int = grid_building[n.x][n.y]
				if nb == GameData.BuildingType.FARM or nb == GameData.BuildingType.FOREST or nb == GameData.BuildingType.LAKE:
					links.append(n)
		GameData.BuildingType.GEOTHERMAL:
			for n in neighbors:
				var nb: int = grid_building[n.x][n.y]
				if nb == GameData.BuildingType.LAKE or nb == GameData.BuildingType.WATER_PLANT:
					links.append(n)
		GameData.BuildingType.CCS:
			for n in neighbors:
				var nb: int = grid_building[n.x][n.y]
				if nb == GameData.BuildingType.FOSSIL or nb == GameData.BuildingType.COAL_PLANT or nb == GameData.BuildingType.COP31:
					links.append(n)
		GameData.BuildingType.BIOCORRIDOR:
			for n in neighbors:
				var nb: int = grid_building[n.x][n.y]
				if nb == GameData.BuildingType.FARM or nb == GameData.BuildingType.FOREST:
					links.append(n)
		GameData.BuildingType.BATTERY:
			for n in neighbors:
				var nb: int = grid_building[n.x][n.y]
				if nb == GameData.BuildingType.SOLAR or nb == GameData.BuildingType.WIND:
					links.append(n)
		GameData.BuildingType.COP31:
			for n in neighbors:
				var nb: int = grid_building[n.x][n.y]
				if nb != GameData.BuildingType.NONE and nb != GameData.BuildingType.LAKE:
					links.append(n)
	return links

func has_available_synergy(card_id: int) -> bool:
	if card_id < 0 or card_id >= GameData.CARDS.size():
		return false
	if not GameData.CARDS[card_id].has("building"):
		return false
	var btype: int = GameData.CARDS[card_id]["building"]
	for x in range(GameData.GRID_SIZE):
		for y in range(GameData.GRID_SIZE):
			if grid_state[x][y] == GameData.TileState.UNLOCKED and grid_building[x][y] == GameData.BuildingType.NONE:
				if get_synergy_links(Vector2i(x, y), btype).size() > 0:
					return true
	return false

func get_synergy_description(coord: Vector2i, btype: int) -> String:
	var neighbors: Array[Vector2i] = get_orthogonal_neighbors(coord)
	match btype:
		GameData.BuildingType.SOLAR:
			for n in neighbors:
				if grid_building[n.x][n.y] == GameData.BuildingType.HOUSING:
					return "✨ +1⚡ Eko-Konut Sinerjisi!"
		GameData.BuildingType.WIND:
			if neighbors.size() == 4:
				var all_empty: bool = true
				for n in neighbors:
					if grid_building[n.x][n.y] != GameData.BuildingType.NONE:
						all_empty = false
						break
				if all_empty:
					return "✨ +2⚡ Rüzgar Koridoru Bonusu!"
		GameData.BuildingType.HOUSING:
			for n in neighbors:
				var nb: int = grid_building[n.x][n.y]
				if nb == GameData.BuildingType.FOREST:
					return "✨ 0☣ +1🌱 Park Sinerjisi!"
				elif nb == GameData.BuildingType.BATTERY:
					return "✨ +1⚡ Akıllı Şebeke Yedek Güç Sinerjisi!"
		GameData.BuildingType.FARM:
			for n in neighbors:
				var nb: int = grid_building[n.x][n.y]
				if nb == GameData.BuildingType.WATER_PLANT or nb == GameData.BuildingType.LAKE or nb == GameData.BuildingType.BIOCORRIDOR:
					return "✨ +2🌱 Sulama/Vaha Bonusu!"
				elif nb == GameData.BuildingType.BATTERY:
					return "✨ +1🌱 Kesintisiz Tarımsal LED Sinerjisi!"
		GameData.BuildingType.FOREST:
			for n in neighbors:
				var nb: int = grid_building[n.x][n.y]
				if nb == GameData.BuildingType.COP31:
					return "✨ -2☣ COP31 Küresel Karbon Kredisi Desteği!"
				elif nb == GameData.BuildingType.HOUSING or nb == GameData.BuildingType.FOSSIL or nb == GameData.BuildingType.COAL_PLANT or nb == GameData.BuildingType.BIOCORRIDOR:
					return "✨ -1☣ Karbon Yutağı Bonusu!"
		GameData.BuildingType.RECYCLE:
			for n in neighbors:
				if grid_building[n.x][n.y] == GameData.BuildingType.HOUSING:
					return "✨ +1💧 Geri Dönüşüm Sinerjisi!"
		GameData.BuildingType.WATER_PLANT:
			for n in neighbors:
				var nb: int = grid_building[n.x][n.y]
				if nb == GameData.BuildingType.LAKE:
					return "✨ +2💧 Doğal Göl Sinerjisi!"
		GameData.BuildingType.GEOTHERMAL:
			for n in neighbors:
				var nb: int = grid_building[n.x][n.y]
				if nb == GameData.BuildingType.LAKE or nb == GameData.BuildingType.WATER_PLANT:
					return "✨ +2⚡ Akifer Termal Bonusu!"
		GameData.BuildingType.CCS:
			for n in neighbors:
				var nb: int = grid_building[n.x][n.y]
				if nb == GameData.BuildingType.COP31:
					return "✨ -3☣ COP31 Doğrudan Hava Yakalama Fonu!"
				elif nb == GameData.BuildingType.FOSSIL or nb == GameData.BuildingType.COAL_PLANT:
					return "✨ -2☣ Sanayi Karbon Yakalama!"
					return "✨ -2☣ Sanayi Karbon Yakalama!"
		GameData.BuildingType.BIOCORRIDOR:
			for n in neighbors:
				var nb: int = grid_building[n.x][n.y]
				if nb == GameData.BuildingType.FARM or nb == GameData.BuildingType.FOREST:
					return "✨ +1🌱 -1☣ Ekosistem Koridoru!"
		GameData.BuildingType.BATTERY:
			for n in neighbors:
				var nb: int = grid_building[n.x][n.y]
				if nb == GameData.BuildingType.SOLAR or nb == GameData.BuildingType.WIND:
					return "✨ +2⚡ Temiz Enerji Depolama Sinerjisi!"
		GameData.BuildingType.COP31:
			return "✨ Solarpunk İklim Liderliği & Diplomatik Moral!"
	return ""

func calculate_building_yield(coord: Vector2i, btype: int, level_override: int = -1) -> Dictionary:
	var d_energy: int = 0
	var d_food: int = 0
	var d_water: int = 0
	var d_carbon: int = 0
	var lvl: int = level_override if level_override > 0 else grid_level[coord.x][coord.y]
	var neighbors: Array[Vector2i] = get_orthogonal_neighbors(coord)

	match btype:
		GameData.BuildingType.SOLAR:
			d_energy += 3 + (5 if lvl >= 3 else (2 if lvl == 2 else 0))
			d_water -= (0 if lvl >= 3 else 1)
			if current_weather == GameData.WeatherType.CLEAR_SUN:
				d_energy += 2 if lvl >= 3 else 1
			for n in neighbors:
				if grid_building[n.x][n.y] == GameData.BuildingType.HOUSING:
					d_energy += 2 if lvl >= 3 else 1
					break
			if active_perks.has("solar_roof"):
				d_energy += 1
			if active_perks.has("energy_storage"):
				d_energy += 1

		GameData.BuildingType.WIND:
			d_energy += 3 + (5 if lvl >= 3 else (2 if lvl == 2 else 0))
			d_water -= (1 if lvl >= 3 else 2)
			if current_weather == GameData.WeatherType.FRESH_BREEZE:
				d_energy += 2 if lvl >= 3 else 1
			var all_empty: bool = (neighbors.size() == 4)
			for n in neighbors:
				if grid_building[n.x][n.y] != GameData.BuildingType.NONE:
					all_empty = false
					break
			if all_empty:
				d_energy += 3 if lvl >= 3 else 2
			if active_perks.has("wind_corridor"):
				d_energy += 1
			if active_perks.has("energy_storage"):
				d_energy += 1

		GameData.BuildingType.HOUSING:
			d_water += 3 + (5 if lvl >= 3 else (2 if lvl == 2 else 0))
			d_energy -= (0 if lvl >= 3 else 1)
			var has_forest: bool = false
			for n in neighbors:
				if grid_building[n.x][n.y] == GameData.BuildingType.FOREST:
					has_forest = true
					break
			if has_forest:
				d_food += 2 if lvl >= 3 else (1 if lvl == 2 else 1)
				if lvl >= 3:
					d_carbon -= 1
			else:
				d_carbon += (0 if lvl >= 3 else 1)
			for n in neighbors:
				if grid_building[n.x][n.y] == GameData.BuildingType.BATTERY:
					d_energy += 1
					break
			if active_perks.has("green_roof"):
				d_carbon -= 1
				d_food += 1
			if active_perks.has("circular_metropolis"):
				d_water += 1
				for n in neighbors:
					if grid_building[n.x][n.y] == GameData.BuildingType.RECYCLE:
						d_energy += 1
						break

		GameData.BuildingType.FARM:
			d_food += 3 + (5 if lvl >= 3 else (2 if lvl == 2 else 0))
			d_energy -= (0 if lvl >= 3 else 1)
			d_water -= (0 if lvl >= 3 else 1)
			if current_weather == GameData.WeatherType.SPRING_RAIN:
				d_food += 1
			var has_water_source: bool = false
			for n in neighbors:
				var nb: int = grid_building[n.x][n.y]
				if nb == GameData.BuildingType.WATER_PLANT or nb == GameData.BuildingType.LAKE:
					has_water_source = true
				if nb == GameData.BuildingType.BIOCORRIDOR:
					d_food += 2 if lvl >= 3 else 1
			if has_water_source:
				d_food += 3 if lvl >= 3 else 2
			for n in neighbors:
				if grid_building[n.x][n.y] == GameData.BuildingType.BATTERY:
					d_food += 1
					break
			if active_perks.has("drip_irrigation"):
				d_food += 1
				d_water += 1
			if active_perks.has("pollinator_network"):
				for n in neighbors:
					var nb: int = grid_building[n.x][n.y]
					if nb == GameData.BuildingType.FOREST or nb == GameData.BuildingType.BIOCORRIDOR:
						d_food += 2
						break

		GameData.BuildingType.FOREST:
			d_carbon -= 2 + (5 if lvl >= 3 else (2 if lvl == 2 else 0))
			d_water -= (0 if lvl >= 3 else 1)
			if current_weather == GameData.WeatherType.SPRING_RAIN:
				d_food += 1
			if lvl >= 3:
				d_food += 1
			for n in neighbors:
				var nb: int = grid_building[n.x][n.y]
				if nb == GameData.BuildingType.HOUSING or nb == GameData.BuildingType.FOSSIL or nb == GameData.BuildingType.COAL_PLANT or nb == GameData.BuildingType.BIOCORRIDOR:
					d_carbon -= 2 if lvl >= 3 else 1
			for n in neighbors:
				if grid_building[n.x][n.y] == GameData.BuildingType.COP31:
					d_carbon -= 2 if lvl >= 3 else 1
					break
			if active_perks.has("carbon_sink"):
				d_carbon -= 1
			if active_perks.has("wetland_conservation"):
				for n in neighbors:
					var nb: int = grid_building[n.x][n.y]
					if nb == GameData.BuildingType.LAKE or nb == GameData.BuildingType.WATER_PLANT:
						d_carbon -= 2
						break

		GameData.BuildingType.RECYCLE:
			d_water += 2 + (3 if lvl >= 3 else (1 if lvl == 2 else 0))
			d_energy += (1 if lvl >= 3 else -1)
			d_carbon -= 1 + (2 if lvl >= 3 else (1 if lvl == 2 else 0))
			for n in neighbors:
				if grid_building[n.x][n.y] == GameData.BuildingType.HOUSING:
					d_water += 2 if lvl >= 3 else 1
			if active_perks.has("zero_waste"):
				d_water += 1
				d_carbon -= 1

		GameData.BuildingType.WATER_PLANT:
			d_water += 3 + (5 if lvl >= 3 else (2 if lvl == 2 else 0))
			d_energy -= (0 if lvl >= 3 else 1)
			if current_weather == GameData.WeatherType.SPRING_RAIN:
				d_water += 1
			if lvl >= 3:
				d_food += 1
			var has_green: bool = false
			var has_lake: bool = false
			for n in neighbors:
				var nb: int = grid_building[n.x][n.y]
				if nb == GameData.BuildingType.FARM or nb == GameData.BuildingType.FOREST:
					has_green = true
				if nb == GameData.BuildingType.LAKE:
					has_lake = true
			if has_green:
				d_carbon -= 2 if lvl >= 3 else 1
			if has_lake:
				d_water += 3 if lvl >= 3 else 2
			if active_perks.has("blue_economy"):
				d_water += 1

		GameData.BuildingType.FOSSIL:
			d_energy += 6 + (8 if lvl >= 3 else (3 if lvl == 2 else 0))
			d_carbon += 5 + (5 if lvl >= 3 else (2 if lvl == 2 else 0))

		GameData.BuildingType.COAL_PLANT:
			d_carbon += 1 if active_perks.has("coal_phaseout") else 2

		GameData.BuildingType.GEOTHERMAL:
			d_energy += 4 + (5 if lvl >= 3 else (2 if lvl == 2 else 0))
			d_food -= (0 if (lvl >= 3 or active_perks.has("geothermal_district")) else 1)
			if lvl >= 3:
				d_water += 1
			for n in neighbors:
				var nb: int = grid_building[n.x][n.y]
				if nb == GameData.BuildingType.LAKE or nb == GameData.BuildingType.WATER_PLANT:
					d_energy += 3 if lvl >= 3 else 2
					break
			if active_perks.has("geothermal_district"):
				d_energy += 2
			if active_perks.has("energy_storage"):
				d_energy += 1

		GameData.BuildingType.CCS:
			d_carbon -= 4 + (6 if lvl >= 3 else (2 if lvl == 2 else 0))
			d_energy -= (1 if (lvl >= 3 or active_perks.has("direct_air_subsidies")) else 2)
			for n in neighbors:
				var nb: int = grid_building[n.x][n.y]
				if nb == GameData.BuildingType.FOSSIL or nb == GameData.BuildingType.COAL_PLANT:
					d_carbon -= 3 if lvl >= 3 else 2
				elif nb == GameData.BuildingType.COP31:
					d_carbon -= 3 if lvl >= 3 else 2
			if active_perks.has("direct_air_subsidies"):
				d_carbon -= 2

		GameData.BuildingType.BIOCORRIDOR:
			d_food += 2 + (3 if lvl >= 3 else (1 if lvl == 2 else 0))
			d_water += 1 + (1 if lvl >= 3 else 0)
			d_carbon -= 1 + (2 if lvl >= 3 else (1 if lvl == 2 else 0))
			for n in neighbors:
				var nb: int = grid_building[n.x][n.y]
				if nb == GameData.BuildingType.FARM or nb == GameData.BuildingType.FOREST:
					d_food += 2 if lvl >= 3 else 1
					d_carbon -= 2 if lvl >= 3 else 1

		GameData.BuildingType.BATTERY:
			d_energy += 4 + (6 if lvl >= 3 else (2 if lvl == 2 else 0))
			d_water -= (0 if lvl >= 3 else 1)
			for n in neighbors:
				var nb: int = grid_building[n.x][n.y]
				if nb == GameData.BuildingType.SOLAR or nb == GameData.BuildingType.WIND:
					d_energy += 2 if lvl >= 3 else 1
			if active_perks.has("energy_storage"):
				d_energy += 2

		GameData.BuildingType.COP31:
			d_energy += 3 + (5 if lvl >= 3 else (2 if lvl == 2 else 0))
			d_food += 3 + (4 if lvl >= 3 else (1 if lvl == 2 else 0))
			d_water += 3 + (4 if lvl >= 3 else (1 if lvl == 2 else 0))
			d_carbon -= 4 + (6 if lvl >= 3 else (2 if lvl == 2 else 0))
			if active_perks.has("climate_diplomacy"):
				d_energy += 2
				d_food += 2
				d_water += 2
				d_carbon -= 2

	return {"e": d_energy, "f": d_food, "w": d_water, "c": d_carbon}

func get_tile_inspector_text(coord: Vector2i) -> String:
	if coord.x < 0 or coord.x >= GameData.GRID_SIZE or coord.y < 0 or coord.y >= GameData.GRID_SIZE:
		return ""
	var state: int = grid_state[coord.x][coord.y]
	var btype: int = grid_building[coord.x][coord.y]
	var blvl: int = grid_level[coord.x][coord.y]
	var state_str: String = "Açık Alan" if state == GameData.TileState.UNLOCKED else ("Sınır (Islah Edilebilir)" if state == GameData.TileState.BORDER else "Kilitli Bölge (Radar Taraması)")

	if btype == GameData.BuildingType.NONE:
		return "📍 Kare (%d, %d) — %s" % [coord.x, coord.y, state_str]
	elif btype == GameData.BuildingType.LAKE:
		return "🌊 Doğal Göl (%d, %d) — Komşu Tarım, Su Arıtma ve Jeotermal tesislere +2 bonus verir" % [coord.x, coord.y]

	var vis: Dictionary = GameData.get_building_visual(btype)
	var yld: Dictionary = calculate_building_yield(coord, btype)
	var syn_count: int = get_synergy_links(coord, btype).size()
	var lvl_str: String = "Lv.3★★ (Mega)" if blvl >= 3 else ("Lv.2★" if blvl == 2 else "Lv.1")
	var syn_str: String = (" | ✨ %d Aktif Sinerji" % syn_count) if syn_count > 0 else ""
	return "%s %s [%s] (%d,%d) — Net Tur Üretimi: ⚡%+d  🌱%+d  💧%+d  ☣%+d%s" % [
		vis["symbol"], vis["name"], lvl_str, coord.x, coord.y, yld["e"], yld["f"], yld["w"], yld["c"], syn_str
	]

func calculate_total_turn_production() -> Dictionary:
	var tot := {"e": 0, "f": 0, "w": 0, "c": 0}
	for x in range(GameData.GRID_SIZE):
		for y in range(GameData.GRID_SIZE):
			var btype: int = grid_building[x][y]
			if btype != GameData.BuildingType.NONE and btype != GameData.BuildingType.LAKE:
				var yld: Dictionary = calculate_building_yield(Vector2i(x, y), btype)
				tot["e"] += yld["e"]
				tot["f"] += yld["f"]
				tot["w"] += yld["w"]
				tot["c"] += yld["c"]

	# Perk: COP31 Küresel İklim Liderliği (Karbon <= 10 iken ekstra hibe desteği)
	if carbon <= 10 and active_perks.has("climate_diplomacy"):
		tot["e"] += 2
		tot["f"] += 2
		tot["w"] += 2

	# Hava Durumu: Temiz Rüzgar temizliği
	if current_weather == GameData.WeatherType.FRESH_BREEZE:
		tot["c"] -= 1

	# Perk: Kentsel Doğa Onarımı Teşviki (En az 4 doğa alanı varken)
	if active_perks.has("rewilding_incentive"):
		var nat_count: int = 0
		for x in range(GameData.GRID_SIZE):
			for y in range(GameData.GRID_SIZE):
				var b: int = grid_building[x][y]
				if b == GameData.BuildingType.FOREST or b == GameData.BuildingType.BIOCORRIDOR or b == GameData.BuildingType.LAKE:
					nat_count += 1
		if nat_count >= 4:
			tot["w"] += 2
			tot["f"] += 2

	# Eko-Bölge (District) Bölgesel Üretim Bonusları
	var dists := detect_active_districts()
	for d in dists:
		var bon: Dictionary = d.get("bonus", {})
		tot["e"] += bon.get("e", 0)
		tot["f"] += bon.get("f", 0)
		tot["w"] += bon.get("w", 0)
		tot["c"] += bon.get("c", 0)

	return tot

func detect_active_districts() -> Array[Dictionary]:
	var districts: Array[Dictionary] = []
	var visited: Dictionary = {}

	# 1. Enerji Koridoru (Energy District): En az 3 komşu Temiz Enerji tesisi
	for x in range(GameData.GRID_SIZE):
		for y in range(GameData.GRID_SIZE):
			var pos := Vector2i(x, y)
			if visited.has("energy_%d_%d" % [x, y]):
				continue
			var b: int = grid_building[x][y]
			if b in [GameData.BuildingType.SOLAR, GameData.BuildingType.WIND, GameData.BuildingType.GEOTHERMAL, GameData.BuildingType.BATTERY]:
				var cluster: Array[Vector2i] = []
				var queue: Array[Vector2i] = [pos]
				visited["energy_%d_%d" % [x, y]] = true
				while not queue.is_empty():
					var curr: Vector2i = queue.pop_front()
					cluster.append(curr)
					for nb in get_orthogonal_neighbors(curr):
						var key := "energy_%d_%d" % [nb.x, nb.y]
						if not visited.has(key):
							var n_b: int = grid_building[nb.x][nb.y]
							if n_b in [GameData.BuildingType.SOLAR, GameData.BuildingType.WIND, GameData.BuildingType.GEOTHERMAL, GameData.BuildingType.BATTERY]:
								visited[key] = true
								queue.append(nb)
				if cluster.size() >= 3:
					districts.append({
						"id": "energy_district",
						"title": "⚡ Süper Şebeke Enerji Koridoru",
						"color": Color(0.35, 0.95, 1.0),
						"coords": cluster,
						"bonus": {"e": 2, "f": 0, "w": 0, "c": 0},
						"bonus_text": "⚡+2 Şebeke Bonusu"
					})

	# 2. Biyo-Çeşitlilik Havzası (Nature Basin): En az 3 komşu Doğa tesisi
	visited.clear()
	for x in range(GameData.GRID_SIZE):
		for y in range(GameData.GRID_SIZE):
			var pos := Vector2i(x, y)
			if visited.has("nature_%d_%d" % [x, y]):
				continue
			var b: int = grid_building[x][y]
			if b in [GameData.BuildingType.FOREST, GameData.BuildingType.BIOCORRIDOR, GameData.BuildingType.LAKE]:
				var cluster: Array[Vector2i] = []
				var queue: Array[Vector2i] = [pos]
				visited["nature_%d_%d" % [x, y]] = true
				while not queue.is_empty():
					var curr: Vector2i = queue.pop_front()
					cluster.append(curr)
					for nb in get_orthogonal_neighbors(curr):
						var key := "nature_%d_%d" % [nb.x, nb.y]
						if not visited.has(key):
							var n_b: int = grid_building[nb.x][nb.y]
							if n_b in [GameData.BuildingType.FOREST, GameData.BuildingType.BIOCORRIDOR, GameData.BuildingType.LAKE]:
								visited[key] = true
								queue.append(nb)
				if cluster.size() >= 3:
					districts.append({
						"id": "nature_basin",
						"title": "🌿 Biyo-Çeşitlilik Koruma Havzası",
						"color": Color(0.38, 1.0, 0.65),
						"coords": cluster,
						"bonus": {"e": 0, "f": 2, "w": 0, "c": -1},
						"bonus_text": "🌱+2, ☣-1 Karbon Yutağı"
					})

	# 3. Döngüsel Eko-Köy (Circular Eco-Village): Konut + Tarım + Su Arıtma/Geri Dönüşüm
	visited.clear()
	for x in range(GameData.GRID_SIZE):
		for y in range(GameData.GRID_SIZE):
			var pos := Vector2i(x, y)
			if visited.has("village_%d_%d" % [x, y]):
				continue
			var b: int = grid_building[x][y]
			if b in [GameData.BuildingType.HOUSING, GameData.BuildingType.FARM, GameData.BuildingType.WATER_PLANT, GameData.BuildingType.RECYCLE]:
				var cluster: Array[Vector2i] = []
				var queue: Array[Vector2i] = [pos]
				var has_house: bool = false
				var has_farm: bool = false
				var has_water_or_rec: bool = false
				visited["village_%d_%d" % [x, y]] = true
				while not queue.is_empty():
					var curr: Vector2i = queue.pop_front()
					cluster.append(curr)
					var cur_b: int = grid_building[curr.x][curr.y]
					if cur_b == GameData.BuildingType.HOUSING: has_house = true
					if cur_b == GameData.BuildingType.FARM: has_farm = true
					if cur_b == GameData.BuildingType.WATER_PLANT or cur_b == GameData.BuildingType.RECYCLE: has_water_or_rec = true
					for nb in get_orthogonal_neighbors(curr):
						var key := "village_%d_%d" % [nb.x, nb.y]
						if not visited.has(key):
							var n_b: int = grid_building[nb.x][nb.y]
							if n_b in [GameData.BuildingType.HOUSING, GameData.BuildingType.FARM, GameData.BuildingType.WATER_PLANT, GameData.BuildingType.RECYCLE]:
								visited[key] = true
								queue.append(nb)
				if cluster.size() >= 3 and has_house and has_farm and has_water_or_rec:
					districts.append({
						"id": "eco_village",
						"title": "🏡 Döngüsel Kentsel Eko-Köy",
						"color": Color(1.0, 0.88, 0.35),
						"coords": cluster,
						"bonus": {"e": 1, "f": 0, "w": 2, "c": 0},
						"bonus_text": "💧+2, ⚡+1 Döngüsel Verim"
					})

	return districts

func preview_card_delta(coord: Vector2i, card_id: int) -> Dictionary:
	if card_id == GameData.CardId.UPGRADE_KIT:
		var btype: int = grid_building[coord.x][coord.y]
		var cur_lvl: int = grid_level[coord.x][coord.y]
		var yld: Dictionary = calculate_building_yield(coord, btype, mini(cur_lvl + 1, 3))
		return {"e": yld["e"] - 2, "f": yld["f"], "w": yld["w"] - 1, "c": yld["c"]}
	elif card_id == GameData.CardId.ECO_SURVEY:
		return {"e": -3, "f": 0, "w": -1, "c": 0}
	elif card_id == GameData.CardId.EXPAND:
		return {"e": -2, "f": 0, "w": -2, "c": -2}
	elif card_id == GameData.CardId.DEMOLISH:
		var e_cost: int = 0 if (grid_building[coord.x][coord.y] == GameData.BuildingType.COAL_PLANT and active_perks.has("coal_phaseout")) else -1
		var c_bonus: int = -3 if grid_building[coord.x][coord.y] == GameData.BuildingType.COAL_PLANT else 0
		return {"e": e_cost, "f": 0, "w": 2, "c": c_bonus}
	else:
		var btype: int = GameData.CARDS[card_id]["building"]
		var cur_lvl: int = grid_level[coord.x][coord.y]
		var target_lvl: int = mini(cur_lvl + 1, 3) if grid_building[coord.x][coord.y] == btype else 1
		return calculate_building_yield(coord, btype, target_lvl)

func apply_card_effects(coord: Vector2i, card_id: int) -> Dictionary:
	var delta_dict: Dictionary
	var is_upgrade: bool = false
	var shake_val: float = 3.0
	var flash_col: Color = Color(1, 1, 1, 0)
	var flash_a: float = 0.0
	stats_cards_played += 1

	if card_id == GameData.CardId.UPGRADE_KIT:
		var cur_lvl: int = grid_level[coord.x][coord.y]
		var next_lvl: int = mini(cur_lvl + 1, 3)
		grid_level[coord.x][coord.y] = next_lvl
		is_upgrade = true
		stats_upgrades_done += 1
		shake_val = 6.0
		flash_col = Color(1.0, 0.88, 0.32)
		flash_a = 0.22
		tile_anim[coord] = 0.0
		var btype: int = grid_building[coord.x][coord.y]
		delta_dict = calculate_building_yield(coord, btype)
		delta_dict["e"] -= 2
		delta_dict["w"] -= 1
	elif card_id == GameData.CardId.ECO_SURVEY:
		delta_dict = {"e": -3, "f": 0, "w": -1, "c": 0}
		grid_state[coord.x][coord.y] = GameData.TileState.UNLOCKED
		tile_anim[coord] = 0.0
		recalculate_borders()
		for nb in get_orthogonal_neighbors(coord):
			if grid_state[nb.x][nb.y] == GameData.TileState.BORDER:
				tile_anim[nb] = 0.0
		shake_val = 4.2
		flash_col = Color(0.28, 0.85, 1.0)
		flash_a = 0.22
	elif card_id == GameData.CardId.EXPAND:
		delta_dict = {"e": -2, "f": 0, "w": -2, "c": -2}
		for dx in range(-1, 2):
			for dy in range(-1, 2):
				var nx: int = coord.x + dx
				var ny: int = coord.y + dy
				if nx >= 0 and nx < GameData.GRID_SIZE and ny >= 0 and ny < GameData.GRID_SIZE:
					grid_state[nx][ny] = GameData.TileState.UNLOCKED
					tile_anim[Vector2i(nx, ny)] = 0.0
		recalculate_borders()
		shake_val = 4.5
	elif card_id == GameData.CardId.DEMOLISH:
		delta_dict = preview_card_delta(coord, card_id)
		if grid_building[coord.x][coord.y] == GameData.BuildingType.COAL_PLANT:
			stats_coal_demolished += 1
		grid_building[coord.x][coord.y] = GameData.BuildingType.NONE
		grid_level[coord.x][coord.y] = 1
		tile_anim[coord] = 0.0
		shake_val = 6.5
		flash_col = Color(1.0, 0.7, 0.3)
		flash_a = 0.18
	else:
		var btype: int = GameData.CARDS[card_id]["building"]
		if grid_building[coord.x][coord.y] == btype:
			var cur_lvl: int = grid_level[coord.x][coord.y]
			var next_lvl: int = mini(cur_lvl + 1, 3)
			grid_level[coord.x][coord.y] = next_lvl
			is_upgrade = true
			stats_upgrades_done += 1
			shake_val = 5.0 + (1.5 if next_lvl == 3 else 0.0)
			flash_col = Color(0.35, 1.0, 0.9) if next_lvl == 3 else Color(0.4, 1.0, 0.7)
			flash_a = 0.20 if next_lvl == 3 else 0.16
		else:
			grid_building[coord.x][coord.y] = btype
			grid_level[coord.x][coord.y] = 1
			shake_val = 3.0
			if btype == GameData.BuildingType.FOREST or btype == GameData.BuildingType.BIOCORRIDOR:
				stats_forests_planted += 1
			elif btype == GameData.BuildingType.SOLAR or btype == GameData.BuildingType.WIND or btype == GameData.BuildingType.GEOTHERMAL:
				stats_clean_energy_built += 1
		tile_anim[coord] = 0.0
		delta_dict = calculate_building_yield(coord, btype)

	energy += delta_dict["e"]
	food += delta_dict["f"]
	water += delta_dict["w"]
	carbon = clampi(carbon + delta_dict["c"], 0, GameData.MAX_CARBON)

	var title: String = GameData.CARDS[card_id]["title"]
	var target_lvl: int = grid_level[coord.x][coord.y]
	var action_str: String = "kuruldu!"
	if is_upgrade:
		action_str = "Seviye 3'e (★★ Mega) yükseltildi!" if target_lvl == 3 else "Seviye 2'ye (★) yükseltildi!"
	elif card_id == GameData.CardId.EXPAND:
		action_str = "ile bölge ıslah edildi!"
	elif card_id == GameData.CardId.ECO_SURVEY:
		action_str = "ile uzaktan tarandı ve keşif üssü açıldı!"
	elif card_id == GameData.CardId.DEMOLISH:
		action_str = "yıkıldı ve geri dönüştürüldü!"
	log_event("📅 Gün %d: %s %s (⚡%+d, 🌱%+d, 💧%+d, ☣%+d)" % [
		day, title, action_str, delta_dict["e"], delta_dict["f"], delta_dict["w"], delta_dict["c"]
	])
	var summary: String = "✅ %s %s Anlık ve Tur Üretimi: ⚡%+d, 🌱%+d, 💧%+d, ☣%+d" % [
		title, action_str, delta_dict["e"], delta_dict["f"], delta_dict["w"], delta_dict["c"]
	]
	return {
		"summary": summary,
		"delta": delta_dict,
		"shake": shake_val,
		"flash_color": flash_col,
		"flash_alpha": flash_a,
		"is_upgrade": is_upgrade,
		"level": target_lvl
	}

func trigger_random_crisis() -> String:
	var crisis_roll: int = upcoming_crisis_id if upcoming_crisis_id >= 0 else (randi() % 5)
	active_crisis_type = crisis_roll
	var crisis_result: String = ""
	if crisis_roll == 0:
		var forest_count: int = 0
		for x in range(GameData.GRID_SIZE):
			for y in range(GameData.GRID_SIZE):
				if grid_building[x][y] == GameData.BuildingType.FOREST:
					forest_count += 1
		if forest_count < 2:
			water -= 4
			crisis_result = "Sıcak Hava Dalgası! Haritada en az 2 Kent Ormanı olmadığı için 💧-4 Su kaybedildi. (📚 Kent ormanları buharlaşma kaybını önler.)"
		else:
			crisis_result = "Sıcak Hava Dalgası! Kent Ormanları şehri korudu, su kaybı yaşanmadı."

	elif crisis_roll == 1:
		if carbon >= 50:
			var occupied: Array[Vector2i] = []
			for x in range(GameData.GRID_SIZE):
				for y in range(GameData.GRID_SIZE):
					var b: int = grid_building[x][y]
					if b != GameData.BuildingType.NONE and b != GameData.BuildingType.LAKE and b != GameData.BuildingType.COAL_PLANT:
						occupied.append(Vector2i(x, y))
			if not occupied.is_empty():
				var victim: Vector2i = occupied[randi() % occupied.size()]
				grid_building[victim.x][victim.y] = GameData.BuildingType.NONE
				crisis_result = "Asit Yağmuru! Karbon >= 50 olduğu için (%d, %d) konumundaki bina yıkıldı! (📚 Yüksek emisyon yağış pH değerini düşürür.)" % [victim.x, victim.y]
			else:
				crisis_result = "Asit Yağmuru! Yıkılacak bina bulunamadı."
		else:
			crisis_result = "Asit Yağmuru! Karbon < 50 tutulduğu için şehir hasar almadı."

	elif crisis_roll == 2:
		if carbon >= 60:
			var outer_unlocked: Array[Vector2i] = []
			for x in range(GameData.GRID_SIZE):
				for y in range(GameData.GRID_SIZE):
					if grid_state[x][y] == GameData.TileState.UNLOCKED:
						for n in get_orthogonal_neighbors(Vector2i(x, y)):
							if grid_state[n.x][n.y] != GameData.TileState.UNLOCKED:
								outer_unlocked.append(Vector2i(x, y))
								break
			outer_unlocked.shuffle()
			var locked_count: int = mini(2, outer_unlocked.size())
			for i in range(locked_count):
				var pos: Vector2i = outer_unlocked[i]
				grid_state[pos.x][pos.y] = GameData.TileState.LOCKED
				if grid_building[pos.x][pos.y] != GameData.BuildingType.LAKE:
					grid_building[pos.x][pos.y] = GameData.BuildingType.NONE
			recalculate_borders()
			crisis_result = "Yükselen Deniz Seviyesi! Karbon >= 60 olduğu için %d dış sınır karesi sular altında kaldı! (📚 Buzul erimesi kıyı şehirlerini tehdit eder.)" % locked_count
		else:
			crisis_result = "Yükselen Deniz Seviyesi kontrol altında (Karbon < 60 olduğu için kıyı kaybı yok)."

	elif crisis_roll == 3:
		if active_perks.has("energy_storage"):
			crisis_result = "Şebeke Çöküşü! Akıllı Mega-Bataryalar devreye girdi ve kesintiyi tamamen engelledi; şebeke stabil kaldı."
		else:
			var clean_count: int = 0
			for x in range(GameData.GRID_SIZE):
				for y in range(GameData.GRID_SIZE):
					var b: int = grid_building[x][y]
					if b == GameData.BuildingType.SOLAR or b == GameData.BuildingType.WIND or b == GameData.BuildingType.GEOTHERMAL:
						clean_count += 1
			if clean_count < 2:
				energy -= 3
				crisis_result = "Şebeke Çöküşü! Yeterli yenilenebilir enerji tesisi (<2) olmadığı için ⚡-3 Enerji kaybedildi."
			else:
				crisis_result = "Aşırı Yüklenme! Dağıtık Güneş ve Rüzgar şebekesi kesintiyi önledi."

	else:
		var water_count: int = 0
		for x in range(GameData.GRID_SIZE):
			for y in range(GameData.GRID_SIZE):
				if grid_building[x][y] == GameData.BuildingType.WATER_PLANT:
					water_count += 1
		if water_count < 1:
			food -= 3
			crisis_result = "Kuraklık! Şehirde Su Arıtma Tesisi olmadığı için tarımsal verim düştü (🌱-3 Gıda)."
		else:
			crisis_result = "Kuraklık Dalgası! Su Arıtma Tesisleri sayesinde tarım korundu."

	log_event("🚨 Gün %d İklim Krizi: %s" % [day, crisis_result])
	return crisis_result

func count_building(btype: int) -> int:
	var count: int = 0
	for x in range(GameData.GRID_SIZE):
		for y in range(GameData.GRID_SIZE):
			if grid_building[x][y] == btype:
				count += 1
	return count

func calculate_eco_score(won: bool) -> int:
	return (stats_forests_planted * 12) + (stats_coal_demolished * 25) + (stats_clean_energy_built * 10) + (stats_upgrades_done * 15) - carbon + (35 if won else 0)

func build_eco_report_card(won: bool) -> String:
	var score: int = calculate_eco_score(won)
	var grade: String = "C"
	if score >= 120:
		grade = "A+ (Kusursuz Eko-Metropol)"
	elif score >= 85:
		grade = "A (Sürdürülebilir Lider)"
	elif score >= 55:
		grade = "B (Yeşil Dönüşüm Adayı)"
	return "\n📊 COP31 EKOLOJİ KARNESİ (Skor: %d):\n• Dikilen Kent Ormanı: %d   |   • Yıkılan Kömür Santrali: %d\n• Kurulan Temiz Enerji: %d   |   • Seviye 2 Yükseltme: %d\n• Oynanan Kart: %d   |   🏆 Ekolojik Derece: %s" % [
		score, stats_forests_planted, stats_coal_demolished, stats_clean_energy_built, stats_upgrades_done, stats_cards_played, grade
	]

func calculate_city_population() -> int:
	var pop: int = 1200
	for x in range(GameData.GRID_SIZE):
		for y in range(GameData.GRID_SIZE):
			if grid_building[x][y] == GameData.BuildingType.HOUSING:
				var lvl: int = grid_level[x][y]
				pop += 3500 if lvl == 2 else 1600
				for n in get_orthogonal_neighbors(Vector2i(x, y)):
					if grid_building[n.x][n.y] == GameData.BuildingType.FOREST or grid_building[n.x][n.y] == GameData.BuildingType.BIOCORRIDOR:
						pop += 800
	return pop

func get_climate_resilience_tier() -> String:
	var pop: int = calculate_city_population()
	if pop >= 15000:
		return "🌟 Net-Sıfır Metropol"
	elif pop >= 8000:
		return "🏙 Sürdürülebilir Şehir"
	elif pop >= 4000:
		return "🏡 Dirençli Kasaba"
	else:
		return "🌱 Ekolojik Yerleşim"

func get_resilience_tier_index() -> int:
	var pop: int = calculate_city_population()
	if pop >= 15000:
		return 3
	elif pop >= 8000:
		return 2
	elif pop >= 4000:
		return 1
	else:
		return 0

func calculate_resource_flow_breakdown() -> Dictionary:
	var flow := {
		"e_prod": 0, "e_cons": 0,
		"f_prod": 0, "f_cons": 0,
		"w_prod": 0, "w_cons": 0,
		"c_emit": 0, "c_sink": 0,
		"building_count": 0
	}
	for x in range(GameData.GRID_SIZE):
		for y in range(GameData.GRID_SIZE):
			var b: int = grid_building[x][y]
			if b == GameData.BuildingType.NONE:
				continue
			flow["building_count"] += 1
			var yld: Dictionary = calculate_building_yield(Vector2i(x, y), b)

			if yld["e"] > 0:
				flow["e_prod"] += yld["e"]
			elif yld["e"] < 0:
				flow["e_cons"] += abs(yld["e"])

			if yld["f"] > 0:
				flow["f_prod"] += yld["f"]
			elif yld["f"] < 0:
				flow["f_cons"] += abs(yld["f"])

			if yld["w"] > 0:
				flow["w_prod"] += yld["w"]
			elif yld["w"] < 0:
				flow["w_cons"] += abs(yld["w"])

			if yld["c"] > 0:
				flow["c_emit"] += yld["c"]
			elif yld["c"] < 0:
				flow["c_sink"] += abs(yld["c"])
	flow["lakes_preserved"] = get_building_count(GameData.BuildingType.LAKE)
	return flow

func get_building_count(target_type: GameData.BuildingType) -> int:
	var count := 0
	for x in range(GameData.GRID_SIZE):
		for y in range(GameData.GRID_SIZE):
			if grid_building[x][y] == target_type:
				count += 1
	return count

func calculate_biodiversity() -> Dictionary:
	var forests: int = 0
	var lakes: int = 0
	var biocorridors: int = 0
	var farms: int = 0
	var total_nature_tiles: int = 0
	var connected_links: int = 0

	for x in range(GameData.GRID_SIZE):
		for y in range(GameData.GRID_SIZE):
			var b: int = grid_building[x][y]
			if b == GameData.BuildingType.FOREST:
				forests += 1
				total_nature_tiles += 1
			elif b == GameData.BuildingType.LAKE:
				lakes += 1
				total_nature_tiles += 1
			elif b == GameData.BuildingType.BIOCORRIDOR:
				biocorridors += 1
				total_nature_tiles += 1
			elif b == GameData.BuildingType.FARM:
				farms += 1

			if b in [GameData.BuildingType.FOREST, GameData.BuildingType.LAKE, GameData.BuildingType.BIOCORRIDOR]:
				var nbs: Array[Vector2i] = get_orthogonal_neighbors(Vector2i(x, y))
				for n in nbs:
					var nb_b: int = grid_building[n.x][n.y]
					if nb_b in [GameData.BuildingType.FOREST, GameData.BuildingType.LAKE, GameData.BuildingType.BIOCORRIDOR]:
						connected_links += 1

	var unique_corridor_links: int = connected_links / 2

	var type_variety: int = 0
	if forests > 0: type_variety += 15
	if lakes > 0: type_variety += 15
	if biocorridors > 0: type_variety += 15
	if farms > 0: type_variety += 15

	var quantity_pts: int = mini(20, total_nature_tiles * 3)
	var link_pts: int = mini(20, unique_corridor_links * 4)
	var score: int = clampi(type_variety + quantity_pts + link_pts, 0, 100)

	var rating: String
	var color: Color
	if score >= 80:
		rating = "Vahşi Yaşam Sığınağı (Mükemmel - COP31)"
		color = Color(0.35, 0.95, 0.60)
	elif score >= 55:
		rating = "Zengin Biyo-Çeşitlilik (İyi Eko-Ağ)"
		color = Color(0.45, 0.88, 0.72)
	elif score >= 30:
		rating = "Gelişmekte Olan Habitat"
		color = Color(1.0, 0.85, 0.35)
	else:
		rating = "Monokültür / Kritik Düşük"
		color = Color(0.95, 0.45, 0.35)

	return {
		"score": score,
		"rating": rating,
		"color": color,
		"forests": forests,
		"lakes": lakes,
		"biocorridors": biocorridors,
		"farms": farms,
		"corridor_links": unique_corridor_links
	}

