extends RefCounted

const GRID_SIZE: int = 20
const ISO_W: float = 68.0
const ISO_H: float = 34.0
const MAX_DAYS: int = 25
const MAX_CARBON: int = 100
const ZERO_CARBON_WIN_DAYS: int = 5
const PAN_SPEED: float = 480.0
const MIN_ZOOM: float = 0.55
const MAX_ZOOM: float = 1.85
const SAVE_PATH: String = "user://eco_grid_save.json"

enum TileState { LOCKED, BORDER, UNLOCKED }
enum BuildingType {
	NONE,
	SOLAR,
	WIND,
	HOUSING,
	FARM,
	FOREST,
	RECYCLE,
	WATER_PLANT,
	FOSSIL,
	COAL_PLANT,
	LAKE,
	GEOTHERMAL,
	CCS,
	BIOCORRIDOR,
	BATTERY,
	COP31
}

enum CardId {
	SOLAR,
	WIND,
	HOUSING,
	FARM,
	FOREST,
	RECYCLE,
	WATER_PLANT,
	FOSSIL,
	EXPAND,
	DEMOLISH,
	GEOTHERMAL,
	CCS,
	BIOCORRIDOR,
	UPGRADE_KIT,
	ECO_SURVEY,
	BATTERY,
	COP31
}

enum WeatherType {
	MODERATE,
	CLEAR_SUN,
	SPRING_RAIN,
	FRESH_BREEZE,
	HEATWAVE_WARNING
}

const WEATHER_INFO: Dictionary = {
	WeatherType.MODERATE: {
		"title": "Ilıman Solarpunk",
		"icon": "🌤️",
		"desc": "Standart mevsim sıcaklıkları, şehir şebekesi dengeli çalışıyor.",
		"color": Color(0.68, 0.88, 0.95),
		"bonus_desc": "Dengeli gün"
	},
	WeatherType.CLEAR_SUN: {
		"title": "Güneş Zirvesi",
		"icon": "☀️",
		"desc": "Güneş panelleri maksimum verimde! Her Güneş Paneli ekstra ⚡+1 üretir.",
		"color": Color(1.0, 0.88, 0.25),
		"bonus_desc": "Güneş Panelleri ⚡+1"
	},
	WeatherType.SPRING_RAIN: {
		"title": "Bahar Yağmurları",
		"icon": "🌧️",
		"desc": "Yağmur akiferleri ve barajları besliyor! Su Tesisleri 💧+1, Orman ve Tarım 🌱+1.",
		"color": Color(0.38, 0.82, 1.0),
		"bonus_desc": "Su & Tarım 💧+1, 🌱+1"
	},
	WeatherType.FRESH_BREEZE: {
		"title": "Temiz Rüzgarlar",
		"icon": "💨",
		"desc": "Sert temiz hava koridoru! Rüzgar türbinleri ekstra ⚡+1 üretir, hava temizlenir (-1☣️).",
		"color": Color(0.42, 0.96, 0.82),
		"bonus_desc": "Rüzgar Türbinleri ⚡+1, -1☣️"
	},
	WeatherType.HEATWAVE_WARNING: {
		"title": "Sıcaklık Uyarısı",
		"icon": "⚠️",
		"desc": "Ufukta sıcak hava dalgası yaklaşıyor! Kent Ormanlarını koruyun.",
		"color": Color(1.0, 0.45, 0.25),
		"bonus_desc": "Kriz öncesi sıcaklık baskısı"
	}
}

