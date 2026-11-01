import pptx
from pptx.util import Inches, Pt
from pptx.dml.color import RGBColor
from pptx.enum.text import PP_ALIGN
from PIL import Image
import os
import io

template_path = r'C:\Users\serhat\Downloads\Oyun Hackathonu Sunum Şablonu.pptx'
output_path = r'C:\Users\serhat\Desktop\Eco-Grid-2050-Hackathon-Sunumu.pptx'

# Step 1: Pre-crop Slide 2 and Slide 10 illustrations to remove giant transparent padding
prs_temp = pptx.Presentation(template_path)

# Extract and crop Slide 2 Resim 4
s2_temp = prs_temp.slides[1]
for shape in s2_temp.shapes:
    if shape.name == "Resim 4":
        im2 = Image.open(io.BytesIO(shape.image.blob))
        bbox2 = im2.getbbox()
        im2_cropped = im2.crop(bbox2)
        s2_img_path = r'C:\Users\serhat\eco-grid-2050\slide2_illustration.png'
        im2_cropped.save(s2_img_path)
        orig_l, orig_t, orig_w, orig_h = shape.left, shape.top, shape.width, shape.height
        s2_crop_l = int(orig_l + orig_w * (bbox2[0] / im2.width))
        s2_crop_t = int(orig_t + orig_h * (bbox2[1] / im2.height))
        s2_crop_w = int(orig_w * ((bbox2[2] - bbox2[0]) / im2.width))
        s2_crop_h = int(orig_h * ((bbox2[3] - bbox2[1]) / im2.height))
        break

# Extract and crop Slide 10 Resim 4
s10_temp = prs_temp.slides[9]
for shape in s10_temp.shapes:
    if shape.name == "Resim 4":
        im10 = Image.open(io.BytesIO(shape.image.blob))
        bbox10 = im10.getbbox()
        im10_cropped = im10.crop(bbox10)
        s10_img_path = r'C:\Users\serhat\eco-grid-2050\slide10_illustration.png'
        im10_cropped.save(s10_img_path)
        orig_l, orig_t, orig_w, orig_h = shape.left, shape.top, shape.width, shape.height
        s10_crop_l = int(orig_l + orig_w * (bbox10[0] / im10.width))
        s10_crop_t = int(orig_t + orig_h * (bbox10[1] / im10.height))
        s10_crop_w = int(orig_w * ((bbox10[2] - bbox10[0]) / im10.width))
        s10_crop_h = int(orig_h * ((bbox10[3] - bbox10[1]) / im10.height))
        break

# Step 2: Now load fresh template presentation
prs = pptx.Presentation(template_path)

# Image paths
frame_6s = r'C:\Users\serhat\.gemini\antigravity-cli\brain\34d2156b-815d-45dc-9b77-e05e6c0c4baa\test_frame_6s.png'
frame_12s = r'C:\Users\serhat\.gemini\antigravity-cli\brain\34d2156b-815d-45dc-9b77-e05e6c0c4baa\test_frame_12s.png'
frame_15s = r'C:\Users\serhat\.gemini\antigravity-cli\brain\34d2156b-815d-45dc-9b77-e05e6c0c4baa\test_frame_15s.png'
frame_21s = r'C:\Users\serhat\.gemini\antigravity-cli\brain\34d2156b-815d-45dc-9b77-e05e6c0c4baa\test_frame_v2_21s.png'
frame_23s = r'C:\Users\serhat\.gemini\antigravity-cli\brain\34d2156b-815d-45dc-9b77-e05e6c0c4baa\test_frame_v2_23s.png'

C_NAVY = RGBColor(24, 43, 73)
C_TEAL = RGBColor(16, 95, 105)
C_DARK = RGBColor(40, 50, 60)
C_GRAY = RGBColor(90, 105, 120)

def set_p(p, text, size=15, bold=False, color=C_DARK, space_after=6, space_before=0, align=PP_ALIGN.LEFT):
    p.text = text
    p.font.name = 'Outfit'
    p.font.size = Pt(size)
    p.font.bold = bold
    p.font.color.rgb = color
    p.space_after = Pt(space_after)
    p.space_before = Pt(space_before)
    p.alignment = align

