extends Node

var sfx_player: AudioStreamPlayer
var music_player: AudioStreamPlayer
var volume: float = 0.85
var music_volume: float = 0.45
var current_carbon: int = 20
var is_muted: bool = false
var _saved_vol: float = 0.85
var _saved_music_vol: float = 0.45

func toggle_mute() -> bool:
	is_muted = not is_muted
	if is_muted:
		_saved_vol = volume
		_saved_music_vol = music_volume
		volume = 0.0
		music_volume = 0.0
	else:
		volume = _saved_vol if _saved_vol > 0.05 else 0.85
		music_volume = _saved_music_vol if _saved_music_vol > 0.05 else 0.45
	return is_muted

var _music_phase_1: float = 0.0
var _music_phase_2: float = 0.0
var _music_phase_3: float = 0.0
var _music_phase_4: float = 0.0
var _music_phase_sub: float = 0.0
var _music_phase_chime: float = 0.0

var _cur_f1: float = 130.81
var _cur_f2: float = 196.00
var _cur_f3: float = 246.94
var _cur_f4: float = 329.63
var _cur_fsub: float = 65.41

var _chime_timer: float = 0.0
var _chime_step: int = 0
var _chime_freq: float = 523.25
var _chime_env: float = 0.0
var _music_time: float = 0.0

const CHORDS_CLEAN: Array = [
	[130.81, 196.00, 246.94, 329.63], # C maj7/9 (ferah ve aydınlık)
	[110.00, 164.81, 220.00, 261.63], # A min7
	[87.31, 174.61, 220.00, 261.63],  # F maj7
	[98.00, 146.83, 196.00, 246.94]   # G6/9 (çözünüm)
]

const CHORDS_MODERATE: Array = [
	[130.81, 164.81, 196.00, 246.94], # C maj7
	[110.00, 146.83, 196.00, 220.00], # A min7 (yumuşak pad)
	[87.31, 146.83, 174.61, 220.00],  # F add9
	[98.00, 146.83, 196.00, 220.00]   # G sus4
]

const CHORDS_POLLUTED: Array = [
	[73.42, 110.00, 146.83, 174.61],  # D min (derin gerilim)
	[69.30, 103.83, 138.59, 164.81],  # C# min drone
	[77.78, 116.54, 155.56, 185.00],  # Eb dim
	[65.41, 98.00, 130.81, 164.81]    # C min koyu
]

const CHORDS_INDUSTRIAL: Array = [
	[65.41, 130.81, 196.00, 233.08],  # C min7 (endüstriyel bas)
	[73.42, 146.83, 220.00, 261.63],  # D min7
	[58.27, 116.54, 174.61, 233.08],  # Bb sus
	[61.74, 123.47, 185.00, 246.94]   # B min gerilimi
]

const CHORDS_DESERT: Array = [
	[87.31, 174.61, 220.00, 277.18],  # F aug / Phrygian esintisi
	[82.41, 164.81, 207.65, 246.94],  # E Phrygian dominant
	[98.00, 196.00, 246.94, 293.66],  # G maj vaha ferahlığı
	[73.42, 146.83, 220.00, 277.18]   # Dm/F# serap
]

const CHORDS_SANDBOX: Array = [
	[146.83, 220.00, 293.66, 369.99], # D maj9 (sonsuz ufuk)
	[110.00, 164.81, 220.00, 277.18], # A add9
	[98.00, 146.83, 196.00, 246.94],  # G maj7
	[130.81, 196.00, 261.63, 329.63]  # C add9 kristal
]

const CHIME_PENTATONIC: Array[float] = [
	392.00, 440.00, 523.25, 587.33, 659.25, 783.99, 880.00, 1046.50
]

var current_scenario: int = 0

func set_scenario(scenario: int) -> void:
	current_scenario = scenario

func update_climate_mood(carbon: int) -> void:
	current_carbon = carbon

var _audio_unlocked: bool = false

func _can_play_sfx() -> bool:
	if sfx_player == null or volume <= 0.01 or is_muted:
		return false
	if OS.has_feature("web") and not _audio_unlocked:
		return false
	return true