const CARDS: Dictionary = {
	CardId.SOLAR: {
		"title": "Güneş Paneli",
		"symbol": "☀️",
		"tag": "ENERJİ",
		"sprite_path": "res://assets/sprites/building_solar_farm.png",
		"color": Color(0.95, 0.76, 0.15),
		"cost_text": "⚡+3  💧-1",
		"desc": "Komşu Eko-Konut ile ekstra ⚡+1",
		"pills": [ {"icon": "⚡", "text": "+3", "type": "energy"}, {"icon": "💧", "text": "-1", "type": "water_cost"} ],
		"synergy_tag": "✨ Konut ile: +1⚡",
		"fact": "📚 İklim Bilgisi: Güneş enerjisi, kömüre kıyasla yaşam döngüsü karbon salımını %95 oranında azaltır.",
		"target": "EMPTY",
		"building": BuildingType.SOLAR
	},
	CardId.WIND: {
		"title": "Rüzgar Türbini",
		"symbol": "🌀",
		"tag": "ENERJİ",
		"sprite_path": "res://assets/sprites/building_wind_turbine.png",
		"color": Color(0.35, 0.78, 0.95),
		"cost_text": "⚡+3  💧-2",
		"desc": "4 komşusu da boşsa ekstra ⚡+2",
		"pills": [ {"icon": "⚡", "text": "+3", "type": "energy"}, {"icon": "💧", "text": "-2", "type": "water_cost"} ],
		"synergy_tag": "✨ Boş Komşular: +2⚡",
		"fact": "📚 İklim Bilgisi: Tek bir modern rüzgar türbini yılda yaklaşık 6.000 ton CO₂ salımını önler.",
		"target": "EMPTY",
		"building": BuildingType.WIND
	},
	CardId.HOUSING: {
		"title": "Eko-Konut",
		"symbol": "🏠",
		"tag": "BARINMA",
		"sprite_path": "res://assets/sprites/building_eco_housing.png",
		"color": Color(0.92, 0.52, 0.24),
		"cost_text": "💧+3  ⚡-1  ☣️+1",
		"desc": "Komşuda Kent Ormanı varsa ☣️0, 🌱+1",
		"pills": [ {"icon": "💧", "text": "+3", "type": "water"}, {"icon": "⚡", "text": "-1", "type": "energy_cost"}, {"icon": "☣️", "text": "+1", "type": "carbon_bad"} ],
		"synergy_tag": "✨ Orman: ☣️0, +1🌱",
		"fact": "📚 İklim Bilgisi: Yeşil alanlarla entegre pasif evler ısıtma ve soğutma enerjisini %70 düşürür.",
		"target": "EMPTY",
		"building": BuildingType.HOUSING
	},
	CardId.FARM: {
		"title": "Dikey Tarım",
		"symbol": "🌾",
		"tag": "TARIM",
		"sprite_path": "res://assets/sprites/building_vertical_farm.png",
		"color": Color(0.55, 0.82, 0.22),
		"cost_text": "🌱+3  ⚡-1  💧-1",
		"desc": "Komşu Su Arıtma veya Göl ile ekstra 🌱+2",
		"pills": [ {"icon": "🌱", "text": "+3", "type": "food"}, {"icon": "⚡", "text": "-1", "type": "energy_cost"}, {"icon": "💧", "text": "-1", "type": "water_cost"} ],
		"synergy_tag": "✨ Su / Göl: +2🌱",
		"fact": "📚 İklim Bilgisi: Dikey tarım, geleneksel tarıma göre %90 daha az su ve %75 daha az arazi kullanır.",
		"target": "EMPTY",
		"building": BuildingType.FARM
	},
	CardId.FOREST: {
		"title": "Kent Ormanı",
		"symbol": "🌲",
		"tag": "EKOLOJİ",
		"sprite_path": "res://assets/sprites/building_urban_forest.png",
		"color": Color(0.16, 0.62, 0.34),
		"cost_text": "☣️-2  💧-1",
		"desc": "Komşu Konut/Kömür başına ekstra ☣️-1",
		"pills": [ {"icon": "☣️", "text": "-2", "type": "carbon_good"}, {"icon": "💧", "text": "-1", "type": "water_cost"} ],
		"synergy_tag": "✨ Kirletici başına: -1☣️",
		"fact": "📚 İklim Bilgisi: Kent ormanları kentsel ısı adası etkisini 5°C'ye kadar düşürür ve karbon yutağı oluşturur.",
		"target": "EMPTY",
		"building": BuildingType.FOREST
	},
	CardId.RECYCLE: {
		"title": "Geri Dönüşüm",
		"symbol": "♻️",
		"tag": "DÖNGÜ",
		"sprite_path": "res://assets/sprites/building_recycling.png",
		"color": Color(0.22, 0.74, 0.64),
		"cost_text": "💧+2  ⚡-1  ☣️-1",
		"desc": "Komşu her Eko-Konut için ekstra 💧+1",
		"pills": [ {"icon": "💧", "text": "+2", "type": "water"}, {"icon": "⚡", "text": "-1", "type": "energy_cost"}, {"icon": "☣️", "text": "-1", "type": "carbon_good"} ],
		"synergy_tag": "✨ Eko-Konut ile: +1💧",
		"fact": "📚 İklim Bilgisi: Sıfır atık ve döngüsel ekonomi, kentsel sera gazı emisyonlarını %40 azaltabilir.",
		"target": "EMPTY",
		"building": BuildingType.RECYCLE
	},
	CardId.WATER_PLANT: {
		"title": "Su Arıtma Tesisi",
		"symbol": "🚰",
		"tag": "ALTYAPI",
		"sprite_path": "res://assets/sprites/building_water_treatment.png",
		"color": Color(0.20, 0.48, 0.88),
		"cost_text": "💧+3  ⚡-1",
		"desc": "Komşu Göl ile 💧+2, Orman ile ☣️-1",
		"pills": [ {"icon": "💧", "text": "+3", "type": "water"}, {"icon": "⚡", "text": "-1", "type": "energy_cost"} ],
		"synergy_tag": "✨ Göl: 💧+2 | Orman: ☣️-1",
		"fact": "📚 İklim Bilgisi: Atık suyun geri kazanımı, kuraklık dönemlerinde şehirlerin tatlı su rezervini korur.",
		"target": "EMPTY",
		"building": BuildingType.WATER_PLANT
	},
	CardId.FOSSIL: {
		"title": "Fosil Jeneratör",
		"symbol": "🏭",
		"tag": "FOSİL",
		"sprite_path": "res://assets/sprites/building_coal_plant.png",
		"color": Color(0.46, 0.38, 0.48),
		"cost_text": "⚡+6  ☣️+5",
		"desc": "Acil yüksek enerji, yoğun kirlilik!",
		"pills": [ {"icon": "⚡", "text": "+6", "type": "energy"}, {"icon": "☣️", "text": "+5", "type": "carbon_bad"} ],
		"synergy_tag": "⚠️ Atmosferi Kirletir",
		"fact": "📚 İklim Bilgisi: Fosil yakıtlar küresel sera gazı emisyonlarının %75'inden fazlasından sorumludur.",
		"target": "EMPTY",
		"building": BuildingType.FOSSIL
	},
	CardId.EXPAND: {
		"title": "Toprak Islahı",
		"symbol": "🚜",
		"tag": "ISLAH",
		"sprite_path": "res://assets/sprites/tile_border_reclamation.png",
		"color": Color(0.76, 0.60, 0.32),
		"cost_text": "💧-2  ⚡-2  ☣️-2",
		"desc": "Sınır kareyi ve 3x3 çevresini açar",
		"pills": [ {"icon": "🌱", "text": "3x3 Aç", "type": "special"}, {"icon": "⚡", "text": "-2", "type": "energy_cost"}, {"icon": "💧", "text": "-2", "type": "water_cost"}, {"icon": "☣️", "text": "-2", "type": "carbon_good"} ],
		"synergy_tag": "🌱 Sadece Sınır Kareye",
		"fact": "📚 İklim Bilgisi: Bozulan toprakların onarımı hem biyoçeşitliliği artırır hem de toprakta karbon tutar.",
		"target": "BORDER",
		"building": BuildingType.NONE
	},
	CardId.DEMOLISH: {
		"title": "Kentsel Dönüşüm",
		"symbol": "🏗️",
		"tag": "YIKIM",
		"sprite_path": "res://assets/sprites/tile_industrial_polluted.png",
		"color": Color(0.86, 0.32, 0.32),
		"cost_text": "⚡-1  💧+2",
		"desc": "Dolu kareyi veya Kömürü yıkar",
		"pills": [ {"icon": "💥", "text": "Yık", "type": "special"}, {"icon": "⚡", "text": "-1", "type": "energy_cost"}, {"icon": "💧", "text": "+2", "type": "water"} ],
		"synergy_tag": "💥 Kömür / Dolu Kareyi Yıkar",
		"fact": "📚 İklim Bilgisi: Eski ve kirletici tesislerin tasfiyesi, net-sıfır karbon hedefine geçişin anahtarıdır.",
		"target": "OCCUPIED",
		"building": BuildingType.NONE
	},
	CardId.GEOTHERMAL: {
		"title": "Jeotermal Santral",
		"symbol": "🌋",
		"tag": "TERMAL",
		"sprite_path": "res://assets/sprites/building_geothermal.png",
		"color": Color(0.95, 0.48, 0.22),
		"cost_text": "⚡+4  🌱-1",
		"desc": "Komşu Göl veya Su Arıtma ile ekstra ⚡+2",
		"pills": [ {"icon": "⚡", "text": "+4", "type": "energy"}, {"icon": "🌱", "text": "-1", "type": "food_cost"} ],
		"synergy_tag": "✨ Göl / Su Tesisi: +2⚡",
		"fact": "📚 İklim Bilgisi: Jeotermal enerji, hava koşullarından bağımsız 7/24 kesintisiz temiz baz yük enerjisi sağlar.",
		"target": "EMPTY",
		"building": BuildingType.GEOTHERMAL
	},
	CardId.CCS: {
		"title": "Karbon Yakalama",
		"symbol": "🧪",
		"tag": "KARBON",
		"sprite_path": "res://assets/sprites/building_carbon_capture.png",
		"color": Color(0.45, 0.88, 0.92),
		"cost_text": "☣️-4  ⚡-2",
		"desc": "Komşu Fosil/Kömür başına ekstra ☣️-2",
		"pills": [ {"icon": "☣️", "text": "-4", "type": "carbon_good"}, {"icon": "⚡", "text": "-2", "type": "energy_cost"} ],
		"synergy_tag": "✨ Kömür / Fosil: -2☣️",
		"fact": "📚 İklim Bilgisi: Doğrudan hava yakalama (DAC) ve CCS teknolojileri atmosferdeki birikmiş CO₂'yi kalıcı olarak hapseder.",
		"target": "EMPTY",
		"building": BuildingType.CCS
	},
	CardId.BIOCORRIDOR: {
		"title": "Biyo-Koridor",
		"symbol": "🦋",
		"tag": "BİYO",
		"sprite_path": "res://assets/sprites/building_bio_corridor.png",
		"color": Color(0.38, 0.92, 0.55),
		"cost_text": "🌱+2  💧+1  ☣️-1",
		"desc": "Komşu Tarım ve Orman ile 🌱+1, ☣️-1",
		"pills": [ {"icon": "🌱", "text": "+2", "type": "food"}, {"icon": "💧", "text": "+1", "type": "water"}, {"icon": "☣️", "text": "-1", "type": "carbon_good"} ],
		"synergy_tag": "✨ Tarım/Orman: 🌱+1 ☣️-1",
		"fact": "📚 İklim Bilgisi: Ekolojik koridorlar tozlayıcı böcekleri koruyarak tarımsal verimi ve ekosistem direncini artırır.",
		"target": "EMPTY",
		"building": BuildingType.BIOCORRIDOR
	},
	CardId.UPGRADE_KIT: {
		"title": "Modüler Yükseltme",
		"symbol": "✨",
		"tag": "MODÜLER",
		"sprite_path": "res://assets/sprites/building_cop31_center.png",
		"color": Color(0.98, 0.85, 0.32),
		"cost_text": "⚡-2  💧-1",
		"desc": "Binayı Lv.2 (★) veya Mega'ya (★★) yükseltir",
		"pills": [ {"icon": "★", "text": "Yükselt", "type": "special"}, {"icon": "⚡", "text": "-2", "type": "energy_cost"}, {"icon": "💧", "text": "-1", "type": "water_cost"} ],
		"synergy_tag": "★ Doğrudan Üst Seviyeye",
		"fact": "📚 İklim Bilgisi: Binaları yıkıp yeniden yapmak yerine retrofit (iyileştirme) yapmak gömülü karbonu %80 azaltır.",
		"target": "UPGRADEABLE",
		"building": BuildingType.NONE
	},
	CardId.ECO_SURVEY: {
		"title": "Eko-Radar Tarama",
		"symbol": "🛰️",
		"tag": "RADAR",
		"sprite_path": "res://assets/sprites/tile_unlocked_grid.png",
		"color": Color(0.28, 0.78, 0.95),
		"cost_text": "⚡-3  💧-1",
		"desc": "Herhangi bir kilitli sisi uzaktan tarar",
		"pills": [ {"icon": "🛰️", "text": "Keşif", "type": "special"}, {"icon": "⚡", "text": "-3", "type": "energy_cost"}, {"icon": "💧", "text": "-1", "type": "water_cost"} ],
		"synergy_tag": "🛰️ Haritada Kilitli Kareyi Açar",
		"fact": "📚 İklim Bilgisi: Yüksek çözünürlüklü uydu radar spektroskopisi, uzak ekosistemleri izlemek için yüksek enerji harcar.",
		"target": "LOCKED",
		"building": BuildingType.NONE
	},
	CardId.BATTERY: {
		"title": "Mega Batarya",
		"symbol": "🔋",
		"tag": "BATARYA",
		"sprite_path": "res://assets/sprites/building_battery_lvl2.png",
		"color": Color(0.24, 0.88, 0.72),
		"cost_text": "⚡+4  💧-1",
		"desc": "Komşu Güneş/Rüzgar başına ekstra ⚡+2",
		"pills": [ {"icon": "⚡", "text": "+4", "type": "energy"}, {"icon": "💧", "text": "-1", "type": "water_cost"} ],
		"synergy_tag": "✨ Güneş / Rüzgar: +2⚡",
		"fact": "📚 İklim Bilgisi: Şebeke ölçekli lityum ve tuz bataryaları, yenilenebilir enerjinin kesintili üretimini kesintisiz baz yüke dönüştürür.",
		"target": "EMPTY",
		"building": BuildingType.BATTERY
	},
	CardId.COP31: {
		"title": "COP31 Zirve Merkezi",
		"symbol": "🏛️",
		"tag": "DİPLOMASİ",
		"sprite_path": "res://assets/sprites/building_cop31_center.png",
		"color": Color(0.35, 0.72, 1.0),
		"cost_text": "⚡+3 🌱+3 💧+3 ☣️-4",
		"desc": "Net-sıfır iklim zirvesi anıtı",
		"pills": [ {"icon": "⚡", "text": "+3", "type": "energy"}, {"icon": "🌱", "text": "+3", "type": "food"}, {"icon": "💧", "text": "+3", "type": "water"}, {"icon": "☣️", "text": "-4", "type": "carbon_good"} ],
		"synergy_tag": "🏆 Net-Sıfır Liderlik Anıtı",
		"fact": "📚 İklim Bilgisi: COP31 İklim Liderliği, küresel şehirlerin net-sıfır teknoloji transferini ve iklim direncini koordine eder.",
		"target": "EMPTY",
		"building": BuildingType.COP31
	}
}

