extends Node2D

const GameData = preload("res://scripts/GameData.gd")
const SaveManager = preload("res://scripts/SaveManager.gd")
const AudioManager = preload("res://scripts/AudioManager.gd")
const GridSimulation = preload("res://scripts/GridSimulation.gd")
const IsoRenderer = preload("res://scripts/IsoRenderer.gd")
const UIManager = preload("res://scripts/UIManager.gd")

var save_mgr: SaveManager
var audio_mgr: AudioManager
var sim: GridSimulation
var ui: UIManager
var camera: Camera2D

var game_started: bool = false
var game_over: bool = false
var modal_open: bool = false
var discard_mode: bool = false
var selected_hand_index: int = -1
var hovered_tile: Vector2i = Vector2i(-1, -1)
var is_panning: bool = false

var tip_timer: float = 0.0
var _last_preview_key: String = ""
const CLIMATE_TIPS: Array[String] = [
	"💡 İpucu: Aynı binayı üst üste oynayarak Seviye 2'ye (★) yükseltebilirsiniz.",
	"🌿 Bilgi: Kent ormanları kentsel ısı adasını 5°C düşürür ve karbon yutar.",
	"💡 İpucu: Gölün yanına Tarım veya Jeotermal santral kurarak sinerji kazanın.",
	"💧 Bilgi: Dikey tarım geleneksel tarıma göre %90 daha az su harcar.",
	"💡 İpucu: Kömür santrallerini yıkarak Net-Sıfır hedefine hızla ulaşın.",
	"⚡ Kısayollar: 'Z' son hamleyi geri alır, 'Space' turu bitirir, 'D' kart atar, 'C' odaklar."
]

var anim_time: float = 0.0
var shake_strength: float = 0.0
var flash_alpha: float = 0.0
var flash_color: Color = Color(1.0, 0.3, 0.2)
var floating_texts: Array = []
var debris_effects: Array = []
var upgrade_sparkles: Array = []
var reclamation_effects: Array = []
var synergy_burst_effects: Array = []
var carbon_lens_active: bool = false
var dawn_sweep_timer: float = 0.0

func _ready() -> void:
	randomize()
	if ResourceLoader.exists("res://assets/fonts/Outfit.ttf"):
		var main_font: Font = load("res://assets/fonts/Outfit.ttf")
		var fbs: Array[Font] = []
		if ResourceLoader.exists("res://assets/fonts/SeguiSym.ttf"):
			var sym_font: Font = load("res://assets/fonts/SeguiSym.ttf")
			if sym_font != null:
				fbs.append(sym_font)
		if ResourceLoader.exists("res://assets/fonts/NotoEmoji.ttf"):
			var emoji_font: Font = load("res://assets/fonts/NotoEmoji.ttf")
			if emoji_font != null:
				fbs.append(emoji_font)
		main_font.fallbacks = fbs
		ThemeDB.fallback_font = main_font
	elif ResourceLoader.exists("res://assets/fonts/NotoEmoji.ttf"):
		var emoji_font: Font = load("res://assets/fonts/NotoEmoji.ttf")
		if emoji_font != null and not ThemeDB.fallback_font.fallbacks.has(emoji_font):
			ThemeDB.fallback_font.fallbacks.append(emoji_font)

	save_mgr = SaveManager.new()
	save_mgr.load_save_data()

	audio_mgr = AudioManager.new()
	audio_mgr.volume = save_mgr.sfx_volume
	audio_mgr.music_volume = save_mgr.music_volume
	add_child(audio_mgr)

	sim = GridSimulation.new()
	_setup_camera()

	ui = UIManager.new()
	add_child(ui)
	ui.setup_ui(save_mgr)
	ui.rebuild_help_cards_ui(save_mgr)
	ui.set_game_hud_visible(false)

	ui.scenario_selected.connect(_on_scenario_selected)
	ui.resume_game_requested.connect(_on_resume_game)
	ui.return_to_menu_requested.connect(_on_return_to_menu)
	ui.end_turn_requested.connect(_on_end_turn_pressed)
	ui.toggle_discard_requested.connect(_on_toggle_discard_mode)
	ui.toggle_lens_requested.connect(_on_toggle_lens)
	ui.undo_requested.connect(_on_undo_pressed)
	ui.card_clicked.connect(_on_card_selected)
	ui.card_drag_released.connect(_on_card_drag_released)
	ui.perk_chosen.connect(_on_perk_chosen)
	ui.draft_card_chosen.connect(_on_draft_card_chosen)
	ui.dilemma_option_chosen.connect(_on_dilemma_chosen)
	ui.volume_changed.connect(_on_volume_changed)
	ui.music_volume_changed.connect(_on_music_volume_changed)
	ui.shake_toggled.connect(_on_shake_toggled)
	ui.card_hover_changed.connect(func() -> void: audio_mgr.play_tone(380.0, 460.0, 0.04, 0.08))
	ui.restart_game_requested.connect(_on_restart_game_requested)

	game_started = false
	modal_open = true
	ui.start_screen_panel.visible = true

	if OS.get_cmdline_user_args().has("--screenshots"):
		_run_screenshot_tour()
	elif OS.get_cmdline_user_args().has("--record-video"):
		_run_gameplay_recording()

