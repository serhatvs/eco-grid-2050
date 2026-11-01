extends CanvasLayer

const GameData = preload("res://scripts/GameData.gd")
const SaveManager = preload("res://scripts/SaveManager.gd")
const GridSimulation = preload("res://scripts/GridSimulation.gd")

signal scenario_selected(scenario: int)
signal return_to_menu_requested()
signal end_turn_requested()
signal toggle_discard_requested()
signal undo_requested()
signal resume_game_requested()
signal card_clicked(index: int)
signal card_drag_released(index: int, global_pos: Vector2)
signal perk_chosen(perk_id: String)
signal draft_card_chosen(card_id: int)
signal dilemma_option_chosen(delta_dict: Dictionary, choice_title: String, perk_id: String)
signal volume_changed(new_vol: float)
signal music_volume_changed(new_vol: float)
signal shake_toggled(enabled: bool)
signal card_hover_changed()
signal restart_game_requested()
signal toggle_lens_requested()

var top_bar_panel: PanelContainer
var left_perks_panel_node: PanelContainer
var bottom_panel_node: PanelContainer
var to_menu_btn_node: Button

var energy_label: Label
var food_label: Label
var water_label: Label
var carbon_label: Label
var carbon_bar: ProgressBar
var streak_label: Label
var day_label: Label
var weather_label: Label
var is_photo_mode: bool = false
var photo_watermark: PanelContainer
var forecast_label: Label
var status_label: Label
var fact_label: Label
var perks_vbox: VBoxContainer
var crisis_panel: PanelContainer
var crisis_label: Label
var hand_container: Control
var card_nodes: Array[Control] = []
var undo_button: Button
var discard_mode_button: Button
var lens_button: Button
var end_turn_button: Button

var _dragged_card_idx: int = -1
var _drag_start_pos: Vector2 = Vector2.ZERO
var _is_dragging: bool = false

var modal_panel: PanelContainer
var modal_title_label: Label
var modal_subtitle_label: Label
var modal_options_box: HBoxContainer
var help_panel: PanelContainer
var shortcuts_panel: PanelContainer
var deck_inspector_panel: PanelContainer
var deck_cards_grid: GridContainer
var deck_inspector_title: Label
var deck_sub_title: Label
var deck_tab_btn: Button
var discard_tab_btn: Button
var _inspector_view_discard: bool = false
var _cached_inspector_sim: GridSimulation = null
var journal_panel: PanelContainer
var journal_vbox: VBoxContainer
var stats_breakdown_panel: PanelContainer
var stats_breakdown_vbox: VBoxContainer
var restart_run_btn: Button
var help_codex_header: Label
var help_cards_grid: GridContainer
var help_tab_cards_btn: Button
var help_tab_ach_btn: Button
var help_tab_evolve_btn: Button
var help_active_tab: int = 0
var cached_save_mgr: SaveManager
var speed_btn: Button
var is_fast_speed: bool = false
var settings_panel: PanelContainer
var start_screen_panel: PanelContainer
var start_stats_label: Label
var start_stat_slot_lbl: Label
var start_stat_score_lbl: Label
var start_stat_ach_lbl: Label
var start_stat_cards_lbl: Label
var resume_btn: Button
var mode_select_panel: PanelContainer
var scen1_btn_node: Button
var scen2_btn_node: Button
var scen3_btn_node: Button
var scen4_btn_node: Button

var slot_buttons: Array[Button] = []
var settings_slot_buttons: Array[Button] = []
var settings_reset_save_btn: Button

var onboarding_panel: PanelContainer
var onboarding_label: Label
var onboarding_dismiss_btn: Button
var tutorial_dismissed: bool = false
var end_screen_panel: PanelContainer
var end_card_node: PanelContainer
var end_title_label: Label
var end_subtitle_label: Label
var end_metrics_box: VBoxContainer
var copy_report_btn: Button

var carbon_lens_banner: PanelContainer

var quest_toast_panel: PanelContainer
var quest_toast_label: Label
var quest_toast_timer: float = 0.0

var day_recap_panel: PanelContainer
var day_recap_label: Label
var day_recap_timer: float = 0.0

var hovered_hand_index: int = -1

func setup_ui(save_mgr: SaveManager) -> void:
	cached_save_mgr = save_mgr
	var top_bar := PanelContainer.new()
	top_bar_panel = top_bar
	top_bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_bar.offset_bottom = 54
	var t_sb := GameData.make_stylebox(Color(0.06, 0.10, 0.13, 0.96), Color(0.22, 0.48, 0.38), 2, 0)
	t_sb.content_margin_left = 8
	t_sb.content_margin_right = 8
	t_sb.content_margin_top = 4
	t_sb.content_margin_bottom = 4
	top_bar.add_theme_stylebox_override("panel", t_sb)
	add_child(top_bar)

	var top_hbox := HBoxContainer.new()
	top_hbox.add_theme_constant_override("separation", 6)
	top_bar.add_child(top_hbox)

	var brand_box := HBoxContainer.new()
	brand_box.add_theme_constant_override("separation", 6)
	top_hbox.add_child(brand_box)

	var top_globe := TextureRect.new()
	if ResourceLoader.exists("res://assets/sprites/icon_earth.png"):
		top_globe.texture = load("res://assets/sprites/icon_earth.png")
	top_globe.custom_minimum_size = Vector2(18, 18)
	top_globe.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	top_globe.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	top_globe.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	brand_box.add_child(top_globe)

	var brand_label := Label.new()
	brand_label.text = "ECO-GRID"
	brand_label.add_theme_font_size_override("font_size", 14)
	brand_label.add_theme_color_override("font_color", Color(0.45, 0.95, 0.65))
	brand_box.add_child(brand_label)

	energy_label = _create_stat_widget(top_hbox, "res://assets/sprites/icon_energy.png", Color(1.0, 0.88, 0.32), "⚡ ENERJİ ŞEBEKESİ:\nŞehrin temiz ve fosil güç rezervi.\n0 veya altına düşerse şebeke çöker ve oyun kaybedilir!\nHer gün binalarınızdan gelen net üretim parantez içinde gösterilir.")

	food_label = _create_stat_widget(top_hbox, "res://assets/sprites/icon_food.png", Color(0.52, 0.94, 0.42), "🌱 GIDA GÜVENLİĞİ:\nDikey tarım ve biyo-koridorlardan üretilir.\n0 veya altına düşerse kıtlık başlar ve oyun kaybedilir!")

	water_label = _create_stat_widget(top_hbox, "res://assets/sprites/icon_water.png", Color(0.42, 0.82, 1.0), "💧 SU REZERVLERİ:\nDoğal göller, arıtma tesisleri ve geri dönüşüm ile sağlanır.\n0 veya altına düşerse kuraklık felaketinde şehir çöker!")

	var carbon_box := HBoxContainer.new()
	carbon_box.add_theme_constant_override("separation", 5)
	top_hbox.add_child(carbon_box)

	var tr_carbon := TextureRect.new()
	if ResourceLoader.exists("res://assets/sprites/icon_carbon.png"):
		tr_carbon.texture = load("res://assets/sprites/icon_carbon.png")
	tr_carbon.custom_minimum_size = Vector2(16, 16)
	tr_carbon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr_carbon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr_carbon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	tr_carbon.mouse_filter = Control.MOUSE_FILTER_PASS
	carbon_box.add_child(tr_carbon)

	carbon_label = _create_stat_label(carbon_box, Color(1.0, 0.52, 0.45))
	carbon_label.tooltip_text = "☣ KARBON EMİSYONU (0 - 100):\nKömür ve fosil santralleri atmosferi kirletir.\n100'e ulaşırsa küresel ısınma kaynaklı iklim felaketi tetiklenir!\nKent ormanları ve Karbon Yakalama (CCS) ile düşürün."
	carbon_bar = ProgressBar.new()
	carbon_bar.custom_minimum_size = Vector2(56, 16)
	carbon_bar.max_value = GameData.MAX_CARBON
	carbon_bar.show_percentage = false
	carbon_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	carbon_bar.add_theme_stylebox_override("background", GameData.make_stylebox(Color(0.18, 0.18, 0.22), Color(0.35, 0.35, 0.4), 1, 4))
	carbon_bar.add_theme_stylebox_override("fill", GameData.make_stylebox(Color(0.88, 0.28, 0.24), Color(1.0, 0.4, 0.35), 0, 4))
	carbon_box.add_child(carbon_bar)

	streak_label = _create_stat_label(top_hbox, Color(0.55, 0.96, 0.78))
	streak_label.tooltip_text = "🌿 NET-SIFIR SERİSİ (Hedef: 5 Gün):\nKarbon emisyonunu aralıksız 5 gün boyunca 0'da tutarsanız\nCOP31 Net-Sıfır Zaferi kazanırsınız!"

	day_label = _create_stat_label(top_hbox, Color(0.95, 0.95, 0.98))
	day_label.tooltip_text = "📅 GÜN SAYACI (Hedef: 25 Gün):\n25 gün boyunca şehri hayatta tutup iklim krizlerine direnirseniz\nSürdürülebilirlik Zaferi kazanırsınız!"

	weather_label = _create_stat_label(top_hbox, Color(0.68, 0.88, 0.95))
	weather_label.mouse_filter = Control.MOUSE_FILTER_STOP

	# Esnek Boşluk (Spacer): İstatistikler ile araç butonlarını birbirinden zarifçe ayırır
	var top_spacer := Control.new()
	top_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_hbox.add_child(top_spacer)

	lens_button = Button.new()
	lens_button.text = "👁 Lens [V]"
	lens_button.tooltip_text = "Karbon Emisyon & Yutak Isı Haritası Lensi (Kısayol: V)"
	lens_button.custom_minimum_size = Vector2(64, 28)
	lens_button.add_theme_font_size_override("font_size", 11)
	lens_button.pressed.connect(func() -> void: toggle_lens_requested.emit())
	top_hbox.add_child(lens_button)
	update_lens_button_style(false)

	discard_mode_button = Button.new()
	discard_mode_button.text = "🗑 At [X]"
	discard_mode_button.tooltip_text = "Kart atma modunu aç/kapat (Kısayol: X, atılan her kart +1⚡ Enerji kazandırır)"
	discard_mode_button.custom_minimum_size = Vector2(62, 28)
	discard_mode_button.add_theme_font_size_override("font_size", 11)
	discard_mode_button.pressed.connect(func() -> void: toggle_discard_requested.emit())
	top_hbox.add_child(discard_mode_button)
	update_discard_button_style(false)

	undo_button = Button.new()
	undo_button.text = "↩ Geri [Z]"
	undo_button.tooltip_text = "Son oynanan kartı geri al (Kısayol: Z, Gün başına 1 hak)"
	undo_button.custom_minimum_size = Vector2(64, 28)
	undo_button.add_theme_font_size_override("font_size", 11)
	undo_button.add_theme_stylebox_override("normal", GameData.make_stylebox(Color(0.24, 0.22, 0.14), Color(0.78, 0.68, 0.32), 2, 6))
	undo_button.add_theme_stylebox_override("hover", GameData.make_stylebox(Color(0.34, 0.30, 0.18), Color(0.95, 0.85, 0.42), 2, 6))
	undo_button.add_theme_stylebox_override("disabled", GameData.make_stylebox(Color(0.14, 0.15, 0.18), Color(0.32, 0.34, 0.38), 1, 6))
	undo_button.pressed.connect(func() -> void: undo_requested.emit())
	top_hbox.add_child(undo_button)

	var help_btn := Button.new()
	help_btn.text = "📖 Rehber"
	help_btn.tooltip_text = "Klavye Kısayolları ve Oyun Kılavuzu (Kısayol: H veya F1)"
	help_btn.custom_minimum_size = Vector2(68, 28)
	help_btn.add_theme_font_size_override("font_size", 11)
	help_btn.add_theme_stylebox_override("normal", GameData.make_stylebox(Color(0.16, 0.26, 0.36), Color(0.38, 0.64, 0.86), 2, 6))
	help_btn.add_theme_stylebox_override("hover", GameData.make_stylebox(Color(0.22, 0.36, 0.48), Color(0.52, 0.78, 0.98), 2, 6))
	help_btn.pressed.connect(func() -> void:
		shortcuts_panel.visible = not shortcuts_panel.visible
	)
	top_hbox.add_child(help_btn)

	var photo_btn := Button.new()
	photo_btn.text = "📸 [F]"
	photo_btn.tooltip_text = "Sinematik Fotoğraf Modu (Kısayol: F — Tüm arayüzü gizler/açar)"
	photo_btn.custom_minimum_size = Vector2(40, 28)
	photo_btn.add_theme_font_size_override("font_size", 11)
	photo_btn.add_theme_stylebox_override("normal", GameData.make_stylebox(Color(0.18, 0.28, 0.24), Color(0.42, 0.82, 0.68), 2, 6))
	photo_btn.add_theme_stylebox_override("hover", GameData.make_stylebox(Color(0.24, 0.38, 0.32), Color(0.55, 0.95, 0.78), 2, 6))
	photo_btn.pressed.connect(func() -> void: toggle_photo_mode())
	top_hbox.add_child(photo_btn)

	speed_btn = Button.new()
	speed_btn.text = "⚡ 1x [T]"
	speed_btn.tooltip_text = "Oyun Hızı Değiştir (Kısayol: T — 1.0x Normal / 1.75x Hızlı Simülasyon)"
	speed_btn.custom_minimum_size = Vector2(56, 28)
	speed_btn.add_theme_font_size_override("font_size", 11)
	speed_btn.add_theme_stylebox_override("normal", GameData.make_stylebox(Color(0.20, 0.22, 0.28), Color(0.48, 0.65, 0.85), 2, 6))
	speed_btn.add_theme_stylebox_override("hover", GameData.make_stylebox(Color(0.26, 0.30, 0.38), Color(0.65, 0.85, 1.0), 2, 6))
	speed_btn.pressed.connect(func() -> void: toggle_game_speed())
	top_hbox.add_child(speed_btn)

	var settings_top_btn := Button.new()
	settings_top_btn.text = "⚙"
	settings_top_btn.tooltip_text = "Ayarlar & Ana Menü"
	settings_top_btn.custom_minimum_size = Vector2(26, 28)
	settings_top_btn.add_theme_font_size_override("font_size", 12)
	settings_top_btn.add_theme_stylebox_override("normal", GameData.make_stylebox(Color(0.20, 0.22, 0.28), Color(0.52, 0.58, 0.68), 2, 6))
	settings_top_btn.add_theme_stylebox_override("hover", GameData.make_stylebox(Color(0.28, 0.32, 0.38), Color(0.75, 0.82, 0.92), 2, 6))
	settings_top_btn.pressed.connect(func() -> void: settings_panel.visible = not settings_panel.visible)
	top_hbox.add_child(settings_top_btn)

	var left_perks_panel := PanelContainer.new()
	left_perks_panel_node = left_perks_panel
	left_perks_panel.position = Vector2(12, 64)
	left_perks_panel.custom_minimum_size = Vector2(288, 0)
	left_perks_panel.add_theme_stylebox_override("panel", GameData.make_stylebox(Color(0.07, 0.11, 0.15, 0.90), Color(0.24, 0.46, 0.38), 1, 8))
	add_child(left_perks_panel)

	var left_vbox := VBoxContainer.new()
	left_vbox.add_theme_constant_override("separation", 6)
	left_perks_panel.add_child(left_vbox)

	forecast_label = Label.new()
	forecast_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	forecast_label.add_theme_font_size_override("font_size", 12)
	forecast_label.add_theme_color_override("font_color", Color(1.0, 0.82, 0.38))
	left_vbox.add_child(forecast_label)

	perks_vbox = VBoxContainer.new()
	perks_vbox.add_theme_constant_override("separation", 4)
	left_vbox.add_child(perks_vbox)

	crisis_panel = PanelContainer.new()
	crisis_panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
	crisis_panel.offset_top = 74
	crisis_panel.offset_bottom = 122
	crisis_panel.offset_left = 310
	crisis_panel.offset_right = -20
	crisis_panel.add_theme_stylebox_override("panel", GameData.make_stylebox(Color(0.42, 0.12, 0.12, 0.94), Color(0.95, 0.38, 0.32), 2, 8))
	crisis_panel.visible = false
	add_child(crisis_panel)

	crisis_label = Label.new()
	crisis_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	crisis_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	crisis_label.add_theme_font_size_override("font_size", 14)
	crisis_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.85))
	crisis_panel.add_child(crisis_label)

	day_recap_panel = PanelContainer.new()
	day_recap_panel.z_index = 94
	day_recap_panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	day_recap_panel.offset_top = 74
	day_recap_panel.custom_minimum_size = Vector2(520, 44)
	var d_sb := GameData.make_stylebox(Color(0.06, 0.12, 0.16, 0.96), Color(0.35, 0.82, 0.65), 2, 8)
	d_sb.content_margin_left = 16
	d_sb.content_margin_right = 16
	d_sb.content_margin_top = 8
	d_sb.content_margin_bottom = 8
	day_recap_panel.add_theme_stylebox_override("panel", d_sb)
	day_recap_panel.visible = false
	add_child(day_recap_panel)

	day_recap_label = Label.new()
	day_recap_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	day_recap_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	day_recap_label.add_theme_font_size_override("font_size", 13)
	day_recap_label.add_theme_color_override("font_color", Color(0.92, 0.98, 0.95))
	day_recap_panel.add_child(day_recap_label)

	quest_toast_panel = PanelContainer.new()
	quest_toast_panel.z_index = 95
	quest_toast_panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	quest_toast_panel.offset_top = 76
	quest_toast_panel.custom_minimum_size = Vector2(440, 50)
	var q_sb := GameData.make_stylebox(Color(0.08, 0.16, 0.14, 0.96), Color(1.0, 0.85, 0.28), 2, 10)
	q_sb.content_margin_left = 18
	q_sb.content_margin_right = 18
	q_sb.content_margin_top = 10
	q_sb.content_margin_bottom = 10
	quest_toast_panel.add_theme_stylebox_override("panel", q_sb)
	quest_toast_panel.visible = false
	add_child(quest_toast_panel)

	quest_toast_label = Label.new()
	quest_toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	quest_toast_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	quest_toast_label.add_theme_font_size_override("font_size", 14)
	quest_toast_label.add_theme_color_override("font_color", Color(1.0, 0.94, 0.45))
	quest_toast_panel.add_child(quest_toast_label)

	var bottom_panel := PanelContainer.new()
	bottom_panel_node = bottom_panel
	bottom_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bottom_panel.offset_top = -246
	bottom_panel.clip_contents = false
	bottom_panel.add_theme_stylebox_override("panel", GameData.make_stylebox(Color(0.06, 0.10, 0.13, 0.94), Color(0.22, 0.48, 0.38), 2, 0))
	add_child(bottom_panel)

	var bottom_vbox := VBoxContainer.new()
	bottom_vbox.clip_contents = false
	bottom_vbox.add_theme_constant_override("separation", 2)
	bottom_panel.add_child(bottom_vbox)

	status_label = Label.new()
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 12)
	status_label.add_theme_color_override("font_color", Color(0.84, 0.94, 0.88))
	bottom_vbox.add_child(status_label)

	fact_label = Label.new()
	fact_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	fact_label.add_theme_font_size_override("font_size", 11)
	fact_label.add_theme_color_override("font_color", Color(0.58, 0.92, 0.72))
	fact_label.text = "💡 İpucu: Aynı binayı üst üste oynayarak Seviye 2 (★) yapabilirsiniz."
	bottom_vbox.add_child(fact_label)

	hand_container = Control.new()
	hand_container.custom_minimum_size = Vector2(0, 186)
	hand_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hand_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hand_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bottom_vbox.add_child(hand_container)

	end_turn_button = Button.new()
	end_turn_button.z_index = 80
	end_turn_button.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	end_turn_button.offset_left = -168
	end_turn_button.offset_top = -105
	end_turn_button.offset_right = -16
	end_turn_button.offset_bottom = -35
	end_turn_button.custom_minimum_size = Vector2(152, 68)
	end_turn_button.text = "⏭ Turu Bitir\n[Space]"
	end_turn_button.tooltip_text = "Turu tamamla ve sonraki güne geç (Kısayol: Space / Boşluk)"
	end_turn_button.add_theme_font_size_override("font_size", 14)
	end_turn_button.add_theme_stylebox_override("normal", GameData.make_stylebox(Color(0.16, 0.48, 0.34), Color(0.38, 0.92, 0.62), 2, 8))
	end_turn_button.add_theme_stylebox_override("hover", GameData.make_stylebox(Color(0.22, 0.62, 0.44), Color(0.55, 1.0, 0.75), 3, 8))
	end_turn_button.add_theme_stylebox_override("pressed", GameData.make_stylebox(Color(0.12, 0.36, 0.26), Color(0.32, 0.78, 0.56), 2, 8))
	end_turn_button.pressed.connect(func() -> void: end_turn_requested.emit())
	add_child(end_turn_button)

	carbon_lens_banner = PanelContainer.new()
	carbon_lens_banner.z_index = 96
	carbon_lens_banner.set_anchors_preset(Control.PRESET_CENTER_TOP)
	carbon_lens_banner.offset_top = 74
	carbon_lens_banner.custom_minimum_size = Vector2(640, 36)
	var lens_sb := GameData.make_stylebox(Color(0.04, 0.09, 0.13, 0.96), Color(0.38, 0.92, 0.65), 2, 8)
	lens_sb.content_margin_left = 16
	lens_sb.content_margin_right = 16
	lens_sb.content_margin_top = 7
	lens_sb.content_margin_bottom = 7
	carbon_lens_banner.add_theme_stylebox_override("panel", lens_sb)
	carbon_lens_banner.visible = false
	add_child(carbon_lens_banner)

	var lens_lbl := Label.new()
	lens_lbl.text = "👁 KARBON LENSİ: 🟢 Yeşil = Karbon Yutağı  |  🔴 Kırmızı = Kirletici Kaynak  |  🔵 Mavi = Nötr  [Kapat: V]"
	lens_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lens_lbl.add_theme_font_size_override("font_size", 12)
	lens_lbl.add_theme_color_override("font_color", Color(0.92, 0.98, 0.95))
	carbon_lens_banner.add_child(lens_lbl)

	onboarding_panel = PanelContainer.new()
	onboarding_panel.z_index = 85
	onboarding_panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	onboarding_panel.offset_left = -440
	onboarding_panel.offset_right = 440
	onboarding_panel.offset_top = -288
	onboarding_panel.offset_bottom = -252
	onboarding_panel.custom_minimum_size = Vector2(880, 36)
	var onb_sb := GameData.make_stylebox(Color(0.05, 0.12, 0.16, 0.96), Color(0.35, 0.92, 0.65), 2, 8)
	onb_sb.content_margin_left = 14
	onb_sb.content_margin_right = 14
	onb_sb.content_margin_top = 4
	onb_sb.content_margin_bottom = 4
	onboarding_panel.add_theme_stylebox_override("panel", onb_sb)
	onboarding_panel.visible = false
	add_child(onboarding_panel)

	var onb_hbox := HBoxContainer.new()
	onb_hbox.add_theme_constant_override("separation", 10)
	onboarding_panel.add_child(onb_hbox)

	onboarding_label = Label.new()
	onboarding_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	onboarding_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	onboarding_label.add_theme_font_size_override("font_size", 11)
	onboarding_label.add_theme_color_override("font_color", Color(0.95, 0.98, 0.85))
	onboarding_label.text = "🌱 1. ADIM: Başlamak için elinizden bir Güneş Paneli veya Konut kartı seçin (1-5 tuşları veya kartlara tıklayın)."
	onb_hbox.add_child(onboarding_label)

	onboarding_dismiss_btn = Button.new()
	onboarding_dismiss_btn.text = "✕ Gizle"
	onboarding_dismiss_btn.tooltip_text = "Başlangıç rehberini kapat"
	onboarding_dismiss_btn.custom_minimum_size = Vector2(56, 24)
	onboarding_dismiss_btn.add_theme_font_size_override("font_size", 11)
	onboarding_dismiss_btn.add_theme_stylebox_override("normal", GameData.make_stylebox(Color(0.18, 0.24, 0.28), Color(0.45, 0.60, 0.68), 1, 4))
	onboarding_dismiss_btn.add_theme_stylebox_override("hover", GameData.make_stylebox(Color(0.28, 0.35, 0.40), Color(0.70, 0.85, 0.95), 1, 4))
	onboarding_dismiss_btn.pressed.connect(func() -> void:
		tutorial_dismissed = true
		onboarding_panel.visible = false
	)
	onb_hbox.add_child(onboarding_dismiss_btn)

	_setup_modals(save_mgr)