const PERKS: Array = [
	{
		"id": "solar_roof",
		"title": "☀️ Güneş Çatı Zorunluluğu",
		"desc": "Tüm Güneş Panelleri her tur ekstra ⚡+1 üretir."
	},
	{
		"id": "wind_corridor",
		"title": "🌀 Rüzgar Koridoru Yasası",
		"desc": "Tüm Rüzgar Türbinleri her tur ekstra ⚡+1 üretir."
	},
	{
		"id": "green_roof",
		"title": "🏠 Yeşil Çatı Yönetmeliği",
		"desc": "Tüm Eko-Konutların karbon salımı ☣️-1 azalır ve 🌱+1 gıda sağlar."
	},
	{
		"id": "drip_irrigation",
		"title": "🌾 Damla Sulama Reformu",
		"desc": "Tüm Dikey Tarım tesisleri her tur ekstra 🌱+1 ve 💧+1 sağlar."
	},
	{
		"id": "carbon_sink",
		"title": "🌲 Karbon Yutağı Seferberliği",
		"desc": "Tüm Kent Ormanları her tur ekstra ☣️-1 karbon temizler."
	},
	{
		"id": "zero_waste",
		"title": "♻️ Sıfır Atık Yasası",
		"desc": "Tüm Geri Dönüşüm Tesisleri her tur ekstra 💧+1 ve ☣️-1 sağlar."
	},
	{
		"id": "blue_economy",
		"title": "🚰 Mavi Ekonomi Koruma Paketi",
		"desc": "Tüm Su Arıtma Tesisleri her tur ekstra 💧+1 üretir."
	},
	{
		"id": "coal_phaseout",
		"title": "🔥 Kömürden Çıkış Fonu",
		"desc": "Haritadaki Kömür Santrallerinin kirliliği yarıya iner ve yıkımı ⚡ harcamaz."
	},
	{
		"id": "energy_storage",
		"title": "⚡ Akıllı Şebeke & Mega-Bataryalar",
		"desc": "Tüm Güneş, Rüzgar ve Jeotermal tesisler her tur fazladan ⚡+1 üretir; Şebeke Çöküşü krizini önler."
	},
	{
		"id": "pollinator_network",
		"title": "🐝 Polenleme & Biyo-Çeşitlilik Fonu",
		"desc": "Kent Ormanı ve Biyo-Koridorlar komşularındaki Dikey Tarıma her tur fazladan 🌱+2 gıda kazandırır."
	},
	{
		"id": "circular_metropolis",
		"title": "🔄 Döngüsel Şehirleşme Paktı",
		"desc": "Eko-Konutlar her tur fazladan 💧+1 sağlar ve komşudaki Geri Dönüşümden ⚡+1 kazanır."
	},
	{
		"id": "geothermal_district",
		"title": "🌋 Kentsel Jeotermal Bölge Isıtması",
		"desc": "Jeotermal Santraller gıda tüketmez (🌱0) ve her tur ekstra ⚡+2 temiz enerji sağlar."
	},
	{
		"id": "wetland_conservation",
		"title": "🪷 Sulak Alan Muhafazası",
		"desc": "Doğal Göller ve Su Arıtma Tesisleri komşudaki Kent Ormanına ☣️-2 ekstra karbon emilimi verir."
	},
	{
		"id": "direct_air_subsidies",
		"title": "🧪 Doğrudan Karbon Yakalama (DAC) Teşviki",
		"desc": "Karbon Yakalama (CCS) tesislerinin enerji sarfiyatı yarıya iner (⚡-1) ve ☣️-2 daha fazla karbon çeker."
	},
	{
		"id": "rewilding_incentive",
		"title": "🌿 Kentsel Doğa Onarımı Teşviki",
		"desc": "Haritada en az 4 doğa alanı (Orman/Koridor/Göl) varken her gün başlangıcında şehre 💧+2 ve 🌱+2 hibe verilir."
	},
	{
		"id": "climate_diplomacy",
		"title": "🏛️ COP31 Küresel İklim Liderliği",
		"desc": "Karbon seviyesi 10 ve altındayken şehir her tur uluslararası iklim fonundan ⚡+2, 🌱+2 ve 💧+2 destek alır."
	}
]