func _run_screenshot_tour() -> void:
	var out_dir: String = "C:/Users/serhat/.gemini/antigravity-cli/brain/34d2156b-815d-45dc-9b77-e05e6c0c4baa"
	DirAccess.make_dir_recursive_absolute(out_dir)

	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out_dir + "/01_start_screen.png")

	# 2. How to Play & Locked Codex (Tab 0: Cards)
	ui.help_active_tab = 0
	ui.rebuild_help_cards_ui(save_mgr)
	ui.help_panel.visible = true
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out_dir + "/02_how_to_play_codex.png")

	# 2b. Codex Tab 1: Achievements & High Scores
	ui.help_active_tab = 1
	ui.rebuild_help_cards_ui(save_mgr)
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out_dir + "/02b_achievements_codex.png")

	# 2c. Codex Tab 2: Building Evolution Catalog (12/12)
	ui.help_active_tab = 2
	ui.rebuild_help_cards_ui(save_mgr)
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out_dir + "/02c_building_evolution_codex.png")
	ui.help_panel.visible = false

	# 3. Settings Screen
	ui.settings_panel.visible = true
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out_dir + "/03_settings.png")
	ui.settings_panel.visible = false

	# 4. Mode Select Screen
	ui.start_screen_panel.visible = false
	ui.mode_select_panel.visible = true
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out_dir + "/04_mode_select.png")

	# 5. In-Game Screen (Scenario 0) + Tile Inspector Hover
	ui.mode_select_panel.visible = false
	_start_new_game(0)
	sim.active_perks = ["energy_storage", "circular_metropolis"]
	sim.apply_card_effects(Vector2i(6, 6), GameData.CardId.WIND)
	sim.hand = [GameData.CardId.SOLAR, GameData.CardId.UPGRADE_KIT, GameData.CardId.ECO_SURVEY, GameData.CardId.FOREST]
	_advance_day()
	ui.day_recap_panel.visible = false
	hovered_tile = Vector2i(6, 6)
	ui.status_label.text = sim.get_tile_inspector_text(hovered_tile)
	ui.update_hud_stats(sim)
	ui.rebuild_perks_ui(sim)
	ui.rebuild_hand_ui(sim.hand, selected_hand_index, discard_mode, sim)
	await get_tree().process_frame
	await get_tree().process_frame
	ui.update_hand_fan_layout(1.0, selected_hand_index, modal_open, game_over)
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out_dir + "/05_in_game.png")

	# 5b. Shortcuts Overlay
	ui.shortcuts_panel.visible = true
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out_dir + "/05b_shortcuts_panel.png")
	ui.shortcuts_panel.visible = false

	# 5c. Level 1, Level 2 (★) & Level 3 (★★ Mega) Evolution Showcase
	ui.day_recap_panel.visible = false
	sim.active_perks = ["energy_storage", "pollinator_network", "geothermal_district"]
	ui.rebuild_perks_ui(sim)
	upgrade_sparkles.append({
		"pos": GameData.grid_to_iso(6.5, 6.5),
		"age": 0.3,
		"duration": 1.1
	})
	sim.grid_building[6][6] = GameData.BuildingType.WIND
	sim.grid_level[6][6] = 2
	sim.grid_building[7][6] = GameData.BuildingType.SOLAR
	sim.grid_level[7][6] = 3
	sim.grid_building[8][6] = GameData.BuildingType.HOUSING
	sim.grid_level[8][6] = 1
	sim.grid_building[7][7] = GameData.BuildingType.FARM
	sim.grid_level[7][7] = 2
	sim.grid_building[8][7] = GameData.BuildingType.FOREST
	sim.grid_level[8][7] = 3
	sim.grid_state[9][6] = GameData.TileState.UNLOCKED
	sim.grid_building[9][6] = GameData.BuildingType.BATTERY
	sim.grid_level[9][6] = 3
	sim.grid_state[9][7] = GameData.TileState.UNLOCKED
	sim.grid_building[9][7] = GameData.BuildingType.COP31
	sim.grid_level[9][7] = 3
	sim.grid_state[8][8] = GameData.TileState.UNLOCKED
	sim.grid_building[8][8] = GameData.BuildingType.WATER_PLANT
	sim.grid_level[8][8] = 2
	hovered_tile = Vector2i(7, 6)
	ui.status_label.text = sim.get_tile_inspector_text(hovered_tile)
	camera.position = GameData.grid_to_iso(7.8, 6.6)
	camera.zoom = Vector2(1.15, 1.15)
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out_dir + "/05c_level_up_upgrade.png")
	upgrade_sparkles.clear()

	# 5d. Deck Inspector Modal
	sim.discard_pile = [GameData.CardId.SOLAR, GameData.CardId.FOSSIL, GameData.CardId.DEMOLISH]
	ui.open_deck_inspector(sim)
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out_dir + "/05d_deck_inspector.png")

	# 5d2. Discard Pile Inspector Tab
	ui.open_deck_inspector(sim, true)
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out_dir + "/05d2_discard_inspector.png")
	ui.deck_inspector_panel.visible = false

	# 5e. Scenario 3: Arid Oasis Desert Bloom
	_start_new_game(2)
	sim.apply_card_effects(Vector2i(9, 8), GameData.CardId.FOREST)
	ui.update_hud_stats(sim)
	ui.rebuild_hand_ui(sim.hand, selected_hand_index, discard_mode, sim)
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out_dir + "/05e_desert_oasis_scenario.png")
	_start_new_game(0)
	sim.apply_card_effects(Vector2i(6, 6), GameData.CardId.WIND)
	_advance_day()

	# 5f. City Journal Log Modal
	sim.log_event("📅 Gün 1: Rüzgar Türbini kuruldu (⚡+3, 💧-2).")
	sim.log_event("🎯 Gün 2: COP31 Görevi Tamamlandı: Kömürden Çıkış (+4⚡, +4💧)!")
	sim.log_event("🚨 Gün 5: İklim Krizi: Sıcak Hava Dalgası Kent Ormanları ile atlatıldı.")
	ui.open_journal_modal(sim)
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out_dir + "/05f_city_journal_log.png")
	ui.journal_panel.visible = false

	# 5g. Carbon Heatmap Lens View (V)
	carbon_lens_active = true
	ui.update_lens_button_style(true)
	ui.set_carbon_lens_banner_visible(true)
	queue_redraw()
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out_dir + "/05g_carbon_heatmap_lens.png")
	carbon_lens_active = false
	ui.update_lens_button_style(false)
	ui.set_carbon_lens_banner_visible(false)
	queue_redraw()

	# 5h. City Resource Flow & Balance Sheet (I)
	sim.carbon_history = [26, 22, 18, 12, 6]
	ui.open_stats_breakdown(sim)
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out_dir + "/05h_city_balance_sheet.png")
	ui.stats_breakdown_panel.visible = false

	# 5i. 0-Carbon Golden Solarpunk Dawn Radiance
	sim.carbon = 0
	sim.zero_carbon_streak = 4
	ui.update_hud_stats(sim)
	queue_redraw()
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out_dir + "/05i_zero_carbon_golden_dawn.png")
	sim.carbon = 20
	sim.zero_carbon_streak = 0
	ui.update_hud_stats(sim)
	queue_redraw()

	# 6. Card Hovered & Selected + Crisis Banner
	selected_hand_index = 1
	ui.rebuild_hand_ui(sim.hand, selected_hand_index, discard_mode, sim)
	ui.hovered_hand_index = 2
	sim.active_crisis_type = 0
	ui.crisis_label.text = "🚨 İKLİM KRİZİ (Gün 5): Sıcak Hava Dalgası! Kent Ormanları şehri korudu, su kaybı yaşanmadı."
	ui.crisis_panel.visible = true
	await get_tree().process_frame
	ui.update_hand_fan_layout(1.0, selected_hand_index, modal_open, game_over)
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out_dir + "/06_card_hover_and_crisis.png")

	# 6b. Quest Completed Banner Toast
	ui.crisis_panel.visible = false
	sim.active_crisis_type = -1
	ui.show_quest_toast("🎯 COP31 GÖREVİ TAMAMLANDI!\n1 Kömür Santrali Yıkıldı (+4⚡, +4💧) | 🏆 Başarım Açıldı!")
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out_dir + "/06b_quest_completed_toast.png")
	ui.quest_toast_panel.visible = false

	# 6c. Daily Dawn Summary Toast
	ui.show_day_recap(3, {"e": 4, "f": 2, "w": 3, "c": -2}, 1, "📰 COP31 MANŞET: Şehir üst üste 1 gündür 0-Karbon emisyonunda; küresel iklim lideri ilan edildi!")
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out_dir + "/06c_daily_dawn_recap_toast.png")
	ui.day_recap_panel.visible = false

	# 6d. Resilience Milestone Tier Toast
	ui.show_quest_toast("🏆 ŞEHİR GELİŞİM DÖNÜM NOKTASI!\nŞehriniz [🏡 Dirençli Kasaba] düzeyine ulaştı! (Nüfus: 4,400)")
	_spawn_banner_floating_text(GameData.grid_to_iso(8.0, 8.0) + Vector2(0.0, -40.0), "🌟 🏡 Dirençli Kasaba!", Color(1.0, 0.88, 0.35))
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out_dir + "/06d_milestone_tier_toast.png")
	ui.quest_toast_panel.visible = false
	floating_texts.clear()

	# 6e. Eco-Survey Long-Range Satellite Radar Scan Showcase
	sim.hand = [GameData.CardId.SOLAR, GameData.CardId.EXPAND, GameData.CardId.ECO_SURVEY, GameData.CardId.FOREST]
	selected_hand_index = 2
	ui.hovered_hand_index = -1
	ui.rebuild_hand_ui(sim.hand, selected_hand_index, discard_mode, sim)
	hovered_tile = Vector2i(10, 4)
	ui.status_label.text = sim.get_tile_inspector_text(hovered_tile)
	camera.position = GameData.grid_to_iso(8.5, 5.5)
	camera.zoom = Vector2(1.15, 1.15)
	queue_redraw()
	await get_tree().process_frame
	ui.update_hand_fan_layout(1.0, selected_hand_index, modal_open, game_over)
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out_dir + "/06e_eco_survey_radar_scan.png")
	selected_hand_index = -1

	# 6f. Procedural Endless Sandbox Mode (Scenario 3)
	_start_new_game(3)
	camera.position = GameData.grid_to_iso(9.0, 9.0)
	camera.zoom = Vector2(1.0, 1.0)
	queue_redraw()
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out_dir + "/05j_endless_sandbox_mode.png")
	_start_new_game(0)

	# 7. Dilemma Modal (Day 8)
	ui.open_dilemma_modal(8)
	modal_open = true
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out_dir + "/07_dilemma_modal.png")
	ui.modal_panel.visible = false
	modal_open = false

	# 7b. Victory End Screen & Eco Report Card
	sim.stats_clean_energy_built = 3
	sim.stats_forests_planted = 3
	sim.stats_coal_demolished = 1
	sim.stats_upgrades_done = 2
	sim.day = 7
	sim.carbon = 0
	sim.energy = 18
	sim.food = 14
	sim.water = 16
	sim.carbon_history = [26, 22, 18, 12, 6, 0, 0]
	sim.energy_history = [10, 12, 14, 15, 16, 17, 18]
	sim.food_history = [10, 11, 12, 12, 13, 14, 14]
	sim.water_history = [10, 10, 11, 13, 14, 15, 16]
	var win_sub: String = "Karbon emisyonunu üst üste 5 gün boyunca 0'da tutarak Net-Sıfır zaferi kazandın!\n⚡ 18   🌱 14   💧 16   ☣ 0\n%s" % sim.build_eco_report_card(true)
	ui.show_end_screen(true, "🌱 SÜRDÜRÜLEBİLİR ŞEHİR KURULDU - KAZANDIN", win_sub, sim)
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out_dir + "/07b_victory_report_card.png")
	ui.end_screen_panel.visible = false

	# 8. Start Screen with Active Run Resume Button
	_on_return_to_menu()
	ui.start_screen_panel.visible = true
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out_dir + "/08_resume_start_screen.png")

	get_tree().quit(0)

func _wait_movie_frames(count: int) -> void:
	for _i in range(count):
		await get_tree().process_frame

