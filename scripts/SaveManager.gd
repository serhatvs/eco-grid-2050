extends RefCounted

const GameData = preload("res://scripts/GameData.gd")

const GridSimulation = preload("res://scripts/GridSimulation.gd")

var unlocked_cards: Array[int] = []
var unlocked_achievements: Array[String] = []
var active_run: Dictionary = {}
var completed_scenarios: Array[int] = []
var high_score: int = 0
var games_won: int = 0
var sfx_volume: float = 0.85
var music_volume: float = 0.45
var screen_shake_enabled: bool = true
var current_slot: int = 1
const SLOT_PREF_PATH: String = "user://eco_grid_active_slot.json"

func get_slot_save_path(slot: int) -> String:
	if slot <= 1:
		return GameData.SAVE_PATH
	return "user://eco_grid_save_slot_%d.json" % slot

func get_current_save_path() -> String:
	return get_slot_save_path(current_slot)

func load_slot_preference() -> void:
	if FileAccess.file_exists(SLOT_PREF_PATH):
		var f := FileAccess.open(SLOT_PREF_PATH, FileAccess.READ)
		if f != null:
			var txt: String = f.get_as_text()
			f.close()
			var parsed: Variant = JSON.parse_string(txt)
			if typeof(parsed) == TYPE_DICTIONARY and parsed.has("slot"):
				current_slot = clampi(int(parsed["slot"]), 1, 3)

func save_slot_preference() -> void:
	var f := FileAccess.open(SLOT_PREF_PATH, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify({"slot": current_slot}))
		f.close()

func select_slot(slot: int) -> void:
	current_slot = clampi(slot, 1, 3)
	save_slot_preference()
	load_save_data()

func get_slot_summary(slot: int) -> Dictionary:
	var p: String = get_slot_save_path(slot)
	if not FileAccess.file_exists(p):
		return {
			"exists": false,
			"has_active_run": false,
			"day": 0,
			"score": 0,
			"games_won": 0,
			"unlocked_cards_count": 6
		}
	var f := FileAccess.open(p, FileAccess.READ)
	if f == null:
		return {"exists": false, "has_active_run": false, "day": 0, "score": 0, "games_won": 0, "unlocked_cards_count": 6}
	var txt: String = f.get_as_text()
	f.close()
	var parsed: Variant = JSON.parse_string(txt)
	if typeof(parsed) != TYPE_DICTIONARY:
		return {"exists": false, "has_active_run": false, "day": 0, "score": 0, "games_won": 0, "unlocked_cards_count": 6}
	var d: Dictionary = parsed
	var ar: Dictionary = d.get("active_run", {})
	var has_ar: bool = not ar.is_empty() and int(ar.get("day", 0)) > 0
	var unl: int = d.get("unlocked_cards", []).size()
	return {
		"exists": true,
		"has_active_run": has_ar,
		"day": int(ar.get("day", 0)) if has_ar else 0,
		"scenario": int(ar.get("scenario", 0)) if has_ar else 0,
		"score": int(d.get("high_score", 0)),
		"games_won": int(d.get("games_won", 0)),
		"unlocked_cards_count": unl
	}

func load_save_data() -> void:
	load_slot_preference()
	unlocked_cards.clear()
	unlocked_achievements.clear()
	active_run.clear()
	var cur_path: String = get_current_save_path()
	if not FileAccess.file_exists(cur_path):
		save_progress()
		return
	var file := FileAccess.open(cur_path, FileAccess.READ)
	if file == null:
		return
	var text: String = file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) == TYPE_DICTIONARY:
		var data: Dictionary = parsed
		if data.has("unlocked_cards") and typeof(data["unlocked_cards"]) == TYPE_ARRAY:
			for c in data["unlocked_cards"]:
				var cid: int = int(c)
				if GameData.CARDS.has(cid) and not unlocked_cards.has(cid):
					unlocked_cards.append(cid)
		if data.has("unlocked_achievements") and typeof(data["unlocked_achievements"]) == TYPE_ARRAY:
			for a in data["unlocked_achievements"]:
				var aid: String = str(a)
				if not unlocked_achievements.has(aid):
					unlocked_achievements.append(aid)
		if data.has("active_run") and typeof(data["active_run"]) == TYPE_DICTIONARY:
			active_run = data["active_run"]
		if data.has("completed_scenarios") and typeof(data["completed_scenarios"]) == TYPE_ARRAY:
			for sc in data["completed_scenarios"]:
				var sc_id: int = int(sc)
				if not completed_scenarios.has(sc_id):
					completed_scenarios.append(sc_id)
		if data.has("high_score"):
			high_score = int(data["high_score"])
		if data.has("games_won"):
			games_won = int(data["games_won"])
		if data.has("sfx_volume"):
			sfx_volume = clampf(float(data["sfx_volume"]), 0.0, 1.0)
		if data.has("music_volume"):
			music_volume = clampf(float(data["music_volume"]), 0.0, 1.0)
		if data.has("screen_shake_enabled"):
			screen_shake_enabled = bool(data["screen_shake_enabled"])

	if unlocked_cards.is_empty():
		for cid in [GameData.CardId.SOLAR, GameData.CardId.WIND, GameData.CardId.HOUSING, GameData.CardId.FARM, GameData.CardId.FOREST, GameData.CardId.FOSSIL]:
			unlocked_cards.append(cid)