const DILEMMAS: Array = [
	{
		"day": 4,
		"title": "🌾 BİYO-TARIM & GIDA DÖNÜŞÜMÜ",
		"desc": "Şehir konseyi artan nüfus için gıda politikasını oyluyor. Doğal polenleme ekolojisi mi, yoksa yüksek teknolojili damla sulama otomasyonu mu seçilmeli?",
		"opt_a_text": "🐝 Polenleme & Doğa Koridoru Paktı\n\n• Anında: 🌱+4 Gıda, ☣️-6 Karbon\n• Kalıcı Yasa: 🐝 Polenleme Fonu (Ormanlar tarıma 🌱+2 verir)",
		"opt_a_delta": {"e": 0, "f": 4, "w": 0, "c": -6},
		"opt_a_perk": "pollinator_network",
		"opt_b_text": "💧 Damla Sulama & LED Otomasyonu\n\n• Anında: ⚡+4 Enerji, 🌱+5 Gıda, ☣️+3 Karbon\n• Kalıcı Yasa: 🌾 Damla Sulama Reformu (Tüm tarım 🌱+1, 💧+1)",
		"opt_b_delta": {"e": 4, "f": 5, "w": 0, "c": 3},
		"opt_b_perk": "drip_irrigation"
	},
	{
		"day": 8,
		"title": "⚡ KARBON VERGİSİ & ENERJİ GEÇİŞİ",
		"desc": "COP31 iklim raporları bölgesel emisyonların acilen düşürülmesini istiyor. Kömür santrallerine karşı radikal yaptırım mı, yoksa yeşil enerji teşviki mi?",
		"opt_a_text": "🔥 Kömürden Radikal Çıkış Paktı\n\n• Anında: ☣️-14 Karbon, 💧+3 Su, ⚡-2 Enerji\n• Kalıcı Yasa: 🔥 Kömürden Çıkış Fonu (Kirlilik yarıya iner, yıkım bedava)",
		"opt_a_delta": {"e": -2, "f": 0, "w": 3, "c": -14},
		"opt_a_perk": "coal_phaseout",
		"opt_b_text": "☀️ Güneş Çatı & Şebeke Sübvansiyonu\n\n• Anında: ⚡+8 Enerji, 💧-2 Su\n• Kalıcı Yasa: ☀️ Güneş Çatı Zorunluluğu (Güneş panelleri fazladan ⚡+1 üretir)",
		"opt_b_delta": {"e": 8, "f": 0, "w": -2, "c": 0},
		"opt_b_perk": "solar_roof"
	},
	{
		"day": 12,
		"title": "🔄 DÖNGÜSEL EKONOMİ & AKILLI ŞEBEKE",
		"desc": "Şehir atık yönetimi ve enerji depolama alanında kritik bir dönemeçte. Hangi altyapı devrimini hayata geçireceksiniz?",
		"opt_a_text": "♻️ Döngüsel Şehirleşme & Sıfır Atık\n\n• Anında: 🌱+3 Gıda, 💧+5 Su, ☣️-6 Karbon\n• Kalıcı Yasa: 🔄 Döngüsel Şehirleşme Paktı (Konutlar 💧+1 üretir ve geri dönüşümden ⚡+1 alır)",
		"opt_a_delta": {"e": 0, "f": 3, "w": 5, "c": -6},
		"opt_a_perk": "circular_metropolis",
		"opt_b_text": "⚡ Mega-Batarya & Dinamik Depolama\n\n• Anında: ⚡+9 Enerji, ☣️+2 Karbon\n• Kalıcı Yasa: ⚡ Akıllı Şebeke (Temiz enerjiler ⚡+1 üretir, Şebeke Çöküşünü önler)",
		"opt_b_delta": {"e": 9, "f": 0, "w": 0, "c": 2},
		"opt_b_perk": "energy_storage"
	},
	{
		"day": 16,
		"title": "🏛️ COP31 KÜRESEL İKLİM ZİRVESİ TAAHHÜDÜ",
		"desc": "Birleşmiş Milletler COP31 Genel Kurulu şehrinizi 'Öncü İklim Kenti' ilan etmek üzere. Küresel taahhüdünüz nedir?",
		"opt_a_text": "🌍 Uluslararası İklim Diplomasisi\n\n• Anında: ⚡+5 Enerji, 🌱+5 Gıda, 💧+5 Su, ☣️-12 Karbon\n• Kalıcı Yasa: 🏛️ COP31 İklim Liderliği (Karbon ≤10 iken her gün ⚡+2, 🌱+2, 💧+2 fon)",
		"opt_a_delta": {"e": 5, "f": 5, "w": 5, "c": -12},
		"opt_a_perk": "climate_diplomacy",
		"opt_b_text": "🧪 Doğrudan Karbon Yakalama (DAC) Seferberliği\n\n• Anında: ☣️-22 Karbon (Devasa Temizlik!), ⚡-5 Enerji, 💧-3 Su\n• Kalıcı Yasa: 🧪 DAC Teşviki (CCS maliyeti yarıya iner, ☣️-2 daha çok çeker)",
		"opt_b_delta": {"e": -5, "f": 0, "w": -3, "c": -22},
		"opt_b_perk": "direct_air_subsidies"
	}
]