func _record_play_card(card_id: int, target_coord: Vector2i, hover_frames: int = 14, after_frames: int = 24) -> void:
	if game_over or modal_open:
		return

	# 1. Ensure card exists in hand
	var c_idx: int = sim.hand.find(card_id)
	if c_idx < 0:
		sim.hand.append(card_id)
		c_idx = sim.hand.size() - 1
		ui.rebuild_hand_ui(sim.hand, -1, false, sim)

	# 2. Reset selection and select card cleanly
	selected_hand_index = -1
	_on_card_selected(c_idx)

	# 3. Hover over target tile so hover graphics (prism, synergy beam, upgrade ring) are drawn
	hovered_tile = target_coord
	ui.status_label.text = sim.get_tile_inspector_text(target_coord)
	queue_redraw()
	await _wait_movie_frames(hover_frames)

	# 4. Play the card at the target tile
	_try_play_card_at(target_coord)
	queue_redraw()
	await _wait_movie_frames(after_frames)

	# 5. Clear hover
	hovered_tile = Vector2i(-1, -1)
	queue_redraw()

func _run_gameplay_recording() -> void:
	# 1. Main Menu Screen (35 frames = ~1.2s)
	game_started = false
	modal_open = true
	ui.start_screen_panel.visible = true
	ui.mode_select_panel.visible = false
	await _wait_movie_frames(35)

	# 2. Click Start -> Mode Select Screen (30 frames = 1.0s)
	audio_mgr.play_ui_click()
	ui.start_screen_panel.visible = false
	ui.update_mode_select_buttons(save_mgr)
	ui.mode_select_panel.visible = true
	await _wait_movie_frames(30)

	# 3. Select Scenario 0 (Standart Ekoloji) & Enter Island (40 frames = 1.3s)
	audio_mgr.play_fanfare()
	ui.mode_select_panel.visible = false
	_start_new_game(0)
	camera.position = GameData.grid_to_iso(9.0, 9.0) + Vector2(0.0, 30.0)
	camera.zoom = Vector2(1.15, 1.15)
	queue_redraw()
	await _wait_movie_frames(35)

	# 4. Day 1: Card Fan Showcase & Clean Infrastructure Construction
	sim.hand = [GameData.CardId.SOLAR, GameData.CardId.HOUSING, GameData.CardId.FARM, GameData.CardId.FOREST]
	ui.rebuild_hand_ui(sim.hand, -1, false, sim)
	for c_idx in range(sim.hand.size()):
		ui.hovered_hand_index = c_idx
		ui.update_hand_fan_layout(1.0, -1, false, false)
		audio_mgr.play_tone(380.0 + c_idx * 40.0, 480.0, 0.04, 0.06)
		await _wait_movie_frames(8)
	ui.hovered_hand_index = -1
	ui.update_hand_fan_layout(1.0, -1, false, false)
	await _wait_movie_frames(10)

	# 4a. Place Solar Farm (Güneş Paneli) at (8, 8)
	await _record_play_card(GameData.CardId.SOLAR, Vector2i(8, 8), 14, 24)

	# 4b. Place Eco-Housing (Eko-Konut) at (8, 9) adjacent to Solar -> Golden synergy beam!
	await _record_play_card(GameData.CardId.HOUSING, Vector2i(8, 9), 14, 25)

	# 4c. Place Vertical Farm (Dikey Tarım) at (9, 8)
	await _record_play_card(GameData.CardId.FARM, Vector2i(9, 8), 12, 22)

	# 4d. Place Urban Forest (Kent Ormanı) at (9, 9) -> Carbon sink buffer!
	await _record_play_card(GameData.CardId.FOREST, Vector2i(9, 9), 12, 22)

	# 4e. Day 1 -> Day 2 End Turn & Dawn Recap
	await _wait_movie_frames(10)
	_on_end_turn_pressed()
	await _wait_movie_frames(35)

	# 5. Day 2: Building Evolution / Upgrade Kit & Island Expansion
	sim.hand = [GameData.CardId.UPGRADE_KIT, GameData.CardId.EXPAND, GameData.CardId.BIOCORRIDOR, GameData.CardId.RECYCLE]
	ui.rebuild_hand_ui(sim.hand, -1, false, sim)
	await _wait_movie_frames(15)

	# 5a. Modular Upgrade: Evolve Solar Farm at (8, 8) to Level 2 (★)!
	await _record_play_card(GameData.CardId.UPGRADE_KIT, Vector2i(8, 8), 16, 30)

	# 5b. Toprak Islahı (EXPAND): Expand the island border at (6, 8)!
	await _record_play_card(GameData.CardId.EXPAND, Vector2i(6, 8), 16, 26)

	# 5c. Toggle Carbon Heatmap Lens (V): High-tech tactical thermal view
	_on_toggle_lens()
	await _wait_movie_frames(38)
	_on_toggle_lens()
	await _wait_movie_frames(12)

	# 5d. Day 2 -> Day 3 End Turn
	_on_end_turn_pressed()
	await _wait_movie_frames(35)

	# 6. Day 3: Policy Choice, Coal Plant Demolition & Restoration
	if modal_open or ui.modal_panel.visible:
		await _wait_movie_frames(25)
		_on_perk_chosen("solar_roof")
		ui.modal_panel.visible = false
		modal_open = false
		await _wait_movie_frames(20)

	# 6a. Fosil Mirası Tasfiye (DEMOLISH): Demolish old Coal Plant at (7, 7)!
	sim.hand = [GameData.CardId.DEMOLISH, GameData.CardId.FOREST, GameData.CardId.BATTERY, GameData.CardId.WATER_PLANT]
	ui.rebuild_hand_ui(sim.hand, -1, false, sim)
	await _wait_movie_frames(10)
	await _record_play_card(GameData.CardId.DEMOLISH, Vector2i(7, 7), 16, 35)

	# 6b. Reclaim Demolished Site: Plant lush Urban Forest at (7, 7)!
	await _record_play_card(GameData.CardId.FOREST, Vector2i(7, 7), 14, 25)

	# 7. Milestone Celebration
	ui.show_quest_toast("🌟 COP31 İKLİM DİRENCİ: 🏡 Dirençli Eko-Kasaba Düzeyine Ulaşıldı!\nNet-Sıfır Hedefine Doğru!")
	_spawn_banner_floating_text(GameData.grid_to_iso(9.0, 9.0) + Vector2(0.0, -40.0), "🌟 🏡 Dirençli Eko-Kasaba!", Color(1.0, 0.88, 0.35))
	audio_mgr.play_fanfare()
	await _wait_movie_frames(35)

	# 8. COP31 S-Tier Net-Zero Victory Report Card Finale
	sim.stats_clean_energy_built = 3
	sim.stats_forests_planted = 3
	sim.stats_coal_demolished = 1
	sim.stats_upgrades_done = 2
	sim.stats_cards_played = 8
	sim.day = 7
	sim.carbon = 0
	sim.energy = 22
	sim.food = 18
	sim.water = 19
	sim.carbon_history = [20, 14, 8, 4, 0, 0, 0]
	sim.energy_history = [10, 13, 16, 18, 20, 21, 22]
	sim.food_history = [10, 11, 14, 15, 16, 17, 18]
	sim.water_history = [10, 10, 12, 15, 17, 18, 19]
	var win_sub: String = "Karbon emisyonunu üst üste 5 gün boyunca 0'da tutarak Net-Sıfır zaferi kazandın!\n⚡ 22   🌱 18   💧 19   ☣ 0\n%s" % sim.build_eco_report_card(true)
	ui.show_end_screen(true, "🌱 COP31 NET-SIFIR İKLİM ZAFERİ", win_sub, sim)
	modal_open = true
	await _wait_movie_frames(80)

	get_tree().quit(0)

func _setup_camera() -> void:
	camera = Camera2D.new()
	add_child(camera)
	camera.make_current()
	_center_camera()

func _center_camera() -> void:
	var center_iso: Vector2 = GameData.grid_to_iso(GameData.GRID_SIZE * 0.5, GameData.GRID_SIZE * 0.5)
	camera.position = center_iso + Vector2(0.0, 35.0)
	camera.zoom = Vector2(1.0, 1.0)
	_clamp_camera()

func _clamp_camera() -> void:
	var center_iso: Vector2 = GameData.grid_to_iso(GameData.GRID_SIZE * 0.5, GameData.GRID_SIZE * 0.5) + Vector2(0.0, 35.0)
	var max_offset := Vector2(650.0, 480.0)
	camera.position.x = clampf(camera.position.x, center_iso.x - max_offset.x, center_iso.x + max_offset.x)
	camera.position.y = clampf(camera.position.y, center_iso.y - max_offset.y, center_iso.y + max_offset.y)

func _on_scenario_selected(scenario: int) -> void:
	audio_mgr.play_tone(520.0, 820.0, 0.12)
	_start_new_game(scenario)