# ==============================================================================
# SLIDE 1: Title & Introduction
# ==============================================================================
s1 = prs.slides[0]
for shape in list(s1.shapes):
    if shape.name == "Grafik 8":
        l, t, w, h = shape.left, shape.top, shape.width, shape.height
        sp = shape._element
        sp.getparent().remove(sp)
        s1.shapes.add_picture(frame_12s, l, t, w, h)
    elif shape.name == "Metin kutusu 10":
        shape.left = int(6.4 * 914400)
        shape.top = int(2.3 * 914400)
        shape.width = int(5.6 * 914400)
        shape.height = int(0.9 * 914400)
        tf = shape.text_frame
        tf.word_wrap = True
        tf.clear()
        p = tf.paragraphs[0]
        set_p(p, "Eco-Grid: 2050", size=42, bold=True, color=C_NAVY)
    elif shape.name == "Metin kutusu 11":
        shape.left = int(6.4 * 914400)
        shape.top = int(3.3 * 914400)
        shape.width = int(5.6 * 914400)
        shape.height = int(1.4 * 914400)
        tf = shape.text_frame
        tf.word_wrap = True
        tf.clear()
        p1 = tf.paragraphs[0]
        set_p(p1, "Net-Sıfır 2050 Vizyonuyla Geliştirilen", size=18, bold=True, color=C_TEAL, space_after=4)
        p2 = tf.add_paragraph()
        set_p(p2, "Solarpunk Roguelike Kart ve Şehir Kurma Stratejisi", size=16, color=C_GRAY)

# ==============================================================================
# SLIDE 2: Odak Tema
# ==============================================================================
s2 = prs.slides[1]
for shape in list(s2.shapes):
    if shape.name == "Resim 4":
        sp = shape._element
        sp.getparent().remove(sp)
        s2.shapes.add_picture(s2_img_path, s2_crop_l, s2_crop_t, s2_crop_w, s2_crop_h)
    elif shape.name == "Metin kutusu 5":
        shape.left = int(0.87 * 914400)
        shape.top = int(1.85 * 914400)
        shape.width = int(4.80 * 914400)
        shape.height = int(4.40 * 914400)
        tf = shape.text_frame
        tf.word_wrap = True
        tf.clear()
        
        p0 = tf.paragraphs[0]
        set_p(p0, "🌍 Birincil Tema: Net-Sıfır 2050 & COP31", size=17, bold=True, color=C_NAVY, space_after=8)
        
        items = [
            ("⚡ Yenilenebilir Enerji Geçişi", "Güneş, rüzgar, jeotermal santraller ve mega-batarya depolama şebekesi."),
            ("💧 Döngüsel Su ve Gıda Güvenliği", "Atık su geri kazanımı, dikey tarım kuleleri ve sıfır-atık geri dönüşüm."),
            ("🌱 Doğa Tabanlı Karbon Yutakları", "Karbon yutan kent ormanları, biyo-koridorlar ve doğrudan hava yakalama (DAC)."),
            ("🛡️ İklim Direnci & Kriz Yönetimi", "Sıcak dalgaları, kuraklık ve ani fırtınalara karşı kentsel altyapı savunması.")
        ]
        for title, desc in items:
            pt = tf.add_paragraph()
            set_p(pt, title, size=13, bold=True, color=C_TEAL, space_before=4, space_after=1)
            pd = tf.add_paragraph()
            set_p(pd, desc, size=12, color=C_DARK, space_before=0, space_after=6)

# ==============================================================================
# SLIDE 3: Oyun Hikayesi
# ==============================================================================
s3 = prs.slides[2]
for shape in s3.shapes:
    if shape.name == "Metin kutusu 5":
        shape.left = int(0.87 * 914400)
        shape.top = int(1.85 * 914400)
        shape.width = int(5.40 * 914400)
        shape.height = int(4.40 * 914400)
        tf = shape.text_frame
        tf.word_wrap = True
        tf.clear()
        
        p0 = tf.paragraphs[0]
        set_p(p0, "🎭 Baş Ekoloji Mimarı'nın Görevi", size=17, bold=True, color=C_NAVY, space_after=8)
        
        story = [
            ("🌆 Başlangıç Çatışması", "Kent, geçmişin kirletici kömür santralleri ve 5 günde bir vuran yıkıcı iklim krizlerinin (kuraklık, sıcak dalgası) baskısı altındadır."),
            ("⚖️ Yönetim İkilemi", "Halkın elektrik, su ve gıda arzını kesintiye uğratmadan eski santralleri tasfiye etmek ve yeşil şebekeleri kurmak zorundasınız."),
            ("🎯 Nihai Hedef & Zafer", "Karbon emisyonunu üst üste 5 gün boyunca net-sıfırda (0) tutarak COP31 İklim Zirvesi Zaferine ulaşmak.")
        ]
        for title, desc in story:
            pt = tf.add_paragraph()
            set_p(pt, title, size=13, bold=True, color=C_TEAL, space_before=4, space_after=1)
            pd = tf.add_paragraph()
            set_p(pd, desc, size=12, color=C_DARK, space_before=0, space_after=6)