static func get_dilemma_for_day(day: int) -> Dictionary:
	for d in DILEMMAS:
		if d["day"] == day:
			return d
	var fallback_idx: int = int(day / 4) % DILEMMAS.size()
	return DILEMMAS[fallback_idx]

static func get_perk_title(perk_id: String) -> String:
	for p in PERKS:
		if p["id"] == perk_id:
			return p["title"]
	return perk_id

const ACHIEVEMENTS: Array = [
	{
		"id": "first_win",
		"title": "🏅 Sürdürülebilir Vali",
		"desc": "Herhangi bir senaryoda oyunu zaferle tamamla."
	},
	{
		"id": "zero_carbon_hero",
		"title": "🌿 Net-Sıfır Kahramanı",
		"desc": "Karbon emisyonunu 0'a indir."
	},
	{
		"id": "coal_breaker",
		"title": "🏗️ Kömürden Çıkış",
		"desc": "Bir oyunda en az 2 Kömür Santrali yık."
	},
	{
		"id": "master_architect",
		"title": "★ Baş Mimar",
		"desc": "Bir oyunda en az 3 binayı Seviye 2'ye (★) yükselt."
	},
	{
		"id": "mega_metropolis",
		"title": "★★ Mega Mühendis",
		"desc": "Herhangi bir binayı Seviye 3'e (★★ Mega-Tesis) yükselt."
	},
	{
		"id": "hard_mode_victor",
		"title": "🏭 Sanayi Dönüştürücü",
		"desc": "Zorlu 'Senaryo 2: Sanayi Mirası' modunu kazan."
	},
	{
		"id": "arid_oasis_master",
		"title": "🏜️ Çöl Vahası Lideri",
		"desc": "Uzman 'Senaryo 3: Kuraklık Vahası' modunu zaferle tamamla."
	},
	{
		"id": "forest_guardian",
		"title": "🌲 Yeşil Devrim Muhafızı",
		"desc": "Bir oyunda en az 4 Kent Ormanı veya Biyo-Koridor dik."
	},
	{
		"id": "clean_grid",
		"title": "⚡ Temiz Şebeke Lideri",
		"desc": "Bir oyunda en az 5 Güneş, Rüzgar veya Jeotermal tesis kur."
	},
	{
		"id": "metropolis",
		"title": "🌟 Eko-Metropol Kurucusu",
		"desc": "Şehir nüfusunu 8.000 veya üzerine ulaştır."
	},
	{
		"id": "battery_pioneer",
		"title": "🔋 Süper Şebeke Öncüsü",
		"desc": "Akıllı Mega-Batarya Depolama tesisini kur veya Seviye 3'e yükselt."
	},
	{
		"id": "cop31_champion",
		"title": "🏛️ COP31 Küresel Delegesi",
		"desc": "COP31 Diplomasi Merkezi inşa ederek küresel iklim zirvesine ev sahipliği yap."
	},
	{
		"id": "solarpunk_trio",
		"title": "✨ Solarpunk Mimarlar Birliği",
		"desc": "Aynı anda en az 3 farklı Seviye 3 (★★ Mega) tesis kurarak şehri taçlandır."
	}
]