func _setup_modals(save_mgr: SaveManager) -> void:
	modal_panel = PanelContainer.new()
	modal_panel.z_index = 100
	modal_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	modal_panel.add_theme_stylebox_override("panel", GameData.make_stylebox(Color(0.02, 0.05, 0.08, 0.92), Color(0, 0, 0, 0), 0, 0))
	modal_panel.visible = false
	add_child(modal_panel)

	var modal_vbox := VBoxContainer.new()
	modal_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	modal_vbox.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	modal_vbox.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	modal_vbox.add_theme_constant_override("separation", 16)
	modal_panel.add_child(modal_vbox)

	modal_title_label = Label.new()
	modal_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	modal_title_label.add_theme_font_size_override("font_size", 22)
	modal_title_label.add_theme_color_override("font_color", Color(0.48, 0.96, 0.68))
	modal_vbox.add_child(modal_title_label)

	modal_subtitle_label = Label.new()
	modal_subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	modal_subtitle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	modal_subtitle_label.custom_minimum_size = Vector2(720, 0)
	modal_subtitle_label.add_theme_font_size_override("font_size", 14)
	modal_subtitle_label.add_theme_color_override("font_color", Color(0.84, 0.90, 0.88))
	modal_vbox.add_child(modal_subtitle_label)

	modal_options_box = HBoxContainer.new()
	modal_options_box.alignment = BoxContainer.ALIGNMENT_CENTER
	modal_options_box.add_theme_constant_override("separation", 18)
	modal_vbox.add_child(modal_options_box)

	help_panel = PanelContainer.new()
	help_panel.z_index = 150
	help_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	help_panel.add_theme_stylebox_override("panel", GameData.make_stylebox(Color(0.02, 0.05, 0.08, 0.92), Color(0, 0, 0, 0), 0, 0))
	help_panel.visible = false
	help_panel.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			help_panel.visible = false
	)
	add_child(help_panel)

	var help_card := PanelContainer.new()
	help_card.mouse_filter = Control.MOUSE_FILTER_STOP
	help_card.custom_minimum_size = Vector2(880, 600)
	help_card.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	help_card.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var help_sb := GameData.make_stylebox(Color(0.06, 0.11, 0.15, 0.99), Color(0.35, 0.78, 0.58), 2, 12)
	help_sb.content_margin_left = 18
	help_sb.content_margin_right = 18
	help_sb.content_margin_top = 14
	help_sb.content_margin_bottom = 14
	help_card.add_theme_stylebox_override("panel", help_sb)
	help_panel.add_child(help_card)

	var help_vbox := VBoxContainer.new()
	help_vbox.add_theme_constant_override("separation", 8)
	help_card.add_child(help_vbox)

	var help_title := Label.new()
	help_title.text = "🌍 ECO-GRID: 2050 — NASIL OYNANIR, KARTLAR & BAŞARIMLAR"
	help_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	help_title.add_theme_font_size_override("font_size", 20)
	help_title.add_theme_color_override("font_color", Color(0.45, 0.95, 0.65))
	help_vbox.add_child(help_title)

	var help_text := Label.new()
	help_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	help_text.add_theme_font_size_override("font_size", 12)
	help_text.text = "• Kamera & İnceleme: Sağ Tık veya WASD ile kaydırın, Tekerlek ile Zoom yapın. Binaların üzerine gelerek net üretimi ve sinerjileri inceleyin.\n• Kart & Hamle: Kaynağınız yettiği sürece sınırsız kart oynayabilirsiniz. '↩ Geri Al' ile günde 1 kez son kartı geri alabilir, '🗑 Kart At' ile elden kart atabilirsiniz.\n• Seviye Yükseltme & Görevler: Aynı kartı veya 'Modüler Yükseltme' kitiyle binalarınızı Seviye 2'ye (★) ve Seviye 3'e (★★ Mega-Tesis) yükseltin. Sol paneldeki COP31 Görevlerini tamamlayarak anında ödül kazanın!"
	help_vbox.add_child(help_text)

	help_codex_header = Label.new()
	help_codex_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	help_codex_header.add_theme_font_size_override("font_size", 14)
	help_codex_header.add_theme_color_override("font_color", Color(1.0, 0.88, 0.38))
	help_vbox.add_child(help_codex_header)

	var tab_hbox := HBoxContainer.new()
	tab_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	tab_hbox.add_theme_constant_override("separation", 14)
	help_vbox.add_child(tab_hbox)

	help_tab_cards_btn = Button.new()
	help_tab_cards_btn.text = "🃏 Kart Koleksiyonu"
	help_tab_cards_btn.custom_minimum_size = Vector2(215, 36)
	help_tab_cards_btn.pressed.connect(func() -> void:
		help_active_tab = 0
		_update_help_tabs_style()
		if cached_save_mgr != null:
			rebuild_help_cards_ui(cached_save_mgr)
	)
	tab_hbox.add_child(help_tab_cards_btn)

	help_tab_ach_btn = Button.new()
	help_tab_ach_btn.text = "🏆 Başarımlar & Rekorlar"
	help_tab_ach_btn.custom_minimum_size = Vector2(215, 36)
	help_tab_ach_btn.pressed.connect(func() -> void:
		help_active_tab = 1
		_update_help_tabs_style()
		if cached_save_mgr != null:
			rebuild_help_cards_ui(cached_save_mgr)
	)
	tab_hbox.add_child(help_tab_ach_btn)

	help_tab_evolve_btn = Button.new()
	help_tab_evolve_btn.text = "🏛 Yapı Evrimi (12/12)"
	help_tab_evolve_btn.custom_minimum_size = Vector2(215, 36)
	help_tab_evolve_btn.pressed.connect(func() -> void:
		help_active_tab = 2
		_update_help_tabs_style()
		if cached_save_mgr != null:
			rebuild_help_cards_ui(cached_save_mgr)
	)
	tab_hbox.add_child(help_tab_evolve_btn)
	_update_help_tabs_style()

	var cards_scroll := ScrollContainer.new()
	cards_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cards_scroll.custom_minimum_size = Vector2(830, 305)
	help_vbox.add_child(cards_scroll)

	help_cards_grid = GridContainer.new()
	help_cards_grid.columns = 2
	help_cards_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	help_cards_grid.add_theme_constant_override("h_separation", 10)
	help_cards_grid.add_theme_constant_override("v_separation", 10)
	cards_scroll.add_child(help_cards_grid)

	var close_help := Button.new()
	close_help.text = "✓ Anladım, Kapat"
	close_help.custom_minimum_size = Vector2(190, 38)
	close_help.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close_help.add_theme_stylebox_override("normal", GameData.make_stylebox(Color(0.16, 0.46, 0.32), Color(0.38, 0.88, 0.62), 2, 8))
	close_help.add_theme_stylebox_override("hover", GameData.make_stylebox(Color(0.22, 0.58, 0.40), Color(0.55, 0.98, 0.75), 2, 8))
	close_help.pressed.connect(func() -> void: help_panel.visible = false)
	help_vbox.add_child(close_help)

	end_screen_panel = PanelContainer.new()
	end_screen_panel.z_index = 110
	end_screen_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	end_screen_panel.add_theme_stylebox_override("panel", GameData.make_stylebox(Color(0.02, 0.04, 0.06, 0.94), Color(0, 0, 0, 0), 0, 0))
	end_screen_panel.visible = false
	add_child(end_screen_panel)

	end_card_node = PanelContainer.new()
	end_card_node.custom_minimum_size = Vector2(760, 620)
	end_card_node.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	end_card_node.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var end_sb := GameData.make_stylebox(Color(0.06, 0.10, 0.14, 0.98), Color(0.38, 0.85, 0.62), 2, 14)
	end_sb.content_margin_left = 26
	end_sb.content_margin_right = 26
	end_sb.content_margin_top = 22
	end_sb.content_margin_bottom = 22
	end_card_node.add_theme_stylebox_override("panel", end_sb)
	end_screen_panel.add_child(end_card_node)

	var center_box := VBoxContainer.new()
	center_box.alignment = BoxContainer.ALIGNMENT_CENTER
	center_box.add_theme_constant_override("separation", 12)
	end_card_node.add_child(center_box)

	end_title_label = Label.new()
	end_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	end_title_label.add_theme_font_size_override("font_size", 22)
	center_box.add_child(end_title_label)

	end_subtitle_label = Label.new()
	end_subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	end_subtitle_label.add_theme_font_size_override("font_size", 13)
	end_subtitle_label.add_theme_color_override("font_color", Color(0.88, 0.94, 0.92))
	end_subtitle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	center_box.add_child(end_subtitle_label)

	end_metrics_box = VBoxContainer.new()
	end_metrics_box.custom_minimum_size = Vector2(660, 0)
	end_metrics_box.add_theme_constant_override("separation", 8)
	center_box.add_child(end_metrics_box)

	var end_btns_hbox := HBoxContainer.new()
	end_btns_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	end_btns_hbox.add_theme_constant_override("separation", 16)
	center_box.add_child(end_btns_hbox)

	var restart_btn := Button.new()
	restart_btn.text = "🔄 Yeni Senaryo / Yeniden Başla"
	restart_btn.custom_minimum_size = Vector2(250, 42)
	restart_btn.add_theme_font_size_override("font_size", 14)
	restart_btn.add_theme_stylebox_override("normal", GameData.make_stylebox(Color(0.18, 0.54, 0.36), Color(0.4, 0.9, 0.62), 2, 8))
	restart_btn.add_theme_stylebox_override("hover", GameData.make_stylebox(Color(0.24, 0.66, 0.44), Color(0.55, 0.98, 0.74), 2, 8))
	restart_btn.pressed.connect(func() -> void:
		end_screen_panel.visible = false
		return_to_menu_requested.emit()
		start_screen_panel.visible = false
		mode_select_panel.visible = true
	)
	end_btns_hbox.add_child(restart_btn)

	copy_report_btn = Button.new()
	copy_report_btn.text = "📋 Raporu Kopyala"
	copy_report_btn.tooltip_text = "COP31 iklim karnenizi ve skorunuzu panoya kopyalayın"
	copy_report_btn.custom_minimum_size = Vector2(180, 42)
	copy_report_btn.add_theme_font_size_override("font_size", 13)
	copy_report_btn.add_theme_stylebox_override("normal", GameData.make_stylebox(Color(0.16, 0.28, 0.38), Color(0.38, 0.75, 0.95), 2, 8))
	copy_report_btn.add_theme_stylebox_override("hover", GameData.make_stylebox(Color(0.22, 0.38, 0.50), Color(0.55, 0.90, 1.0), 2, 8))
	copy_report_btn.pressed.connect(func() -> void:
		DisplayServer.clipboard_set(end_title_label.text + "\n" + end_subtitle_label.text)
		copy_report_btn.text = "✓ Kopyalandı!"
	)
	end_btns_hbox.add_child(copy_report_btn)

	var to_menu_end_btn := Button.new()
	to_menu_end_btn.text = "🏠 Ana Menüye Dön"
	to_menu_end_btn.custom_minimum_size = Vector2(200, 42)
	to_menu_end_btn.add_theme_font_size_override("font_size", 14)
	to_menu_end_btn.add_theme_stylebox_override("normal", GameData.make_stylebox(Color(0.18, 0.22, 0.28), Color(0.55, 0.65, 0.78), 2, 8))
	to_menu_end_btn.add_theme_stylebox_override("hover", GameData.make_stylebox(Color(0.26, 0.32, 0.38), Color(0.75, 0.85, 0.96), 2, 8))
	to_menu_end_btn.pressed.connect(func() -> void:
		end_screen_panel.visible = false
		return_to_menu_requested.emit()
		start_screen_panel.visible = true
	)
	end_btns_hbox.add_child(to_menu_end_btn)

	start_screen_panel = PanelContainer.new()
	start_screen_panel.z_index = 120
	start_screen_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	start_screen_panel.add_theme_stylebox_override("panel", GameData.make_stylebox(Color(0.03, 0.07, 0.10, 1.0), Color(0, 0, 0, 0), 0, 0))
	start_screen_panel.visible = false
	add_child(start_screen_panel)

	var start_vbox := VBoxContainer.new()
	start_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	start_vbox.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	start_vbox.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	start_vbox.add_theme_constant_override("separation", 16)
	start_screen_panel.add_child(start_vbox)

	var title_hbox := HBoxContainer.new()
	title_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	title_hbox.add_theme_constant_override("separation", 12)
	start_vbox.add_child(title_hbox)

	var start_globe := TextureRect.new()
	if ResourceLoader.exists("res://assets/sprites/icon_earth.png"):
		start_globe.texture = load("res://assets/sprites/icon_earth.png")
	start_globe.custom_minimum_size = Vector2(40, 40)
	start_globe.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	start_globe.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	start_globe.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	title_hbox.add_child(start_globe)

	var start_title := Label.new()
	start_title.text = "ECO-GRID: 2050"
	start_title.add_theme_font_size_override("font_size", 32)
	start_title.add_theme_color_override("font_color", Color(0.45, 0.96, 0.68))
	title_hbox.add_child(start_title)

	var start_sub := Label.new()
	start_sub.text = "COP31 İklim Dirençli Şehirler & Sürdürülebilirlik Strateji Simülasyonu"
	start_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	start_sub.add_theme_font_size_override("font_size", 15)
	start_sub.add_theme_color_override("font_color", Color(0.82, 0.90, 0.86))
	start_vbox.add_child(start_sub)

	var stats_hbox := HBoxContainer.new()
	stats_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	stats_hbox.add_theme_constant_override("separation", 16)
	start_vbox.add_child(stats_hbox)

	# Slot
	var slot_box := HBoxContainer.new()
	slot_box.add_theme_constant_override("separation", 5)
	var tr_save := TextureRect.new()
	if ResourceLoader.exists("res://assets/sprites/icon_save.png"):
		tr_save.texture = load("res://assets/sprites/icon_save.png")
	tr_save.custom_minimum_size = Vector2(16, 16)
	tr_save.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr_save.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	slot_box.add_child(tr_save)
	start_stat_slot_lbl = Label.new()
	start_stat_slot_lbl.add_theme_font_size_override("font_size", 13)
	start_stat_slot_lbl.add_theme_color_override("font_color", Color(0.85, 0.85, 0.95))
	slot_box.add_child(start_stat_slot_lbl)
	stats_hbox.add_child(slot_box)

	# Score
	var score_box := HBoxContainer.new()
	score_box.add_theme_constant_override("separation", 5)
	var tr_trophy := TextureRect.new()
	if ResourceLoader.exists("res://assets/sprites/icon_trophy.png"):
		tr_trophy.texture = load("res://assets/sprites/icon_trophy.png")
	tr_trophy.custom_minimum_size = Vector2(16, 16)
	tr_trophy.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr_trophy.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	score_box.add_child(tr_trophy)
	start_stat_score_lbl = Label.new()
	start_stat_score_lbl.add_theme_font_size_override("font_size", 13)
	start_stat_score_lbl.add_theme_color_override("font_color", Color(1.0, 0.86, 0.38))
	score_box.add_child(start_stat_score_lbl)
	stats_hbox.add_child(score_box)

	# Achievements
	var ach_box := HBoxContainer.new()
	ach_box.add_theme_constant_override("separation", 5)
	var tr_medal := TextureRect.new()
	if ResourceLoader.exists("res://assets/sprites/icon_medal.png"):
		tr_medal.texture = load("res://assets/sprites/icon_medal.png")
	tr_medal.custom_minimum_size = Vector2(16, 16)
	tr_medal.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr_medal.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ach_box.add_child(tr_medal)
	start_stat_ach_lbl = Label.new()
	start_stat_ach_lbl.add_theme_font_size_override("font_size", 13)
	start_stat_ach_lbl.add_theme_color_override("font_color", Color(0.95, 0.75, 0.45))
	ach_box.add_child(start_stat_ach_lbl)
	stats_hbox.add_child(ach_box)

	# Cards
	var cards_box := HBoxContainer.new()
	cards_box.add_theme_constant_override("separation", 5)
	var tr_cards := TextureRect.new()
	if ResourceLoader.exists("res://assets/sprites/icon_cards.png"):
		tr_cards.texture = load("res://assets/sprites/icon_cards.png")
	tr_cards.custom_minimum_size = Vector2(16, 16)
	tr_cards.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr_cards.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	cards_box.add_child(tr_cards)
	start_stat_cards_lbl = Label.new()
	start_stat_cards_lbl.add_theme_font_size_override("font_size", 13)
	start_stat_cards_lbl.add_theme_color_override("font_color", Color(0.55, 0.95, 0.80))
	cards_box.add_child(start_stat_cards_lbl)
	stats_hbox.add_child(cards_box)

	var slot_panel := PanelContainer.new()
	slot_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var slot_panel_sb := GameData.make_stylebox(Color(0.04, 0.08, 0.12, 0.94), Color(0.18, 0.38, 0.48, 0.7), 1, 8)
	slot_panel_sb.content_margin_left = 14
	slot_panel_sb.content_margin_right = 14
	slot_panel_sb.content_margin_top = 8
	slot_panel_sb.content_margin_bottom = 8
	slot_panel.add_theme_stylebox_override("panel", slot_panel_sb)
	start_vbox.add_child(slot_panel)

	var slot_vbox := VBoxContainer.new()
	slot_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	slot_vbox.add_theme_constant_override("separation", 6)
	slot_panel.add_child(slot_vbox)

	var slot_header_box := HBoxContainer.new()
	slot_header_box.alignment = BoxContainer.ALIGNMENT_CENTER
	slot_header_box.add_theme_constant_override("separation", 6)
	var tr_folder := TextureRect.new()
	if ResourceLoader.exists("res://assets/sprites/icon_folder.png"):
		tr_folder.texture = load("res://assets/sprites/icon_folder.png")
	tr_folder.custom_minimum_size = Vector2(16, 16)
	tr_folder.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr_folder.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	slot_header_box.add_child(tr_folder)
	var slot_title := Label.new()
	slot_title.text = "OYUN KAYIT PROFİLLERİ (SAVE SLOTS)"
	slot_title.add_theme_font_size_override("font_size", 12)
	slot_title.add_theme_color_override("font_color", Color(0.48, 0.88, 1.0))
	slot_header_box.add_child(slot_title)
	slot_vbox.add_child(slot_header_box)

	var slot_hbox := HBoxContainer.new()
	slot_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	slot_hbox.add_theme_constant_override("separation", 10)
	slot_vbox.add_child(slot_hbox)

	slot_buttons.clear()
	for s_idx in range(1, 4):
		var s_btn := Button.new()
		s_btn.custom_minimum_size = Vector2(150, 48)
		s_btn.add_theme_font_size_override("font_size", 12)
		var s_num: int = s_idx
		s_btn.pressed.connect(func() -> void:
			_on_slot_selected(s_num, save_mgr)
		)
		slot_hbox.add_child(s_btn)
		slot_buttons.append(s_btn)

	update_start_screen_stats(save_mgr)

	var main_btns_vbox := VBoxContainer.new()
	main_btns_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	main_btns_vbox.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	main_btns_vbox.add_theme_constant_override("separation", 12)
	start_vbox.add_child(main_btns_vbox)

	resume_btn = Button.new()
	resume_btn.text = "▶ DEVAM ET"
	resume_btn.custom_minimum_size = Vector2(260, 44)
	resume_btn.add_theme_font_size_override("font_size", 16)
	resume_btn.add_theme_stylebox_override("normal", GameData.make_stylebox(Color(0.20, 0.46, 0.26), Color(0.48, 0.98, 0.65), 2, 10))
	resume_btn.add_theme_stylebox_override("hover", GameData.make_stylebox(Color(0.28, 0.58, 0.34), Color(0.68, 1.0, 0.78), 3, 10))
	resume_btn.pressed.connect(func() -> void:
		start_screen_panel.visible = false
		resume_game_requested.emit()
	)
	resume_btn.visible = false
	main_btns_vbox.add_child(resume_btn)

	var play_main_btn := Button.new()
	play_main_btn.text = "▶ OYUNA BAŞLA (START)"
	play_main_btn.custom_minimum_size = Vector2(260, 46)
	play_main_btn.add_theme_font_size_override("font_size", 16)
	play_main_btn.add_theme_stylebox_override("normal", GameData.make_stylebox(Color(0.14, 0.44, 0.30), Color(0.42, 0.94, 0.66), 2, 10))
	play_main_btn.add_theme_stylebox_override("hover", GameData.make_stylebox(Color(0.20, 0.56, 0.38), Color(0.62, 1.0, 0.78), 3, 10))
	play_main_btn.pressed.connect(func() -> void:
		update_mode_select_buttons(save_mgr)
		start_screen_panel.visible = false
		mode_select_panel.visible = true
	)
	main_btns_vbox.add_child(play_main_btn)

	var menu_how_btn := Button.new()
	menu_how_btn.text = "  NASIL OYNANIR & KOLEKSİYON"
	if ResourceLoader.exists("res://assets/sprites/icon_book.png"):
		menu_how_btn.icon = load("res://assets/sprites/icon_book.png")
		menu_how_btn.expand_icon = true
	menu_how_btn.custom_minimum_size = Vector2(260, 40)
	menu_how_btn.add_theme_font_size_override("font_size", 14)
	menu_how_btn.add_theme_stylebox_override("normal", GameData.make_stylebox(Color(0.14, 0.24, 0.34), Color(0.38, 0.68, 0.92), 2, 8))
	menu_how_btn.add_theme_stylebox_override("hover", GameData.make_stylebox(Color(0.20, 0.32, 0.44), Color(0.55, 0.82, 1.0), 2, 8))
	menu_how_btn.pressed.connect(func() -> void:
		rebuild_help_cards_ui(save_mgr)
		help_panel.visible = true
	)
	main_btns_vbox.add_child(menu_how_btn)

	var menu_settings_btn := Button.new()
	menu_settings_btn.text = "  AYARLAR (SETTINGS)"
	if ResourceLoader.exists("res://assets/sprites/icon_gear.png"):
		menu_settings_btn.icon = load("res://assets/sprites/icon_gear.png")
		menu_settings_btn.expand_icon = true
	menu_settings_btn.custom_minimum_size = Vector2(260, 40)
	menu_settings_btn.add_theme_font_size_override("font_size", 14)
	menu_settings_btn.add_theme_stylebox_override("normal", GameData.make_stylebox(Color(0.18, 0.22, 0.28), Color(0.55, 0.64, 0.75), 2, 8))
	menu_settings_btn.add_theme_stylebox_override("hover", GameData.make_stylebox(Color(0.26, 0.30, 0.38), Color(0.75, 0.84, 0.95), 2, 8))
	menu_settings_btn.pressed.connect(func() -> void: settings_panel.visible = true)
	main_btns_vbox.add_child(menu_settings_btn)

	var menu_quit_btn := Button.new()
	menu_quit_btn.text = "✕ ÇIKIŞ (QUIT)"
	menu_quit_btn.custom_minimum_size = Vector2(260, 40)
	menu_quit_btn.add_theme_font_size_override("font_size", 14)
	menu_quit_btn.add_theme_stylebox_override("normal", GameData.make_stylebox(Color(0.32, 0.12, 0.14), Color(0.82, 0.35, 0.35), 2, 8))
	menu_quit_btn.add_theme_stylebox_override("hover", GameData.make_stylebox(Color(0.45, 0.16, 0.18), Color(1.0, 0.48, 0.48), 2, 8))
	menu_quit_btn.pressed.connect(func() -> void: get_tree().quit())
	if OS.has_feature("web"):
		menu_quit_btn.visible = false
	main_btns_vbox.add_child(menu_quit_btn)

	mode_select_panel = PanelContainer.new()
	mode_select_panel.z_index = 125
	mode_select_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	mode_select_panel.add_theme_stylebox_override("panel", GameData.make_stylebox(Color(0.03, 0.07, 0.10, 1.0), Color(0, 0, 0, 0), 0, 0))
	mode_select_panel.visible = false
	add_child(mode_select_panel)

	var mode_vbox := VBoxContainer.new()
	mode_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	mode_vbox.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	mode_vbox.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	mode_vbox.add_theme_constant_override("separation", 20)
	mode_select_panel.add_child(mode_vbox)

	var mode_title := Label.new()
	mode_title.text = "SENARYO / OYUN MODU SEÇİMİ"
	mode_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mode_title.add_theme_font_size_override("font_size", 24)
	mode_title.add_theme_color_override("font_color", Color(0.45, 0.96, 0.68))
	mode_vbox.add_child(mode_title)

	var mode_sub := Label.new()
	mode_sub.text = "Yönetmek istediğiniz şehrin başlangıç koşullarını ve zorluk seviyesini seçin:"
	mode_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mode_sub.add_theme_font_size_override("font_size", 14)
	mode_sub.add_theme_color_override("font_color", Color(0.82, 0.90, 0.86))
	mode_vbox.add_child(mode_sub)

	var scen_hbox := HBoxContainer.new()
	scen_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	scen_hbox.add_theme_constant_override("separation", 16)
	mode_vbox.add_child(scen_hbox)

	var scen1_btn := Button.new()
	scen1_btn_node = scen1_btn
	scen1_btn.custom_minimum_size = Vector2(235, 175)
	scen1_btn.add_theme_font_size_override("font_size", 13)
	scen1_btn.add_theme_stylebox_override("normal", GameData.make_stylebox(Color(0.12, 0.28, 0.22), Color(0.38, 0.88, 0.62), 2, 10))
	scen1_btn.add_theme_stylebox_override("hover", GameData.make_stylebox(Color(0.18, 0.38, 0.28), Color(0.55, 0.98, 0.75), 3, 10))
	scen1_btn.pressed.connect(func() -> void:
		mode_select_panel.visible = false
		scenario_selected.emit(0)
	)
	scen_hbox.add_child(scen1_btn)

	var scen2_btn := Button.new()
	scen2_btn_node = scen2_btn
	scen2_btn.custom_minimum_size = Vector2(235, 175)
	scen2_btn.add_theme_font_size_override("font_size", 13)
	scen2_btn.add_theme_stylebox_override("normal", GameData.make_stylebox(Color(0.28, 0.14, 0.16), Color(0.88, 0.42, 0.38), 2, 10))
	scen2_btn.add_theme_stylebox_override("hover", GameData.make_stylebox(Color(0.38, 0.18, 0.20), Color(1.0, 0.58, 0.52), 3, 10))
	scen2_btn.pressed.connect(func() -> void:
		mode_select_panel.visible = false
		scenario_selected.emit(1)
	)
	scen_hbox.add_child(scen2_btn)

	var scen3_btn := Button.new()
	scen3_btn_node = scen3_btn
	scen3_btn.custom_minimum_size = Vector2(235, 175)
	scen3_btn.add_theme_font_size_override("font_size", 13)
	scen3_btn.add_theme_stylebox_override("normal", GameData.make_stylebox(Color(0.28, 0.22, 0.12), Color(0.95, 0.75, 0.35), 2, 10))
	scen3_btn.add_theme_stylebox_override("hover", GameData.make_stylebox(Color(0.38, 0.30, 0.16), Color(1.0, 0.88, 0.45), 3, 10))
	scen3_btn.pressed.connect(func() -> void:
		mode_select_panel.visible = false
		scenario_selected.emit(2)
	)
	scen_hbox.add_child(scen3_btn)

	var scen4_btn := Button.new()
	scen4_btn_node = scen4_btn
	scen4_btn.custom_minimum_size = Vector2(235, 175)
	scen4_btn.add_theme_font_size_override("font_size", 13)
	scen4_btn.add_theme_stylebox_override("normal", GameData.make_stylebox(Color(0.12, 0.20, 0.32), Color(0.42, 0.78, 1.0), 2, 10))
	scen4_btn.add_theme_stylebox_override("hover", GameData.make_stylebox(Color(0.18, 0.28, 0.44), Color(0.65, 0.92, 1.0), 3, 10))
	scen4_btn.pressed.connect(func() -> void:
		mode_select_panel.visible = false
		scenario_selected.emit(3)
	)
	scen_hbox.add_child(scen4_btn)
	update_mode_select_buttons(save_mgr)

	var back_to_main_btn := Button.new()
	back_to_main_btn.text = "⬅ Ana Menüye Geri Dön"
	back_to_main_btn.custom_minimum_size = Vector2(230, 42)
	back_to_main_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back_to_main_btn.add_theme_font_size_override("font_size", 15)
	back_to_main_btn.add_theme_stylebox_override("normal", GameData.make_stylebox(Color(0.18, 0.22, 0.28), Color(0.55, 0.64, 0.75), 2, 8))
	back_to_main_btn.add_theme_stylebox_override("hover", GameData.make_stylebox(Color(0.26, 0.30, 0.38), Color(0.75, 0.84, 0.95), 2, 8))
	back_to_main_btn.pressed.connect(func() -> void:
		mode_select_panel.visible = false
		start_screen_panel.visible = true
	)
	mode_vbox.add_child(back_to_main_btn)

	settings_panel = PanelContainer.new()
	settings_panel.z_index = 150
	settings_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	settings_panel.add_theme_stylebox_override("panel", GameData.make_stylebox(Color(0.02, 0.05, 0.08, 0.92), Color(0, 0, 0, 0), 0, 0))
	settings_panel.visible = false
	settings_panel.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			settings_panel.visible = false
	)
	add_child(settings_panel)

	var settings_card := PanelContainer.new()
	settings_card.mouse_filter = Control.MOUSE_FILTER_STOP
	settings_card.custom_minimum_size = Vector2(490, 380)
	settings_card.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	settings_card.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var set_sb := GameData.make_stylebox(Color(0.07, 0.11, 0.15, 0.99), Color(0.42, 0.78, 0.62), 2, 12)
	set_sb.content_margin_left = 20
	set_sb.content_margin_right = 20
	set_sb.content_margin_top = 18
	set_sb.content_margin_bottom = 18
	settings_card.add_theme_stylebox_override("panel", set_sb)
	settings_panel.add_child(settings_card)

	var set_vbox := VBoxContainer.new()
	set_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	set_vbox.add_theme_constant_override("separation", 12)
	settings_card.add_child(set_vbox)

	var set_title := Label.new()
	set_title.text = "⚙ OYUN AYARLARI (SETTINGS)"
	set_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	set_title.add_theme_font_size_override("font_size", 22)
	set_title.add_theme_color_override("font_color", Color(0.48, 0.95, 0.68))
	set_vbox.add_child(set_title)

	var vol_hbox := HBoxContainer.new()
	vol_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vol_hbox.add_theme_constant_override("separation", 12)
	set_vbox.add_child(vol_hbox)

	var vol_lbl := Label.new()
	vol_lbl.text = "🔊 Efekt Sesi: %%%d" % int(round(save_mgr.sfx_volume * 100.0))
	vol_lbl.custom_minimum_size = Vector2(170, 0)
	vol_hbox.add_child(vol_lbl)

	var vol_slider := HSlider.new()
	vol_slider.custom_minimum_size = Vector2(180, 24)
	vol_slider.min_value = 0.0
	vol_slider.max_value = 1.0
	vol_slider.step = 0.05
	vol_slider.value = save_mgr.sfx_volume
	vol_slider.value_changed.connect(func(v: float) -> void:
		vol_lbl.text = "🔊 Efekt Sesi: %%%d" % int(round(v * 100.0))
		volume_changed.emit(v)
	)
	vol_hbox.add_child(vol_slider)

	var mvol_hbox := HBoxContainer.new()
	mvol_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	mvol_hbox.add_theme_constant_override("separation", 12)
	set_vbox.add_child(mvol_hbox)

	var mvol_lbl := Label.new()
	mvol_lbl.text = "🎵 Ambient Müzik: %%%d" % int(round(save_mgr.music_volume * 100.0))
	mvol_lbl.custom_minimum_size = Vector2(170, 0)
	mvol_hbox.add_child(mvol_lbl)

	var mvol_slider := HSlider.new()
	mvol_slider.custom_minimum_size = Vector2(180, 24)
	mvol_slider.min_value = 0.0
	mvol_slider.max_value = 1.0
	mvol_slider.step = 0.05
	mvol_slider.value = save_mgr.music_volume
	mvol_slider.value_changed.connect(func(v: float) -> void:
		mvol_lbl.text = "🎵 Ambient Müzik: %%%d" % int(round(v * 100.0))
		music_volume_changed.emit(v)
	)
	mvol_hbox.add_child(mvol_slider)

	var shake_chk := CheckButton.new()
	shake_chk.text = "💥 Ekran Sarsıntısı ve Efektler (Screen Shake)"
	shake_chk.button_pressed = save_mgr.screen_shake_enabled
	shake_chk.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	shake_chk.toggled.connect(func(on: bool) -> void: shake_toggled.emit(on))
	set_vbox.add_child(shake_chk)

	var fs_chk := CheckButton.new()
	fs_chk.text = "🖥 Tam Ekran Modu (Fullscreen)"
	fs_chk.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	fs_chk.toggled.connect(func(on: bool) -> void:
		if on:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	)
	set_vbox.add_child(fs_chk)

	# Settings Save Slot Switcher & Info
	var set_slot_card := PanelContainer.new()
	set_slot_card.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var set_slot_sb := GameData.make_stylebox(Color(0.06, 0.10, 0.14, 0.92), Color(0.20, 0.42, 0.52, 0.7), 1, 6)
	set_slot_sb.content_margin_left = 12
	set_slot_sb.content_margin_right = 12
	set_slot_sb.content_margin_top = 6
	set_slot_sb.content_margin_bottom = 6
	set_slot_card.add_theme_stylebox_override("panel", set_slot_sb)
	set_vbox.add_child(set_slot_card)

	var set_slot_vbox := VBoxContainer.new()
	set_slot_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	set_slot_vbox.add_theme_constant_override("separation", 4)
	set_slot_card.add_child(set_slot_vbox)

	var set_slot_hdr := Label.new()
	set_slot_hdr.text = "💾 Aktif Kayıt Profili Yuvası:"
	set_slot_hdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	set_slot_hdr.add_theme_font_size_override("font_size", 12)
	set_slot_hdr.add_theme_color_override("font_color", Color(0.48, 0.88, 1.0))
	set_slot_vbox.add_child(set_slot_hdr)

	var set_slot_hbox := HBoxContainer.new()
	set_slot_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	set_slot_hbox.add_theme_constant_override("separation", 8)
	set_slot_vbox.add_child(set_slot_hbox)

	settings_slot_buttons.clear()
	for s_idx in range(1, 4):
		var s_btn := Button.new()
		s_btn.custom_minimum_size = Vector2(85, 28)
		s_btn.add_theme_font_size_override("font_size", 12)
		var s_num: int = s_idx
		s_btn.pressed.connect(func() -> void:
			_on_slot_selected(s_num, save_mgr)
		)
		set_slot_hbox.add_child(s_btn)
		settings_slot_buttons.append(s_btn)

	settings_reset_save_btn = Button.new()
	settings_reset_save_btn.text = "⚠ Yuva %d İlerlemesini Sıfırla" % save_mgr.current_slot
	settings_reset_save_btn.custom_minimum_size = Vector2(250, 32)
	settings_reset_save_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	settings_reset_save_btn.add_theme_font_size_override("font_size", 12)
	settings_reset_save_btn.add_theme_stylebox_override("normal", GameData.make_stylebox(Color(0.24, 0.12, 0.12), Color(0.75, 0.35, 0.35), 1, 6))
	settings_reset_save_btn.add_theme_stylebox_override("hover", GameData.make_stylebox(Color(0.36, 0.16, 0.16), Color(0.95, 0.45, 0.45), 2, 6))
	settings_reset_save_btn.pressed.connect(func() -> void:
		if settings_reset_save_btn.text.begins_with("⚠"):
			settings_reset_save_btn.text = "❓ Yuva %d Sıfırlansın mı? (Tekrar Tıklayın)" % save_mgr.current_slot
		else:
			save_mgr.reset_all_data()
			settings_reset_save_btn.text = "✓ Yuva %d Sıfırlandı!" % save_mgr.current_slot
			update_start_screen_stats(save_mgr)
			rebuild_help_cards_ui(save_mgr)
	)
	set_vbox.add_child(settings_reset_save_btn)

	restart_run_btn = Button.new()
	restart_run_btn.text = "🔄 Bu Senaryoyu Yeniden Başlat"
	restart_run_btn.custom_minimum_size = Vector2(250, 32)
	restart_run_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	restart_run_btn.add_theme_font_size_override("font_size", 12)
	restart_run_btn.add_theme_stylebox_override("normal", GameData.make_stylebox(Color(0.18, 0.28, 0.35), Color(0.38, 0.72, 0.88), 1, 6))
	restart_run_btn.add_theme_stylebox_override("hover", GameData.make_stylebox(Color(0.24, 0.36, 0.46), Color(0.55, 0.88, 1.0), 2, 6))
	restart_run_btn.pressed.connect(func() -> void:
		if restart_run_btn.text == "🔄 Bu Senaryoyu Yeniden Başlat":
			restart_run_btn.text = "❓ Baştan Başlansın mı? (Tekrar Tıklayın)"
		else:
			restart_run_btn.text = "🔄 Bu Senaryoyu Yeniden Başlat"
			settings_panel.visible = false
			restart_game_requested.emit()
	)
	set_vbox.add_child(restart_run_btn)

	var set_btns_hbox := HBoxContainer.new()
	set_btns_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	set_btns_hbox.add_theme_constant_override("separation", 14)
	set_vbox.add_child(set_btns_hbox)

	var to_menu_btn := Button.new()
	to_menu_btn_node = to_menu_btn
	to_menu_btn.text = "🏠 Ana Menüye Dön"
	to_menu_btn.custom_minimum_size = Vector2(170, 38)
	to_menu_btn.add_theme_stylebox_override("normal", GameData.make_stylebox(Color(0.28, 0.16, 0.16), Color(0.82, 0.42, 0.42), 2, 6))
	to_menu_btn.pressed.connect(func() -> void:
		settings_panel.visible = false
		mode_select_panel.visible = false
		end_screen_panel.visible = false
		modal_panel.visible = false
		return_to_menu_requested.emit()
		start_screen_panel.visible = true
	)
	set_btns_hbox.add_child(to_menu_btn)

	var close_set_btn := Button.new()
	close_set_btn.text = "✓ Kaydet & Kapat"
	close_set_btn.custom_minimum_size = Vector2(170, 38)
	close_set_btn.add_theme_stylebox_override("normal", GameData.make_stylebox(Color(0.16, 0.46, 0.32), Color(0.38, 0.88, 0.62), 2, 6))
	close_set_btn.pressed.connect(func() -> void: settings_panel.visible = false)
	set_btns_hbox.add_child(close_set_btn)

	_setup_shortcuts_panel()
	_setup_deck_inspector_panel()
	_setup_journal_panel()
	_setup_stats_breakdown_panel()

	help_panel.move_to_front()
	shortcuts_panel.move_to_front()
	deck_inspector_panel.move_to_front()
	journal_panel.move_to_front()
	stats_breakdown_panel.move_to_front()
	settings_panel.move_to_front()