func _ready() -> void:
	sfx_player = AudioStreamPlayer.new()
	var gen := AudioStreamGenerator.new()
	gen.mix_rate = 22050.0
	gen.buffer_length = 0.25
	sfx_player.stream = gen
	add_child(sfx_player)

	music_player = AudioStreamPlayer.new()
	var mgen := AudioStreamGenerator.new()
	mgen.mix_rate = 22050.0
	mgen.buffer_length = 0.35
	music_player.stream = mgen
	add_child(music_player)
	if not OS.has_feature("web"):
		_audio_unlocked = true
		music_player.play()

func _input(event: InputEvent) -> void:
	if not _audio_unlocked and (event is InputEventMouseButton or event is InputEventKey or event is InputEventScreenTouch):
		_audio_unlocked = true
		if music_player != null and not music_player.playing and music_volume > 0.01:
			music_player.play()

func _process(delta: float) -> void:
	_music_time += delta
	if music_player == null or music_volume <= 0.01 or is_muted:
		return
	if not _audio_unlocked:
		return
	if not music_player.playing:
		music_player.play()
	var pb := music_player.get_stream_playback() as AudioStreamGeneratorPlayback
	if pb == null:
		return
	var avail: int = pb.get_frames_available()
	if avail <= 0:
		return

	var active_chords: Array = CHORDS_MODERATE
	if current_scenario == 3:
		active_chords = CHORDS_SANDBOX
	elif current_scenario == 1:
		if current_carbon <= 20:
			active_chords = CHORDS_CLEAN
		elif current_carbon >= 38:
			active_chords = CHORDS_INDUSTRIAL
		else:
			active_chords = CHORDS_POLLUTED
	elif current_scenario == 2:
		if current_carbon <= 20:
			active_chords = CHORDS_CLEAN
		else:
			active_chords = CHORDS_DESERT
	else:
		if current_carbon <= 25:
			active_chords = CHORDS_CLEAN
		elif current_carbon >= 55:
			active_chords = CHORDS_POLLUTED

	var chord_duration: float = 5.0
	var chord_idx: int = int(_music_time / chord_duration) % active_chords.size()
	var chord: Array = active_chords[chord_idx]
	var tf1: float = float(chord[0])
	var tf2: float = float(chord[1])
	var tf3: float = float(chord[2])
	var tf4: float = float(chord[3]) if chord.size() > 3 else tf1 * 2.0
	var tfsub: float = tf1 * 0.5

	# Pürüzsüz akor geçişi (glissando / portamento)
	var smooth_rate: float = clampf(delta * 2.8, 0.0, 1.0)
	_cur_f1 = lerpf(_cur_f1, tf1, smooth_rate)
	_cur_f2 = lerpf(_cur_f2, tf2, smooth_rate)
	_cur_f3 = lerpf(_cur_f3, tf3, smooth_rate)
	_cur_f4 = lerpf(_cur_f4, tf4, smooth_rate)
	_cur_fsub = lerpf(_cur_fsub, tfsub, smooth_rate)

	# Solarpunk Kristal Arpej / Kalimba Nabzı
	_chime_timer += delta
	var chime_step_dur: float = 0.52
	if _chime_timer >= chime_step_dur:
		_chime_timer -= chime_step_dur
		_chime_step = (_chime_step + 1) % CHIME_PENTATONIC.size()
		var p_idx: int = (_chime_step + chord_idx * 2) % CHIME_PENTATONIC.size()
		_chime_freq = CHIME_PENTATONIC[p_idx]
		if current_carbon <= 15:
			# Düşük karbonda ışıldayan üst oktav
			_chime_freq = _chime_freq * 1.5 if (_chime_step % 2 == 1) else _chime_freq
		_chime_env = 1.0

	var lfo: float = 0.80 + 0.20 * sin(_music_time * 0.9)
	var amp: float = 0.038 * music_volume * lfo
	var decay_rate: float = 1.0 / (0.42 * 22050.0)

	for i in range(avail):
		# Pad katmanı (Yumuşak harmonikler)
		var p1: float = sin(_music_phase_1 * TAU) * 0.32
		var p2: float = sin(_music_phase_2 * TAU) * 0.28
		var p3: float = sin(_music_phase_3 * TAU) * 0.22
		var p4: float = sin(_music_phase_4 * TAU) * 0.18
		var pad_sample: float = p1 + p2 + p3 + p4

		# Sub-bas katmanı (Derin sıcaklık)
		var sub_sample: float = sin(_music_phase_sub * TAU) * 0.30

		# Kalimba / Çan arpej katmanı
		var chime_sample: float = (sin(_music_phase_chime * TAU) * 0.85 + sin(_music_phase_chime * TAU * 2.0) * 0.15) * _chime_env * 0.35
		_chime_env = maxf(0.0, _chime_env - decay_rate)

		var s_left: float = (pad_sample + sub_sample + chime_sample * 1.15) * amp
		var s_right: float = (pad_sample + sub_sample + chime_sample * 0.85) * amp

		_music_phase_1 = fmod(_music_phase_1 + _cur_f1 / 22050.0, 1.0)
		_music_phase_2 = fmod(_music_phase_2 + _cur_f2 / 22050.0, 1.0)
		_music_phase_3 = fmod(_music_phase_3 + _cur_f3 / 22050.0, 1.0)
		_music_phase_4 = fmod(_music_phase_4 + _cur_f4 / 22050.0, 1.0)
		_music_phase_sub = fmod(_music_phase_sub + _cur_fsub / 22050.0, 1.0)
		_music_phase_chime = fmod(_music_phase_chime + _chime_freq / 22050.0, 1.0)

		pb.push_frame(Vector2(s_left, s_right))