# ==============================================================================
# SLIDE 4: Oyun Türü
# ==============================================================================
s4 = prs.slides[3]
for shape in s4.shapes:
    if shape.name == "Metin kutusu 5":
        shape.left = int(0.87 * 914400)
        shape.top = int(1.85 * 914400)
        shape.width = int(5.10 * 914400)
        shape.height = int(4.40 * 914400)
        tf = shape.text_frame
        tf.word_wrap = True
        tf.clear()
        
        p0 = tf.paragraphs[0]
        set_p(p0, "🎮 Solarpunk Roguelike Deckbuilder & Şehir Kurma", size=17, bold=True, color=C_NAVY, space_after=8)
        
        type_info = [
            ("✨ Kart Tabanlı Şebeke Mekaniği", "Binaları kart olarak oynayın; komşuluk sinerjileriyle enerji ve su verimini artırın."),
            ("⭐ Modüler Tesis Evrimi", "Aynı kartı veya yükseltme kitlerini kullanarak binaları Seviye 2 (★) ve Seviye 3 (★★ Mega) biçiminde geliştirin."),
            ("🌡️ Dinamik 1.5°C Karbon Bilançosu", "Her inşaat kararının ve krizin küresel ısınma üzerindeki anlık yansıması."),
            ("👁️ Karbon Isı Haritası Lensi (V)", "Kirlilik kaynaklarını ve yeşil yutakları termal vizyonla anlık analiz edin.")
        ]
        for title, desc in type_info:
            pt = tf.add_paragraph()
            set_p(pt, title, size=13, bold=True, color=C_TEAL, space_before=4, space_after=1)
            pd = tf.add_paragraph()
            set_p(pd, desc, size=12, color=C_DARK, space_before=0, space_after=6)

# ==============================================================================
# SLIDE 5: Oyun Oynanış Videosu
# ==============================================================================
s5 = prs.slides[4]
for shape in list(s5.shapes):
    if shape.name in ["Metin kutusu 5", "Dikdörtgen 4"]:
        sp = shape._element
        sp.getparent().remove(sp)
    elif shape.name == "Metin kutusu 3":
        shape.height = int(0.7 * 914400)

sub_box = s5.shapes.add_textbox(int(0.87 * 914400), int(1.48 * 914400), int(11.5 * 914400), int(0.4 * 914400))
tf_sub = sub_box.text_frame
tf_sub.word_wrap = True
p_sub = tf_sub.paragraphs[0]
set_p(p_sub, "🎬 26 Saniyelik 720p HD Oynanış Videosu | Masaüstü Dosyası: Eco-Grid-2050-Oynanis-Videosu.mp4", size=14, bold=True, color=C_TEAL)

vid_h_fit = int(4.6 * 914400)
vid_w_fit = int(vid_h_fit * 16 / 9)
vid_l = int((prs.slide_width - vid_w_fit) / 2)
vid_t = int(2.05 * 914400)
s5.shapes.add_picture(frame_12s, vid_l, vid_t, vid_w_fit, vid_h_fit)

# ==============================================================================
# SLIDE 6: Oyunumuzdan Sahneler
# ==============================================================================
s6 = prs.slides[5]
for shape in list(s6.shapes):
    if shape.name == "Resim 4":
        sp = shape._element
        sp.getparent().remove(sp)
    elif shape.name == "Metin kutusu 20":
        shape.left = int(0.87 * 914400)
        shape.top = int(1.85 * 914400)
        shape.width = int(3.10 * 914400)
        shape.height = int(4.40 * 914400)
        tf = shape.text_frame
        tf.word_wrap = True
        tf.clear()
        
        p0 = tf.paragraphs[0]
        set_p(p0, "📸 Temel Oyun Döngüsü", size=17, bold=True, color=C_NAVY, space_after=8)
        
        scenes = [
            ("1. Sinerji Işınları", "Güneş paneli ve eko-konut bitişik kurulduğunda altın plazma ışınları ve bonus enerji üretimi."),
            ("2. Karbon Lensi (V)", "Yeşil yutaklar ve kırmızı kirlilik kaynaklarını gösteren taktiksel termal lens."),
            ("3. Kömür Yıkımı & Zafer", "Eski kömür bacalarının moloz patlamasıyla tasfiyesi ve COP31 Zafer Karnesi.")
        ]
        for title, desc in scenes:
            pt = tf.add_paragraph()
            set_p(pt, title, size=13, bold=True, color=C_TEAL, space_before=4, space_after=1)
            pd = tf.add_paragraph()
            set_p(pd, desc, size=11, color=C_DARK, space_before=0, space_after=6)