func _setup_shortcuts_panel() -> void:
	shortcuts_panel = PanelContainer.new()
	shortcuts_panel.z_index = 145
	shortcuts_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	shortcuts_panel.add_theme_stylebox_override("panel", GameData.make_stylebox(Color(0.02, 0.05, 0.08, 0.90), Color(0, 0, 0, 0), 0, 0))
	shortcuts_panel.visible = false
	shortcuts_panel.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			shortcuts_panel.visible = false
	)
	add_child(shortcuts_panel)

	var center_box := PanelContainer.new()
	center_box.mouse_filter = Control.MOUSE_FILTER_STOP
	center_box.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	center_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	center_box.custom_minimum_size = Vector2(800, 470)
	var sb := GameData.make_stylebox(Color(0.07, 0.11, 0.15, 0.99), Color(0.38, 0.75, 0.92), 2, 12)
	sb.content_margin_left = 22
	sb.content_margin_right = 22
	sb.content_margin_top = 18
	sb.content_margin_bottom = 18
	center_box.add_theme_stylebox_override("panel", sb)
	shortcuts_panel.add_child(center_box)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	center_box.add_child(vbox)

	var title := Label.new()
	title.text = "⌨ KLAVYE KISAYOLLARI & KONTROLLER"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(0.45, 0.95, 0.75))
	vbox.add_child(title)

	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 6)
	vbox.add_child(grid)

	var shortcuts_data: Array = [
		["Space", "Turu Bitir & Üretimi Yap"],
		["W / A / S / D", "Haritada Kamerayı Kaydır"],
		["1 - 9", "Eldeki Kartları Seç / Oyna"],
		["Sağ Tık", "İptal Et / Haritada Gezin"],
		["Z  /  U", "Son Kartı Geri Al (1 Hak)"],
		["Sol Tık + Sürükle", "Kartı Haritaya Bırak"],
		["X", "Kart Atma Modu (Iskarta/+1⚡)"],
		["Fare Tekerleği", "Haritayı Yakınlaştır / Zoom"],
		["C / Home", "Kamerayı Merkeze Odakla"],
		["Esc", "İptal Et / Ayarları Aç-Kapat"],
		["V", "Karbon Isı Haritası Lensi"],
		["K", "Deste & Iskarta İncele"],
		["T", "Simülasyon Hızı (1x / 1.75x)"],
		["L", "Şehir Günlüğü (Journal)"],
		["F", "Fotoğraf Modu (HUD Gizle)"],
		["I", "Kaynak Akışı & Bilançosu"],
		["M", "Sesleri / Müziği Kapat"],
		["F12", "Ekran Görüntüsü Kaydet"],
		["H / F1", "Bu Kısayol Yardımını Aç"],
		["", ""]
	]

	for item in shortcuts_data:
		if item[0] == "" and item[1] == "":
			var empty_box := Control.new()
			grid.add_child(empty_box)
			var empty_box2 := Control.new()
			grid.add_child(empty_box2)
			continue
		var key_lbl := Label.new()
		key_lbl.text = item[0]
		key_lbl.custom_minimum_size = Vector2(95, 24)
		key_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		key_lbl.add_theme_font_size_override("font_size", 11)
		key_lbl.add_theme_color_override("font_color", Color(1.0, 0.90, 0.38))
		key_lbl.add_theme_stylebox_override("normal", GameData.make_stylebox(Color(0.14, 0.20, 0.26), Color(0.38, 0.58, 0.78), 1, 4))
		grid.add_child(key_lbl)

		var desc_lbl := Label.new()
		desc_lbl.text = item[1]
		desc_lbl.custom_minimum_size = Vector2(245, 24)
		desc_lbl.add_theme_font_size_override("font_size", 11)
		desc_lbl.add_theme_color_override("font_color", Color(0.90, 0.94, 0.96))
		grid.add_child(desc_lbl)

	var btn_hbox := HBoxContainer.new()
	btn_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_hbox.add_theme_constant_override("separation", 14)
	vbox.add_child(btn_hbox)

	var codex_btn := Button.new()
	codex_btn.text = "📚 Kart Koleksiyonu & Başarımlar"
	codex_btn.custom_minimum_size = Vector2(230, 36)
	codex_btn.add_theme_font_size_override("font_size", 12)
	codex_btn.add_theme_stylebox_override("normal", GameData.make_stylebox(Color(0.14, 0.24, 0.34), Color(0.38, 0.68, 0.92), 2, 8))
	codex_btn.add_theme_stylebox_override("hover", GameData.make_stylebox(Color(0.20, 0.32, 0.44), Color(0.55, 0.82, 1.0), 2, 8))
	codex_btn.pressed.connect(func() -> void:
		shortcuts_panel.visible = false
		if cached_save_mgr != null:
			rebuild_help_cards_ui(cached_save_mgr)
		help_panel.visible = true
	)
	btn_hbox.add_child(codex_btn)

	var close_btn := Button.new()
	close_btn.text = "✓ Anladım, Kapat [Esc / H]"
	close_btn.custom_minimum_size = Vector2(190, 36)
	close_btn.add_theme_font_size_override("font_size", 12)
	close_btn.add_theme_stylebox_override("normal", GameData.make_stylebox(Color(0.16, 0.46, 0.32), Color(0.38, 0.88, 0.62), 2, 8))
	close_btn.add_theme_stylebox_override("hover", GameData.make_stylebox(Color(0.22, 0.58, 0.40), Color(0.55, 0.98, 0.75), 2, 8))
	close_btn.pressed.connect(func() -> void: shortcuts_panel.visible = false)
	btn_hbox.add_child(close_btn)