func _exit_tree() -> void:
	if sfx_player != null:
		sfx_player.stop()
	if music_player != null:
		music_player.stop()

func play_tone(freq_start: float, freq_end: float, duration: float = 0.12, vol: float = 0.22) -> void:
	if not _can_play_sfx():
		return
	if not sfx_player.playing:
		sfx_player.play()
	var playback := sfx_player.get_stream_playback() as AudioStreamGeneratorPlayback
	if playback == null:
		return
	var frames: int = mini(int(duration * 22050.0), playback.get_frames_available())
	var phase: float = 0.0
	for i in range(frames):
		var t: float = float(i) / maxf(1.0, float(frames))
		var freq: float = lerpf(freq_start, freq_end, t)
		var env: float = (1.0 - t) * vol * volume
		var sample: float = sin(phase * TAU) * env
		phase = fmod(phase + freq / 22050.0, 1.0)
		playback.push_frame(Vector2(sample, sample))

func play_fanfare() -> void:
	if not _can_play_sfx():
		return
	if not sfx_player.playing:
		sfx_player.play()
	var playback := sfx_player.get_stream_playback() as AudioStreamGeneratorPlayback
	if playback == null:
		return
	var notes: Array[float] = [523.25, 659.25, 783.99, 1046.50]
	var note_dur: float = 0.09
	var total_frames: int = mini(int(notes.size() * note_dur * 22050.0), playback.get_frames_available())
	var frames_per_note: int = int(note_dur * 22050.0)
	var phase: float = 0.0
	for i in range(total_frames):
		var n_idx: int = mini(int(i / frames_per_note), notes.size() - 1)
		var freq: float = notes[n_idx]
		var local_t: float = float(i % frames_per_note) / float(frames_per_note)
		var env: float = (1.0 - local_t * 0.7) * 0.28 * volume
		var sample: float = (sin(phase * TAU) * 0.7 + sin(phase * TAU * 2.0) * 0.3) * env
		phase = fmod(phase + freq / 22050.0, 1.0)
		playback.push_frame(Vector2(sample, sample))

func play_crisis_alarm() -> void:
	if not _can_play_sfx():
		return
	if not sfx_player.playing:
		sfx_player.play()
	var playback := sfx_player.get_stream_playback() as AudioStreamGeneratorPlayback
	if playback == null:
		return
	var duration: float = 0.40
	var frames: int = mini(int(duration * 22050.0), playback.get_frames_available())
	var phase: float = 0.0
	for i in range(frames):
		var t: float = float(i) / float(frames)
		var freq: float = 280.0 + sin(t * TAU * 4.0) * 110.0
		var env: float = (1.0 - t * 0.5) * 0.32 * volume
		var sample: float = (sin(phase * TAU) + (1.0 if sin(phase * TAU) > 0.0 else -1.0) * 0.25) * 0.5 * env
		phase = fmod(phase + freq / 22050.0, 1.0)
		playback.push_frame(Vector2(sample, sample))