card_w = int(2.75 * 914400)
card_h = int(card_w * 9 / 16)
top_pos = int(2.20 * 914400)

shots = [
    (int(4.15 * 914400), frame_6s, "⚡ Sinerji Işınları & İnşa"),
    (int(7.00 * 914400), frame_15s, "👁️ Karbon Isı Haritası Lensi"),
    (int(9.85 * 914400), frame_21s, "🏆 Kömür Tasfiyesi & Zafer")
]

for left_pos, img_file, caption in shots:
    s6.shapes.add_picture(img_file, left_pos, top_pos, card_w, card_h)
    cap_box = s6.shapes.add_textbox(left_pos, top_pos + card_h + int(0.1 * 914400), card_w, int(0.4 * 914400))
    tf_c = cap_box.text_frame
    tf_c.word_wrap = True
    p_c = tf_c.paragraphs[0]
    set_p(p_c, caption, size=12, bold=True, color=C_NAVY, align=PP_ALIGN.CENTER)

# ==============================================================================
# SLIDE 7: Ekip - PERFECT COORDINATES (ZERO COLLISION)
# ==============================================================================
s7 = prs.slides[6]
# Left column (Members 1 & 3): left = 2.95", width = 2.80" (ends at 5.75", avatar 2 starts at 6.07")
# Right column (Members 2 & 4): left = 8.20", width = 4.50" (starts after avatar 2/4 at 7.98", ends at 12.70")
for shape in s7.shapes:
    if shape.name == "Metin kutusu 13":
        shape.left = int(2.95 * 914400)
        shape.top = int(1.95 * 914400)
        shape.width = int(2.80 * 914400)
        shape.height = int(0.40 * 914400)
        tf = shape.text_frame
        tf.clear()
        p = tf.paragraphs[0]
        set_p(p, "Serhat", size=20, bold=True, color=C_NAVY)
    elif shape.name == "Metin kutusu 17":
        shape.left = int(2.95 * 914400)
        shape.top = int(2.40 * 914400)
        shape.width = int(2.80 * 914400)
        shape.height = int(0.95 * 914400)
        tf = shape.text_frame
        tf.word_wrap = True
        tf.clear()
        p1 = tf.paragraphs[0]
        set_p(p1, "Proje Lideri & Oyun Geliştirici", size=13, bold=True, color=C_TEAL, space_after=1)
        p2 = tf.add_paragraph()
        set_p(p2, "Game Design, GDScript & Ekoloji Modeli", size=11, color=C_GRAY)
    elif shape.name == "Metin kutusu 14":
        shape.left = int(8.20 * 914400)
        shape.top = int(1.95 * 914400)
        shape.width = int(4.50 * 914400)
        shape.height = int(0.40 * 914400)
        tf = shape.text_frame
        tf.clear()
        p = tf.paragraphs[0]
        set_p(p, "Ekip Üyesi", size=18, bold=True, color=C_NAVY)
    elif shape.name == "Metin kutusu 18":
        shape.left = int(8.20 * 914400)
        shape.top = int(2.40 * 914400)
        shape.width = int(4.50 * 914400)
        shape.height = int(0.95 * 914400)
        tf = shape.text_frame
        tf.word_wrap = True
        tf.clear()
        p1 = tf.paragraphs[0]
        set_p(p1, "Tasarım & Görsel Sanatlar", size=13, bold=True, color=C_TEAL, space_after=1)
        p2 = tf.add_paragraph()
        set_p(p2, "UI/UX, Kart Tasarımları & İllüstrasyon", size=11, color=C_GRAY)
    elif shape.name == "Metin kutusu 12":
        shape.left = int(2.95 * 914400)
        shape.top = int(4.20 * 914400)
        shape.width = int(2.80 * 914400)
        shape.height = int(0.40 * 914400)
        tf = shape.text_frame
        tf.clear()
        p = tf.paragraphs[0]
        set_p(p, "Ekip Üyesi", size=18, bold=True, color=C_NAVY)
    elif shape.name == "Metin kutusu 16":
        shape.left = int(2.95 * 914400)
        shape.top = int(4.65 * 914400)
        shape.width = int(2.80 * 914400)
        shape.height = int(0.95 * 914400)
        tf = shape.text_frame
        tf.word_wrap = True
        tf.clear()
        p1 = tf.paragraphs[0]
        set_p(p1, "Ses & Müzik Tasarımı", size=13, bold=True, color=C_TEAL, space_after=1)
        p2 = tf.add_paragraph()
        set_p(p2, "Dinamik Çevre Sesleri & Besteler", size=11, color=C_GRAY)
    elif shape.name == "Metin kutusu 19":
        shape.left = int(8.20 * 914400)
        shape.top = int(4.20 * 914400)
        shape.width = int(4.50 * 914400)
        shape.height = int(0.40 * 914400)
        tf = shape.text_frame
        tf.clear()
        p = tf.paragraphs[0]
        set_p(p, "Ekip Üyesi", size=18, bold=True, color=C_NAVY)
    elif shape.name == "Metin kutusu 20":
        shape.left = int(8.20 * 914400)
        shape.top = int(4.65 * 914400)
        shape.width = int(4.50 * 914400)
        shape.height = int(0.95 * 914400)
        tf = shape.text_frame
        tf.word_wrap = True
        tf.clear()
        p1 = tf.paragraphs[0]
        set_p(p1, "İklim Bilimi & Araştırma", size=13, bold=True, color=C_TEAL, space_after=1)
        p2 = tf.add_paragraph()
        set_p(p2, "COP31 Veri Modellemesi & Matematik", size=11, color=C_GRAY)