func _setup_deck_inspector_panel() -> void:
	deck_inspector_panel = PanelContainer.new()
	deck_inspector_panel.z_index = 146
	deck_inspector_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	deck_inspector_panel.add_theme_stylebox_override("panel", GameData.make_stylebox(Color(0.02, 0.05, 0.08, 0.90), Color(0, 0, 0, 0), 0, 0))
	deck_inspector_panel.visible = false
	deck_inspector_panel.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			deck_inspector_panel.visible = false
	)
	add_child(deck_inspector_panel)

	var center_box := PanelContainer.new()
	center_box.mouse_filter = Control.MOUSE_FILTER_STOP
	center_box.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	center_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	center_box.custom_minimum_size = Vector2(660, 500)
	var sb := GameData.make_stylebox(Color(0.07, 0.11, 0.15, 0.99), Color(0.35, 0.82, 0.65), 2, 12)
	sb.content_margin_left = 24
	sb.content_margin_right = 24
	sb.content_margin_top = 18
	sb.content_margin_bottom = 18
	center_box.add_theme_stylebox_override("panel", sb)
	deck_inspector_panel.add_child(center_box)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	center_box.add_child(vbox)

	deck_inspector_title = Label.new()
	deck_inspector_title.text = "🃏 DESTEDEKİ KARTLAR"
	deck_inspector_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	deck_inspector_title.add_theme_font_size_override("font_size", 20)
	deck_inspector_title.add_theme_color_override("font_color", Color(0.48, 0.95, 0.72))
	vbox.add_child(deck_inspector_title)

	var tab_hbox := HBoxContainer.new()
	tab_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	tab_hbox.add_theme_constant_override("separation", 12)
	vbox.add_child(tab_hbox)

	deck_tab_btn = Button.new()
	deck_tab_btn.text = "❖ Çekilme Destesi"
	deck_tab_btn.custom_minimum_size = Vector2(210, 32)
	deck_tab_btn.pressed.connect(func() -> void:
		_inspector_view_discard = false
		if _cached_inspector_sim != null:
			_render_deck_inspector_content(_cached_inspector_sim)
	)
	tab_hbox.add_child(deck_tab_btn)

	discard_tab_btn = Button.new()
	discard_tab_btn.text = "🗑 Iskarta & Kullanılanlar"
	discard_tab_btn.custom_minimum_size = Vector2(210, 32)
	discard_tab_btn.pressed.connect(func() -> void:
		_inspector_view_discard = true
		if _cached_inspector_sim != null:
			_render_deck_inspector_content(_cached_inspector_sim)
	)
	tab_hbox.add_child(discard_tab_btn)

	deck_sub_title = Label.new()
	deck_sub_title.text = "Her tur başında çekilme havuzundaki kartların güncel dağılımı:"
	deck_sub_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	deck_sub_title.add_theme_font_size_override("font_size", 12)
	deck_sub_title.add_theme_color_override("font_color", Color(0.75, 0.82, 0.86))
	vbox.add_child(deck_sub_title)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(610, 310)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)

	deck_cards_grid = GridContainer.new()
	deck_cards_grid.columns = 2
	deck_cards_grid.add_theme_constant_override("h_separation", 12)
	deck_cards_grid.add_theme_constant_override("v_separation", 8)
	scroll.add_child(deck_cards_grid)

	var close_btn := Button.new()
	close_btn.text = "✓ Kapat [Esc / K]"
	close_btn.custom_minimum_size = Vector2(200, 36)
	close_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close_btn.add_theme_stylebox_override("normal", GameData.make_stylebox(Color(0.16, 0.46, 0.32), Color(0.38, 0.88, 0.62), 2, 8))
	close_btn.add_theme_stylebox_override("hover", GameData.make_stylebox(Color(0.22, 0.58, 0.40), Color(0.55, 0.98, 0.75), 2, 8))
	close_btn.pressed.connect(func() -> void: deck_inspector_panel.visible = false)
	vbox.add_child(close_btn)

func open_deck_inspector(sim: GridSimulation, view_discard: bool = false) -> void:
	if deck_inspector_panel == null or deck_cards_grid == null:
		return
	_cached_inspector_sim = sim
	_inspector_view_discard = view_discard
	_render_deck_inspector_content(sim)
	deck_inspector_panel.visible = true

func _render_deck_inspector_content(sim: GridSimulation) -> void:
	if deck_cards_grid == null:
		return
	for c in deck_cards_grid.get_children():
		c.queue_free()

	if _inspector_view_discard:
		deck_tab_btn.add_theme_stylebox_override("normal", GameData.make_stylebox(Color(0.10, 0.14, 0.18), Color(0.25, 0.35, 0.42), 1, 6))
		discard_tab_btn.add_theme_stylebox_override("normal", GameData.make_stylebox(Color(0.42, 0.18, 0.22), Color(0.95, 0.45, 0.52), 2, 6))
		var total_discard: int = sim.discard_pile.size()
		deck_inspector_title.text = "🗑 ISKARTA DESTESİ (%d KART)" % total_discard
		deck_inspector_title.add_theme_color_override("font_color", Color(1.0, 0.55, 0.60))
		deck_sub_title.text = "Oyun boyunca elden atılan [D] ve sahada inşa edilen kartların dökümü:"

		if total_discard == 0:
			var empty_panel := PanelContainer.new()
			empty_panel.custom_minimum_size = Vector2(600, 100)
			empty_panel.add_theme_stylebox_override("panel", GameData.make_stylebox(Color(0.10, 0.14, 0.18, 0.90), Color(0.35, 0.45, 0.52), 1, 8))
			var empty_lbl := Label.new()
			empty_lbl.text = "🗑 Iskarta destesi henüz boş.\nOynadığınız veya elden attığınız kartlar burada listelenir."
			empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			empty_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			empty_lbl.add_theme_font_size_override("font_size", 13)
			empty_lbl.add_theme_color_override("font_color", Color(0.65, 0.75, 0.82))
			empty_panel.add_child(empty_lbl)
			deck_cards_grid.add_child(empty_panel)
			return

		var counts: Dictionary = {}
		for cid in sim.discard_pile:
			counts[cid] = counts.get(cid, 0) + 1

		var sorted_cids: Array = counts.keys()
		sorted_cids.sort_custom(func(a: int, b: int) -> bool:
			if counts[a] != counts[b]:
				return counts[a] > counts[b]
			return a < b
		)

		for cid in sorted_cids:
			var c_count: int = counts[cid]
			var pct: float = (float(c_count) / float(max(1, total_discard))) * 100.0
			var info: Dictionary = GameData.CARDS[cid]
			_add_inspector_card_item(info, c_count, pct)
	else:
		deck_tab_btn.add_theme_stylebox_override("normal", GameData.make_stylebox(Color(0.16, 0.42, 0.32), Color(0.42, 0.92, 0.68), 2, 6))
		discard_tab_btn.add_theme_stylebox_override("normal", GameData.make_stylebox(Color(0.10, 0.14, 0.18), Color(0.25, 0.35, 0.42), 1, 6))
		var total_deck: int = sim.deck.size()
		deck_inspector_title.text = "🃏 DESTEDEKİ KARTLAR (%d KART)" % total_deck
		deck_inspector_title.add_theme_color_override("font_color", Color(0.48, 0.95, 0.72))
		deck_sub_title.text = "Her tur başında çekilme havuzundaki kartların güncel dağılımı:"

		var counts: Dictionary = {}
		for cid in sim.deck:
			counts[cid] = counts.get(cid, 0) + 1

		var sorted_cids: Array = counts.keys()
		sorted_cids.sort_custom(func(a: int, b: int) -> bool:
			if counts[a] != counts[b]:
				return counts[a] > counts[b]
			return a < b
		)

		for cid in sorted_cids:
			var c_count: int = counts[cid]
			var pct: float = (float(c_count) / float(max(1, total_deck))) * 100.0
			var info: Dictionary = GameData.CARDS[cid]
			_add_inspector_card_item(info, c_count, pct)

func _add_inspector_card_item(info: Dictionary, c_count: int, pct: float) -> void:
	var item_panel := PanelContainer.new()
	item_panel.custom_minimum_size = Vector2(295, 68)
	item_panel.add_theme_stylebox_override("panel", GameData.make_stylebox(Color(0.10, 0.16, 0.20, 0.95), info["color"], 1, 6))

	var ivbox := VBoxContainer.new()
	ivbox.add_theme_constant_override("separation", 2)
	item_panel.add_child(ivbox)

	var ihbox := HBoxContainer.new()
	ivbox.add_child(ihbox)

	var ititle := Label.new()
	ititle.text = "%s %s" % [info["symbol"], info["title"]]
	ititle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ititle.add_theme_font_size_override("font_size", 13)
	ititle.add_theme_color_override("font_color", info["color"].lightened(0.3))
	ihbox.add_child(ititle)

	var icount := Label.new()
	icount.text = "x%d (%%%d)" % [c_count, int(round(pct))]
	icount.add_theme_font_size_override("font_size", 12)
	icount.add_theme_color_override("font_color", Color(1.0, 0.88, 0.35))
	ihbox.add_child(icount)

	var icost := Label.new()
	icost.text = info["cost_text"]
	icost.add_theme_font_size_override("font_size", 12)
	icost.add_theme_color_override("font_color", Color(0.75, 0.88, 0.82))
	ivbox.add_child(icost)

	deck_cards_grid.add_child(item_panel)

func _setup_journal_panel() -> void:
	journal_panel = PanelContainer.new()
	journal_panel.z_index = 147
	journal_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	journal_panel.add_theme_stylebox_override("panel", GameData.make_stylebox(Color(0.02, 0.05, 0.08, 0.90), Color(0, 0, 0, 0), 0, 0))
	journal_panel.visible = false
	journal_panel.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			journal_panel.visible = false
	)
	add_child(journal_panel)

	var center_box := PanelContainer.new()
	center_box.mouse_filter = Control.MOUSE_FILTER_STOP
	center_box.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	center_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	center_box.custom_minimum_size = Vector2(640, 490)
	var sb := GameData.make_stylebox(Color(0.07, 0.11, 0.15, 0.99), Color(0.42, 0.78, 0.88), 2, 12)
	sb.content_margin_left = 22
	sb.content_margin_right = 22
	sb.content_margin_top = 18
	sb.content_margin_bottom = 18
	center_box.add_theme_stylebox_override("panel", sb)
	journal_panel.add_child(center_box)

	var main_vbox := VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 10)
	center_box.add_child(main_vbox)

	var title := Label.new()
	title.text = "📜 ŞEHİR GÜNLÜĞÜ & OLAY KAYDI"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(0.48, 0.95, 0.82))
	main_vbox.add_child(title)

	var sub := Label.new()
	sub.text = "Bu oyunda gerçekleşen tüm hamleler, COP31 görevleri ve iklim krizleri kronolojisi:"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 12)
	sub.add_theme_color_override("font_color", Color(0.72, 0.82, 0.86))
	main_vbox.add_child(sub)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(595, 340)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	main_vbox.add_child(scroll)

	journal_vbox = VBoxContainer.new()
	journal_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	journal_vbox.add_theme_constant_override("separation", 5)
	scroll.add_child(journal_vbox)

	var close_btn := Button.new()
	close_btn.text = "✓ Kapat [Esc / L]"
	close_btn.custom_minimum_size = Vector2(190, 36)
	close_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close_btn.add_theme_stylebox_override("normal", GameData.make_stylebox(Color(0.16, 0.46, 0.32), Color(0.38, 0.88, 0.62), 2, 8))
	close_btn.add_theme_stylebox_override("hover", GameData.make_stylebox(Color(0.22, 0.58, 0.40), Color(0.55, 0.98, 0.75), 2, 8))
	close_btn.pressed.connect(func() -> void: journal_panel.visible = false)
	main_vbox.add_child(close_btn)

func open_journal_modal(sim: GridSimulation) -> void:
	if journal_panel == null or journal_vbox == null:
		return
	for c in journal_vbox.get_children():
		c.queue_free()

	if sim.event_log.is_empty():
		var empty_lbl := Label.new()
		empty_lbl.text = "Henüz kaydedilmiş bir şehir olayı yok."
		empty_lbl.add_theme_font_size_override("font_size", 13)
		empty_lbl.add_theme_color_override("font_color", Color(0.65, 0.70, 0.72))
		journal_vbox.add_child(empty_lbl)
	else:
		for i in range(sim.event_log.size() - 1, -1, -1):
			var entry_txt: String = sim.event_log[i]
			var entry_panel := PanelContainer.new()
			var e_bg := Color(0.10, 0.14, 0.18, 0.92)
			var e_border := Color(0.25, 0.42, 0.48, 0.75)
			if entry_txt.contains("🚨"):
				e_bg = Color(0.22, 0.10, 0.10, 0.92)
				e_border = Color(0.85, 0.35, 0.35, 0.85)
			elif entry_txt.contains("🎯") or entry_txt.contains("🏆"):
				e_bg = Color(0.12, 0.18, 0.12, 0.92)
				e_border = Color(0.45, 0.85, 0.45, 0.85)
			elif entry_txt.contains("📰"):
				e_bg = Color(0.08, 0.16, 0.22, 0.95)
				e_border = Color(0.25, 0.70, 0.88, 0.85)

			var e_sb := GameData.make_stylebox(e_bg, e_border, 1, 6)
			e_sb.content_margin_left = 12
			e_sb.content_margin_right = 12
			e_sb.content_margin_top = 6
			e_sb.content_margin_bottom = 6
			entry_panel.add_theme_stylebox_override("panel", e_sb)

			var lbl := Label.new()
			lbl.text = entry_txt
			lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			lbl.add_theme_font_size_override("font_size", 12)
			lbl.add_theme_color_override("font_color", Color(0.92, 0.96, 0.94))
			entry_panel.add_child(lbl)

			journal_vbox.add_child(entry_panel)

	journal_panel.visible = true

func _setup_stats_breakdown_panel() -> void:
	stats_breakdown_panel = PanelContainer.new()
	stats_breakdown_panel.z_index = 148
	stats_breakdown_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	stats_breakdown_panel.add_theme_stylebox_override("panel", GameData.make_stylebox(Color(0.02, 0.05, 0.08, 0.90), Color(0, 0, 0, 0), 0, 0))
	stats_breakdown_panel.visible = false
	stats_breakdown_panel.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			stats_breakdown_panel.visible = false
	)
	add_child(stats_breakdown_panel)

	var center_box := PanelContainer.new()
	center_box.mouse_filter = Control.MOUSE_FILTER_STOP
	center_box.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	center_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	center_box.custom_minimum_size = Vector2(700, 624)
	var sb := GameData.make_stylebox(Color(0.07, 0.11, 0.15, 0.99), Color(0.35, 0.85, 0.65), 2, 12)
	sb.content_margin_left = 24
	sb.content_margin_right = 24
	sb.content_margin_top = 16
	sb.content_margin_bottom = 16
	center_box.add_theme_stylebox_override("panel", sb)
	stats_breakdown_panel.add_child(center_box)

	var main_vbox := VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 8)
	center_box.add_child(main_vbox)

	var title := Label.new()
	title.text = "📊 ŞEHİR KAYNAK BİLANÇOSU & COP31 METRİKLERİ"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(0.45, 0.96, 0.72))
	main_vbox.add_child(title)

	var sub := Label.new()
	sub.text = "Tüm binalarınızın günlük üretim, tüketim ve net kaynak akış bilançosu:"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 12)
	sub.add_theme_color_override("font_color", Color(0.72, 0.82, 0.86))
	main_vbox.add_child(sub)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(652, 485)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	main_vbox.add_child(scroll)

	stats_breakdown_vbox = VBoxContainer.new()
	stats_breakdown_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stats_breakdown_vbox.add_theme_constant_override("separation", 8)
	scroll.add_child(stats_breakdown_vbox)

	var close_btn := Button.new()
	close_btn.text = "✓ Kapat [Esc / I]"
	close_btn.custom_minimum_size = Vector2(190, 36)
	close_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close_btn.add_theme_stylebox_override("normal", GameData.make_stylebox(Color(0.16, 0.46, 0.32), Color(0.38, 0.88, 0.62), 2, 8))
	close_btn.add_theme_stylebox_override("hover", GameData.make_stylebox(Color(0.22, 0.58, 0.40), Color(0.55, 0.98, 0.75), 2, 8))
	close_btn.pressed.connect(func() -> void: stats_breakdown_panel.visible = false)
	main_vbox.add_child(close_btn)

