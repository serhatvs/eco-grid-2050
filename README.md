# 🌿 Eco-Grid: 2050

[![Godot Engine](https://img.shields.io/badge/Godot-4.3%2B-478cbf?logo=godotengine&logoColor=white)](https://godotengine.org)
[![Theme](https://img.shields.io/badge/COP31-Net--Zero%202050-2ecc71)](https://cop31.org)
[![Genre](https://img.shields.io/badge/Genre-Solarpunk%20Roguelike%20City--Builder-f39c12)](#)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](#)

> **GameUP Türkiye & COP31 İklim Temalı Oyun Hackathonu Projesi**  
> *"COP31 Antalya vizyonuyla geliştirilen; enerji, su ve gıda şebekelerini dengeleyerek şehri net-sıfır emisyona ulaştırdığınız Solarpunk roguelike kart ve izometrik şehir kurma stratejisi."*

---

## 🎮 Oyun Özeti (Overview)

2050 yılında COP31 İklim Zirvesi öncesinde kentin yönetimini devralan **"Baş Ekoloji Mimarı"** olarak görev yapıyorsunuz. Şehir geçmişin fosil mirası (kirletici Kömür Santralleri) ve her 5 günde bir vuran yıkıcı iklim krizleri (aşırı sıcak dalgaları, kuraklık, fırtına, deniz seviyesi yükselmesi) ile karşı karşıyadır.

Temel hedefiniz: Halkın enerji, su ve gıda arzını kesintiye uğratmadan eski kömür santrallerini tasfiye etmek, yeşil şebekeleri kurmak ve **üst üste 5 gün boyunca Net-Sıfır Karbon emisyonunu koruyarak COP31 İklim Zaferine ulaşmak**.

---

## ✨ Temel Özellikler (Core Features)

* **🃏 Roguelike Deste & Kart Tabanlı İnşaat:** Binaları kart olarak oynayın; temiz enerji santralleri, biyo-koridorlar, dikey tarım kuleleri ve sıfır-atık geri dönüşüm tesisleri kurun.
* **🔗 Komşuluk Sinerjileri:** Güneş Panelleri konutların yanına kurulduğunda enerji şebekesi verimi artar; Kent Ormanları konutları ve sanayi alanlarını tamponlayarak karbon yutağı oluşturur.
* **⭐ Modüler Tesis Evrimi (Seviye 2 ★ & Seviye 3 ★★ Mega):** Binaları modüler yükseltme kitleri veya aynı kartı üzerlerine oynayarak dönüştürün.
* **👁️ Karbon Isı Haritası Lensi (`V` Kısayolu):** Taktiksel termal vizyon ile haritadaki karbon yutaklarını (yeşil), kirleticileri (kırmızı) ve nötr tesisleri anlık denetleyin.
* **🌊 Toprak Islahı (Ada Genişletme):** Doğa tabanlı ıslah kartlarıyla deniz sınırlarını yeşil çayırlara dönüştürerek ada kapasitesini büyütün.
* **⚖️ Sürdürülebilirlik Reform Yasaları:** Her 3 günde bir kente kalıcı yeşil politikalar ve hibeler getiren reform yasalarını yürürlüğe koyun.
* **🏭 Fosil Miras Tasfiyesi:** Kömür santrallerini yıkarak molozları geri dönüştürün ve yerlerine biyo-çeşitlilik alanları inşa edin.
* **📊 COP31 Zafer Karnesi:** Dinamik eko-skorlama, nüfus direnci seviyeleri ve 7 günlük interaktif karbon/kaynak dönüşüm grafiği.

---

## 🕹️ Kontroller (Controls)

| Tuş / Eylem | İşlev |
| :--- | :--- |
| **Sol Tık** | Kart seçme / Adaya bina inşa etme |
| **Sağ Tık / ESC** | Kart seçimini iptal etme |
| **Boşluk (Space)** | Günü tamamla / Turu bitir |
| **V** | Karbon Isı Haritası Lensini aç / kapat |
| **1 - 6** | El kartlarını hızlı seçme |
| **F** | Haritayı merkeze odakla |
| **Z / Geri Al** | Son hamleyi geri al (Günde 1 kez) |
| **Mouse Drag / WASD** | Kamerayı kaydırma ve ada çevresinde gezinme |
| **Tekerlek (Wheel)** | Yakınlaşma / Uzaklaşma (Zoom In / Out) |

---

## 🛠️ Kurulum & Geliştirici Kılavuzu (Setup)

Proje **Godot Engine 4.3+ / 4.7+** ile geliştirilmiştir ve harici bir kütüphane kurulumu gerektirmez.

1. Depoyu klonlayın:
   ```bash
   git clone https://github.com/<kullanici-adiniz>/eco-grid-2050.git
   cd eco-grid-2050
   ```
2. **Godot Engine**'i açın, `Import` seçeneğiyle `project.godot` dosyasını seçin.
3. `F5` tuşuna basarak oyunu doğrudan başlatın.

### 🌐 Web / HTML5 Sürümü
Web dışa aktarımı WebAssembly (WASM) ve WebGL2 uyumludur. `build/web` dizini altından `python -m http.server 8000` komutuyla yerel sunucu başlatılarak test edilebilir.

---

## 👥 Ekip & İletişim

* **Serhat** — Proje Lideri, Oyun Tasarımı & Programlama
* **Etkinlik:** GameUP Türkiye Hackathonu (COP31 İklim Değişikliği Teması)

---

## 📄 Lisans

Bu proje [MIT Lisansı](LICENSE) kapsamında açık kaynak olarak geliştirilmiştir.