func reset_all_data() -> void:
	unlocked_cards.clear()
	for cid in [GameData.CardId.SOLAR, GameData.CardId.WIND, GameData.CardId.HOUSING, GameData.CardId.FARM, GameData.CardId.FOREST, GameData.CardId.FOSSIL]:
		unlocked_cards.append(cid)
	unlocked_achievements.clear()
	active_run.clear()
	completed_scenarios.clear()
	high_score = 0
	games_won = 0
	save_progress()

func save_progress() -> void:
	var file := FileAccess.open(get_current_save_path(), FileAccess.WRITE)
	if file == null:
		return
	var save_dict: Dictionary = {
		"unlocked_cards": unlocked_cards,
		"unlocked_achievements": unlocked_achievements,
		"active_run": active_run,
		"completed_scenarios": completed_scenarios,
		"high_score": high_score,
		"games_won": games_won,
		"sfx_volume": sfx_volume,
		"music_volume": music_volume,
		"screen_shake_enabled": screen_shake_enabled
	}
	file.store_string(JSON.stringify(save_dict, "\t"))
	file.close()

func has_active_run() -> bool:
	return not active_run.is_empty() and int(active_run.get("day", 0)) > 0

func clear_active_run() -> void:
	active_run.clear()
	save_progress()

func save_active_run(sim: GridSimulation) -> void:
	var g_state: Array = []
	var g_bldg: Array = []
	var g_lvl: Array = []
	for x in range(GameData.GRID_SIZE):
		var s_row: Array = []
		var b_row: Array = []
		var l_row: Array = []
		for y in range(GameData.GRID_SIZE):
			s_row.append(sim.grid_state[x][y])
			b_row.append(sim.grid_building[x][y])
			l_row.append(sim.grid_level[x][y])
		g_state.append(s_row)
		g_bldg.append(b_row)
		g_lvl.append(l_row)

	active_run = {
		"scenario": sim.current_scenario,
		"day": sim.day,
		"active_crisis_type": sim.active_crisis_type,
		"energy": sim.energy,
		"food": sim.food,
		"water": sim.water,
		"carbon": sim.carbon,
		"zero_streak": sim.zero_carbon_streak,
		"max_resilience_tier": sim.max_resilience_tier_reached,
		"carbon_history": sim.carbon_history.duplicate(),
		"energy_history": sim.energy_history.duplicate(),
		"food_history": sim.food_history.duplicate(),
		"water_history": sim.water_history.duplicate(),
		"hand": sim.hand.duplicate(),
		"deck": sim.deck.duplicate(),
		"discard_pile": sim.discard_pile.duplicate(),
		"perks": sim.active_perks.duplicate(),
		"stats_cards_played": sim.stats_cards_played,
		"stats_forests_planted": sim.stats_forests_planted,
		"stats_clean_energy_built": sim.stats_clean_energy_built,
		"stats_coal_demolished": sim.stats_coal_demolished,
		"stats_upgrades_done": sim.stats_upgrades_done,
		"quests_coal": sim.quests_completed["coal"],
		"quests_forest": sim.quests_completed["forest"],
		"quests_upgrade": sim.quests_completed["upgrade"],
		"event_log": sim.event_log.duplicate(),
		"grid_state": g_state,
		"grid_building": g_bldg,
		"grid_level": g_lvl
	}
	save_progress()