func open_stats_breakdown(sim: GridSimulation) -> void:
	if stats_breakdown_panel == null or stats_breakdown_vbox == null:
		return
	for c in stats_breakdown_vbox.get_children():
		c.queue_free()

	var flow: Dictionary = sim.calculate_resource_flow_breakdown()
	var net_e: int = flow["e_prod"] - flow["e_cons"]
	var net_f: int = flow["f_prod"] - flow["f_cons"]
	var net_w: int = flow["w_prod"] - flow["w_cons"]
	var net_c: int = flow["c_emit"] - flow["c_sink"]
	var bio: Dictionary = sim.calculate_biodiversity()

	var categories := [
		{
			"title": "⚡ ENERJİ ŞEBEKESİ",
			"net": net_e,
			"desc": "Temiz & Fosil Üretim: +%d ⚡   |   Şehir Tüketimi: -%d ⚡   |   Net Günlük: %+d ⚡" % [flow["e_prod"], flow["e_cons"], net_e],
			"col": Color(1.0, 0.88, 0.35),
			"bg": Color(0.16, 0.15, 0.08, 0.92),
			"border": Color(0.65, 0.55, 0.25)
		},
		{
			"title": "🌱 GIDA GÜVENLİĞİ",
			"net": net_f,
			"desc": "Dikey Tarım Üretimi: +%d 🌱   |   Nüfus Tüketimi: -%d 🌱   |   Net Günlük: %+d 🌱" % [flow["f_prod"], flow["f_cons"], net_f],
			"col": Color(0.48, 0.95, 0.55),
			"bg": Color(0.08, 0.18, 0.10, 0.92),
			"border": Color(0.28, 0.65, 0.35)
		},
		{
			"title": "💧 SU REZERVLERİ",
			"net": net_w,
			"desc": "Arıtma & Göller: +%d 💧   |   Tesis İhtiyacı: -%d 💧   |   Net Günlük: %+d 💧\n🌊 Doğal Akifer Koruma: %d Doğal Göl (Kuraklık Direnci: %%%d)" % [flow["w_prod"], flow["w_cons"], net_w, flow.get("lakes_preserved", 0), mini(100, flow.get("lakes_preserved", 0) * 33)],
			"col": Color(0.40, 0.85, 1.0),
			"bg": Color(0.08, 0.15, 0.22, 0.92),
			"border": Color(0.25, 0.55, 0.75)
		},
		{
			"title": "☣ KARBON BİLANÇOSU & NET-SIFIR",
			"net": net_c,
			"desc": "Brüt Salım: +%d ☣   |   Yutulan (Orman & CCS): -%d ☣   |   Net Günlük: %+d ☣" % [flow["c_emit"], flow["c_sink"], net_c],
			"col": Color(0.42, 1.0, 0.68) if net_c <= 0 else Color(1.0, 0.42, 0.35),
			"bg": Color(0.08, 0.18, 0.14, 0.92) if net_c <= 0 else Color(0.22, 0.10, 0.08, 0.92),
			"border": Color(0.35, 0.85, 0.55) if net_c <= 0 else Color(0.85, 0.35, 0.28),
			"is_score": false
		},
		{
			"title": "🌿 COP31 BİYO-ÇEŞİTLİLİK & HABİTAT ENDEKSİ",
			"net": bio["score"],
			"desc": "Endeks: %d/100 (%s)\n🌲 Orman: %d  |  🌊 Göl: %d  |  🦋 Biyo-Koridor: %d  |  🌾 Tarım: %d  |  🔗 Eko-Bağlantı: %d Adet" % [bio["score"], bio["rating"], bio["forests"], bio["lakes"], bio["biocorridors"], bio["farms"], bio["corridor_links"]],
			"col": bio["color"],
			"bg": Color(0.06, 0.16, 0.12, 0.92),
			"border": bio["color"].darkened(0.25),
			"is_score": true
		}
	]

	for cat in categories:
		var card := PanelContainer.new()
		card.add_theme_stylebox_override("panel", GameData.make_stylebox(cat["bg"], cat["border"], 1, 8))
		var cvbox := VBoxContainer.new()
		cvbox.add_theme_constant_override("separation", 3)
		card.add_child(cvbox)

		var ctitle := Label.new()
		if cat.get("is_score", false):
			ctitle.text = "%s  (%d / 100)" % [cat["title"], cat["net"]]
		else:
			ctitle.text = "%s  (Net: %+d)" % [cat["title"], cat["net"]]
		ctitle.add_theme_font_size_override("font_size", 13)
		ctitle.add_theme_color_override("font_color", cat["col"])
		cvbox.add_child(ctitle)

		var cdesc := Label.new()
		cdesc.text = cat["desc"]
		cdesc.add_theme_font_size_override("font_size", 12)
		cdesc.add_theme_color_override("font_color", Color(0.90, 0.94, 0.92))
		cvbox.add_child(cdesc)

		stats_breakdown_vbox.add_child(card)

	# Demografik ve Sürdürülebilirlik Özeti
	var summary_card := PanelContainer.new()
	summary_card.add_theme_stylebox_override("panel", GameData.make_stylebox(Color(0.07, 0.12, 0.16, 0.92), Color(0.35, 0.65, 0.80), 1, 8))
	var svbox := VBoxContainer.new()
	svbox.add_theme_constant_override("separation", 3)
	summary_card.add_child(svbox)

	var stitle := Label.new()
	stitle.text = "🏛 ŞEHİR DEMOGRAFİSİ & SÜRDÜRÜLEBİLİRLİK"
	stitle.add_theme_font_size_override("font_size", 13)
	stitle.add_theme_color_override("font_color", Color(0.55, 0.92, 0.98))
	svbox.add_child(stitle)

	var sdesc := Label.new()
	sdesc.text = "👥 Toplam Nüfus: %s   |   COP31 Seviyesi: %s\n🌿 0-Karbon Zafer Serisi: %d/5   |   Aktif Bina Sayısı: %d   |   Gün: %d/25" % [
		String.num_int64(sim.calculate_city_population()),
		sim.get_climate_resilience_tier(),
		sim.zero_carbon_streak,
		flow["building_count"],
		sim.day
	]
	sdesc.add_theme_font_size_override("font_size", 12)
	sdesc.add_theme_color_override("font_color", Color(0.88, 0.94, 0.92))
	svbox.add_child(sdesc)

	stats_breakdown_vbox.add_child(summary_card)

	var chart := build_timeline_chart(sim, 600.0, 115.0)
	stats_breakdown_vbox.add_child(chart)

	# Karbon Emisyon Eğilimi ve Tarihçe Sparkline Kartı
	if not sim.carbon_history.is_empty():
		var hist_card := PanelContainer.new()
		hist_card.add_theme_stylebox_override("panel", GameData.make_stylebox(Color(0.06, 0.12, 0.16, 0.94), Color(0.25, 0.65, 0.82), 1, 6))
		var hvbox := VBoxContainer.new()
		hvbox.add_theme_constant_override("separation", 6)
		hist_card.add_child(hvbox)

		var h_title := Label.new()
		h_title.text = "📈 ŞEHİR KARBON TARİHÇESİ & EMİSYON EĞİLİMİ (Gün 1 ➔ %d)" % sim.day
		h_title.add_theme_font_size_override("font_size", 13)
		h_title.add_theme_color_override("font_color", Color(0.45, 0.92, 1.0))
		hvbox.add_child(h_title)

		var spark_hbox := HBoxContainer.new()
		spark_hbox.add_theme_constant_override("separation", 6)
		hvbox.add_child(spark_hbox)

		for d_idx in range(sim.carbon_history.size()):
			var c_val: int = sim.carbon_history[d_idx]
			var day_badge := PanelContainer.new()
			var b_bg := Color(0.08, 0.24, 0.14) if c_val <= 10 else (Color(0.24, 0.20, 0.08) if c_val <= 40 else Color(0.32, 0.10, 0.08))
			var b_brd := Color(0.35, 0.95, 0.55) if c_val <= 10 else (Color(1.0, 0.85, 0.35) if c_val <= 40 else Color(1.0, 0.38, 0.32))
			var sbox := GameData.make_stylebox(b_bg, b_brd, 1, 4)
			sbox.content_margin_left = 6
			sbox.content_margin_right = 6
			sbox.content_margin_top = 2
			sbox.content_margin_bottom = 2
			day_badge.add_theme_stylebox_override("panel", sbox)

			var d_lbl := Label.new()
			d_lbl.text = "G%d: %d☣" % [d_idx + 1, c_val]
			d_lbl.add_theme_font_size_override("font_size", 12)
			d_lbl.add_theme_color_override("font_color", Color(0.95, 0.98, 0.96))
			day_badge.add_child(d_lbl)
			spark_hbox.add_child(day_badge)

			if d_idx < sim.carbon_history.size() - 1:
				var arrow_lbl := Label.new()
				arrow_lbl.text = "➔"
				arrow_lbl.add_theme_font_size_override("font_size", 12)
				arrow_lbl.add_theme_color_override("font_color", Color(0.55, 0.65, 0.72))
				spark_hbox.add_child(arrow_lbl)

		stats_breakdown_vbox.add_child(hist_card)

	stats_breakdown_panel.visible = true

func _on_slot_selected(slot_num: int, save_mgr: SaveManager) -> void:
	save_mgr.select_slot(slot_num)
	update_start_screen_stats(save_mgr)
	update_slot_buttons_ui(save_mgr)
	rebuild_help_cards_ui(save_mgr)

func update_slot_buttons_ui(save_mgr: SaveManager) -> void:
	for i in range(slot_buttons.size()):
		var slot_num: int = i + 1
		var btn: Button = slot_buttons[i]
		var sum: Dictionary = save_mgr.get_slot_summary(slot_num)
		var is_cur: bool = (slot_num == save_mgr.current_slot)

		var status_text: String = ""
		if sum["has_active_run"]:
			status_text = "📅 Gün %d Seferi" % sum["day"]
		elif sum["exists"] and sum["games_won"] > 0:
			status_text = "🏆 %d Zafer • %d P" % [sum["games_won"], sum["score"]]
		elif sum["exists"] and sum["score"] > 0:
			status_text = "⭐ %d Puan" % sum["score"]
		else:
			status_text = "(Boş Profil)"

		var prefix: String = "[✓] " if is_cur else "[ ] "
		var suffix: String = " [AKTİF]" if is_cur else ""
		btn.text = "%sYUVA %d%s\n%s" % [prefix, slot_num, suffix, status_text]

		if is_cur:
			btn.add_theme_stylebox_override("normal", GameData.make_stylebox(Color(0.12, 0.32, 0.22, 0.95), Color(0.48, 0.98, 0.65), 2, 6))
			btn.add_theme_stylebox_override("hover", GameData.make_stylebox(Color(0.18, 0.44, 0.30, 0.98), Color(0.68, 1.0, 0.82), 2, 6))
			btn.add_theme_color_override("font_color", Color(0.92, 1.0, 0.95))
		else:
			btn.add_theme_stylebox_override("normal", GameData.make_stylebox(Color(0.08, 0.14, 0.18, 0.85), Color(0.22, 0.38, 0.46, 0.8), 1, 6))
			btn.add_theme_stylebox_override("hover", GameData.make_stylebox(Color(0.14, 0.24, 0.32, 0.95), Color(0.45, 0.75, 0.90), 2, 6))
			btn.add_theme_color_override("font_color", Color(0.70, 0.82, 0.88))

	for i in range(settings_slot_buttons.size()):
		var slot_num: int = i + 1
		var btn: Button = settings_slot_buttons[i]
		var is_cur: bool = (slot_num == save_mgr.current_slot)
		btn.text = "[✓] Yuva %d [Aktif]" % slot_num if is_cur else "[ ] Yuva %d" % slot_num
		if is_cur:
			btn.add_theme_stylebox_override("normal", GameData.make_stylebox(Color(0.14, 0.36, 0.24), Color(0.48, 0.98, 0.65), 2, 6))
			btn.add_theme_color_override("font_color", Color(0.95, 1.0, 0.95))
		else:
			btn.add_theme_stylebox_override("normal", GameData.make_stylebox(Color(0.10, 0.16, 0.22), Color(0.28, 0.40, 0.50), 1, 6))
			btn.add_theme_color_override("font_color", Color(0.70, 0.82, 0.88))

	if settings_reset_save_btn != null:
		settings_reset_save_btn.text = "⚠ Yuva %d İlerlemesini Sıfırla" % save_mgr.current_slot

func update_start_screen_stats(save_mgr: SaveManager) -> void:
	if start_stat_slot_lbl != null:
		start_stat_slot_lbl.text = "[ YUVA %d ]" % save_mgr.current_slot
	if start_stat_score_lbl != null:
		start_stat_score_lbl.text = "En Yüksek Skor: %d" % save_mgr.high_score
	if start_stat_ach_lbl != null:
		start_stat_ach_lbl.text = "Başarımlar: %d/%d" % [save_mgr.unlocked_achievements.size(), GameData.ACHIEVEMENTS.size()]
	if start_stat_cards_lbl != null:
		start_stat_cards_lbl.text = "Kartlar: %d/%d" % [save_mgr.unlocked_cards.size(), GameData.CARDS.size()]
	if start_stats_label != null:
		start_stats_label.text = "" 
	if resume_btn != null:
		if save_mgr.has_active_run():
			resume_btn.visible = true
			var r_day: int = int(save_mgr.active_run.get("day", 1))
			var r_scen: int = int(save_mgr.active_run.get("scenario", 0))
			var s_name: String = "Sonsuz Sandbox" if r_scen == 3 else ("Senaryo 3" if r_scen == 2 else ("Senaryo 2" if r_scen == 1 else "Senaryo 1"))
			resume_btn.text = "▶ DEVAM ET (Gün %d - %s)" % [r_day, s_name]
		else:
			resume_btn.visible = false
	update_slot_buttons_ui(save_mgr)
	update_mode_select_buttons(save_mgr)

func update_mode_select_buttons(save_mgr: SaveManager) -> void:
	if scen1_btn_node != null:
		var crown1: String = " 👑 [KAZANILDI]" if save_mgr.completed_scenarios.has(0) else ""
		scen1_btn_node.text = "🌱 Standart Ekoloji%s\n\n⚡ 10   🌱 10   💧 10   |   ☣ 20\n• Dengeli iklim geçişi (Önerilen)" % crown1
	if scen2_btn_node != null:
		var crown2: String = " 👑 [KAZANILDI]" if save_mgr.completed_scenarios.has(1) else ""
		scen2_btn_node.text = "🏭 Sanayi Mirası (Zor)%s\n\n⚡ 12   🌱 10   💧 10   |   ☣ 42\n• Kömür kirliliğini temizle" % crown2
	if scen3_btn_node != null:
		var crown3: String = " 👑 [KAZANILDI]" if save_mgr.completed_scenarios.has(2) else ""
		scen3_btn_node.text = "🏜 Kuraklık Vahası%s\n\n⚡ 16   🌱 10   💧 5 (Kritik!)   |   ☣ 16\n• Çölleşmeye karşı su direnci" % crown3
	if scen4_btn_node != null:
		var crown4: String = " 👑 [KAZANILDI]" if save_mgr.completed_scenarios.has(3) else ""
		scen4_btn_node.text = "♾ Sonsuz Sandbox%s\n\n⚡ 14   🌱 14   💧 14   |   ☣ 25\n• Süresiz serbest inşaat & test" % crown4

func update_undo_button(sim: GridSimulation) -> void:
	if undo_button == null:
		return
	undo_button.disabled = not (sim.undo_available and sim.undo_remaining_today > 0)
	undo_button.text = "↩ Geri (%d) [Z]" % sim.undo_remaining_today

func set_game_hud_visible(vis: bool) -> void:
	if top_bar_panel != null:
		top_bar_panel.visible = vis
	if left_perks_panel_node != null:
		left_perks_panel_node.visible = vis
	if bottom_panel_node != null:
		bottom_panel_node.visible = vis
	if to_menu_btn_node != null:
		to_menu_btn_node.visible = vis
	if end_turn_button != null:
		end_turn_button.visible = vis
	if not vis and carbon_lens_banner != null:
		carbon_lens_banner.visible = false
	if not vis and onboarding_panel != null:
		onboarding_panel.visible = false
	if not vis:
		if crisis_panel != null:
			crisis_panel.visible = false
		if quest_toast_panel != null:
			quest_toast_panel.visible = false
		if day_recap_panel != null:
			day_recap_panel.visible = false
		if deck_inspector_panel != null:
			deck_inspector_panel.visible = false
		if journal_panel != null:
			journal_panel.visible = false
		card_nodes.clear()
		if hand_container != null:
			for c in hand_container.get_children():
				c.queue_free()

func toggle_photo_mode() -> bool:
	is_photo_mode = not is_photo_mode
	set_game_hud_visible(not is_photo_mode)
	if is_photo_mode:
		if photo_watermark == null:
			photo_watermark = PanelContainer.new()
			photo_watermark.anchor_left = 0.5
			photo_watermark.anchor_right = 0.5
			photo_watermark.offset_left = -230
			photo_watermark.offset_right = 230
			photo_watermark.offset_top = 18
			photo_watermark.offset_bottom = 56
			photo_watermark.add_theme_stylebox_override("panel", GameData.make_stylebox(Color(0.08, 0.12, 0.16, 0.88), Color(0.35, 0.88, 0.72), 1, 8))
			var w_lbl := Label.new()
			w_lbl.text = "🌱 ECO-GRID: 2050 | Sinematik Görünüm [Kapat: F]"
			w_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			w_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			w_lbl.add_theme_font_size_override("font_size", 13)
			w_lbl.add_theme_color_override("font_color", Color(0.92, 0.98, 0.95))
			photo_watermark.add_child(w_lbl)
			add_child(photo_watermark)
		photo_watermark.visible = true
	else:
		if photo_watermark != null:
			photo_watermark.visible = false
	return is_photo_mode

func _process(delta: float) -> void:
	if day_recap_timer > 0.0:
		day_recap_timer -= delta
		if day_recap_timer <= 0.8:
			day_recap_panel.modulate.a = maxf(0.0, day_recap_timer / 0.8)
		if day_recap_timer <= 0.0:
			day_recap_panel.visible = false

	if quest_toast_timer > 0.0:
		quest_toast_timer -= delta
		if quest_toast_timer <= 0.8:
			quest_toast_panel.modulate.a = maxf(0.0, quest_toast_timer / 0.8)
		if quest_toast_timer <= 0.0:
			quest_toast_panel.visible = false

func show_day_recap(day_num: int, turn_prod: Dictionary, zero_streak: int, news: String = "") -> void:
	if day_recap_panel == null or day_recap_label == null:
		return
	var streak_note: String = (" | 🌟 0-Karbon: %d/5" % zero_streak) if zero_streak > 0 else ""
	var recap_text := "🌅 GÜN %d BAŞLADI — Net Üretim: ⚡%+d  🌱%+d  💧%+d  ☣%+d%s" % [
		day_num, turn_prod["e"], turn_prod["f"], turn_prod["w"], turn_prod["c"], streak_note
	]
	if not news.is_empty():
		recap_text += "\n" + news
		day_recap_panel.custom_minimum_size = Vector2(760, 68)
	else:
		day_recap_panel.custom_minimum_size = Vector2(520, 44)
	day_recap_label.text = recap_text
	day_recap_panel.visible = true
	day_recap_panel.modulate.a = 1.0
	day_recap_timer = 4.2

func show_quest_toast(msg: String) -> void:
	if quest_toast_panel == null or quest_toast_label == null:
		return
	if day_recap_panel != null and day_recap_panel.visible:
		quest_toast_panel.offset_top = 126
	else:
		quest_toast_panel.offset_top = 76
	quest_toast_label.text = msg
	quest_toast_panel.visible = true
	quest_toast_panel.modulate.a = 1.0
	quest_toast_timer = 3.2

func update_discard_button_style(discard_mode: bool) -> void:
	if discard_mode_button == null:
		return
	if discard_mode:
		discard_mode_button.text = "🗑 Açık [X]"
		discard_mode_button.add_theme_stylebox_override("normal", GameData.make_stylebox(Color(0.62, 0.18, 0.18), Color(1.0, 0.52, 0.48), 2, 6))
		discard_mode_button.add_theme_stylebox_override("hover", GameData.make_stylebox(Color(0.72, 0.24, 0.24), Color(1.0, 0.68, 0.62), 2, 6))
	else:
		discard_mode_button.text = "🗑 At [X]"
		discard_mode_button.add_theme_stylebox_override("normal", GameData.make_stylebox(Color(0.28, 0.15, 0.18), Color(0.72, 0.36, 0.38), 2, 6))
		discard_mode_button.add_theme_stylebox_override("hover", GameData.make_stylebox(Color(0.38, 0.20, 0.24), Color(0.92, 0.48, 0.48), 2, 6))

func update_lens_button_style(active: bool) -> void:
	if lens_button == null:
		return
	if active:
		lens_button.text = "👁 AÇIK [V]"
		lens_button.add_theme_stylebox_override("normal", GameData.make_stylebox(Color(0.12, 0.44, 0.32), Color(0.45, 1.0, 0.72), 2, 6))
		lens_button.add_theme_stylebox_override("hover", GameData.make_stylebox(Color(0.18, 0.54, 0.38), Color(0.65, 1.0, 0.85), 2, 6))
	else:
		lens_button.text = "👁 Lens [V]"
		lens_button.add_theme_stylebox_override("normal", GameData.make_stylebox(Color(0.16, 0.22, 0.28), Color(0.38, 0.55, 0.68), 2, 6))
		lens_button.add_theme_stylebox_override("hover", GameData.make_stylebox(Color(0.22, 0.30, 0.38), Color(0.55, 0.75, 0.90), 2, 6))

func set_carbon_lens_banner_visible(vis: bool) -> void:
	if carbon_lens_banner != null:
		carbon_lens_banner.visible = vis

func _update_help_tabs_style() -> void:
	if help_tab_cards_btn == null or help_tab_ach_btn == null:
		return
	var active_card := GameData.make_stylebox(Color(0.18, 0.44, 0.34), Color(0.45, 0.96, 0.68), 2, 8)
	var hover_card := GameData.make_stylebox(Color(0.24, 0.52, 0.40), Color(0.60, 1.0, 0.78), 2, 8)
	var active_ach := GameData.make_stylebox(Color(0.32, 0.26, 0.12), Color(1.0, 0.84, 0.35), 2, 8)
	var hover_ach := GameData.make_stylebox(Color(0.42, 0.34, 0.16), Color(1.0, 0.92, 0.50), 2, 8)
	var active_evolve := GameData.make_stylebox(Color(0.14, 0.32, 0.46), Color(0.38, 0.88, 1.0), 2, 8)
	var hover_evolve := GameData.make_stylebox(Color(0.20, 0.40, 0.56), Color(0.55, 0.96, 1.0), 2, 8)
	var inactive := GameData.make_stylebox(Color(0.12, 0.16, 0.20), Color(0.35, 0.42, 0.48), 1, 8)
	var hover_inactive := GameData.make_stylebox(Color(0.18, 0.24, 0.30), Color(0.55, 0.65, 0.75), 1, 8)

	help_tab_cards_btn.add_theme_stylebox_override("normal", active_card if help_active_tab == 0 else inactive)
	help_tab_cards_btn.add_theme_stylebox_override("hover", hover_card if help_active_tab == 0 else hover_inactive)

	help_tab_ach_btn.add_theme_stylebox_override("normal", active_ach if help_active_tab == 1 else inactive)
	help_tab_ach_btn.add_theme_stylebox_override("hover", hover_ach if help_active_tab == 1 else hover_inactive)

	if help_tab_evolve_btn != null:
		help_tab_evolve_btn.add_theme_stylebox_override("normal", active_evolve if help_active_tab == 2 else inactive)
		help_tab_evolve_btn.add_theme_stylebox_override("hover", hover_evolve if help_active_tab == 2 else hover_inactive)

func toggle_game_speed() -> float:
	is_fast_speed = not is_fast_speed
	var target_scale: float = 1.75 if is_fast_speed else 1.0
	Engine.time_scale = target_scale
	if speed_btn != null:
		if is_fast_speed:
			speed_btn.text = "⏩ 1.75x [T]"
			speed_btn.add_theme_stylebox_override("normal", GameData.make_stylebox(Color(0.35, 0.28, 0.12), Color(1.0, 0.84, 0.32), 2, 6))
			speed_btn.add_theme_stylebox_override("hover", GameData.make_stylebox(Color(0.45, 0.36, 0.16), Color(1.0, 0.94, 0.45), 2, 6))
		else:
			speed_btn.text = "⚡ 1x [T]"
			speed_btn.add_theme_stylebox_override("normal", GameData.make_stylebox(Color(0.20, 0.22, 0.28), Color(0.48, 0.65, 0.85), 2, 6))
			speed_btn.add_theme_stylebox_override("hover", GameData.make_stylebox(Color(0.26, 0.30, 0.38), Color(0.65, 0.85, 1.0), 2, 6))
	return target_scale