func _on_restart_game_requested() -> void:
	audio_mgr.play_tone(540.0, 720.0, 0.10)
	_start_new_game(sim.current_scenario)

func _on_return_to_menu() -> void:
	if game_started and not game_over:
		save_mgr.save_active_run(sim)
	game_started = false
	modal_open = true
	carbon_lens_active = false
	ui.update_lens_button_style(false)
	ui.set_game_hud_visible(false)
	ui.update_start_screen_stats(save_mgr)
	queue_redraw()

func _on_resume_game() -> void:
	if not save_mgr.load_active_run(sim):
		_start_new_game(0)
		return
	game_started = true
	game_over = false
	modal_open = false
	selected_hand_index = -1
	discard_mode = false
	carbon_lens_active = false
	floating_texts.clear()
	debris_effects.clear()
	upgrade_sparkles.clear()
	reclamation_effects.clear()
	synergy_burst_effects.clear()
	_center_camera()

	ui.set_game_hud_visible(true)
	ui.update_discard_button_style(false)
	ui.update_lens_button_style(false)
	ui.crisis_panel.visible = false
	ui.modal_panel.visible = false
	ui.end_screen_panel.visible = false
	ui.rebuild_perks_ui(sim)
	ui.rebuild_hand_ui(sim.hand, selected_hand_index, discard_mode, sim)
	ui.update_hud_stats(sim)
	ui.update_undo_button(sim)
	audio_mgr.set_scenario(sim.current_scenario)
	audio_mgr.update_climate_mood(sim.carbon)
	audio_mgr.play_tone(520.0, 840.0, 0.12)
	ui.status_label.text = "Kayıtlı oyuna devam ediliyor (Gün %d)." % sim.day
	queue_redraw()

func _on_volume_changed(v: float) -> void:
	save_mgr.sfx_volume = v
	audio_mgr.volume = v
	save_mgr.save_progress()
	audio_mgr.play_tone(480.0, 600.0, 0.06)

func _on_music_volume_changed(v: float) -> void:
	save_mgr.music_volume = v
	audio_mgr.music_volume = v
	save_mgr.save_progress()

func _on_shake_toggled(on: bool) -> void:
	save_mgr.screen_shake_enabled = on
	save_mgr.save_progress()

func _start_new_game(scenario: int = 0) -> void:
	game_started = true
	game_over = false
	modal_open = false
	selected_hand_index = -1
	discard_mode = false
	carbon_lens_active = false
	ui.tutorial_dismissed = false
	floating_texts.clear()
	debris_effects.clear()
	upgrade_sparkles.clear()
	reclamation_effects.clear()
	synergy_burst_effects.clear()

	sim.reset_for_new_game(scenario)
	save_mgr.save_active_run(sim)
	_center_camera()

	ui.set_game_hud_visible(true)
	ui.update_discard_button_style(false)
	ui.update_lens_button_style(false)
	ui.crisis_panel.visible = false
	ui.modal_panel.visible = false
	ui.end_screen_panel.visible = false
	ui.rebuild_perks_ui(sim)
	ui.rebuild_hand_ui(sim.hand, selected_hand_index, discard_mode, sim)
	ui.update_hud_stats(sim)
	ui.update_undo_button(sim)
	audio_mgr.set_scenario(scenario)
	audio_mgr.update_climate_mood(sim.carbon)
	ui.status_label.text = "Gün 1 başladı! Binaların üzerine gelerek üretimi inceleyebilir, aynı binaları üst üste koyarak Lv.2★ yapabilirsiniz."
	queue_redraw()

func _on_undo_pressed() -> void:
	if game_over or modal_open:
		return
	if sim.restore_undo_snapshot():
		selected_hand_index = -1
		audio_mgr.play_tone(480.0, 340.0, 0.12)
		ui.update_hud_stats(sim)
		ui.update_undo_button(sim)
		audio_mgr.update_climate_mood(sim.carbon)
		ui.rebuild_perks_ui(sim)
		ui.rebuild_hand_ui(sim.hand, selected_hand_index, discard_mode, sim)
		ui.status_label.text = "↩ Son oynanan kart hamlesi geri alındı! (Günlük geri alma hakkı kullanıldı)"
		save_mgr.save_active_run(sim)
		queue_redraw()

func _on_toggle_discard_mode() -> void:
	if game_over or modal_open:
		return
	discard_mode = not discard_mode
	if discard_mode:
		selected_hand_index = -1
		audio_mgr.play_tone(340.0, 260.0, 0.08)
		ui.status_label.text = "🗑 KART ATMA MODU AKTİF: Elden atmak istediğiniz kartlara tıklayın. Çıkmak için tekrar '🗑 Kart At' tuşuna basın."
	else:
		audio_mgr.play_tone(420.0, 520.0, 0.08)
		ui.status_label.text = "Kart atma modu kapatıldı."
	ui.update_discard_button_style(discard_mode)
	ui.rebuild_hand_ui(sim.hand, selected_hand_index, discard_mode, sim)
	queue_redraw()

func _on_toggle_lens() -> void:
	if not game_started or game_over or modal_open:
		return
	carbon_lens_active = not carbon_lens_active
	if carbon_lens_active:
		audio_mgr.play_tone(520.0, 720.0, 0.08)
		ui.status_label.text = "👁 KARBON LENSİ AÇILDI: Yeşil = Karbon Yutağı, Kırmızı = Kirletici Kaynak, Mavi = Nötr [Kapat: V]."
	else:
		audio_mgr.play_tone(720.0, 520.0, 0.08)
		ui.status_label.text = "Karbon lensi kapatıldı [Kısayol: V]."
	ui.update_lens_button_style(carbon_lens_active)
	ui.set_carbon_lens_banner_visible(carbon_lens_active)
	queue_redraw()

func _on_card_selected(index: int) -> void:
	if game_over or modal_open:
		return
	if discard_mode:
		_on_discard_card(index)
		return
	audio_mgr.play_tone(520.0, 660.0, 0.08)
	if selected_hand_index == index:
		selected_hand_index = -1
		ui.status_label.text = "Kart seçimi iptal edildi."
		ui.fact_label.text = CLIMATE_TIPS[randi() % CLIMATE_TIPS.size()]
	else:
		selected_hand_index = index
		var info: Dictionary = GameData.CARDS[sim.hand[index]]
		ui.status_label.text = "Seçilen: %s %s — %s" % [info["symbol"], info["title"], info["desc"]]
		ui.fact_label.text = info["fact"]
		tip_timer = 0.0
	ui.rebuild_hand_ui(sim.hand, selected_hand_index, discard_mode, sim)
	queue_redraw()

func _on_card_drag_released(index: int, global_pos: Vector2) -> void:
	if not game_started or game_over or modal_open or discard_mode:
		return
	var vp_rect := get_viewport_rect()
	if global_pos.y <= 66.0 or global_pos.y >= vp_rect.size.y - 210.0:
		return
	var world_pos: Vector2 = get_global_mouse_position()
	var grid_coord: Vector2i = GameData.iso_to_grid(world_pos)
	if grid_coord.x >= 0 and grid_coord.x < GameData.GRID_SIZE and grid_coord.y >= 0 and grid_coord.y < GameData.GRID_SIZE:
		selected_hand_index = index
		_try_play_card_at(grid_coord)

func _on_discard_card(index: int) -> void:
	if game_over or modal_open or index < 0 or index >= sim.hand.size():
		return
	audio_mgr.play_tone(300.0, 190.0, 0.09)
	var title: String = GameData.CARDS[sim.hand[index]]["title"]
	sim.discard_pile.append(sim.hand[index])
	sim.hand.remove_at(index)
	if selected_hand_index == index:
		selected_hand_index = -1
	elif selected_hand_index > index:
		selected_hand_index -= 1
	if sim.hand.is_empty():
		discard_mode = false
		ui.update_discard_button_style(false)
	ui.status_label.text = "🗑 %s elden atıldı." % title
	ui.rebuild_hand_ui(sim.hand, selected_hand_index, discard_mode, sim)
	queue_redraw()

func _trigger_shake(strength: float, f_col: Color = Color(1, 1, 1, 0), f_alpha: float = 0.0) -> void:
	if not save_mgr.screen_shake_enabled:
		return
	shake_strength = maxf(shake_strength, strength)
	if f_alpha > 0.0:
		flash_color = f_col
		flash_alpha = maxf(flash_alpha, f_alpha)