func play_upgrade(level: int = 2) -> void:
	if not _can_play_sfx():
		return
	if not sfx_player.playing:
		sfx_player.play()
	var playback := sfx_player.get_stream_playback() as AudioStreamGeneratorPlayback
	if playback == null:
		return

	if level >= 3:
		# Level 3 (★★ Mega): Görkemli göksel arpejli çift armonik fanfar [C5, E5, G5, C6, E6, G6, C7]
		var notes: Array[float] = [523.25, 659.25, 783.99, 1046.50, 1318.51, 1567.98, 2093.00]
		var note_dur: float = 0.065
		var total_frames: int = mini(int(notes.size() * note_dur * 22050.0), playback.get_frames_available())
		var frames_per_note: int = int(note_dur * 22050.0)
		var phase1: float = 0.0
		var phase2: float = 0.0
		for i in range(total_frames):
			var n_idx: int = mini(int(i / frames_per_note), notes.size() - 1)
			var freq: float = notes[n_idx]
			var t_note: float = float(i % frames_per_note) / float(frames_per_note)
			var total_t: float = float(i) / float(total_frames)
			var env: float = (1.0 - t_note * 0.45) * (0.8 + 0.2 * total_t) * 0.35 * volume
			var shimmer: float = sin(total_t * TAU * 12.0) * 0.15
			var s: float = (sin(phase1 * TAU) * 0.65 + sin(phase2 * TAU) * 0.35 + shimmer) * env
			phase1 = fmod(phase1 + freq / 22050.0, 1.0)
			phase2 = fmod(phase2 + (freq * 1.5) / 22050.0, 1.0)
			playback.push_frame(Vector2(s, s))
	else:
		# Level 2 (★): Parlak yükselen kristalize triad akor [E5, G#5, B5, E6]
		var notes: Array[float] = [659.25, 830.61, 987.77, 1318.51]
		var note_dur: float = 0.075
		var total_frames: int = mini(int(notes.size() * note_dur * 22050.0), playback.get_frames_available())
		var frames_per_note: int = int(note_dur * 22050.0)
		var phase: float = 0.0
		for i in range(total_frames):
			var n_idx: int = mini(int(i / frames_per_note), notes.size() - 1)
			var freq: float = notes[n_idx]
			var t_note: float = float(i % frames_per_note) / float(frames_per_note)
			var env: float = (1.0 - t_note * 0.6) * 0.30 * volume
			var s: float = (sin(phase * TAU) * 0.75 + sin(phase * TAU * 2.0) * 0.25) * env
			phase = fmod(phase + freq / 22050.0, 1.0)
			playback.push_frame(Vector2(s, s))

func play_perk_unlocked() -> void:
	if not _can_play_sfx():
		return
	if not sfx_player.playing:
		sfx_player.play()
	var playback := sfx_player.get_stream_playback() as AudioStreamGeneratorPlayback
	if playback == null:
		return
	# Solarpunk Reform Kanunu: İlham verici Cmaj9 akor tınısı [C5, E5, G5, B5, D6]
	var notes: Array[float] = [523.25, 659.25, 783.99, 987.77, 1174.66]
	var duration: float = 0.42
	var frames: int = mini(int(duration * 22050.0), playback.get_frames_available())
	var phases: Array[float] = [0.0, 0.0, 0.0, 0.0, 0.0]
	for i in range(frames):
		var t: float = float(i) / float(frames)
		var env: float = (1.0 - t * 0.8) * 0.28 * volume
		var s: float = 0.0
		for k in range(notes.size()):
			s += sin(phases[k] * TAU) * (0.35 - float(k) * 0.05)
			phases[k] = fmod(phases[k] + notes[k] / 22050.0, 1.0)
		playback.push_frame(Vector2(s * env, s * env))