func rebuild_help_cards_ui(save_mgr: SaveManager) -> void:
	cached_save_mgr = save_mgr
	if help_cards_grid == null or help_codex_header == null:
		return
	for child in help_cards_grid.get_children():
		child.queue_free()

	_update_help_tabs_style()

	var unlocked_cards: Array[int] = save_mgr.unlocked_cards
	var total_cards: int = GameData.CARDS.size()
	var unlocked_count: int = unlocked_cards.size()

	if help_tab_cards_btn != null:
		help_tab_cards_btn.text = "🃏 Kart Koleksiyonu (%d/%d)" % [unlocked_count, total_cards]
	if help_tab_ach_btn != null:
		help_tab_ach_btn.text = "🏆 Başarımlar (%d/%d)" % [save_mgr.unlocked_achievements.size(), GameData.ACHIEVEMENTS.size()]

	if help_active_tab == 0:
		help_codex_header.text = "📚 KART KOLEKSİYONU (%d/%d) — Oyunda oynadığınız kartların sırları açılır" % [
			unlocked_count, total_cards
		]
		for card_id in GameData.CARDS.keys():
			var cid: int = int(card_id)
			var info: Dictionary = GameData.CARDS[cid]
			var is_unlocked: bool = unlocked_cards.has(cid)

			var entry_panel := PanelContainer.new()
			entry_panel.custom_minimum_size = Vector2(395, 92)
			entry_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

			if is_unlocked:
				entry_panel.add_theme_stylebox_override("panel", GameData.make_stylebox(Color(0.10, 0.16, 0.20, 0.96), info["color"], 2, 8))
				var vbox := VBoxContainer.new()
				vbox.add_theme_constant_override("separation", 3)
				entry_panel.add_child(vbox)

				var title_lbl := Label.new()
				title_lbl.text = "🔓 %s %s   (%s)" % [info["symbol"], info["title"], info["cost_text"]]
				title_lbl.add_theme_font_size_override("font_size", 14)
				title_lbl.add_theme_color_override("font_color", info["color"].lightened(0.3))
				vbox.add_child(title_lbl)

				var desc_lbl := Label.new()
				desc_lbl.text = info["desc"]
				desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				desc_lbl.add_theme_font_size_override("font_size", 12)
				desc_lbl.add_theme_color_override("font_color", Color(0.90, 0.95, 0.92))
				vbox.add_child(desc_lbl)

				var fact_lbl := Label.new()
				fact_lbl.text = info["fact"]
				fact_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				fact_lbl.add_theme_font_size_override("font_size", 12)
				fact_lbl.add_theme_color_override("font_color", Color(0.58, 0.88, 0.72))
				vbox.add_child(fact_lbl)
			else:
				entry_panel.add_theme_stylebox_override("panel", GameData.make_stylebox(Color(0.08, 0.09, 0.11, 0.92), Color(0.28, 0.32, 0.38), 2, 8))
				var vbox := VBoxContainer.new()
				vbox.alignment = BoxContainer.ALIGNMENT_CENTER
				vbox.add_theme_constant_override("separation", 4)
				entry_panel.add_child(vbox)

				var lock_title := Label.new()
				lock_title.text = "🔒 ??? [KİLİTLİ KART]"
				lock_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				lock_title.add_theme_font_size_override("font_size", 14)
				lock_title.add_theme_color_override("font_color", Color(0.55, 0.60, 0.66))
				vbox.add_child(lock_title)

				var lock_desc := Label.new()
				lock_desc.text = "Bu kartın bilgilerini açmak için oyun içinde en az 1 kez oynayın."
				lock_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				lock_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				lock_desc.add_theme_font_size_override("font_size", 12)
				lock_desc.add_theme_color_override("font_color", Color(0.45, 0.50, 0.56))
				vbox.add_child(lock_desc)

			help_cards_grid.add_child(entry_panel)

	elif help_active_tab == 1:
		help_codex_header.text = "🏆 BAŞARIMLAR (%d/%d) — En Yüksek Eko-Skor: %d  |  Kazanılan Oyun: %d" % [
			save_mgr.unlocked_achievements.size(), GameData.ACHIEVEMENTS.size(), save_mgr.high_score, save_mgr.games_won
		]
		for ach in GameData.ACHIEVEMENTS:
			var has_ach: bool = save_mgr.unlocked_achievements.has(ach["id"])
			var ach_panel := PanelContainer.new()
			ach_panel.custom_minimum_size = Vector2(395, 78)
			ach_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			var b_col: Color = Color(1.0, 0.84, 0.32) if has_ach else Color(0.28, 0.32, 0.38)
			var bg_c: Color = Color(0.18, 0.16, 0.08, 0.95) if has_ach else Color(0.08, 0.09, 0.11, 0.90)
			ach_panel.add_theme_stylebox_override("panel", GameData.make_stylebox(bg_c, b_col, 2, 8))

			var avbox := VBoxContainer.new()
			avbox.add_theme_constant_override("separation", 3)
			ach_panel.add_child(avbox)

			var atitle := Label.new()
			atitle.text = ("%s  [✓ TAMAMLANDI]" if has_ach else "🔒 %s  [KİLİTLİ]") % ach["title"]
			atitle.add_theme_font_size_override("font_size", 14)
			atitle.add_theme_color_override("font_color", Color(1.0, 0.90, 0.45) if has_ach else Color(0.60, 0.65, 0.70))
			avbox.add_child(atitle)

			var adesc := Label.new()
			adesc.text = ach["desc"]
			adesc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			adesc.add_theme_font_size_override("font_size", 12)
			adesc.add_theme_color_override("font_color", Color(0.88, 0.95, 0.90) if has_ach else Color(0.48, 0.52, 0.58))
			avbox.add_child(adesc)

			help_cards_grid.add_child(ach_panel)

	else:
		help_codex_header.text = "🏛 SÜRDÜRÜLEBİLİR YAPI EVRİMİ (12/12) — Lv.1 Temel ➔ Lv.2 Gelişmiş (★) ➔ Lv.3 Mega-Tesis (★★)"
		var evolution_catalog: Array[Dictionary] = [
			{
				"title": "Güneş Enerji Kompleksi", "icon": "☀", "cat": "⚡ Temiz Enerji", "col": Color(0.95, 0.76, 0.15),
				"lv1": "Lv.1 Güneş Paneli: ⚡+3  💧-1 (Konut komşusu: ⚡+1)",
				"lv2": "Lv.2 Gelişmiş Güneş Çiftliği ★: ⚡+5  💧-1 (Güneşli havada: ⚡+1)",
				"lv3": "Lv.3 Mega Güneş Kompleksi ★★: ⚡+8  💧0 (Sıfır su kaybı fotovoltaik; Konut: ⚡+2)"
			},
			{
				"title": "Manyetik Rüzgar Türbini", "icon": "🌀", "cat": "⚡ Temiz Enerji", "col": Color(0.35, 0.78, 0.95),
				"lv1": "Lv.1 Rüzgar Türbini: ⚡+3  💧-2 (Açık izole alanda: ⚡+2)",
				"lv2": "Lv.2 Gelişmiş Rüzgar Türbini ★: ⚡+5  💧-2 (Tatlı meltemde: ⚡+1)",
				"lv3": "Lv.3 Mega Manyetik Rüzgar Kulesi ★★: ⚡+8  💧-1 (Mag-Lev sürtünmesiz türbin; Açık: ⚡+3)"
			},
			{
				"title": "Kentsel Eko-Konut & Arkoloji", "icon": "🏠", "cat": "🏡 Kentsel Yaşam", "col": Color(0.92, 0.52, 0.24),
				"lv1": "Lv.1 Eko-Konut: 🌱-2  💧-1  👥+150 (Orman/Göl komşusu: 🌱+1 tasarruf)",
				"lv2": "Lv.2 Gelişmiş Eko-Konut ★: 🌱-2  💧-1  👥+350 (Güneş çatılı biyofilik konut)",
				"lv3": "Lv.3 Mega Eko-Arkoloji ★★: 🌱-1  💧-1  👥+800 (Dikey biyofilik mega-şehir yapısı)"
			},
			{
				"title": "Dikey Tarım & Biyo-Kubbe", "icon": "🌾", "cat": "🌾 Gıda Güvenliği", "col": Color(0.55, 0.82, 0.22),
				"lv1": "Lv.1 Dikey Tarım: 🌱+3  ⚡-1 (Su arıtma/Göl komşusu: 🌱+1)",
				"lv2": "Lv.2 Gelişmiş Dikey Tarım ★: 🌱+5  ⚡-1 (Hidroponik LED otomasyonu)",
				"lv3": "Lv.3 Mega Dikey Biyo-Kubbe ★★: 🌱+8  ⚡-1 (Otonom dron polinizasyonu & sıfır su kaybı)"
			},
			{
				"title": "Kent Ormanı & Biyosfer", "icon": "🌲", "cat": "🌲 Doğal Ekosistem", "col": Color(0.16, 0.62, 0.34),
				"lv1": "Lv.1 Kent Ormanı: ☣-3  🌱+1 (Göl komşusu: ☣-1 ek karbon yutağı)",
				"lv2": "Lv.2 Gelişmiş Kent Ormanı ★: ☣-5  🌱+2 (Çok katmanlı serinletici mikro-ekosistem)",
				"lv3": "Lv.3 Mega Kadim Biyosfer Ormanı ★★: ☣-8  🌱+3  💧+1 (Kadim flora & mikorizal ağ)"
			},
			{
				"title": "Karbon Yakalama (CCS)", "icon": "🧪", "cat": "🧪 İklim Mühendisliği", "col": Color(0.45, 0.88, 0.92),
				"lv1": "Lv.1 Karbon Yakalama: ☣-4  ⚡-2 (Kirli sanayi komşusu: ☣-2)",
				"lv2": "Lv.2 Gelişmiş Karbon Yakalama ★: ☣-7  ⚡-2 (Çift türbin doğrudan hava yakalama DAC)",
				"lv3": "Lv.3 Mega Karbon Yakalama Kulesi ★★: ☣-12  ⚡-3 (Jeolojik mineralizasyon ile CO2 taşı)"
			},
			{
				"title": "Su Arıtma Tesisi", "icon": "🚰", "cat": "🚰 Su Güvenliği", "col": Color(0.20, 0.48, 0.88),
				"lv1": "Lv.1 Su Arıtma: 💧+3  ⚡-1 (Göl/Deniz komşusu: 💧+1)",
				"lv2": "Lv.2 Gelişmiş Su Arıtma ★: 💧+5  ⚡-1 (Çift ozon havuzlu ileri filtrasyon)",
				"lv3": "Lv.3 Mega Su Fabrikası ★★: 💧+8  ⚡-1 (Ters osmoz ve biyo-membran döngüsü)"
			},
			{
				"title": "Jeotermal Santral", "icon": "🌋", "cat": "⚡ Taban Güç", "col": Color(0.95, 0.48, 0.22),
				"lv1": "Lv.1 Jeotermal Santral: ⚡+4  💧-1 (Kesintisiz 24/7 taban temiz elektrik)",
				"lv2": "Lv.2 Gelişmiş Jeotermal ★: ⚡+6  💧-1 (Çift buhar kubbesi & derin kuyu geri enjeksiyonu)",
				"lv3": "Lv.3 Mega Derin Jeotermal Tesis ★★: ⚡+10  💧-1 (Magma katmanı termal dönüştürücü)"
			},
			{
				"title": "Geri Dönüşüm Tesisi", "icon": "♻", "cat": "♻ Döngüsel Ekonomi", "col": Color(0.22, 0.74, 0.64),
				"lv1": "Lv.1 Geri Dönüşüm: 💧+1  ⚡+1 (Konut komşularından atık geri kazanımı)",
				"lv2": "Lv.2 Gelişmiş Geri Dönüşüm ★: 💧+2  ⚡+2 (Ayrıştırma serası & biyo-kompost)",
				"lv3": "Lv.3 Mega Sıfır Atık Kompleksi ★★: 💧+3  ⚡+3  ☣-2 (Tam döngüsel atıksız ekosistem)"
			},
			{
				"title": "Ekolojik Biyo-Koridor", "icon": "🦋", "cat": "🦋 Ekosistem Köprüsü", "col": Color(0.38, 0.92, 0.55),
				"lv1": "Lv.1 Biyo-Koridor: 🌱+2  ☣-1 (Ormanlar arasında polen & yaban göç hattı)",
				"lv2": "Lv.2 Gelişmiş Biyo-Koridor ★: 🌱+4  ☣-2 (Eko-otoyol viyadüğü ve çiçekli polen şeridi)",
				"lv3": "Lv.3 Mega Ekosistem Otoyolu ★★: 🌱+6  ☣-3 (Bölgesel flora-fauna göç arteri)"
			},
			{
				"title": "Şebeke Bataryası", "icon": "🔋", "cat": "🔋 Şebeke Güvenliği", "col": Color(0.24, 0.88, 0.72),
				"lv1": "Lv.1 Şebeke Bataryası: ⚡+2 (Üretim dalgalanmalarını dengeler, çöküşü önler)",
				"lv2": "Lv.2 Dağıtık Şebeke Bataryası ★: ⚡+4 (4 silindirli sıvı akış depolama modülü)",
				"lv3": "Lv.3 Mega Kuantum Enerji Deposu ★★: ⚡+7 (Katı-hal elektrolit ile sıfır kayıplı mega rezerv)"
			},
			{
				"title": "COP31 Diplomasi Merkezi", "icon": "🏛", "cat": "🏛 Küresel Zirve", "col": Color(0.35, 0.72, 1.0),
				"lv1": "Lv.1 Yerel İklim Merkezi: ⚡+2  💧+2  🌱+2  ☣-3 (Bölgesel iklim direnç izleme)",
				"lv2": "Lv.2 COP31 Diplomasi Merkezi ★: ⚡+4  💧+4  🌱+4  ☣-6 (Uluslararası mutabakat & yeşil fon)",
				"lv3": "Lv.3 Mega COP31 Zirvesi Kompleksi ★★: ⚡+6  💧+6  🌱+6  ☣-10 (Küresel Net-Sıfır İklim Zirvesi)"
			}
		]
		for bldg in evolution_catalog:
			var panel := PanelContainer.new()
			panel.custom_minimum_size = Vector2(395, 116)
			panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			var col: Color = bldg["col"]
			panel.add_theme_stylebox_override("panel", GameData.make_stylebox(Color(0.08, 0.12, 0.16, 0.96), col, 2, 8))

			var vb := VBoxContainer.new()
			vb.add_theme_constant_override("separation", 3)
			panel.add_child(vb)

			var header_lbl := Label.new()
			header_lbl.text = "%s %s  —  [%s]" % [bldg["icon"], bldg["title"], bldg["cat"]]
			header_lbl.add_theme_font_size_override("font_size", 13)
			header_lbl.add_theme_color_override("font_color", col.lightened(0.35))
			vb.add_child(header_lbl)

			var l1 := Label.new()
			l1.text = "• " + bldg["lv1"]
			l1.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			l1.add_theme_font_size_override("font_size", 11)
			l1.add_theme_color_override("font_color", Color(0.85, 0.94, 0.88))
			vb.add_child(l1)

			var l2 := Label.new()
			l2.text = "• " + bldg["lv2"]
			l2.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			l2.add_theme_font_size_override("font_size", 11)
			l2.add_theme_color_override("font_color", Color(1.0, 0.90, 0.45))
			vb.add_child(l2)

			var l3 := Label.new()
			l3.text = "• " + bldg["lv3"]
			l3.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			l3.add_theme_font_size_override("font_size", 11)
			l3.add_theme_color_override("font_color", Color(0.45, 0.92, 1.0))
			vb.add_child(l3)

			var hint_lbl := Label.new()
			hint_lbl.text = "💡 Yükseltme: Aynı kartı üstüne oynayın veya ✨ Modüler Yükseltme kullanın."
			hint_lbl.add_theme_font_size_override("font_size", 10)
			hint_lbl.add_theme_color_override("font_color", Color(0.60, 0.72, 0.78))
			vb.add_child(hint_lbl)

			help_cards_grid.add_child(panel)

func rebuild_perks_ui(sim: GridSimulation) -> void:
	for child in perks_vbox.get_children():
		child.queue_free()

	var pop_val: int = sim.calculate_city_population()
	var tier_str: String = sim.get_climate_resilience_tier()
	var pop_lbl := Label.new()
	pop_lbl.text = "%s\n👥 Nüfus: %s" % [tier_str, String.num_int64(pop_val)]
	pop_lbl.add_theme_font_size_override("font_size", 12)
	pop_lbl.add_theme_color_override("font_color", Color(0.45, 0.95, 0.75))
	pop_lbl.mouse_filter = Control.MOUSE_FILTER_STOP
	pop_lbl.tooltip_text = "Şehir Nüfusu & COP31 İklim Direnç Seviyesi.\nEko-Konut inşa ederek ve ormanlarla çevreleyerek nüfusu ve dayanıklılığı artırın!"
	perks_vbox.add_child(pop_lbl)

	var sep := HSeparator.new()
	sep.add_theme_stylebox_override("separator", GameData.make_stylebox(Color(0.25, 0.45, 0.38, 0.5), Color(0, 0, 0, 0), 1, 0))
	perks_vbox.add_child(sep)

	var q_header := Label.new()
	q_header.text = "🎯 COP31 Görevleri:"
	q_header.add_theme_font_size_override("font_size", 12)
	q_header.add_theme_color_override("font_color", Color(0.98, 0.88, 0.42))
	perks_vbox.add_child(q_header)

	var q1 := Label.new()
	q1.text = ("%s 1 Kömür Yık (⚡+4,💧+4)" % ("✅" if sim.quests_completed["coal"] else "⬜"))
	q1.add_theme_font_size_override("font_size", 12)
	q1.add_theme_color_override("font_color", Color(0.55, 0.95, 0.68) if sim.quests_completed["coal"] else Color(0.82, 0.86, 0.84))
	perks_vbox.add_child(q1)

	var q2 := Label.new()
	q2.text = ("%s 3 Orman Kur (%d/3) (☣-8)" % ["✅" if sim.quests_completed["forest"] else "⬜", mini(3, sim.stats_forests_planted)])
	q2.add_theme_font_size_override("font_size", 12)
	q2.add_theme_color_override("font_color", Color(0.55, 0.95, 0.68) if sim.quests_completed["forest"] else Color(0.82, 0.86, 0.84))
	perks_vbox.add_child(q2)

	var q3 := Label.new()
	q3.text = ("%s 2x Lv.2★ Yükselt (%d/2) (🌱+5)" % ["✅" if sim.quests_completed["upgrade"] else "⬜", mini(2, sim.stats_upgrades_done)])
	q3.add_theme_font_size_override("font_size", 12)
	q3.add_theme_color_override("font_color", Color(0.55, 0.95, 0.68) if sim.quests_completed["upgrade"] else Color(0.82, 0.86, 0.84))
	perks_vbox.add_child(q3)

	var q4 := Label.new()
	q4.text = ("%s 1x Lv.3★★ Mega Kur (⚡+6,💧+6)" % ("✅" if sim.quests_completed.get("mega", false) else "⬜"))
	q4.add_theme_font_size_override("font_size", 12)
	q4.add_theme_color_override("font_color", Color(0.55, 0.95, 0.68) if sim.quests_completed.get("mega", false) else Color(0.82, 0.86, 0.84))
	perks_vbox.add_child(q4)

	var header_hbox := HBoxContainer.new()
	header_hbox.add_theme_constant_override("separation", 6)
	perks_vbox.add_child(header_hbox)

	var header := Label.new()
	header.text = "⚖ Yasalar (%d)" % sim.active_perks.size()
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_theme_font_size_override("font_size", 12)
	header.add_theme_color_override("font_color", Color(0.55, 0.92, 0.72))
	header_hbox.add_child(header)

	var tools_hbox := HBoxContainer.new()
	tools_hbox.add_theme_constant_override("separation", 4)
	perks_vbox.add_child(tools_hbox)

	var deck_inspect_btn := Button.new()
	deck_inspect_btn.text = " %d" % sim.deck.size()
	if ResourceLoader.exists("res://assets/sprites/icon_cards.png"):
		deck_inspect_btn.icon = load("res://assets/sprites/icon_cards.png")
		deck_inspect_btn.expand_icon = true
	deck_inspect_btn.tooltip_text = "Destenizdeki kart dağılımı ve çekilme olasılıkları [Kısayol: K]"
	deck_inspect_btn.custom_minimum_size = Vector2(48, 26)
	deck_inspect_btn.add_theme_font_size_override("font_size", 12)
	deck_inspect_btn.add_theme_stylebox_override("normal", GameData.make_stylebox(Color(0.12, 0.24, 0.22), Color(0.38, 0.78, 0.65), 1, 4))
	deck_inspect_btn.add_theme_stylebox_override("hover", GameData.make_stylebox(Color(0.18, 0.35, 0.30), Color(0.55, 0.95, 0.80), 1, 4))
	deck_inspect_btn.pressed.connect(func() -> void: open_deck_inspector(sim, false))
	tools_hbox.add_child(deck_inspect_btn)

	var discard_inspect_btn := Button.new()
	discard_inspect_btn.text = "🗑 %d" % sim.discard_pile.size()
	discard_inspect_btn.tooltip_text = "Iskarta destesini ve kullanılan kartları inceleyin"
	discard_inspect_btn.custom_minimum_size = Vector2(0, 26)
	discard_inspect_btn.add_theme_font_size_override("font_size", 12)
	discard_inspect_btn.add_theme_stylebox_override("normal", GameData.make_stylebox(Color(0.24, 0.14, 0.16), Color(0.78, 0.38, 0.42), 1, 4))
	discard_inspect_btn.add_theme_stylebox_override("hover", GameData.make_stylebox(Color(0.35, 0.18, 0.22), Color(0.95, 0.52, 0.58), 1, 4))
	discard_inspect_btn.pressed.connect(func() -> void: open_deck_inspector(sim, true))
	tools_hbox.add_child(discard_inspect_btn)

	var journal_btn := Button.new()
	journal_btn.text = "📜 Günlük"
	journal_btn.tooltip_text = "Şehir olay kaydı ve geçmişini inceleyin [Kısayol: L]"
	journal_btn.custom_minimum_size = Vector2(0, 26)
	journal_btn.add_theme_font_size_override("font_size", 12)
	journal_btn.add_theme_stylebox_override("normal", GameData.make_stylebox(Color(0.12, 0.22, 0.26), Color(0.35, 0.65, 0.82), 1, 4))
	journal_btn.add_theme_stylebox_override("hover", GameData.make_stylebox(Color(0.18, 0.32, 0.38), Color(0.50, 0.85, 1.0), 1, 4))
	journal_btn.pressed.connect(func() -> void: open_journal_modal(sim))
	tools_hbox.add_child(journal_btn)

	var flow_btn := Button.new()
	flow_btn.text = "📊 Bilanço"
	flow_btn.tooltip_text = "Şehrin detaylı kaynak üretim, tüketim ve karbon bilançosunu inceleyin [Kısayol: I]"
	flow_btn.custom_minimum_size = Vector2(0, 26)
	flow_btn.add_theme_font_size_override("font_size", 12)
	flow_btn.add_theme_stylebox_override("normal", GameData.make_stylebox(Color(0.24, 0.22, 0.14), Color(0.78, 0.68, 0.32), 1, 4))
	flow_btn.add_theme_stylebox_override("hover", GameData.make_stylebox(Color(0.34, 0.30, 0.18), Color(0.95, 0.85, 0.42), 1, 4))
	flow_btn.pressed.connect(func() -> void: open_stats_breakdown(sim))
	tools_hbox.add_child(flow_btn)

	if sim.active_perks.is_empty():
		var none_lbl := Label.new()
		none_lbl.text = "Henüz yasa seçilmedi (3 günde bir)"
		none_lbl.add_theme_font_size_override("font_size", 12)
		none_lbl.add_theme_color_override("font_color", Color(0.62, 0.70, 0.68))
		perks_vbox.add_child(none_lbl)
	else:
		for perk_id in sim.active_perks:
			for p in GameData.PERKS:
				if p["id"] == perk_id:
					var lbl := Label.new()
					lbl.text = "• " + p["title"]
					lbl.tooltip_text = "%s\n%s" % [p["title"], p.get("desc", "")]
					lbl.mouse_filter = Control.MOUSE_FILTER_STOP
					lbl.add_theme_font_size_override("font_size", 12)
					lbl.add_theme_color_override("font_color", Color(0.92, 0.96, 0.94))
					perks_vbox.add_child(lbl)