func load_active_run(sim: GridSimulation) -> bool:
	if not has_active_run():
		return false
	sim.current_scenario = int(active_run.get("scenario", 0))
	sim.day = int(active_run.get("day", 1))
	sim.active_crisis_type = int(active_run.get("active_crisis_type", -1))
	sim.energy = int(active_run.get("energy", 10))
	sim.food = int(active_run.get("food", 10))
	sim.water = int(active_run.get("water", 10))
	sim.carbon = int(active_run.get("carbon", 20))
	sim.zero_carbon_streak = int(active_run.get("zero_streak", 0))
	sim.max_resilience_tier_reached = int(active_run.get("max_resilience_tier", 0))
	sim.carbon_history.clear()
	for ch in active_run.get("carbon_history", []):
		sim.carbon_history.append(int(ch))
	sim.energy_history.clear()
	for eh in active_run.get("energy_history", []):
		sim.energy_history.append(int(eh))
	sim.food_history.clear()
	for fh in active_run.get("food_history", []):
		sim.food_history.append(int(fh))
	sim.water_history.clear()
	for wh in active_run.get("water_history", []):
		sim.water_history.append(int(wh))

	sim.hand.clear()
	for c in active_run.get("hand", []):
		sim.hand.append(int(c))

	sim.deck.clear()
	for c in active_run.get("deck", []):
		sim.deck.append(int(c))

	sim.discard_pile.clear()
	for c in active_run.get("discard_pile", []):
		sim.discard_pile.append(int(c))

	sim.active_perks.clear()
	for p in active_run.get("perks", []):
		sim.active_perks.append(str(p))

	sim.stats_cards_played = int(active_run.get("stats_cards_played", 0))
	sim.stats_forests_planted = int(active_run.get("stats_forests_planted", 0))
	sim.stats_clean_energy_built = int(active_run.get("stats_clean_energy_built", 0))
	sim.stats_coal_demolished = int(active_run.get("stats_coal_demolished", 0))
	sim.stats_upgrades_done = int(active_run.get("stats_upgrades_done", 0))

	sim.quests_completed["coal"] = bool(active_run.get("quests_coal", false))
	sim.quests_completed["forest"] = bool(active_run.get("quests_forest", false))
	sim.quests_completed["upgrade"] = bool(active_run.get("quests_upgrade", false))

	sim.event_log.clear()
	for log_entry in active_run.get("event_log", []):
		sim.event_log.append(str(log_entry))

	var g_state: Array = active_run.get("grid_state", [])
	var g_bldg: Array = active_run.get("grid_building", [])
	var g_lvl: Array = active_run.get("grid_level", [])
	if g_state.size() == GameData.GRID_SIZE:
		sim.grid_state.clear()
		sim.grid_building.clear()
		sim.grid_level.clear()
		for x in range(GameData.GRID_SIZE):
			var s_col: Array = []
			var b_col: Array = []
			var l_col: Array = []
			for y in range(GameData.GRID_SIZE):
				s_col.append(int(g_state[x][y]))
				b_col.append(int(g_bldg[x][y]))
				l_col.append(int(g_lvl[x][y]))
			sim.grid_state.append(s_col)
			sim.grid_building.append(b_col)
			sim.grid_level.append(l_col)
	return true

func unlock_card(card_id: int) -> bool:
	if unlocked_cards.has(card_id):
		return false
	unlocked_cards.append(card_id)
	save_progress()
	return true

func unlock_achievement(ach_id: String) -> bool:
	if unlocked_achievements.has(ach_id):
		return false
	unlocked_achievements.append(ach_id)
	save_progress()
	return true

func mark_scenario_completed(scenario: int) -> void:
	if not completed_scenarios.has(scenario):
		completed_scenarios.append(scenario)
		save_progress()

func record_game_result(score: int, won: bool, scenario: int) -> void:
	if score > high_score:
		high_score = score
	if won:
		games_won += 1
		if not completed_scenarios.has(scenario):
			completed_scenarios.append(scenario)
		if not unlocked_achievements.has("first_win"):
			unlocked_achievements.append("first_win")
		if scenario == 1 and not unlocked_achievements.has("hard_mode_victor"):
			unlocked_achievements.append("hard_mode_victor")
		if scenario == 2 and not unlocked_achievements.has("arid_oasis_master"):
			unlocked_achievements.append("arid_oasis_master")
	active_run.clear()
	save_progress()