static func get_building_visual(btype: int) -> Dictionary:
	match btype:
		BuildingType.SOLAR:
			return {"color": Color(0.95, 0.76, 0.15), "symbol": "☀️", "height": 18.0, "name": "Güneş Paneli"}
		BuildingType.WIND:
			return {"color": Color(0.35, 0.78, 0.95), "symbol": "🌀", "height": 24.0, "name": "Rüzgar Türbini"}
		BuildingType.HOUSING:
			return {"color": Color(0.92, 0.52, 0.24), "symbol": "🏠", "height": 22.0, "name": "Eko-Konut"}
		BuildingType.FARM:
			return {"color": Color(0.55, 0.82, 0.22), "symbol": "🌾", "height": 16.0, "name": "Dikey Tarım"}
		BuildingType.FOREST:
			return {"color": Color(0.16, 0.62, 0.34), "symbol": "🌲", "height": 20.0, "name": "Kent Ormanı"}
		BuildingType.RECYCLE:
			return {"color": Color(0.22, 0.74, 0.64), "symbol": "♻️", "height": 18.0, "name": "Geri Dönüşüm"}
		BuildingType.WATER_PLANT:
			return {"color": Color(0.20, 0.48, 0.88), "symbol": "🚰", "height": 18.0, "name": "Su Arıtma Tesisi"}
		BuildingType.FOSSIL:
			return {"color": Color(0.46, 0.38, 0.48), "symbol": "🏭", "height": 26.0, "name": "Fosil Jeneratör"}
		BuildingType.COAL_PLANT:
			return {"color": Color(0.36, 0.20, 0.22), "symbol": "🔥", "height": 28.0, "name": "Kömür Santrali"}
		BuildingType.LAKE:
			return {"color": Color(0.14, 0.54, 0.86), "symbol": "🌊", "height": 4.0, "name": "Doğal Göl"}
		BuildingType.GEOTHERMAL:
			return {"color": Color(0.95, 0.48, 0.22), "symbol": "🌋", "height": 22.0, "name": "Jeotermal Santral"}
		BuildingType.CCS:
			return {"color": Color(0.45, 0.88, 0.92), "symbol": "🧪", "height": 24.0, "name": "Karbon Yakalama (CCS)"}
		BuildingType.BIOCORRIDOR:
			return {"color": Color(0.38, 0.92, 0.55), "symbol": "🦋", "height": 16.0, "name": "Biyo-Koridor"}
		BuildingType.BATTERY:
			return {"color": Color(0.24, 0.88, 0.72), "symbol": "🔋", "height": 22.0, "name": "Akıllı Mega-Batarya"}
		BuildingType.COP31:
			return {"color": Color(0.35, 0.72, 1.0), "symbol": "🏛️", "height": 30.0, "name": "COP31 Diplomasi Merkezi"}
	return {"color": Color.TRANSPARENT, "symbol": "", "height": 0.0, "name": "Boş Alan"}