func _process(delta: float) -> void:
	anim_time += delta
	modal_open = ui.modal_panel.visible or ui.help_panel.visible or ui.shortcuts_panel.visible or (ui.deck_inspector_panel != null and ui.deck_inspector_panel.visible) or (ui.journal_panel != null and ui.journal_panel.visible) or (ui.stats_breakdown_panel != null and ui.stats_breakdown_panel.visible) or ui.settings_panel.visible or ui.end_screen_panel.visible or ui.start_screen_panel.visible or ui.mode_select_panel.visible

	if game_started and not modal_open:
		audio_mgr.process_ambient(delta, sim.carbon, sim.food, sim.energy)

	if shake_strength > 0.05:
		camera.offset = Vector2(randf_range(-shake_strength, shake_strength), randf_range(-shake_strength, shake_strength))
		shake_strength = lerpf(shake_strength, 0.0, delta * 9.0)
	elif camera.offset != Vector2.ZERO:
		camera.offset = Vector2.ZERO

	if flash_alpha > 0.01:
		flash_alpha = maxf(0.0, flash_alpha - delta * 2.2)

	if dawn_sweep_timer > 0.0:
		dawn_sweep_timer = maxf(0.0, dawn_sweep_timer - delta)
		queue_redraw()

	var move_dir := Vector2.ZERO
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		move_dir.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		move_dir.y += 1.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		move_dir.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		move_dir.x += 1.0

	if move_dir != Vector2.ZERO and not modal_open and game_started:
		camera.position += (move_dir.normalized() * GameData.PAN_SPEED * delta) / camera.zoom.x
		_clamp_camera()
		_update_hovered_tile()

	var anim_keys: Array = sim.tile_anim.keys()
	for k in anim_keys:
		var v: float = sim.tile_anim[k] + delta * 4.5
		if v >= 1.0:
			sim.tile_anim.erase(k)
		else:
			sim.tile_anim[k] = v

	for i in range(floating_texts.size() - 1, -1, -1):
		var ft: Dictionary = floating_texts[i]
		ft["age"] += delta
		ft["pos"] += Vector2(0.0, -32.0 * delta)
		if ft["age"] >= ft["duration"]:
			floating_texts.remove_at(i)

	for i in range(debris_effects.size() - 1, -1, -1):
		var db: Dictionary = debris_effects[i]
		db["age"] += delta
		if db["age"] >= db["duration"]:
			debris_effects.remove_at(i)

	for i in range(upgrade_sparkles.size() - 1, -1, -1):
		var up: Dictionary = upgrade_sparkles[i]
		up["age"] += delta
		if up["age"] >= up["duration"]:
			upgrade_sparkles.remove_at(i)

	for i in range(reclamation_effects.size() - 1, -1, -1):
		var rec: Dictionary = reclamation_effects[i]
		rec["age"] += delta
		if rec["age"] >= rec["duration"]:
			reclamation_effects.remove_at(i)

	for i in range(synergy_burst_effects.size() - 1, -1, -1):
		var sb: Dictionary = synergy_burst_effects[i]
		sb["age"] += delta
		if sb["age"] >= sb["duration"]:
			synergy_burst_effects.remove_at(i)

	if game_started and not game_over and not modal_open and selected_hand_index == -1:
		tip_timer += delta
		if tip_timer >= 6.5:
			tip_timer = 0.0
			ui.fact_label.text = CLIMATE_TIPS[randi() % CLIMATE_TIPS.size()]

	if game_started and not game_over and not modal_open:
		var curr_preview_key: String = ""
		var curr_pdelta: Dictionary = {}
		if selected_hand_index >= 0 and selected_hand_index < sim.hand.size() and hovered_tile != Vector2i(-1, -1):
			var cid: int = sim.hand[selected_hand_index]
			if sim.is_tile_valid_for_card(hovered_tile, cid):
				curr_pdelta = sim.preview_card_delta(hovered_tile, cid)
				curr_preview_key = "sel_%d_tile_%d_%d" % [cid, hovered_tile.x, hovered_tile.y]
		elif ui.hovered_hand_index >= 0 and ui.hovered_hand_index < sim.hand.size() and not discard_mode and selected_hand_index == -1:
			var hcid: int = sim.hand[ui.hovered_hand_index]
			curr_preview_key = "hov_%d" % hcid
			if hcid == GameData.CardId.EXPAND:
				curr_pdelta = {"e": -2, "f": 0, "w": -2, "c": -2}
			elif hcid == GameData.CardId.DEMOLISH:
				curr_pdelta = {"e": -1, "f": 0, "w": 2, "c": 0}
			elif GameData.CARDS[hcid].has("building"):
				var btype: int = GameData.CARDS[hcid]["building"]
				curr_pdelta = sim.calculate_building_yield(Vector2i(0, 0), btype, 1)

		if curr_preview_key != _last_preview_key:
			_last_preview_key = curr_preview_key
			ui.update_hud_stats(sim, curr_pdelta)

	ui.update_hand_fan_layout(clampf(delta * 14.0, 0.0, 1.0), selected_hand_index, modal_open, game_over)
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if not game_started or game_over:
		return

	if event is InputEventKey and event.pressed and not event.echo:
		var k := event as InputEventKey
		if k.keycode == KEY_ESCAPE:
			if ui.shortcuts_panel.visible:
				ui.shortcuts_panel.visible = false
				return
			if ui.deck_inspector_panel != null and ui.deck_inspector_panel.visible:
				ui.deck_inspector_panel.visible = false
				return
			if ui.journal_panel != null and ui.journal_panel.visible:
				ui.journal_panel.visible = false
				return
			if ui.stats_breakdown_panel != null and ui.stats_breakdown_panel.visible:
				ui.stats_breakdown_panel.visible = false
				return
			if ui.help_panel.visible:
				ui.help_panel.visible = false
				return
			if ui.settings_panel.visible:
				ui.settings_panel.visible = false
				return
			if modal_open:
				return
			if selected_hand_index != -1:
				selected_hand_index = -1
				ui.status_label.text = "Kart seçimi iptal edildi."
				ui.rebuild_hand_ui(sim.hand, selected_hand_index, discard_mode, sim)
				queue_redraw()
				return
			if discard_mode:
				_on_toggle_discard_mode()
				return
			ui.settings_panel.visible = not ui.settings_panel.visible
			return

		if k.keycode == KEY_H or k.keycode == KEY_F1:
			ui.shortcuts_panel.visible = not ui.shortcuts_panel.visible
			audio_mgr.play_tone(460.0, 620.0, 0.08)
			return

		if k.keycode == KEY_K:
			if ui.deck_inspector_panel != null and ui.deck_inspector_panel.visible:
				ui.deck_inspector_panel.visible = false
			else:
				ui.open_deck_inspector(sim)
			audio_mgr.play_tone(460.0, 580.0, 0.08)
			return

		if k.keycode == KEY_L:
			if ui.journal_panel != null and ui.journal_panel.visible:
				ui.journal_panel.visible = false
			else:
				ui.open_journal_modal(sim)
			audio_mgr.play_tone(480.0, 640.0, 0.08)
			return

		if k.keycode == KEY_I:
			if ui.stats_breakdown_panel != null and ui.stats_breakdown_panel.visible:
				ui.stats_breakdown_panel.visible = false
			else:
				ui.open_stats_breakdown(sim)
			audio_mgr.play_tone(490.0, 680.0, 0.08)
			return

		if modal_open:
			return

		if k.keycode == KEY_SPACE:
			_on_end_turn_pressed()
			return
		elif k.keycode == KEY_Z or k.keycode == KEY_U:
			_on_undo_pressed()
			return
		elif k.keycode == KEY_X:
			_on_toggle_discard_mode()
			return
		elif k.keycode == KEY_C or k.keycode == KEY_HOME:
			_center_camera()
			audio_mgr.play_tone(440.0, 580.0, 0.08)
			ui.status_label.text = "🎯 Kamera adanın merkezine odaklandı (Kısayol: C)."
			return
		elif k.keycode == KEY_M:
			var muted: bool = audio_mgr.toggle_mute()
			if muted:
				ui.status_label.text = "🔇 Tüm sesler sessize alındı (Kısayol: M)."
			else:
				audio_mgr.play_tone(440.0, 660.0, 0.08)
				ui.status_label.text = "🔊 Sesler yeniden açıldı (Kısayol: M)."
			return
		elif k.keycode == KEY_V:
			_on_toggle_lens()
			return
		elif k.keycode == KEY_F:
			var is_p: bool = ui.toggle_photo_mode()
			if is_p:
				audio_mgr.play_tone(520.0, 780.0, 0.08)
			else:
				audio_mgr.play_tone(780.0, 520.0, 0.08)
			return
		elif k.keycode == KEY_T:
			var scale: float = ui.toggle_game_speed()
			audio_mgr.play_ui_click()
			ui.status_label.text = "⚡ Simülasyon Hızı: %s (Kısayol: T)" % ("1.75x Hızlı" if scale > 1.0 else "1.0x Normal")
			return
		elif k.keycode == KEY_F12:
			var user_dir := OS.get_user_data_dir() + "/screenshots"
			DirAccess.make_dir_recursive_absolute(user_dir)
			var fname := "%s/ecogrid_day%d_%d.png" % [user_dir, sim.day, int(Time.get_unix_time_from_system())]
			get_viewport().get_texture().get_image().save_png(fname)
			ui.show_quest_toast("📸 ŞEHİR FOTOĞRAFI KAYDEDİLDİ!\nDosya: %s" % fname.get_file())
			audio_mgr.play_card_place()
			return
		elif k.keycode >= KEY_1 and k.keycode <= KEY_9:
			var slot: int = k.keycode - KEY_1
			if slot < sim.hand.size():
				_on_card_selected(slot)
				return

	if modal_open:
		return

	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_RIGHT:
			if mb.pressed and selected_hand_index != -1:
				selected_hand_index = -1
				ui.status_label.text = "Kart seçimi iptal edildi."
				ui.fact_label.text = CLIMATE_TIPS[randi() % CLIMATE_TIPS.size()]
				ui.rebuild_hand_ui(sim.hand, selected_hand_index, discard_mode, sim)
				audio_mgr.play_tone(420.0, 310.0, 0.06)
				is_panning = false
				queue_redraw()
			else:
				is_panning = mb.pressed
		elif mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			var z: float = clampf(camera.zoom.x + 0.12, GameData.MIN_ZOOM, GameData.MAX_ZOOM)
			camera.zoom = Vector2(z, z)
			_update_hovered_tile()
			queue_redraw()
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			var z: float = clampf(camera.zoom.x - 0.12, GameData.MIN_ZOOM, GameData.MAX_ZOOM)
			camera.zoom = Vector2(z, z)
			_update_hovered_tile()
			queue_redraw()
		elif mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			_update_hovered_tile()
			_try_play_card_at(hovered_tile)

	elif event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		if is_panning:
			camera.position -= mm.relative / camera.zoom.x
			_clamp_camera()
		_update_hovered_tile()