# ==============================================================================
# SLIDE 8: Gelecek Planlarınız
# ==============================================================================
s8 = prs.slides[7]
for shape in list(s8.shapes):
    if shape.name == "Grafik 2":
        sp = shape._element
        sp.getparent().remove(sp)
    elif shape.name == "Metin kutusu 25":
        shape.left = int(0.87 * 914400)
        shape.top = int(1.85 * 914400)
        shape.width = int(5.60 * 914400)
        shape.height = int(4.40 * 914400)
        tf = shape.text_frame
        tf.word_wrap = True
        tf.clear()
        
        p0 = tf.paragraphs[0]
        set_p(p0, "🚀 Yol Haritası (Roadmap)", size=18, bold=True, color=C_NAVY, space_after=8)
        
        plans = [
            ("1. AY: Post-Hackathon & Yayılım", "itch.io ve Steam demosu; mobil dokunmatik kontroller; 10 yeni COP31 iklim politikası kartı."),
            ("3. AY: Türkiye İklim Bölgeleri Paketi", "Bölgesel senaryolar (Antalya Kıyı Direnci, Ege Rüzgarı, İç Anadolu Kuraklığı); STK ve kamu veri ortaklıkları."),
            ("6-12 AY: Multiplayer & COP31 Eğitim", "Eş zamanlı çok oyunculu karbon ticaret şebekesi (Co-op Grid); okullarda iklim farkındalığı için simülasyon sürümü.")
        ]
        for title, desc in plans:
            pt = tf.add_paragraph()
            set_p(pt, title, size=13, bold=True, color=C_TEAL, space_before=4, space_after=1)
            pd = tf.add_paragraph()
            set_p(pd, desc, size=12, color=C_DARK, space_before=0, space_after=6)

s8.shapes.add_picture(frame_23s, int(7.0 * 914400), int(2.10 * 914400), int(4.6 * 914400), int(4.6 * 914400 * 9 / 16))
cap_s8 = s8.shapes.add_textbox(int(7.0 * 914400), int(2.10 * 914400 + 4.6 * 914400 * 9 / 16 + 0.1 * 914400), int(4.6 * 914400), int(0.4 * 914400))
p_s8 = cap_s8.text_frame.paragraphs[0]
set_p(p_s8, "🌟 COP31 İklim Direnci: Eko-Kasaba Seviyesi", size=12, bold=True, color=C_NAVY, align=PP_ALIGN.CENTER)