static func get_crisis_short_forecast(cid: int) -> String:
	match cid:
		0: return "🔥 Sıcak Hava (≥2 Orman lazım)"
		1: return "🌧️ Asit Yağmuru (☣️<50 tutun)"
		2: return "🌊 Deniz Yükselmesi (☣️<60 tutun)"
		3: return "⚡ Şebeke Çöküşü (≥2 Güneş/Rüzgar)"
		_: return "🏜️ Kuraklık (≥1 Su Arıtma lazım)"

static func grid_to_iso(gx: float, gy: float) -> Vector2:
	return Vector2((gx - gy) * (ISO_W * 0.5), (gx + gy) * (ISO_H * 0.5))

static func iso_to_grid(world_pos: Vector2) -> Vector2i:
	var u: float = world_pos.x / (ISO_W * 0.5)
	var v: float = world_pos.y / (ISO_H * 0.5)
	var gx: float = (u + v) * 0.5
	var gy: float = (v - u) * 0.5
	return Vector2i(int(floor(gx)), int(floor(gy)))

static func make_stylebox(bg: Color, border: Color, border_w: int = 2, radius: int = 8) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(border_w)
	sb.set_corner_radius_all(radius)
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	return sb

static func get_daily_eco_news(day: int, carbon: int, zero_streak: int, forests: int, coal_demolished: int) -> String:
	if zero_streak >= 3:
		return "📰 COP31 MANŞET: Şehir üst üste %d gündür 0-Karbon emisyonunda; küresel iklim lideri ilan edildi!" % zero_streak
	if carbon <= 5:
		return "📰 YEŞİL BÜLTEN: Atmosferik karbon neredeyse sıfırlandı; gökyüzü berraklaştı!"
	if coal_demolished >= 1:
		return "📰 SANAYİ GÜNDEMİ: Kömür santralinin tasfiyesiyle şehir solunabilir temiz havaya kavuştu."
	if forests >= 3:
		return "📰 DOĞA RAPORU: Genişleyen Kent Ormanları mikroklimayı serinletip buharlaşmayı önlüyor."
	if carbon >= 60:
		return "🚨 ACİL İKLİM ALARMI: Yüksek emisyon sebebiyle aşırı hava olayları riski arttı!"

	var headlines := [
		"📰 EKONOMİ: Dağıtık temiz enerji şebekesi şehrin enerji bağımsızlığını güçlendiriyor.",
		"📰 BİLİM: Dikey tarım tesisleri %95 daha az su kullanarak şehrin gıda arzını koruyor.",
		"📰 TEKNOLOJİ: Karbon yakalama ve filtreleme tesisleri doğrudan havadan CO2 emiyor.",
		"📰 ÇEVRE: Biyo-koridorlar sayesinde göçmen kuşlar ve yaban hayatı şehre geri döndü.",
		"📰 TOPLUM: Eko-konut sakinleri yeşil çatı bahçelerinde biyo-çeşitliliği destekliyor."
	]
	return headlines[day % headlines.size()]