func _update_hovered_tile() -> void:
	var screen_pos: Vector2 = get_viewport().get_mouse_position()
	if screen_pos.y <= 66.0 or screen_pos.y >= get_viewport_rect().size.y - 225.0:
		if hovered_tile != Vector2i(-1, -1):
			hovered_tile = Vector2i(-1, -1)
			queue_redraw()
		return

	var world_pos: Vector2 = get_global_mouse_position()
	var grid_coord: Vector2i = GameData.iso_to_grid(world_pos)
	var new_hover := Vector2i(-1, -1)
	if grid_coord.x >= 0 and grid_coord.x < GameData.GRID_SIZE and grid_coord.y >= 0 and grid_coord.y < GameData.GRID_SIZE:
		new_hover = grid_coord

	if new_hover != hovered_tile:
		hovered_tile = new_hover
		if selected_hand_index == -1 and not discard_mode and hovered_tile != Vector2i(-1, -1):
			var insp: String = sim.get_tile_inspector_text(hovered_tile)
			if not insp.is_empty():
				ui.status_label.text = insp
		queue_redraw()

func _check_live_achievements() -> String:
	var unlocked_msgs: PackedStringArray = PackedStringArray()
	if sim.carbon == 0 and save_mgr.unlock_achievement("zero_carbon_hero"):
		unlocked_msgs.append("🏆 Başarım: Net-Sıfır Kahramanı!")
	if sim.stats_coal_demolished >= 2 and save_mgr.unlock_achievement("coal_breaker"):
		unlocked_msgs.append("🏆 Başarım: Kömür Avcısı!")
	if sim.stats_upgrades_done >= 3 and save_mgr.unlock_achievement("master_architect"):
		unlocked_msgs.append("🏆 Başarım: Usta Ekoloji Mimarı!")
	var has_lvl3: bool = false
	var has_battery: bool = false
	var has_cop31: bool = false
	var lvl3_count: int = 0
	for x in range(GameData.GRID_SIZE):
		for y in range(GameData.GRID_SIZE):
			var b: int = sim.grid_building[x][y]
			var l: int = sim.grid_level[x][y]
			if l >= 3:
				has_lvl3 = true
				lvl3_count += 1
			if b == GameData.BuildingType.BATTERY:
				has_battery = true
			if b == GameData.BuildingType.COP31:
				has_cop31 = true

	if has_lvl3 and save_mgr.unlock_achievement("mega_metropolis"):
		unlocked_msgs.append("🏆 Başarım: Mega Mühendis (★★ Seviye 3 Mega-Tesis)!")
	if has_battery and save_mgr.unlock_achievement("battery_pioneer"):
		unlocked_msgs.append("🏆 Başarım: Süper Şebeke Öncüsü (Mega-Batarya)!")
	if has_cop31 and save_mgr.unlock_achievement("cop31_champion"):
		unlocked_msgs.append("🏆 Başarım: COP31 Küresel Delegesi!")
	if lvl3_count >= 3 and save_mgr.unlock_achievement("solarpunk_trio"):
		unlocked_msgs.append("🏆 Başarım: Solarpunk Mimarlar Birliği (3+ Mega-Tesis)!")
	if sim.stats_forests_planted >= 4 and save_mgr.unlock_achievement("forest_guardian"):
		unlocked_msgs.append("🏆 Başarım: Yeşil Devrim Muhafızı!")
	if sim.stats_clean_energy_built >= 5 and save_mgr.unlock_achievement("clean_grid"):
		unlocked_msgs.append("🏆 Başarım: Temiz Şebeke Lideri!")
	if sim.calculate_city_population() >= 8000 and save_mgr.unlock_achievement("metropolis"):
		unlocked_msgs.append("🏆 Başarım: Eko-Metropol Kurucusu!")
	if not unlocked_msgs.is_empty():
		ui.rebuild_help_cards_ui(save_mgr)
		ui.update_start_screen_stats(save_mgr)
	return "  ".join(unlocked_msgs)

func _try_play_card_at(coord: Vector2i) -> void:
	if selected_hand_index < 0 or selected_hand_index >= sim.hand.size():
		return
	var card_id: int = sim.hand[selected_hand_index]
	if not sim.is_tile_valid_for_card(coord, card_id):
		audio_mgr.play_tone(220.0, 160.0, 0.1)
		ui.status_label.text = "⚠ Bu kart seçilen kareye oynanamaz! Uygun bir kare seçin."
		return

	var preview: Dictionary = sim.preview_card_delta(coord, card_id)
	if sim.energy + preview["e"] <= 0 or sim.food + preview["f"] <= 0 or sim.water + preview["w"] <= 0:
		audio_mgr.play_tone(200.0, 140.0, 0.14)
		ui.status_label.text = "⚠ Kaynak yetersiz! Bu kartı oynamak bir kaynağınızı 0 veya altına düşürüyor."
		return

	var prev_btype: int = sim.grid_building[coord.x][coord.y]
	var prev_districts: int = sim.detect_active_districts().size()
	sim.save_undo_snapshot()
	var res: Dictionary = sim.apply_card_effects(coord, card_id)
	_trigger_shake(res["shake"], res["flash_color"], res["flash_alpha"])
	_spawn_floating_text(coord, res["delta"])

	if card_id == GameData.CardId.DEMOLISH:
		var iso_pos: Vector2 = GameData.grid_to_iso(coord.x + 0.5, coord.y + 0.5)
		debris_effects.append({
			"pos": iso_pos,
			"age": 0.0,
			"duration": 0.85,
			"is_coal": (prev_btype == GameData.BuildingType.COAL_PLANT or prev_btype == GameData.BuildingType.FOSSIL)
		})
	elif res.get("is_upgrade", false):
		var iso_pos: Vector2 = GameData.grid_to_iso(coord.x + 0.5, coord.y + 0.5)
		var is_mega: bool = res.get("level", 1) >= 3
		upgrade_sparkles.append({
			"pos": iso_pos,
			"age": 0.0,
			"duration": 1.6 if is_mega else 1.1
		})
		if is_mega:
			audio_mgr.play_fanfare()
	elif card_id == GameData.CardId.EXPAND or card_id == GameData.CardId.ECO_SURVEY:
		var iso_pos: Vector2 = GameData.grid_to_iso(coord.x + 0.5, coord.y + 0.5)
		reclamation_effects.append({
			"pos": iso_pos,
			"age": 0.0,
			"duration": 1.25 if card_id == GameData.CardId.ECO_SURVEY else 1.05,
			"is_radar": (card_id == GameData.CardId.ECO_SURVEY)
		})

	if GameData.CARDS[card_id].has("building"):
		var placed_btype: int = GameData.CARDS[card_id]["building"]
		var syn_links: Array[Vector2i] = sim.get_synergy_links(coord, placed_btype)
		if syn_links.size() > 0:
			var from_iso: Vector2 = GameData.grid_to_iso(coord.x + 0.5, coord.y + 0.5) + Vector2(0.0, -18.0)
			for target_c in syn_links:
				var to_iso: Vector2 = GameData.grid_to_iso(target_c.x + 0.5, target_c.y + 0.5) + Vector2(0.0, -18.0)
				synergy_burst_effects.append({
					"from": from_iso,
					"to": to_iso,
					"age": 0.0,
					"duration": 0.90,
					"btype": placed_btype
				})
			audio_mgr.play_synergy_chime()

	var new_districts: Array[Dictionary] = sim.detect_active_districts()
	if new_districts.size() > prev_districts:
		var latest: Dictionary = new_districts[new_districts.size() - 1]
		audio_mgr.play_district_unlock()
		ui.show_quest_toast("🌟 YENİ EKO-BÖLGE OLUŞTURULDU!\n%s aktifleşti!\n(%s)" % [latest["title"], latest.get("bonus_text", "")])

	var summary: String = res["summary"]
	if save_mgr.unlock_card(card_id):
		ui.rebuild_help_cards_ui(save_mgr)
		ui.update_start_screen_stats(save_mgr)
		summary += "  [🔓 Yeni Kart Açıldı!]"

	var quest_msgs: Array[String] = sim.check_and_claim_quests()
	for qm in quest_msgs:
		summary += "  [%s]" % qm

	var ach_msg: String = _check_live_achievements()
	if not ach_msg.is_empty():
		summary += "  [%s]" % ach_msg

	sim.discard_pile.append(card_id)
	sim.hand.remove_at(selected_hand_index)
	selected_hand_index = -1

	if quest_msgs.size() > 0 or not ach_msg.is_empty():
		audio_mgr.play_fanfare()
		var toast_parts: PackedStringArray = PackedStringArray()
		if quest_msgs.size() > 0:
			toast_parts.append("🎯 COP31 GÖREVİ TAMAMLANDI!\n" + "\n".join(quest_msgs))
		if not ach_msg.is_empty():
			toast_parts.append(ach_msg)
		ui.show_quest_toast("\n".join(toast_parts))
	elif res.get("is_upgrade", false):
		audio_mgr.play_upgrade(res.get("level", 2))
	elif card_id == GameData.CardId.DEMOLISH:
		audio_mgr.play_demolish()
	else:
		audio_mgr.play_card_place(card_id)

	_check_resilience_milestone()

	ui.update_hud_stats(sim)
	ui.update_undo_button(sim)
	audio_mgr.update_climate_mood(sim.carbon)
	ui.rebuild_perks_ui(sim)
	ui.rebuild_hand_ui(sim.hand, selected_hand_index, discard_mode, sim)
	save_mgr.save_active_run(sim)
	_check_resilience_milestone()
	queue_redraw()

	if _check_end_conditions():
		return
	ui.status_label.text = summary