func _get_pill_color(pill_type: String) -> Color:
	match pill_type:
		"energy":
			return Color(1.0, 0.84, 0.22)
		"energy_cost":
			return Color(0.88, 0.65, 0.22)
		"water":
			return Color(0.35, 0.88, 1.0)
		"water_cost":
			return Color(0.30, 0.68, 0.95)
		"food":
			return Color(0.55, 0.92, 0.35)
		"food_cost":
			return Color(0.42, 0.75, 0.28)
		"carbon_good":
			return Color(0.28, 0.95, 0.65)
		"carbon_bad":
			return Color(1.0, 0.40, 0.35)
		"special":
			return Color(0.88, 0.72, 1.0)
		_:
			return Color(0.70, 0.82, 0.88)

func rebuild_hand_ui(hand: Array, selected_hand_index: int, discard_mode: bool, sim: GridSimulation = null) -> void:
	hovered_hand_index = -1
	card_nodes.clear()
	for child in hand_container.get_children():
		child.queue_free()

	for i in range(hand.size()):
		var card_id: int = hand[i]
		var info: Dictionary = GameData.CARDS[card_id]
		var is_selected: bool = (i == selected_hand_index)

		var is_affordable: bool = true
		var unaffordable_reason: String = ""
		if sim != null and not discard_mode:
			is_affordable = sim.can_afford_card(card_id)
			if not is_affordable:
				unaffordable_reason = sim.get_card_unaffordable_reason(card_id)

		var card_panel := PanelContainer.new()
		var card_size := Vector2(176, 168)
		card_panel.custom_minimum_size = card_size
		card_panel.size = card_size
		card_panel.pivot_offset = Vector2(card_size.x * 0.5, card_size.y)

		var border_col: Color
		var bg_col: Color
		if discard_mode:
			border_col = Color(0.95, 0.35, 0.35)
			bg_col = Color(0.24, 0.10, 0.12, 0.96)
		elif not is_affordable:
			border_col = Color(0.55, 0.25, 0.25, 0.8)
			bg_col = Color(0.08, 0.09, 0.11, 0.90)
		elif is_selected:
			border_col = Color(1.0, 0.92, 0.35)
			bg_col = Color(0.12, 0.22, 0.18, 0.98)
		else:
			border_col = info["color"]
			bg_col = Color(0.08, 0.12, 0.16, 0.96)

		var c_sb := GameData.make_stylebox(bg_col, border_col, 3 if (is_selected or discard_mode) else 2, 8)
		c_sb.content_margin_left = 5
		c_sb.content_margin_right = 5
		c_sb.content_margin_top = 4
		c_sb.content_margin_bottom = 4
		card_panel.add_theme_stylebox_override("panel", c_sb)

		var idx: int = i
		var on_card_input = func(ev: InputEvent) -> void:
			if ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT:
				if ev.pressed:
					_dragged_card_idx = idx
					_drag_start_pos = ev.global_position
					_is_dragging = false
					card_clicked.emit(idx)
				else:
					if _dragged_card_idx == idx:
						if _is_dragging:
							card_drag_released.emit(idx, ev.global_position)
						_dragged_card_idx = -1
						_is_dragging = false
			elif ev is InputEventMouseMotion:
				if _dragged_card_idx == idx:
					if ev.global_position.distance_to(_drag_start_pos) > 16.0:
						_is_dragging = true

		card_panel.gui_input.connect(on_card_input)

		var vbox := VBoxContainer.new()
		vbox.mouse_filter = Control.MOUSE_FILTER_PASS
		vbox.add_theme_constant_override("separation", 3)
		card_panel.add_child(vbox)

		# 1. Header (Title + Key badge)
		var title_panel := PanelContainer.new()
		title_panel.mouse_filter = Control.MOUSE_FILTER_PASS
		var t_sb := GameData.make_stylebox(Color(0.10, 0.16, 0.20, 0.95) if is_affordable else Color(0.10, 0.11, 0.13, 0.95), border_col.darkened(0.2), 1, 4)
		t_sb.content_margin_left = 4
		t_sb.content_margin_right = 4
		t_sb.content_margin_top = 2
		t_sb.content_margin_bottom = 2
		title_panel.add_theme_stylebox_override("panel", t_sb)
		vbox.add_child(title_panel)

		var header_hbox := HBoxContainer.new()
		header_hbox.mouse_filter = Control.MOUSE_FILTER_PASS
		title_panel.add_child(header_hbox)

		var title_lbl := Label.new()
		var syn_available: bool = (sim != null and not discard_mode and sim.has_available_synergy(card_id))
		var syn_tag: String = " ✨" if syn_available else ""
		title_lbl.text = "%s %s%s" % [info["symbol"], info["title"], syn_tag]
		title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		title_lbl.add_theme_font_size_override("font_size", 12)
		var btn_fcol: Color = (info["color"].lightened(0.35)) if is_affordable else Color(0.65, 0.65, 0.7)
		if syn_available and is_affordable:
			btn_fcol = Color(1.0, 0.92, 0.45)
		title_lbl.add_theme_color_override("font_color", btn_fcol)
		header_hbox.add_child(title_lbl)

		var key_lbl := Label.new()
		key_lbl.text = "[%d]" % (idx + 1)
		key_lbl.add_theme_font_size_override("font_size", 11)
		key_lbl.add_theme_color_override("font_color", Color(0.85, 0.92, 0.96) if is_affordable else Color(0.55, 0.55, 0.58))
		header_hbox.add_child(key_lbl)

		# 2. Artwork Frame Window
		var art_frame := PanelContainer.new()
		art_frame.mouse_filter = Control.MOUSE_FILTER_PASS
		art_frame.custom_minimum_size = Vector2(0, 50)
		var art_sb := GameData.make_stylebox(Color(0.07, 0.12, 0.16, 0.94), border_col.darkened(0.25), 1, 5)
		art_sb.content_margin_left = 2
		art_sb.content_margin_right = 2
		art_sb.content_margin_top = 2
		art_sb.content_margin_bottom = 2
		art_frame.add_theme_stylebox_override("panel", art_sb)
		vbox.add_child(art_frame)

		var art_rect := TextureRect.new()
		var sp_path: String = info.get("sprite_path", "")
		if ResourceLoader.exists(sp_path):
			art_rect.texture = load(sp_path)
		art_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		art_rect.custom_minimum_size = Vector2(0, 46)
		art_rect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		art_rect.size_flags_vertical = Control.SIZE_EXPAND_FILL
		art_rect.mouse_filter = Control.MOUSE_FILTER_PASS
		art_frame.add_child(art_rect)

		# 3. Resource Pills Row
		var pills_hbox := HBoxContainer.new()
		pills_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
		pills_hbox.mouse_filter = Control.MOUSE_FILTER_PASS
		pills_hbox.add_theme_constant_override("separation", 3)
		vbox.add_child(pills_hbox)

		var pills: Array = info.get("pills", [])
		if pills.is_empty():
			var p_panel := PanelContainer.new()
			p_panel.mouse_filter = Control.MOUSE_FILTER_PASS
			var psb := GameData.make_stylebox(Color(0.05, 0.08, 0.11, 0.92), border_col, 1, 4)
			psb.content_margin_left = 5
			psb.content_margin_right = 5
			psb.content_margin_top = 1
			psb.content_margin_bottom = 1
			p_panel.add_theme_stylebox_override("panel", psb)
			var pl := Label.new()
			pl.text = info.get("cost_text", "")
			pl.add_theme_font_size_override("font_size", 11)
			pl.add_theme_color_override("font_color", Color(0.96, 0.97, 0.99))
			p_panel.add_child(pl)
			pills_hbox.add_child(p_panel)
		else:
			for pill in pills:
				var p_panel := PanelContainer.new()
				p_panel.mouse_filter = Control.MOUSE_FILTER_PASS
				var ptype: String = pill.get("type", "")
				var pcol: Color = _get_pill_color(ptype)
				var psb := GameData.make_stylebox(Color(0.05, 0.08, 0.11, 0.92), pcol if is_affordable else Color(0.35, 0.35, 0.38), 1, 4)
				psb.content_margin_left = 4
				psb.content_margin_right = 4
				psb.content_margin_top = 1
				psb.content_margin_bottom = 1
				p_panel.add_theme_stylebox_override("panel", psb)
				var pl := Label.new()
				pl.text = pill.get("icon", "") + pill.get("text", "")
				pl.add_theme_font_size_override("font_size", 10)
				pl.add_theme_color_override("font_color", pcol if is_affordable else Color(0.60, 0.60, 0.65))
				p_panel.add_child(pl)
				pills_hbox.add_child(p_panel)

		# 4. Synergy / Effect Tag
		var syn_lbl := Label.new()
		syn_lbl.text = info.get("synergy_tag", info.get("desc", ""))
		syn_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		syn_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		syn_lbl.add_theme_font_size_override("font_size", 10)
		syn_lbl.add_theme_color_override("font_color", Color(1.0, 0.90, 0.45) if syn_available else (Color(0.72, 0.86, 0.80) if is_affordable else Color(0.48, 0.52, 0.55)))
		vbox.add_child(syn_lbl)

		# 5. Action Button
		var pick_btn := Button.new()
		if discard_mode:
			pick_btn.text = "🗑 Kartı At (+1⚡)"
		elif not is_affordable:
			pick_btn.text = unaffordable_reason if not unaffordable_reason.is_empty() else "⚠ Yetersiz Kaynak"
		elif is_selected:
			pick_btn.text = "✓ Seçili [Kare Seç]"
		else:
			pick_btn.text = "Seç / Oyna [%d]" % (idx + 1)

		pick_btn.custom_minimum_size = Vector2(0, 22)
		pick_btn.mouse_filter = Control.MOUSE_FILTER_PASS
		pick_btn.add_theme_font_size_override("font_size", 11)
		var pick_bg: Color
		if discard_mode:
			pick_bg = Color(0.45, 0.16, 0.16)
		elif not is_affordable:
			pick_bg = Color(0.22, 0.12, 0.12)
		elif is_selected:
			pick_bg = Color(0.18, 0.38, 0.28)
		else:
			pick_bg = Color(0.14, 0.20, 0.25)
		pick_btn.add_theme_stylebox_override("normal", GameData.make_stylebox(pick_bg, border_col, 1, 5))
		pick_btn.pressed.connect(func() -> void: card_clicked.emit(idx))
		vbox.add_child(pick_btn)

		hand_container.add_child(card_panel)
		card_nodes.append(card_panel)

	update_hand_fan_layout(1.0, selected_hand_index, false, false)
	update_onboarding_guide(sim, selected_hand_index)

func update_hand_fan_layout(lerp_weight: float, selected_hand_index: int, modal_open: bool, game_over: bool) -> void:
	var n: int = card_nodes.size()
	if n == 0 or hand_container == null:
		return
	var container_w: float = hand_container.size.x
	if container_w <= 10.0:
		container_w = get_viewport().get_visible_rect().size.x - 24.0
	var card_w: float = 176.0
	var card_h: float = 168.0
	var center_x: float = minf(container_w * 0.5 - 55.0, 560.0)
	var max_step: float = 165.0 if n <= 5 else (820.0 / float(max(1, n - 1)))
	var step_x: float = max_step if n > 1 else 0.0
	var mid: float = float(n - 1) * 0.5

	var new_hovered: int = -1
	if not modal_open and not game_over and hand_container.is_visible_in_tree():
		var local_mouse: Vector2 = hand_container.get_local_mouse_position()
		for i in range(n - 1, -1, -1):
			var c: Control = card_nodes[i]
			if not is_instance_valid(c):
				continue
			var rel_i: float = float(i) - mid
			var base_x: float = center_x + rel_i * step_x - (card_w * 0.5)
			var left_x: float = minf(c.position.x, base_x) - 6.0
			var right_x: float = maxf(c.position.x + card_w, base_x + card_w) + 6.0
			var top_y: float = minf(c.position.y - 12.0, 0.0)
			var bottom_y: float = card_h + 50.0
			if local_mouse.x >= left_x and local_mouse.x <= right_x and local_mouse.y >= top_y and local_mouse.y <= bottom_y:
				new_hovered = i
				break

	if new_hovered != hovered_hand_index:
		hovered_hand_index = new_hovered
		if hovered_hand_index >= 0 and lerp_weight < 0.99:
			card_hover_changed.emit()

	for i in range(n):
		var card: Control = card_nodes[i]
		if not is_instance_valid(card):
			continue
		var rel: float = float(i) - mid
		var norm: float = (rel / maxf(1.0, mid)) if n > 1 else 0.0

		var is_hov: bool = (i == hovered_hand_index) and not modal_open
		var is_sel: bool = (i == selected_hand_index) and not modal_open

		var push_x: float = 0.0
		if hovered_hand_index >= 0 and i != hovered_hand_index and not modal_open:
			push_x = -32.0 if i < hovered_hand_index else 32.0

		var target_x: float = center_x + rel * step_x - (card_w * 0.5) + push_x
		var arch_y: float = absf(norm) * absf(norm) * 5.0 + 4.0
		var target_y: float = arch_y
		var target_rot: float = clampf(rel * 2.2, -7.5, 7.5)
		var target_scale: Vector2 = Vector2.ONE

		if is_sel and is_hov:
			target_y = -12.0
			target_rot = 0.0
			target_scale = Vector2(1.06, 1.06)
			card.z_index = 25
		elif is_hov:
			target_y = -10.0
			target_rot = 0.0
			target_scale = Vector2(1.05, 1.05)
			card.z_index = 22
		elif is_sel:
			target_y = -8.0
			target_rot = rel * 0.8
			target_scale = Vector2(1.03, 1.03)
			card.z_index = 18
		else:
			card.z_index = i + 1

		var target_pos := Vector2(target_x, target_y)
		if lerp_weight >= 0.99:
			card.position = target_pos
			card.rotation_degrees = target_rot
			card.scale = target_scale
		else:
			card.position = card.position.lerp(target_pos, lerp_weight)
			card.rotation_degrees = lerpf(card.rotation_degrees, target_rot, lerp_weight)
			card.scale = card.scale.lerp(target_scale, lerp_weight)

func update_hud_stats(sim: GridSimulation, preview_delta: Dictionary = {}) -> void:
	var prod: Dictionary = sim.calculate_total_turn_production()
	if preview_delta.is_empty():
		energy_label.text = "%d (%+d)" % [sim.energy, prod["e"]]
		energy_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.32))
		energy_label.tooltip_text = "⚡ ENERJİ ŞEBEKESİ:\nMevcut Rezerv: %d ⚡  |  Net Günlük Akış: %+d ⚡\n(0 veya altına düşerse şebeke çöker!)" % [sim.energy, prod["e"]]

		food_label.text = "%d (%+d)" % [sim.food, prod["f"]]
		food_label.add_theme_color_override("font_color", Color(0.52, 0.94, 0.42))
		food_label.tooltip_text = "🌱 GIDA GÜVENLİĞİ:\nMevcut Rezerv: %d 🌱  |  Net Günlük Akış: %+d 🌱\n(0 veya altına düşerse kıtlık başlar!)" % [sim.food, prod["f"]]

		water_label.text = "%d (%+d)" % [sim.water, prod["w"]]
		water_label.add_theme_color_override("font_color", Color(0.42, 0.82, 1.0))
		water_label.tooltip_text = "💧 SU REZERVLERİ:\nMevcut Rezerv: %d 💧  |  Net Günlük Akış: %+d 💧\n(0 veya altına düşerse kuraklık başlar!)" % [sim.water, prod["w"]]

		if sim.carbon >= 70:
			carbon_label.text = "🚨 %d/%d (%+d) [KRİTİK!]" % [sim.carbon, GameData.MAX_CARBON, prod["c"]]
			carbon_label.add_theme_color_override("font_color", Color(1.0, 0.28, 0.24))
		else:
			carbon_label.text = "%d/%d (%+d)" % [sim.carbon, GameData.MAX_CARBON, prod["c"]]
			carbon_label.add_theme_color_override("font_color", Color(1.0, 0.52, 0.45))
		carbon_label.tooltip_text = "☣ KARBON BİLANÇOSU:\nMevcut Atmosferik Karbon: %d/%d  |  Net Günlük: %+d ☣\n(100'e ulaşırsa küresel ısınma felaketi tetiklenir!)" % [sim.carbon, GameData.MAX_CARBON, prod["c"]]
		carbon_bar.value = sim.carbon
	else:
		var ne: int = sim.energy + preview_delta.get("e", 0)
		var nf: int = sim.food + preview_delta.get("f", 0)
		var nw: int = sim.water + preview_delta.get("w", 0)
		var nc: int = clampi(sim.carbon + preview_delta.get("c", 0), 0, GameData.MAX_CARBON)

		var de: int = preview_delta.get("e", 0)
		var df: int = preview_delta.get("f", 0)
		var dw: int = preview_delta.get("w", 0)
		var dc: int = preview_delta.get("c", 0)

		energy_label.text = "%d➔%d (%+d)" % [sim.energy, ne, prod["e"] + de]
		energy_label.add_theme_color_override("font_color", Color(1.0, 1.0, 0.45) if de >= 0 else Color(1.0, 0.42, 0.35))

		food_label.text = "%d➔%d (%+d)" % [sim.food, nf, prod["f"] + df]
		food_label.add_theme_color_override("font_color", Color(0.65, 1.0, 0.55) if df >= 0 else Color(1.0, 0.42, 0.35))

		water_label.text = "%d➔%d (%+d)" % [sim.water, nw, prod["w"] + dw]
		water_label.add_theme_color_override("font_color", Color(0.60, 0.90, 1.0) if dw >= 0 else Color(1.0, 0.42, 0.35))

		carbon_label.text = "%d➔%d (%+d)" % [sim.carbon, nc, prod["c"] + dc]
		carbon_label.add_theme_color_override("font_color", Color(0.45, 1.0, 0.65) if dc <= 0 else Color(1.0, 0.42, 0.35))
		carbon_bar.value = nc

	if sim.zero_carbon_streak > 0:
		var stars: String = ""
		for s_i in range(sim.zero_carbon_streak):
			stars += "★"
		if sim.zero_carbon_streak == 4:
			streak_label.text = "👑 %s 4/5" % stars
			streak_label.add_theme_color_override("font_color", Color(1.0, 0.90, 0.35))
		else:
			streak_label.text = "⭐ %s %d/%d" % [stars, sim.zero_carbon_streak, GameData.ZERO_CARBON_WIN_DAYS]
			streak_label.add_theme_color_override("font_color", Color(0.48, 1.0, 0.72))
	else:
		streak_label.text = "🌿 0/%d" % GameData.ZERO_CARBON_WIN_DAYS
		streak_label.add_theme_color_override("font_color", Color(0.55, 0.96, 0.78))
	day_label.text = "📅 %d/%d" % [sim.day, GameData.MAX_DAYS]
	if weather_label != null:
		var w_type: int = sim.current_weather
		var w_info: Dictionary = GameData.WEATHER_INFO.get(w_type, GameData.WEATHER_INFO[GameData.WeatherType.MODERATE])
		weather_label.text = "%s %s" % [w_info["icon"], w_info["title"]]
		weather_label.tooltip_text = "🌤 EKOLOJİK HAVA DURUMU: %s\n\n🎯 Etki: %s\n📚 %s" % [w_info["title"], w_info["bonus_desc"], w_info["desc"]]
		weather_label.add_theme_color_override("font_color", w_info["color"])
	var next_crisis_day: int = ((int(sim.day / 5) + 1) * 5)
	var playable_cards: int = 0
	for cid in sim.hand:
		if sim.can_afford_card(cid):
			playable_cards += 1

	if next_crisis_day <= 20:
		var days_left: int = next_crisis_day - sim.day
		if days_left == 1:
			forecast_label.text = "🚨 YARIN: %s" % GameData.get_crisis_short_forecast(sim.upcoming_crisis_id)
			forecast_label.add_theme_color_override("font_color", Color(1.0, 0.42, 0.35))
			if left_perks_panel_node != null:
				left_perks_panel_node.add_theme_stylebox_override("panel", GameData.make_stylebox(Color(0.12, 0.08, 0.08, 0.92), Color(0.85, 0.38, 0.28), 2, 8))
			if end_turn_button != null:
				end_turn_button.text = "⚠ Turu Bitir (Kriz!)\n[Space]"
				end_turn_button.add_theme_stylebox_override("normal", GameData.make_stylebox(Color(0.52, 0.22, 0.16), Color(1.0, 0.48, 0.35), 2, 8))
				end_turn_button.add_theme_stylebox_override("hover", GameData.make_stylebox(Color(0.65, 0.28, 0.20), Color(1.0, 0.62, 0.48), 2, 8))
		else:
			forecast_label.text = "📡 Gün %d: %s (%d gün)" % [next_crisis_day, GameData.get_crisis_short_forecast(sim.upcoming_crisis_id), days_left]
			forecast_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.35))
			if left_perks_panel_node != null:
				left_perks_panel_node.add_theme_stylebox_override("panel", GameData.make_stylebox(Color(0.07, 0.11, 0.15, 0.90), Color(0.24, 0.46, 0.38), 1, 8))
			if end_turn_button != null:
				end_turn_button.text = ("⏭ Turu Bitir (%d Hazır)\n[Space]" % playable_cards) if playable_cards > 0 else "⏭ Turu Bitir\n[Space]"
				end_turn_button.add_theme_stylebox_override("normal", GameData.make_stylebox(Color(0.16, 0.48, 0.34), Color(0.38, 0.92, 0.62), 2, 8))
				end_turn_button.add_theme_stylebox_override("hover", GameData.make_stylebox(Color(0.22, 0.60, 0.42), Color(0.55, 1.0, 0.78), 2, 8))
	else:
		forecast_label.text = "📡 Son Düzlük!"
		forecast_label.add_theme_color_override("font_color", Color(0.55, 0.95, 0.75))
		if end_turn_button != null:
			end_turn_button.text = ("⏭ Turu Bitir (%d Hazır)\n[Space]" % playable_cards) if playable_cards > 0 else "⏭ Turu Bitir\n[Space]"
			end_turn_button.add_theme_stylebox_override("normal", GameData.make_stylebox(Color(0.16, 0.48, 0.34), Color(0.38, 0.92, 0.62), 2, 8))
	update_undo_button(sim)
	update_onboarding_guide(sim, hovered_hand_index if hovered_hand_index >= 0 else -1)