# ==============================================================================
# SLIDE 9: Oyuna İlişkin Linkler
# ==============================================================================
s9 = prs.slides[8]
for shape in list(s9.shapes):
    if shape.name == "Resim 8":
        sp = shape._element
        sp.getparent().remove(sp)
    elif shape.name == "Metin kutusu 4":
        shape.left = int(0.87 * 914400)
        shape.top = int(1.85 * 914400)
        shape.width = int(5.60 * 914400)
        shape.height = int(4.40 * 914400)
        tf = shape.text_frame
        tf.word_wrap = True
        tf.clear()
        
        p0 = tf.paragraphs[0]
        set_p(p0, "🔗 Demo, Kod ve Teslim Dosyaları", size=18, bold=True, color=C_NAVY, space_after=8)
        
        links = [
            ("🌐 Canlı Tarayıcı Oyunu (Web Demo)", "https://serhatvs.github.io/eco-grid-2050/"),
            ("💻 Windows & Web Çevrimdışı Paketler", "Masaüstü: Eco-Grid-2050-Windows.zip & Web.zip"),
            ("🎬 720p HD Oynanış Videosu", "Masaüstü: Eco-Grid-2050-Oynanis-Videosu.mp4 (26 saniye)"),
            ("🐙 GitHub Açık Kaynak Deposu", "https://github.com/serhatvs/eco-grid-2050"),
            ("📄 Oyun Tasarım Dokümantasyonu", "GDD & İklim Matematik Modeli proje dizinindedir.")
        ]
        for title, desc in links:
            pt = tf.add_paragraph()
            set_p(pt, title, size=13, bold=True, color=C_TEAL, space_before=3, space_after=1)
            pd = tf.add_paragraph()
            set_p(pd, desc, size=11, color=C_DARK, space_before=0, space_after=4)

s9.shapes.add_picture(frame_12s, int(7.0 * 914400), int(2.10 * 914400), int(4.6 * 914400), int(4.6 * 914400 * 9 / 16))
cap_s9 = s9.shapes.add_textbox(int(7.0 * 914400), int(2.10 * 914400 + 4.6 * 914400 * 9 / 16 + 0.1 * 914400), int(4.6 * 914400), int(0.4 * 914400))
p_s9 = cap_s9.text_frame.paragraphs[0]
set_p(p_s9, "🎮 Eco-Grid 2050 Canlı Oyun Ekranı", size=12, bold=True, color=C_NAVY, align=PP_ALIGN.CENTER)

# ==============================================================================
# SLIDE 10: Kapanış & İletişim
# ==============================================================================
s10 = prs.slides[9]
for shape in list(s10.shapes):
    if shape.name == "Resim 4":
        sp = shape._element
        sp.getparent().remove(sp)
        s10.shapes.add_picture(s10_img_path, s10_crop_l, s10_crop_t, s10_crop_w, s10_crop_h)
    elif shape.name == "Metin kutusu 10":
        shape.left = int(6.4 * 914400)
        shape.top = int(1.9 * 914400)
        shape.width = int(5.4 * 914400)
        shape.height = int(0.7 * 914400)
        tf = shape.text_frame
        tf.clear()
        p = tf.paragraphs[0]
        set_p(p, "Serhat", size=36, bold=True, color=C_NAVY)
    elif shape.name == "Metin kutusu 11":
        shape.left = int(6.4 * 914400)
        shape.top = int(2.7 * 914400)
        shape.width = int(5.4 * 914400)
        shape.height = int(0.7 * 914400)
        tf = shape.text_frame
        tf.word_wrap = True
        tf.clear()
        p = tf.paragraphs[0]
        set_p(p, "Eco-Grid: 2050 Geliştiricisi | GameUp COP31 Hackathonu", size=17, bold=True, color=C_TEAL)
    elif shape.name == "Metin kutusu 8":
        shape.left = int(6.4 * 914400)
        shape.top = int(3.55 * 914400)
        shape.width = int(5.4 * 914400)
        shape.height = int(1.1 * 914400)
        tf = shape.text_frame
        tf.word_wrap = True
        tf.clear()
        p1 = tf.paragraphs[0]
        set_p(p1, "📧 iletisim@gmail.com", size=15, color=C_DARK, space_after=3)
        p2 = tf.add_paragraph()
        set_p(p2, "🌐 https://serhatvs.github.io/eco-grid-2050/", size=14, bold=True, color=C_TEAL, space_after=3)
        p3 = tf.add_paragraph()
        set_p(p3, "🐙 https://github.com/serhatvs/eco-grid-2050", size=14, bold=True, color=C_NAVY)

prs.save(output_path)
print("FLAWLESS PRESENTATION SAVED SUCCESSFULLY!")