func play_dawn_sweep() -> void:
	if not _can_play_sfx():
		return
	if not sfx_player.playing:
		sfx_player.play()
	var playback := sfx_player.get_stream_playback() as AudioStreamGeneratorPlayback
	if playback == null:
		return
	# Şafak Işığı Dalgası: Yükselen yumuşak güneş parıltısı ve ferah rezonans
	var duration: float = 0.38
	var frames: int = mini(int(duration * 22050.0), playback.get_frames_available())
	var phase1: float = 0.0
	var phase2: float = 0.0
	for i in range(frames):
		var t: float = float(i) / float(frames)
		var freq1: float = lerpf(330.0, 660.0, t)
		var freq2: float = lerpf(440.0, 880.0, t)
		var env: float = sin(t * PI) * 0.22 * volume
		var s: float = (sin(phase1 * TAU) * 0.6 + sin(phase2 * TAU) * 0.4) * env
		phase1 = fmod(phase1 + freq1 / 22050.0, 1.0)
		phase2 = fmod(phase2 + freq2 / 22050.0, 1.0)
		playback.push_frame(Vector2(s, s))

func play_milestone() -> void:
	if not _can_play_sfx():
		return
	if not sfx_player.playing:
		sfx_player.play()
	var playback := sfx_player.get_stream_playback() as AudioStreamGeneratorPlayback
	if playback == null:
		return
	# Şehir Gelişim ve Nüfus Dönüm Noktası Zafer Zili [F4, A4, C5, F5, A5, C6]
	var notes: Array[float] = [349.23, 440.00, 523.25, 698.46, 880.00, 1046.50]
	var note_dur: float = 0.08
	var total_frames: int = mini(int(notes.size() * note_dur * 22050.0), playback.get_frames_available())
	var frames_per_note: int = int(note_dur * 22050.0)
	var phase: float = 0.0
	for i in range(total_frames):
		var n_idx: int = mini(int(i / frames_per_note), notes.size() - 1)
		var freq: float = notes[n_idx]
		var t_note: float = float(i % frames_per_note) / float(frames_per_note)
		var env: float = (1.0 - t_note * 0.5) * 0.32 * volume
		var s: float = (sin(phase * TAU) * 0.7 + sin(phase * TAU * 2.0) * 0.3) * env
		phase = fmod(phase + freq / 22050.0, 1.0)
		playback.push_frame(Vector2(s, s))

func play_card_place(card_id: int = -1) -> void:
	const GameData = preload("res://scripts/GameData.gd")
	if card_id in [GameData.CardId.FOREST, GameData.CardId.BIOCORRIDOR, GameData.CardId.FARM]:
		# Doğa & Biyo-Çeşitlilik: Yumuşak organik filizlenme ve koru tınısı
		play_tone(340.0, 620.0, 0.11, 0.26)
	elif card_id in [GameData.CardId.WATER_PLANT]:
		# Su Altyapısı: Berrak su damlacığı ses dalgası
		play_tone(620.0, 1180.0, 0.08, 0.24)
	elif card_id in [GameData.CardId.HOUSING, GameData.CardId.COP31]:
		# Şehir & Diplomasi: Sıcak kentsel majör tınısı
		play_tone(440.0, 680.0, 0.12, 0.28)
	elif card_id in [GameData.CardId.EXPAND, GameData.CardId.ECO_SURVEY]:
		# Toprak Islahı / Radar Keşif: Genişleyen sonar arama dalgası
		play_tone(280.0, 760.0, 0.14, 0.30)
	elif card_id in [GameData.CardId.SOLAR, GameData.CardId.WIND, GameData.CardId.BATTERY, GameData.CardId.GEOTHERMAL]:
		# Temiz Enerji & Batarya: Parlak kristalize elektrik kıvılcımı
		play_tone(520.0, 920.0, 0.09, 0.25)
	else:
		play_tone(480.0, 720.0, 0.08, 0.22)

func play_synergy_chime() -> void:
	play_tone(659.25, 987.77, 0.10, 0.26)

func play_ui_hover() -> void:
	play_tone(1100.0, 1300.0, 0.02, 0.04)

func play_ui_click() -> void:
	play_tone(580.0, 440.0, 0.04, 0.08)

func play_district_unlock() -> void:
	play_tone(554.37, 830.61, 0.16, 0.32)

func play_weather_sound(w_type: int) -> void:
	const GameData = preload("res://scripts/GameData.gd")
	match w_type:
		GameData.WeatherType.CLEAR_SUN:
			play_tone(523.25, 659.25, 0.12, 0.22)
		GameData.WeatherType.SPRING_RAIN:
			play_tone(620.0, 980.0, 0.08, 0.18)
		GameData.WeatherType.FRESH_BREEZE:
			play_tone(440.0, 310.0, 0.14, 0.20)
		GameData.WeatherType.HEATWAVE_WARNING:
			play_tone(220.0, 145.0, 0.20, 0.25)