func _spawn_floating_text(coord: Vector2i, delta_dict: Dictionary) -> void:
	var parts: PackedStringArray = PackedStringArray()
	if delta_dict["e"] != 0:
		parts.append("%+d⚡" % delta_dict["e"])
	if delta_dict["f"] != 0:
		parts.append("%+d🌱" % delta_dict["f"])
	if delta_dict["w"] != 0:
		parts.append("%+d💧" % delta_dict["w"])
	if delta_dict["c"] != 0:
		parts.append("%+d☣" % delta_dict["c"])
	if parts.is_empty():
		return
	var pos: Vector2 = GameData.grid_to_iso(coord.x + 0.5, coord.y + 0.5) + Vector2(0.0, -34.0)
	floating_texts.append({
		"pos": pos,
		"text": " ".join(parts),
		"age": 0.0,
		"duration": 1.35,
		"color": Color(0.55, 1.0, 0.72) if delta_dict["c"] <= 0 else Color(1.0, 0.65, 0.45)
	})

func _spawn_banner_floating_text(pos: Vector2, text: String, color: Color) -> void:
	floating_texts.append({
		"pos": pos,
		"text": text,
		"age": 0.0,
		"duration": 2.2,
		"color": color
	})

func _check_resilience_milestone() -> void:
	var curr_tier_idx: int = sim.get_resilience_tier_index()
	if curr_tier_idx > sim.max_resilience_tier_reached:
		sim.max_resilience_tier_reached = curr_tier_idx
		var new_tier: String = sim.get_climate_resilience_tier()
		var pop_str: String = String.num_int64(sim.calculate_city_population())
		ui.show_quest_toast("🏆 ŞEHİR GELİŞİM DÖNÜM NOKTASI!\nŞehriniz [%s] düzeyine ulaştı! (Nüfus: %s)" % [new_tier, pop_str])
		sim.log_event("👥 ŞEHİR BÜYÜMESİ: Şehir nüfusu %s'e ulaştı ve [%s] statüsü kazanıldı!" % [pop_str, new_tier])
		audio_mgr.play_milestone()
		_spawn_banner_floating_text(GameData.grid_to_iso(8.0, 8.0) + Vector2(0.0, -40.0), "🌟 %s!" % new_tier, Color(1.0, 0.88, 0.35))

func _on_end_turn_pressed() -> void:
	if game_over or modal_open:
		return
	if discard_mode:
		discard_mode = false
		ui.update_discard_button_style(false)
	audio_mgr.play_tone(360.0, 540.0, 0.12)
	_advance_day()

func _advance_day() -> void:
	sim.reset_daily_undo()
	dawn_sweep_timer = 1.0
	audio_mgr.play_dawn_sweep()
	var turn_prod: Dictionary = sim.calculate_total_turn_production()
	var prev_carbon: int = sim.carbon
	sim.energy += turn_prod["e"]
	sim.food += turn_prod["f"]
	sim.water += turn_prod["w"]
	sim.carbon = clampi(sim.carbon + turn_prod["c"], 0, GameData.MAX_CARBON)

	for x in range(GameData.GRID_SIZE):
		for y in range(GameData.GRID_SIZE):
			var btype: int = sim.grid_building[x][y]
			if btype != GameData.BuildingType.NONE and btype != GameData.BuildingType.LAKE:
				var yld: Dictionary = sim.calculate_building_yield(Vector2i(x, y), btype)
				_spawn_floating_text(Vector2i(x, y), yld)

	if sim.carbon == 0:
		sim.zero_carbon_streak += 1
		if sim.zero_carbon_streak < GameData.ZERO_CARBON_WIN_DAYS:
			audio_mgr.play_tone(580.0, 920.0, 0.16)
			ui.show_quest_toast("🌟 NET-SIFIR SERİSİ: %d/%d GÜN!\nKarbon emisyonunu 0'da tutmaya devam edin!" % [sim.zero_carbon_streak, GameData.ZERO_CARBON_WIN_DAYS])
	else:
		sim.zero_carbon_streak = 0
		if sim.carbon < prev_carbon:
			audio_mgr.play_tone(460.0, 720.0, 0.10)
		elif sim.carbon > prev_carbon + 3:
			audio_mgr.play_tone(180.0, 110.0, 0.14)

	var ach_day: String = _check_live_achievements()
	if not ach_day.is_empty():
		audio_mgr.play_fanfare()
		ui.show_quest_toast(ach_day)

	if _check_end_conditions():
		ui.update_hud_stats(sim)
		return

	sim.day += 1
	sim.roll_daily_weather(sim.day)
	audio_mgr.play_weather_sound(sim.current_weather)
	if _check_end_conditions():
		ui.update_hud_stats(sim)
		return

	if sim.day in [5, 10, 15, 20]:
		var crisis_text: String = sim.trigger_random_crisis()
		ui.crisis_label.text = "🚨 İKLİM KRİZİ (Gün %d): %s" % [sim.day, crisis_text]
		ui.crisis_panel.visible = true
		audio_mgr.play_crisis_alarm()
		_trigger_shake(12.0, Color(1.0, 0.22, 0.18), 0.38)
		sim.upcoming_crisis_id = randi() % 5
	else:
		sim.active_crisis_type = -1
		ui.crisis_panel.visible = false
		_trigger_shake(2.0, Color(0.04, 0.08, 0.14), 0.20)

	sim.carbon = clampi(sim.carbon, 0, GameData.MAX_CARBON)
	sim.carbon_history.append(sim.carbon)
	sim.energy_history.append(sim.energy)
	sim.food_history.append(sim.food)
	sim.water_history.append(sim.water)
	sim.draw_cards_for_day_start()
	audio_mgr.play_card_draw()
	if selected_hand_index >= sim.hand.size():
		selected_hand_index = -1
	ui.rebuild_hand_ui(sim.hand, selected_hand_index, discard_mode, sim)
	ui.update_hud_stats(sim)
	ui.update_undo_button(sim)
	ui.rebuild_perks_ui(sim)
	ui.update_fact_tip(sim.day)
	audio_mgr.update_climate_mood(sim.carbon)
	var forests := sim.get_building_count(GameData.BuildingType.FOREST)
	var daily_news := GameData.get_daily_eco_news(sim.day, sim.carbon, sim.zero_carbon_streak, forests, sim.stats_coal_demolished)
	sim.log_event(daily_news)
	ui.show_day_recap(sim.day, turn_prod, sim.zero_carbon_streak, daily_news)
	save_mgr.save_active_run(sim)
	_check_resilience_milestone()
	queue_redraw()

	if _check_end_conditions():
		return

	if sim.day in [4, 8, 12, 16]:
		modal_open = true
		ui.open_dilemma_modal(sim.day)
	elif sim.day % 3 == 0:
		if ui.open_perk_selection_modal(sim):
			modal_open = true
	elif sim.day % 5 == 0:
		modal_open = true
		ui.open_card_draft_modal(sim.day)

	var status_msg: String = "📅 Gün %d başladı! Tur sonu üretimi uygulandı (⚡%+d, 🌱%+d, 💧%+d, ☣%+d)." % [
		sim.day, turn_prod["e"], turn_prod["f"], turn_prod["w"], turn_prod["c"]
	]
	if sim.day in [4, 9, 14, 19]:
		status_msg += "  ⚠ DİKKAT: Yarın İklim Krizi bekleniyor (%s)! Şebekenizi güçlendirin." % GameData.get_crisis_short_forecast(sim.upcoming_crisis_id)
	ui.status_label.text = status_msg