func update_onboarding_guide(sim: GridSimulation, selected_index: int = -1) -> void:
	if onboarding_panel == null:
		return
	if tutorial_dismissed or sim == null or sim.day >= 4 or (bottom_panel_node != null and not bottom_panel_node.visible):
		onboarding_panel.visible = false
		return
	if (modal_panel != null and modal_panel.visible) or (settings_panel != null and settings_panel.visible) or (end_screen_panel != null and end_screen_panel.visible) or (help_panel != null and help_panel.visible) or (shortcuts_panel != null and shortcuts_panel.visible):
		onboarding_panel.visible = false
		return

	onboarding_panel.visible = true
	if sim.day == 1:
		if selected_index < 0:
			if sim.stats_cards_played == 0:
				onboarding_label.text = "🌱 1. ADIM: Aşağıdan bir kart seçin (1-5 tuşları veya tıkla)"
			else:
				onboarding_label.text = "🚀 3. ADIM: Günlük hamleleriniz bitince [Space] ile turu tamamlayın"
		else:
			onboarding_label.text = "✨ 2. ADIM: Açık yeşil kareye tıklayarak inşa edin! (Sinerjilere dikkat edin)"
	elif sim.day == 2:
		onboarding_label.text = "💡 İPUCU: Aynı binanın üzerine oynayarak Seviye 2 (★) yapabilirsiniz!"
	elif sim.day == 3:
		onboarding_label.text = "⚠ DİKKAT: 5. günde İklim Krizi var! Kömürleri yıkın veya Orman dikin."

func update_fact_tip(day_num: int) -> void:
	if fact_label == null:
		return
	var tips := [
		"💡 İpucu: Aynı binayı üst üste oynayarak Seviye 2 (★) yapabilirsiniz.",
		"🌿 Bilgi: Kent ormanları ısı adasını 5°C düşürür ve karbon yutar.",
		"💡 İpucu: Kömür santralini yıkarak acil su ve enerji geri kazanın.",
		"🧪 Bilgi: Karbon Yakalama (CCS) atmosferdeki CO2'yi filtreler.",
		"💧 İpucu: Dikey Tarım, göl veya su tesisi yanından +2🌱 alır.",
		"🏆 Hedef: 5 gün boyunca 0-Karbon emisyonunda kalarak Net-Sıfır Zaferi kazanın!"
	]
	fact_label.text = tips[day_num % tips.size()]

func open_perk_selection_modal(sim: GridSimulation) -> bool:
	var available: Array = []
	for p in GameData.PERKS:
		if not sim.active_perks.has(p["id"]):
			available.append(p)
	if available.is_empty():
		return false

	available.shuffle()
	var count: int = mini(3, available.size())
	modal_panel.visible = true
	modal_title_label.text = "⚖ SÜRDÜRÜLEBİLİRLİK YASASI SEÇİN (Gün %d)" % sim.day
	modal_subtitle_label.text = "Şehriniz için kalıcı bir ekolojik reform yasası yürürlüğe koyun:"

	for child in modal_options_box.get_children():
		child.queue_free()

	for i in range(count):
		var perk: Dictionary = available[i]
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(290, 150)
		btn.text = "%s\n\n%s" % [perk["title"], perk["desc"]]
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		btn.add_theme_font_size_override("font_size", 15)
		btn.add_theme_stylebox_override("normal", GameData.make_stylebox(Color(0.12, 0.22, 0.20), Color(0.38, 0.85, 0.62), 2, 10))
		btn.add_theme_stylebox_override("hover", GameData.make_stylebox(Color(0.18, 0.32, 0.28), Color(0.62, 0.98, 0.78), 3, 10))
		var pid: String = perk["id"]
		btn.pressed.connect(func() -> void:
			modal_panel.visible = false
			perk_chosen.emit(pid)
		)
		modal_options_box.add_child(btn)
	return true

func open_card_draft_modal(day: int) -> void:
	modal_panel.visible = true
	modal_title_label.text = "🃏 DESTEYE YENİ TEKNOLOJİ EKLE (Gün %d)" % day
	modal_subtitle_label.text = "Seçtiğiniz kart hem kalıcı olarak destenize hem de anında elinize eklenir:"

	for child in modal_options_box.get_children():
		child.queue_free()

	var all_cards: Array = GameData.CARDS.keys()
	all_cards.shuffle()
	for i in range(3):
		var cid: int = all_cards[i]
		var info: Dictionary = GameData.CARDS[cid]
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(300, 165)
		btn.text = "%s %s\n%s\n\n%s" % [info["symbol"], info["title"], info["cost_text"], info["desc"]]
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		btn.add_theme_font_size_override("font_size", 14)
		btn.add_theme_stylebox_override("normal", GameData.make_stylebox(Color(0.12, 0.18, 0.24), info["color"], 2, 10))
		btn.add_theme_stylebox_override("hover", GameData.make_stylebox(Color(0.18, 0.26, 0.34), Color(1.0, 0.94, 0.35), 3, 10))
		btn.pressed.connect(func() -> void:
			modal_panel.visible = false
			draft_card_chosen.emit(cid)
		)
		modal_options_box.add_child(btn)

func open_dilemma_modal(day: int) -> void:
	var d: Dictionary = GameData.get_dilemma_for_day(day)
	modal_panel.visible = true
	modal_title_label.text = "%s (Gün %d)" % [d["title"], day]
	modal_subtitle_label.text = d["desc"]

	for child in modal_options_box.get_children():
		child.queue_free()

	var delta_a: Dictionary = d["opt_a_delta"]
	var perk_a: String = d.get("opt_a_perk", "")
	var btn_a := Button.new()
	btn_a.custom_minimum_size = Vector2(340, 160)
	btn_a.text = "%s\n\n📊 Net Kaynak Değişimi: %s" % [d["opt_a_text"], _format_impact_text(delta_a)]
	btn_a.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	btn_a.add_theme_font_size_override("font_size", 13)
	btn_a.add_theme_stylebox_override("normal", GameData.make_stylebox(Color(0.14, 0.24, 0.32), Color(0.45, 0.78, 0.96), 2, 10))
	btn_a.add_theme_stylebox_override("hover", GameData.make_stylebox(Color(0.20, 0.32, 0.42), Color(0.65, 0.92, 1.0), 3, 10))
	btn_a.pressed.connect(func() -> void:
		modal_panel.visible = false
		dilemma_option_chosen.emit(delta_a, d["title"], perk_a)
	)
	modal_options_box.add_child(btn_a)

	var delta_b: Dictionary = d["opt_b_delta"]
	var perk_b: String = d.get("opt_b_perk", "")
	var btn_b := Button.new()
	btn_b.custom_minimum_size = Vector2(340, 160)
	btn_b.text = "%s\n\n📊 Net Kaynak Değişimi: %s" % [d["opt_b_text"], _format_impact_text(delta_b)]
	btn_b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	btn_b.add_theme_font_size_override("font_size", 13)
	btn_b.add_theme_stylebox_override("normal", GameData.make_stylebox(Color(0.14, 0.28, 0.20), Color(0.42, 0.92, 0.62), 2, 10))
	btn_b.add_theme_stylebox_override("hover", GameData.make_stylebox(Color(0.20, 0.38, 0.28), Color(0.62, 1.0, 0.78), 3, 10))
	btn_b.pressed.connect(func() -> void:
		modal_panel.visible = false
		dilemma_option_chosen.emit(delta_b, d["title"], perk_b)
	)
	modal_options_box.add_child(btn_b)

func _format_impact_text(delta: Dictionary) -> String:
	var parts: PackedStringArray = PackedStringArray()
	if delta.get("e", 0) != 0:
		parts.append("⚡%+d" % delta["e"])
	if delta.get("f", 0) != 0:
		parts.append("🌱%+d" % delta["f"])
	if delta.get("w", 0) != 0:
		parts.append("💧%+d" % delta["w"])
	if delta.get("c", 0) != 0:
		parts.append("☣%+d" % delta["c"])
	if parts.is_empty():
		return "Nötr"
	return "  ".join(parts)

func show_end_screen(won: bool, title: String, subtitle: String, sim: GridSimulation = null) -> void:
	modal_panel.visible = false
	end_screen_panel.visible = true
	end_title_label.text = title
	var theme_col: Color = Color(0.38, 0.96, 0.58) if won else Color(1.0, 0.36, 0.32)
	end_title_label.add_theme_color_override("font_color", theme_col)
	end_subtitle_label.text = subtitle
	if copy_report_btn != null:
		copy_report_btn.text = "📋 Raporu Kopyala"

	if end_card_node != null:
		var end_sb := GameData.make_stylebox(Color(0.06, 0.10, 0.14, 0.98), theme_col, 2, 14)
		end_sb.content_margin_left = 26
		end_sb.content_margin_right = 26
		end_sb.content_margin_top = 22
		end_sb.content_margin_bottom = 22
		end_card_node.add_theme_stylebox_override("panel", end_sb)

	if end_metrics_box != null:
		for ch in end_metrics_box.get_children():
			ch.queue_free()
		if sim != null:
			var grid := GridContainer.new()
			grid.columns = 2
			grid.add_theme_constant_override("h_separation", 16)
			grid.add_theme_constant_override("v_separation", 8)
			end_metrics_box.add_child(grid)

			var metrics_data := [
				{
					"label": "⚡ Temiz Enerji Yatırımı: %d Tesis" % sim.stats_clean_energy_built,
					"val": mini(100, sim.stats_clean_energy_built * 20),
					"col": Color(0.35, 0.85, 0.98),
					"bg": Color(0.08, 0.16, 0.22)
				},
				{
					"label": "🌲 Kent Ormanları & Yutak Kapasitesi: %d" % sim.stats_forests_planted,
					"val": mini(100, sim.stats_forests_planted * 25),
					"col": Color(0.38, 0.92, 0.52),
					"bg": Color(0.08, 0.20, 0.12)
				},
				{
					"label": "🏭 Kömür Tasfiyesi: %d Santral Yıkıldı" % sim.stats_coal_demolished,
					"val": mini(100, sim.stats_coal_demolished * 50),
					"col": Color(1.0, 0.65, 0.30),
					"bg": Color(0.22, 0.14, 0.08)
				},
				{
					"label": "👥 İklim Direnci: %s (Nüfus: %s)" % [sim.get_climate_resilience_tier(), String.num_int64(sim.calculate_city_population())],
					"val": mini(100, int(sim.calculate_city_population() / 150.0)),
					"col": Color(0.92, 0.82, 0.40),
					"bg": Color(0.18, 0.17, 0.08)
				}
			]

			for m in metrics_data:
				var m_box := VBoxContainer.new()
				m_box.custom_minimum_size = Vector2(310, 36)
				m_box.add_theme_constant_override("separation", 3)

				var l := Label.new()
				l.text = m["label"]
				l.add_theme_font_size_override("font_size", 12)
				l.add_theme_color_override("font_color", Color(0.92, 0.96, 0.94))
				m_box.add_child(l)

				var pbar := ProgressBar.new()
				pbar.custom_minimum_size = Vector2(310, 14)
				pbar.show_percentage = false
				pbar.value = m["val"]
				pbar.add_theme_stylebox_override("background", GameData.make_stylebox(m["bg"], Color(0.2, 0.28, 0.35), 1, 4))
				pbar.add_theme_stylebox_override("fill", GameData.make_stylebox(m["col"], Color(0, 0, 0, 0), 0, 4))
				m_box.add_child(pbar)

				grid.add_child(m_box)

			var score_badges_hbox := HBoxContainer.new()
			score_badges_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
			score_badges_hbox.add_theme_constant_override("separation", 8)
			end_metrics_box.add_child(score_badges_hbox)

			var score_items := [
				{"txt": "🌲 Orman: +%d" % (sim.stats_forests_planted * 12), "col": Color(0.35, 0.95, 0.55)},
				{"txt": "🏭 Kömür: +%d" % (sim.stats_coal_demolished * 25), "col": Color(1.0, 0.65, 0.35)},
				{"txt": "⚡ Temiz En: +%d" % (sim.stats_clean_energy_built * 10), "col": Color(0.40, 0.88, 1.0)},
				{"txt": "⭐ Tesis Yükseltmeleri: +%d" % (sim.stats_upgrades_done * 15), "col": Color(1.0, 0.88, 0.35)},
				{"txt": "☣ Karbon: -%d" % sim.carbon, "col": Color(1.0, 0.45, 0.45) if sim.carbon > 0 else Color(0.45, 0.95, 0.65)}
			]
			var bio_score_dict: Dictionary = sim.calculate_biodiversity()
			var bio_pts: int = int(bio_score_dict["score"] * 0.25)
			if bio_pts > 0:
				score_items.append({"txt": "🦋 Biyo-Çeşitlilik: +%d" % bio_pts, "col": bio_score_dict["color"]})
			if won:
				score_items.append({"txt": "🏆 Zafer: +35", "col": Color(1.0, 0.92, 0.45)})

			for s_item in score_items:
				var s_badge := PanelContainer.new()
				var s_sb := GameData.make_stylebox(Color(0.08, 0.14, 0.18, 0.92), s_item["col"], 1, 4)
				s_sb.content_margin_left = 6
				s_sb.content_margin_right = 6
				s_sb.content_margin_top = 2
				s_sb.content_margin_bottom = 2
				s_badge.add_theme_stylebox_override("panel", s_sb)
				var s_lbl := Label.new()
				s_lbl.text = s_item["txt"]
				s_lbl.add_theme_font_size_override("font_size", 12)
				s_lbl.add_theme_color_override("font_color", s_item["col"])
				s_badge.add_child(s_lbl)
				score_badges_hbox.add_child(s_badge)

			var chart := build_timeline_chart(sim, 660.0, 115.0)
			end_metrics_box.add_child(chart)

func build_timeline_chart(sim: GridSimulation, chart_w: float = 640.0, chart_h: float = 120.0) -> PanelContainer:
	var container := PanelContainer.new()
	if sim == null:
		return container

	var c_sb := GameData.make_stylebox(Color(0.04, 0.08, 0.12, 0.95), Color(0.20, 0.45, 0.52, 0.8), 1, 8)
	c_sb.content_margin_left = 12
	c_sb.content_margin_right = 12
	c_sb.content_margin_top = 8
	c_sb.content_margin_bottom = 8
	container.add_theme_stylebox_override("panel", c_sb)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	container.add_child(vbox)

	var header_hbox := HBoxContainer.new()
	header_hbox.add_theme_constant_override("separation", 10)
	vbox.add_child(header_hbox)

	var title_lbl := Label.new()
	title_lbl.text = "📈 DÖNÜŞÜM ZAMAN ÇİZELGESİ (Gün 1 ➔ %d)" % sim.day
	title_lbl.add_theme_font_size_override("font_size", 12)
	title_lbl.add_theme_color_override("font_color", Color(0.45, 0.92, 1.0))
	header_hbox.add_child(title_lbl)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_hbox.add_child(spacer)

	var legend_items := [
		{"label": "☣ Karbon (%d)" % sim.carbon, "color": Color(1.0, 0.38, 0.32)},
		{"label": "⚡ Enerji (%d)" % sim.energy, "color": Color(1.0, 0.88, 0.35)},
		{"label": "🌱 Gıda (%d)" % sim.food, "color": Color(0.42, 0.95, 0.52)},
		{"label": "💧 Su (%d)" % sim.water, "color": Color(0.35, 0.82, 1.0)}
	]
	for leg in legend_items:
		var leg_lbl := Label.new()
		leg_lbl.text = leg["label"]
		leg_lbl.add_theme_font_size_override("font_size", 11)
		leg_lbl.add_theme_color_override("font_color", leg["color"])
		header_hbox.add_child(leg_lbl)

	var canvas := Control.new()
	canvas.custom_minimum_size = Vector2(chart_w, chart_h)
	vbox.add_child(canvas)

	canvas.draw.connect(func() -> void:
		var font: Font = ThemeDB.fallback_font
		var lm: float = 34.0
		var rm: float = 18.0
		var tm: float = 10.0
		var bm: float = 20.0
		var pw: float = chart_w - lm - rm
		var ph: float = chart_h - tm - bm

		var max_val: int = 20
		for h_arr in [sim.carbon_history, sim.energy_history, sim.food_history, sim.water_history]:
			for v in h_arr:
				if v > max_val:
					max_val = v
		max_val = int(ceil(float(max_val) / 10.0) * 10.0)
		if max_val < 30:
			max_val = 30

		canvas.draw_rect(Rect2(lm, tm, pw, ph), Color(0.02, 0.05, 0.08, 0.7), true)
		canvas.draw_rect(Rect2(lm, tm, pw, ph), Color(0.15, 0.28, 0.38, 0.6), false, 1.0)

		var y_steps := [0, int(max_val * 0.5), max_val]
		for yv in y_steps:
			var y_pos: float = (tm + ph) - (float(yv) / float(max_val)) * ph
			canvas.draw_line(Vector2(lm, y_pos), Vector2(lm + pw, y_pos), Color(0.18, 0.30, 0.40, 0.35), 1.0)
			canvas.draw_string(font, Vector2(2.0, y_pos + 4.0), str(yv), HORIZONTAL_ALIGNMENT_RIGHT, 28.0, 10, Color(0.55, 0.70, 0.80, 0.8))

		var series := [
			{"data": sim.carbon_history, "color": Color(1.0, 0.38, 0.32)},
			{"data": sim.energy_history, "color": Color(1.0, 0.88, 0.35)},
			{"data": sim.food_history, "color": Color(0.42, 0.95, 0.52)},
			{"data": sim.water_history, "color": Color(0.35, 0.82, 1.0)}
		]

		var total_days: int = maxi(sim.carbon_history.size(), 1)

		for d in range(total_days):
			var x_pos: float = lm + (float(d) / float(maxi(1, total_days - 1))) * pw if total_days > 1 else lm + pw * 0.5
			canvas.draw_line(Vector2(x_pos, tm + ph), Vector2(x_pos, tm + ph + 4.0), Color(0.35, 0.55, 0.68, 0.7), 1.0)
			if total_days <= 12 or d == 0 or d == total_days - 1 or (d + 1) % 5 == 0:
				canvas.draw_string(font, Vector2(x_pos - 14.0, tm + ph + 16.0), "G%d" % (d + 1), HORIZONTAL_ALIGNMENT_CENTER, 28.0, 10, Color(0.65, 0.80, 0.88, 0.85))

		for s in series:
			var arr: Array[int] = s["data"]
			if arr.is_empty():
				continue
			var pts := PackedVector2Array()
			for d in range(arr.size()):
				var xp: float = lm + (float(d) / float(maxi(1, total_days - 1))) * pw if total_days > 1 else lm + pw * 0.5
				var yp: float = (tm + ph) - (clampf(float(arr[d]), 0.0, float(max_val)) / float(max_val)) * ph
				pts.append(Vector2(xp, yp))

			if pts.size() >= 2:
				var glow_c: Color = s["color"]
				glow_c.a = 0.25
				canvas.draw_polyline(pts, glow_c, 5.0, true)
				canvas.draw_polyline(pts, s["color"], 2.4, true)

			for pt in pts:
				canvas.draw_circle(pt, 3.2, s["color"])
				canvas.draw_circle(pt, 1.4, Color(1, 1, 1, 0.95))
	)

	return container

func _create_stat_widget(parent: Node, icon_path: String, color: Color, tooltip: String) -> Label:
	var box := HBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	parent.add_child(box)

	if ResourceLoader.exists(icon_path):
		var tr := TextureRect.new()
		tr.texture = load(icon_path)
		tr.custom_minimum_size = Vector2(16, 16)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		tr.mouse_filter = Control.MOUSE_FILTER_PASS
		box.add_child(tr)

	var lbl := Label.new()
	lbl.mouse_filter = Control.MOUSE_FILTER_STOP
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", color)
	lbl.tooltip_text = tooltip
	box.add_child(lbl)
	return lbl

func _create_stat_label(parent: Node, color: Color) -> Label:

	var lbl := Label.new()
	lbl.mouse_filter = Control.MOUSE_FILTER_STOP
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", color)
	parent.add_child(lbl)
	return lbl