var _ambient_timer: float = 0.0

func process_ambient(delta: float, carbon: int, food: int, energy: int) -> void:
	if is_muted or volume <= 0.01:
		return
	_ambient_timer += delta
	if _ambient_timer >= 17.0:
		_ambient_timer = randf_range(0.0, 4.0)
		if carbon < 30 and food >= 8:
			play_nature_chirp()
		elif carbon >= 60:
			play_hazard_drone()

func play_nature_chirp() -> void:
	if not _can_play_sfx():
		return
	if not sfx_player.playing:
		sfx_player.play()
	var playback := sfx_player.get_stream_playback() as AudioStreamGeneratorPlayback
	if playback == null:
		return
	var duration: float = 0.16
	var frames: int = mini(int(duration * 22050.0), playback.get_frames_available())
	var phase1: float = 0.0
	var phase2: float = 0.0
	for i in range(frames):
		var t: float = float(i) / float(frames)
		var freq1: float = 1800.0 + sin(t * TAU * 3.0) * 450.0 + t * 400.0
		var freq2: float = 2400.0 + cos(t * TAU * 2.5) * 300.0
		var env: float = sin(t * PI) * 0.12 * volume
		var s: float = (sin(phase1 * TAU) * 0.6 + sin(phase2 * TAU) * 0.4) * env
		phase1 = fmod(phase1 + freq1 / 22050.0, 1.0)
		phase2 = fmod(phase2 + freq2 / 22050.0, 1.0)
		playback.push_frame(Vector2(s, s))

func play_hazard_drone() -> void:
	if not _can_play_sfx():
		return
	if not sfx_player.playing:
		sfx_player.play()
	var playback := sfx_player.get_stream_playback() as AudioStreamGeneratorPlayback
	if playback == null:
		return
	var duration: float = 0.32
	var frames: int = mini(int(duration * 22050.0), playback.get_frames_available())
	var phase: float = 0.0
	for i in range(frames):
		var t: float = float(i) / float(frames)
		var freq: float = lerpf(85.0, 60.0, t)
		var env: float = sin(t * PI) * 0.15 * volume
		var s: float = sin(phase * TAU) * env
		phase = fmod(phase + freq / 22050.0, 1.0)
		playback.push_frame(Vector2(s, s))

func play_card_draw() -> void:
	if not _can_play_sfx():
		return
	if not sfx_player.playing:
		sfx_player.play()
	var playback := sfx_player.get_stream_playback() as AudioStreamGeneratorPlayback
	if playback == null:
		return
	var duration: float = 0.09
	var frames: int = mini(int(duration * 22050.0), playback.get_frames_available())
	var phase: float = 0.0
	for i in range(frames):
		var t: float = float(i) / float(frames)
		var freq: float = lerpf(380.0, 740.0, t)
		var noise: float = randf_range(-0.15, 0.15)
		var env: float = sin(t * PI) * 0.22 * volume
		var sample: float = (sin(phase * TAU) * 0.7 + noise * 0.3) * env
		phase = fmod(phase + freq / 22050.0, 1.0)
		playback.push_frame(Vector2(sample, sample))

func play_demolish() -> void:
	if not _can_play_sfx():
		return
	if not sfx_player.playing:
		sfx_player.play()
	var playback := sfx_player.get_stream_playback() as AudioStreamGeneratorPlayback
	if playback == null:
		return
	var duration: float = 0.24
	var frames: int = mini(int(duration * 22050.0), playback.get_frames_available())
	var phase: float = 0.0
	for i in range(frames):
		var t: float = float(i) / float(frames)
		var freq: float = lerpf(160.0, 50.0, t)
		var noise: float = randf_range(-0.4, 0.4)
		var env: float = (1.0 - t) * 0.35 * volume
		var sample: float = (sin(phase * TAU) * 0.55 + noise * 0.45) * env
		phase = fmod(phase + freq / 22050.0, 1.0)
		playback.push_frame(Vector2(sample, sample))