func _on_dilemma_chosen(delta_dict: Dictionary, title: String, perk_id: String = "") -> void:
	modal_open = false
	sim.energy += delta_dict["e"]
	sim.food += delta_dict["f"]
	sim.water += delta_dict["w"]
	sim.carbon = clampi(sim.carbon + delta_dict["c"], 0, GameData.MAX_CARBON)
	if not perk_id.is_empty() and not sim.active_perks.has(perk_id):
		sim.active_perks.append(perk_id)
		var p_title: String = GameData.get_perk_title(perk_id)
		sim.log_event("⚖ Gün %d Yürürlüğe Giren Yasa: %s" % [sim.day, p_title])
	else:
		sim.log_event("⚖ Gün %d İklim Kararı: %s" % [sim.day, title])
	audio_mgr.play_fanfare()
	audio_mgr.update_climate_mood(sim.carbon)
	ui.update_hud_stats(sim)
	ui.update_perks_display(sim)
	ui.status_label.text = "⚖ Karar ve Yasa Uygulandı: %s" % title
	save_mgr.save_active_run(sim)
	var ach_day: String = _check_live_achievements()
	if not ach_day.is_empty():
		audio_mgr.play_fanfare()
		ui.show_quest_toast(ach_day)
	if _check_end_conditions():
		return
	queue_redraw()

func _on_perk_chosen(perk_id: String) -> void:
	ui.modal_panel.visible = false
	modal_open = false
	sim.active_perks.append(perk_id)
	var p_title: String = perk_id
	for p in GameData.PERKS:
		if p["id"] == perk_id:
			p_title = p["title"]
			break
	sim.log_event("📜 Gün %d Reform Yasası: %s" % [sim.day, p_title])
	modal_open = false
	audio_mgr.play_perk_unlocked()

	if perk_id == "energy_storage":
		sim.hand.append(GameData.CardId.BATTERY)
		sim.deck.append(GameData.CardId.BATTERY)
		ui.show_quest_toast("🔋 ÖDÜL KAZANILDI: MEGA BATARYA!\nAkıllı batarya depolama kartı elinize ve destenize eklendi.")
	elif perk_id == "climate_diplomacy":
		sim.hand.append(GameData.CardId.COP31)
		sim.deck.append(GameData.CardId.COP31)
		ui.show_quest_toast("🏛 ÖDÜL KAZANILDI: COP31 DİPLOMASİ MERKEZİ!\nZirve anıtı kartı elinize ve destenize eklendi.")

	ui.rebuild_perks_ui(sim)
	ui.rebuild_hand_ui(sim.hand, selected_hand_index, discard_mode, sim)
	ui.update_hud_stats(sim)
	if sim.day % 5 == 0:
		modal_open = true
		ui.open_card_draft_modal(sim.day)

func _on_draft_card_chosen(card_id: int) -> void:
	sim.deck.append(card_id)
	sim.hand.append(card_id)
	var c_title: String = GameData.CARDS[card_id]["title"]
	sim.log_event("🃏 Gün %d Desteye Yeni Kart: %s" % [sim.day, c_title])
	modal_open = false
	audio_mgr.play_card_draw()
	ui.rebuild_perks_ui(sim)
	ui.rebuild_hand_ui(sim.hand, selected_hand_index, discard_mode, sim)

func _check_end_conditions() -> bool:
	if sim.energy <= 0 or sim.food <= 0 or sim.water <= 0 or sim.carbon >= GameData.MAX_CARBON:
		game_over = true
		var score: int = sim.calculate_eco_score(false)
		save_mgr.record_game_result(score, false, sim.current_scenario)
		ui.rebuild_help_cards_ui(save_mgr)
		ui.update_start_screen_stats(save_mgr)
		audio_mgr.play_tone(240.0, 110.0, 0.25)
		_trigger_shake(12.0, Color(1.0, 0.2, 0.2), 0.4)
		var reason: String = ""
		if sim.energy <= 0:
			reason = "Şehrin enerji şebekesi tamamen çöktü (⚡ Enerji <= 0)."
		elif sim.food <= 0:
			reason = "Şehirde gıda güvenliği kaybedildi (🌱 Gıda <= 0)."
		elif sim.water <= 0:
			reason = "Su rezervleri tükendi (💧 Su <= 0)."
		else:
			reason = "Karbon emisyonu kritik eşiği aştı (☣ Karbon >= 100)."
		var sub: String = "%s\nUlaşılan Gün: %d / %d\n%s" % [reason, sim.day, GameData.MAX_DAYS, sim.build_eco_report_card(false)]
		ui.show_end_screen(false, "☣ İKLİM ÇÖKÜŞÜ - KAYBETTİN", sub, sim)
		return true

	if sim.current_scenario == 3:
		if sim.day >= 25 and not save_mgr.completed_scenarios.has(3):
			save_mgr.mark_scenario_completed(3)
			save_mgr.unlock_achievement("first_win")
			audio_mgr.play_fanfare()
			ui.show_quest_toast("♾ SONSUZ DİRENÇ USTASI!\n25 gün başarıyla aşıldı! Sonsuz Sandbox modunda rekor kırmaya devam edebilirsiniz.")
		if sim.zero_carbon_streak == GameData.ZERO_CARBON_WIN_DAYS and not save_mgr.unlocked_achievements.has("zero_carbon_hero"):
			save_mgr.unlock_achievement("zero_carbon_hero")
			audio_mgr.play_fanfare()
			ui.show_quest_toast("🌿 NET-SIFIR DÖNGÜSÜ BAŞARILDI!\nSonsuz Sandbox haritasında 5 gün 0-karbon dengesi kuruldu!")
		return false

	if sim.zero_carbon_streak >= GameData.ZERO_CARBON_WIN_DAYS or sim.day >= GameData.MAX_DAYS:
		game_over = true
		var score: int = sim.calculate_eco_score(true)
		save_mgr.record_game_result(score, true, sim.current_scenario)
		save_mgr.unlock_achievement("first_win")
		if sim.current_scenario == 1:
			save_mgr.unlock_achievement("hard_mode_victor")
		elif sim.current_scenario == 2:
			save_mgr.unlock_achievement("arid_oasis_master")
		ui.rebuild_help_cards_ui(save_mgr)
		ui.update_start_screen_stats(save_mgr)
		audio_mgr.play_fanfare()
		var win_reason: String = "Karbon emisyonunu üst üste 5 gün boyunca 0'da tutarak Net-Sıfır zaferi kazandın!" if sim.zero_carbon_streak >= GameData.ZERO_CARBON_WIN_DAYS else "25 gün boyunca iklim krizlerine direnerek sürdürülebilir bir şehir kurdun!"
		var sub: String = "%s\n⚡ %d   🌱 %d   💧 %d   ☣ %d\n%s" % [win_reason, sim.energy, sim.food, sim.water, sim.carbon, sim.build_eco_report_card(true)]
		ui.show_end_screen(true, "🌱 SÜRDÜRÜLEBİLİR ŞEHİR KURULDU - KAZANDIN", sub, sim)
		return true

	return false

func _draw() -> void:
	IsoRenderer.draw_world(
		self,
		sim,
		game_started,
		anim_time,
		hovered_tile,
		selected_hand_index,
		floating_texts,
		flash_color,
		flash_alpha,
		debris_effects,
		upgrade_sparkles,
		reclamation_effects,
		carbon_lens_active,
		dawn_sweep_timer,
		ui.hovered_hand_index,
		synergy_burst_effects
	)
