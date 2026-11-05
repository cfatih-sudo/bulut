# -*- coding: utf-8 -*-
"""Alp Fit x Kunaz birleşme/entegrasyon analizi PDF raporunu üretir.

Çalıştırma: python3 rapor/build_report.py
Çıktı:      rapor/AlpFit_Kunaz_Analiz_Raporu.pdf
"""
import os

from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER, TA_JUSTIFY
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib.units import cm
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import (KeepTogether, PageBreak, Paragraph,
                                SimpleDocTemplate, Spacer, Table, TableStyle)

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "AlpFit_Kunaz_Analiz_Raporu.pdf")

FONT_DIR = "/usr/share/fonts/truetype/liberation"
pdfmetrics.registerFont(TTFont("DV", f"{FONT_DIR}/LiberationSans-Regular.ttf"))
pdfmetrics.registerFont(TTFont("DVB", f"{FONT_DIR}/LiberationSans-Bold.ttf"))
pdfmetrics.registerFont(TTFont("DVI", f"{FONT_DIR}/LiberationSans-Italic.ttf"))
pdfmetrics.registerFont(TTFont("DVBI", f"{FONT_DIR}/LiberationSans-BoldItalic.ttf"))
# Onay işareti için (Liberation'da yok)
pdfmetrics.registerFont(TTFont("SYM", "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"))
pdfmetrics.registerFontFamily("DV", normal="DV", bold="DVB", italic="DVI", boldItalic="DVBI")

NAVY = colors.HexColor("#1F2A44")
TEAL = colors.HexColor("#0F766E")
LIGHT = colors.HexColor("#EEF2F7")
MUTED = colors.HexColor("#5B6475")
GREEN = colors.HexColor("#D1FAE5")
AMBER = colors.HexColor("#FEF3C7")
RED = colors.HexColor("#FEE2E2")

S = {
    "title": ParagraphStyle("title", fontName="DVB", fontSize=24, leading=30, textColor=NAVY, alignment=TA_CENTER),
    "subtitle": ParagraphStyle("subtitle", fontName="DV", fontSize=13, leading=18, textColor=MUTED, alignment=TA_CENTER),
    "h1": ParagraphStyle("h1", fontName="DVB", fontSize=16, leading=21, textColor=NAVY, spaceBefore=6, spaceAfter=8),
    "h2": ParagraphStyle("h2", fontName="DVB", fontSize=12, leading=16, textColor=TEAL, spaceBefore=8, spaceAfter=4),
    "body": ParagraphStyle("body", fontName="DV", fontSize=9.5, leading=14, alignment=TA_JUSTIFY, spaceAfter=5),
    "bullet": ParagraphStyle("bullet", fontName="DV", fontSize=9.5, leading=13.5, leftIndent=14, bulletIndent=4, spaceAfter=3),
    "cell": ParagraphStyle("cell", fontName="DV", fontSize=8.3, leading=11),
    "cellb": ParagraphStyle("cellb", fontName="DVB", fontSize=8.3, leading=11, textColor=colors.white),
    "note": ParagraphStyle("note", fontName="DVI", fontSize=8.3, leading=11.5, textColor=MUTED, spaceAfter=4),
    "box": ParagraphStyle("box", fontName="DV", fontSize=9.5, leading=14),
}


def P(text, style="body"):
    return Paragraph(text, S[style])


def bullets(items):
    return [Paragraph(t, S["bullet"], bulletText="•") for t in items]


def table(rows, widths, header=True, zebra=True, extra=None):
    data = []
    for r_i, row in enumerate(rows):
        st = "cellb" if (header and r_i == 0) else "cell"
        data.append([c if not isinstance(c, str) else Paragraph(c, S[st]) for c in row])
    t = Table(data, colWidths=widths, repeatRows=1 if header else 0)
    style = [
        ("GRID", (0, 0), (-1, -1), 0.4, colors.HexColor("#C9D1DC")),
        ("VALIGN", (0, 0), (-1, -1), "TOP"),
        ("TOPPADDING", (0, 0), (-1, -1), 4),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 4),
        ("LEFTPADDING", (0, 0), (-1, -1), 5),
        ("RIGHTPADDING", (0, 0), (-1, -1), 5),
    ]
    if header:
        style.append(("BACKGROUND", (0, 0), (-1, 0), NAVY))
    if zebra:
        for i in range(1 if header else 0, len(rows)):
            if i % 2 == 0:
                style.append(("BACKGROUND", (0, i), (-1, i), LIGHT))
    if extra:
        style.extend(extra)
    t.setStyle(TableStyle(style))
    return t


def callout(text, bg=LIGHT, border=TEAL):
    t = Table([[Paragraph(text, S["box"])]], colWidths=[17 * cm])
    t.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, -1), bg),
        ("LINEBEFORE", (0, 0), (0, -1), 3, border),
        ("LEFTPADDING", (0, 0), (-1, -1), 10),
        ("RIGHTPADDING", (0, 0), (-1, -1), 10),
        ("TOPPADDING", (0, 0), (-1, -1), 8),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 8),
    ]))
    return t


def on_page(canvas, doc):
    if doc.page == 1:
        return
    canvas.saveState()
    canvas.setFont("DV", 7.5)
    canvas.setFillColor(MUTED)
    canvas.drawString(2 * cm, 1.2 * cm, "Alp Fit × Kunaz — Stratejik Birleşme / Entegrasyon Analizi")
    canvas.drawRightString(A4[0] - 2 * cm, 1.2 * cm, f"Sayfa {doc.page}")
    canvas.setStrokeColor(colors.HexColor("#C9D1DC"))
    canvas.line(2 * cm, 1.5 * cm, A4[0] - 2 * cm, 1.5 * cm)
    canvas.restoreState()


# ---------------------------------------------------------------- model
def sim(churn, start=400, new=32, months=12):
    m, tot = start, 0.0
    for _ in range(months):
        m = m * (1 - churn) + new
        tot += m
    return m, tot


FEE = 1500          # TL / üye / ay (varsayım)
BASE_CHURN = 0.08   # aylık bırakma (varsayım)
LIC = 60            # TL / aktif Kunaz kullanıcısı / ay (varsayım)
ADOPT = 160         # Kunaz'ı aktif kullanan üye (~%40)
SETUP = 30000       # kurulum + eğitim + KVKK danışmanlığı (varsayım)
PREM = 500          # premium beslenme koçluğu eki TL/ay
COST = ADOPT * LIC * 12 + SETUP

_, base_tot = sim(BASE_CHURN)


def scenario(drop_pt, prem_rate):
    end, tot = sim(BASE_CHURN - drop_pt / 100)
    extra_mm = tot - base_tot
    ret_rev = extra_mm * FEE
    prem_rev = round(end * prem_rate) * PREM * 12
    net = ret_rev + prem_rev - COST
    return end, extra_mm, ret_rev, prem_rev, net


def tl(x):
    s = f"{abs(x):,.0f}".replace(",", ".")
    return ("−" if x < 0 else "") + s + " TL"


SCEN = [
    ("Kötümser", 0.0, 0.02),
    ("Temel", 1.0, 0.05),
    ("İyimser", 2.0, 0.08),
]

# ---------------------------------------------------------------- içerik
story = []

# Kapak
story += [
    Spacer(1, 5 * cm),
    P("Alp Fit × Kunaz", "title"),
    Spacer(1, 6),
    P("Stratejik Birleşme / Entegrasyon Analizi", "subtitle"),
    Spacer(1, 4),
    P("Farklar, Alp Fit için avantajlar, handikaplar, senaryolar, finansal model ve yol haritası", "subtitle"),
    Spacer(1, 3 * cm),
    callout("<b>Hazırlanma tarihi:</b> 5 Kasım 2026<br/>"
            "<b>Kapsam:</b> Alp Fit spor salonu uygulaması / Gymsoft yönetim altyapısı ile Kunaz "
            "(Saintsun Software) beslenme–antrenman uygulamasının birleşmesi ya da entegrasyonu<br/>"
            "<b>Bakış açısı:</b> Alp Fit (salon işletmesi)<br/>"
            "<b>Dayanak:</b> Kamuya açık kaynaklar (App Store sayfaları, kunaz.tr) ve açıkça belirtilmiş varsayımlar"),
    PageBreak(),
]

# İçindekiler
toc = [
    "1. Yönetici Özeti", "2. Kapsam, Yöntem ve Kısıtlar", "3. Tarafların Profili",
    "4. Karşılaştırmalı Analiz", "5. Pazar Bağlamı", "6. Birleşme Senaryoları",
    "7. Alp Fit İçin Avantajlar", "8. Handikaplar ve Riskler", "9. SWOT Analizi",
    "10. Risk Matrisi", "11. Finansal Etki Modeli", "12. KVKK ve Hukuki Çerçeve",
    "13. Sözleşme Kontrol Listesi", "14. Uygulama Yol Haritası", "15. Başarı Ölçütleri (KPI)",
    "16. Sonuç ve Öneri", "Ek A. Varsayımlar", "Ek B. Kaynaklar",
]
story.append(P("İçindekiler", "h1"))
story += [P(t, "bullet") for t in toc]
story.append(PageBreak())

# 1
story.append(P("1. Yönetici Özeti", "h1"))
story.append(P(
    "Alp Fit ile Kunaz <b>rakip değil, birbirini tamamlayan</b> iki üründür. Alp Fit, Gymsoft altyapısı "
    "üzerinde çalışan, salona özel markalı bir üye uygulamasıdır: QR ile giriş, üyelik bilgisi ve salon içi "
    "duyuru/sosyal akış sunar. Kunaz ise bireysel kullanıcıya yönelik, yapay zekâ destekli bir kalori, "
    "beslenme, antrenman ve uyku takip uygulamasıdır; diyetisyen ve kişisel antrenörler (PT) için "
    "<b>Kunaz Max</b> adlı bir uzman sürümü de vardır."))
story.append(P(
    "Kısacası Alp Fit üyenin <b>salona girdiği anı</b>, Kunaz ise <b>salon dışındaki 23 saatini</b> yönetir. "
    "Bu ikisinin birleşmesi Alp Fit'e, sektörün en büyük sorunu olan üye kaybına (churn) karşı güçlü bir araç, "
    "günlük kullanım alışkanlığı ve yeni gelir kalemleri (premium beslenme paketi, online PT) kazandırabilir."))
story.append(callout(
    "<b>Ana bulgular</b><br/>"
    "• En büyük avantaj: üye bağlılığı ve elde tutma. Örnek modelde aylık bırakma oranında 1 puanlık iyileşme, "
    f"12 ayda yaklaşık <b>{tl(scenario(1.0, 0)[2])}</b> ek üyelik geliri anlamına gelir.<br/>"
    f"• Başa baş noktası düşük: yıllık ~{tl(COST)} maliyet, aylık bırakma oranında yaklaşık <b>0,4 puanlık</b> "
    "iyileşmeyle karşılanır.<br/>"
    "• En büyük risk: <b>KVKK</b>. Kilo, vücut yağı ve beslenme verisi \"özel nitelikli kişisel veri\"dir; "
    "açık rıza, VERBİS ve yurt dışı aktarım yükümlülükleri doğar.<br/>"
    "• İkinci büyük risk: <b>iki tedarikçiye bağımlılık</b> (Gymsoft + Saintsun) ve münhasırlık olmaması "
    "nedeniyle rakiplerin aynı avantajı kopyalayabilmesi.<br/>"
    "• <b>Öneri:</b> Tam birleşme değil, <b>API entegrasyonu + 90 günlük kontrollü pilot</b>. Karar, pilot verisine göre verilmeli."))
story.append(PageBreak())

# 2
story.append(P("2. Kapsam, Yöntem ve Kısıtlar", "h1"))
story.append(P("<b>Kapsam.</b> \"Birleşme\" kavramı bu raporda üç farklı yoğunlukta ele alınmıştır: (i) teknik entegrasyon, "
               "(ii) uzman paneli (Kunaz Max) üzerinden hizmet ortaklığı, (iii) tek uygulamada birleştirme ya da kurumsal ortaklık. "
               "Değerlendirme Alp Fit'in (salon işletmesinin) bakış açısıyla yapılmıştır."))
story.append(P("<b>Yöntem.</b> Ürün özellik karşılaştırması, değer zinciri analizi, senaryo puanlama matrisi, SWOT, "
               "olasılık–etki risk matrisi ve 12 aylık basit bir üye kitlesi simülasyonu kullanılmıştır."))
story.append(P("<b>Kısıtlar.</b>"))
story += bullets([
    "Alp Fit'in üye sayısı, fiyatları ve bırakma oranı kamuya açık değildir. Finansal model <b>açıkça belirtilen "
    "varsayımlarla</b> kurulmuştur (Ek A); gerçek rakamlarla yeniden hesaplanmalıdır.",
    "Kunaz'ın kurumsal (B2B) fiyatı ve API olanakları kamuya açık değildir. Kunaz Pro fiyatı ülkeye göre değişir; "
    "Kunaz Max'in ücretsiz planı 2 danışanla sınırlıdır.",
    "Alp Fit'in App Store sayfasında satıcı \"alican vardar\", telif sahibi \"Gymsoft\" görünmektedir. Gymsoft'un "
    "kurumsal yapısı kaynaklarla doğrulanamamıştır.",
    "Bu rapor hukuki görüş değildir; KVKK bölümü bir avukat/uzman tarafından doğrulanmalıdır.",
])

# 3
story.append(P("3. Tarafların Profili", "h1"))
story.append(P("3.1 Alp Fit (Gymsoft altyapısı)", "h2"))
story += bullets([
    "<b>Tür:</b> Tek bir salona özel markalı üye uygulaması (B2B2C). iOS 14+, 4,7 MB, Sağlık ve Fitness kategorisi.",
    "<b>Özellikler:</b> Uygulamayla/QR kodla salona giriş, üyelik bilgileri, salonun yönetim yazılımına erişim, "
    "duyuru ve haberler için salona özel sosyal ağ.",
    "<b>Altyapı:</b> Gymsoft; aynı geliştiricinin Space Gym, uFit, Gymac, JAVS gibi başka salonlar için de benzer "
    "markalı uygulamalar yayımladığı görülüyor. Yani Alp Fit, çok salonlu bir beyaz etiket (white-label) platformunun bir örneği.",
    "<b>Veri beyanı:</b> \"Veri toplanmıyor.\" Henüz yeterli puan/yorum yok; kullanıcı kitlesi küçük ya da yeni.",
])
story.append(P("3.2 Kunaz (Saintsun Software)", "h2"))
story += bullets([
    "<b>Tür:</b> Bireysel kullanıcıya yönelik (B2C) beslenme, kalori ve antrenman uygulaması; iOS, Android, Apple Watch, widget'lar.",
    "<b>Beslenme:</b> Barkod, besin etiketi ve tabak fotoğrafıyla kayıt; 40.000+ besin; eksik ürünler Open Food Facts'ten; "
    "özel tarif ve besin; su takibi; canlı kalori açığı.",
    "<b>Antrenman:</b> 1.900+ egzersiz; salon ve ev için kişisel program; kuvvet, kalistenik, pilates, esneme; zamanlayıcılı canlı antrenman.",
    "<b>Bilimsel altyapı:</b> Mifflin-St Jeor (dinlenme enerjisi), FAO/WHO/UNU aktivite düzeyleri, MET değerleri (Ainsworth 2011), "
    "kg yağ başına ~7.700 kcal tahmini. Değerlerin tıbbi tavsiye değil tahmin olduğu belirtiliyor.",
    "<b>Yapay zekâ:</b> Fotoğraftan besin tanıma ve kullanıcının durumunu okuyup hedefe yönlendiren yapay zekâ koç.",
    "<b>Entegrasyon:</b> Apple Health ve Health Connect (adım, uyku, antrenman, vücut ölçüleri).",
    "<b>İş modeli:</b> Ücretsiz temel sürüm; Kunaz Pro (daha yüksek yapay zekâ limiti, detaylı grafikler, temalar); "
    "<b>Kunaz Max</b>: diyetisyen, PT ve yaşam koçları için; onay veren danışanları izleme, diyet ve antrenman programı atama, "
    "mesajlaşma, randevu ve PDF rapor; web paneli (panel.kunaz.tr). Ücretsiz Max planı 2 danışan içerir.",
    "<b>Ölçek:</b> 22+ dil; global hedefli.",
])
story.append(PageBreak())

# 4
story.append(P("4. Karşılaştırmalı Analiz", "h1"))
story.append(P("4.1 Konumlanma karşılaştırması", "h2"))
W2 = [3.6 * cm, 6.7 * cm, 6.7 * cm]
story.append(table([
    ["Boyut", "Alp Fit", "Kunaz"],
    ["Hedef müşteri", "Salon ve salonun üyeleri (B2B2C)", "Birey (B2C) + diyetisyen/PT (B2B, Max)"],
    ["Çözdüğü iş", "Giriş, üyelik, salon iletişimi", "Beslenme, kalori, antrenman, uyku, ilerleme"],
    ["Kullanım sıklığı", "Salona her girişte, günde ≤1", "Her öğünde, günde 3–6 kez"],
    ["Değer anı", "Kapıda (işlemsel)", "Gün boyu (alışkanlık, motivasyon)"],
    ["Veri türü", "Kimlik, üyelik, giriş kayıtları", "Sağlık verisi: kilo, yağ, beslenme, uyku, adım"],
    ["Gelir modeli", "Salon üyelik ücreti; Gymsoft lisansı", "Pro abonelik; Max uzman aboneliği"],
    ["Yapay zekâ", "Yok", "Fotoğraftan besin tanıma, yapay zekâ koç"],
    ["Coğrafya", "Yerel, tek salon", "22+ dil, global"],
    ["Marka sahipliği", "Salonun markası", "Kunaz markası"],
    ["Rakip seti", "OxyFit, GymTekno, FitAPP, SporSalonum, BulutGym", "Global kalori/diyet uygulamaları"],
], W2))
story.append(Spacer(1, 8))
story.append(P("4.2 Özellik matrisi", "h2"))
Y, N, K = '<font name="SYM" color="#0F766E">✔</font>', "—", "Kısmi"
W4 = [7 * cm, 3.3 * cm, 3.3 * cm, 3.4 * cm]
story.append(table([
    ["Özellik", "Alp Fit", "Kunaz", "Birleşik"],
    ["QR / uygulamayla giriş", Y, N, Y],
    ["Üyelik bilgisi, yenileme", Y, N, Y],
    ["Salon duyuruları / sosyal akış", Y, N, Y],
    ["Kalori ve beslenme takibi", N, Y, Y],
    ["Antrenman programı ve egzersiz kütüphanesi", N, Y, Y],
    ["Uyku, adım, giyilebilir cihaz verisi", N, Y, Y],
    ["Yapay zekâ koç", N, Y, Y],
    ["PT / diyetisyen paneli", K + " (yönetim yazılımı)", Y + " (Max)", Y],
    ["Gelişim raporu (PDF)", N, Y, Y],
    ["Salona gelme sıklığı + vücut gelişimi birlikte", N, N, Y + " (yeni)"],
    ["Bırakma riski erken uyarısı", N, N, K + " (geliştirme ile)"],
], W4))
story.append(Spacer(1, 6))
story.append(P("Son iki satır önemlidir: Birleşmenin asıl değeri, iki ürünün tek başına üretemeyeceği "
               "<b>birleşik veriden</b> doğar. Salona gelme sıklığı ile vücut gelişiminin aynı yerde görülmesi, hem üye motivasyonu "
               "hem de salon yönetimi için yeni bir kaynaktır."))
story.append(P("4.3 Değer zinciri: üye yolculuğu", "h2"))
story.append(table([
    ["Aşama", "Bugün (yalnız Alp Fit)", "Birleşme sonrası"],
    ["Keşif / kayıt", "Salonda ya da sosyal medyada kayıt", "\"Beslenme koçluğu dahil\" teklif; ücretsiz vücut analizi kancası"],
    ["İlk 30 gün", "Giriş kartı gibi kullanılıyor", "Hedef, kalori planı, PT'nin atadığı program; ilk sonuçlar görünür"],
    ["Alışkanlık (2–6 ay)", "Motivasyon üyeye kalmış", "Günlük kayıt, yapay zekâ koç, PT geri bildirimi, gelişim raporu"],
    ["Risk anı", "Bırakma çoğu zaman fark edilmiyor", "Giriş ve kayıt düşüşü birlikte izlenir, PT araya girer"],
    ["Yenileme", "Fiyat odaklı karar", "Somut gelişim verisiyle değer odaklı karar"],
    ["Salon dışı", "Bağ yok", "Ev antrenmanı, tatil modu"],
], W2))
story.append(Spacer(1, 10))

# 5
story.append(P("5. Pazar Bağlamı", "h1"))
story.append(P(
    "Türkiye'de salon yazılımı pazarı ağırlıkla <b>yönetim yazılımı</b> ekseninde rekabet ediyor: üye ve aidat takibi, "
    "ders rezervasyonu, turnike/QR giriş, e-fatura ve sanal POS. Örneğin OxyFitClub aylık 1.499 TL fiyat açıklıyor; "
    "GymTekno, FitAPP, SporSalonum.net, BulutGym ve Allync+ benzer paketler sunuyor. Bu ürünlerin ortak noktası "
    "<b>işletmeye</b> hizmet etmeleri; üyenin günlük sağlık yolculuğuna dokunan derin bir beslenme ve yapay zekâ katmanı "
    "genelde bulunmuyor."))
story.append(P("Bu tablo Alp Fit için iki sonuç doğuruyor:"))
story += bullets([
    "<b>Farklılaşma fırsatı:</b> Yönetim özellikleri artık standart. \"Yapay zekâ koçlu, beslenme takipli salon\" "
    "konumlanması yerel rakiplerden ayrışmak için güçlü bir hikâye.",
    "<b>Kopyalanabilirlik:</b> Kunaz herkese açık bir ürün. Aynı entegrasyonu rakip salonlar da yapabilir. Avantajın kalıcı "
    "olması için ya münhasırlık ya da salona özgü veri ve hizmet katmanı (PT süreçleri, topluluk) gerekir.",
])
story.append(P("Sektör eğilimleri de birleşmeyi destekliyor: hibrit fitness (salon + ev), giyilebilir cihaz verisi, "
               "yapay zekâ destekli kişiselleştirme ve üyelik yerine \"sonuç\" satma yaklaşımı."))

# 6
story.append(P("6. Birleşme Senaryoları", "h1"))
story.append(table([
    ["Senaryo", "Tanım", "Yatırım", "Süre", "Risk"],
    ["A. API entegrasyonu", "Alp Fit üyesine Kunaz Pro (toplu lisans); tek tıkla bağlanma; giriş verisi ↔ ilerleme verisi paylaşımı", "Düşük–Orta", "1–3 ay", "Düşük"],
    ["B. Kunaz Max ile PT hizmeti", "Salon PT'leri Max panelinden üyeleri izler, program atar; premium paket satılır", "Düşük", "2–6 hafta", "Düşük"],
    ["C. Tek uygulama (white-label)", "Kunaz özellikleri Alp Fit içine gömülür ya da Kunaz'ın salon sürümü Alp Fit markasıyla", "Yüksek", "6–12 ay", "Yüksek"],
    ["D. Kurumsal ortaklık / pay", "Gymsoft–Saintsun ortaklığı; tüm Gymsoft salonlarına ortak ürün", "Çok yüksek", "12+ ay", "Çok yüksek"],
], [3.4 * cm, 7.4 * cm, 2.2 * cm, 2 * cm, 2 * cm]))
story.append(Spacer(1, 8))
story.append(P("6.1 Senaryo puanlama (1 = zayıf, 5 = güçlü)", "h2"))
crit = ["Müşteri değeri", "Uygulanabilirlik", "Maliyet etkinliği", "Hız", "Kontrol / marka", "KVKK riski (ters)"]
wts = [0.25, 0.20, 0.20, 0.10, 0.15, 0.10]
scores = {"A": [4, 4, 4, 4, 3, 3], "B": [3, 5, 5, 5, 3, 4], "C": [5, 2, 2, 1, 5, 2], "D": [5, 1, 1, 1, 4, 2]}
rows = [["Kriter (ağırlık)", "A", "B", "C", "D"]]
for i, c in enumerate(crit):
    rows.append([f"{c} (%{int(wts[i]*100)})"] + [str(scores[k][i]) for k in "ABCD"])
tot = {k: sum(s * w for s, w in zip(scores[k], wts)) for k in "ABCD"}
rows.append(["<b>Ağırlıklı toplam</b>"] + [f"<b>{tot[k]:.2f}</b>" for k in "ABCD"])
best = max(tot, key=tot.get)
col = "ABCD".index(best) + 1
story.append(table(rows, [6.2 * cm, 2.7 * cm, 2.7 * cm, 2.7 * cm, 2.7 * cm],
                   extra=[("BACKGROUND", (col, len(rows) - 1), (col, len(rows) - 1), GREEN)]))
story.append(Spacer(1, 4))
story.append(P(f"Puanlama değerlendirmeye dayalıdır. A ve B birlikte (\"A+B\") en dengeli yol: B hızlı gelir ve öğrenme sağlar, "
               f"A ise ölçeklenmeyi. C ve D, ancak pilot başarısı kanıtlandıktan sonra gündeme gelmelidir.", "note"))
story.append(PageBreak())

# 7
story.append(P("7. Alp Fit İçin Avantajlar", "h1"))
adv = [
    ("Üye elde tutma (en büyük kaldıraç)",
     "Salonlarda üyelerin büyük kısmı ilk aylarda bırakır; temel neden sonuç görememek ve motivasyon kaybıdır. "
     "Kunaz'ın kilo, yağ ve kas tahmini grafikleri \"ilerliyorum\" hissini somutlaştırır. Gelişimini gören üye yenileme "
     "kararını fiyat yerine değere göre verir."),
    ("Günlük kullanım alışkanlığı",
     "Alp Fit bugün günde en fazla bir kez, kapıda açılıyor. Kunaz ile günde birkaç kez açılır. Bu, salon duyurularının, "
     "kampanyaların ve sosyal akışın görünürlüğünü katlar; uygulama bir \"kart\" olmaktan çıkıp bir \"kanal\" olur."),
    ("Yeni gelir kalemleri",
     "• \"Beslenme koçluğu dahil\" premium üyelik katmanı<br/>• Kunaz Max ile online PT ve diyetisyen hizmeti (salona gelmeyen "
     "müşteriye bile satılabilir)<br/>• Vücut analizi ve gelişim raporu gibi ücretli ek hizmetler<br/>• Gelir paylaşımlı Kunaz Pro satışı"),
    ("PT verimliliği ve satış gücü",
     "PT, üyenin beslenme, uyku ve adım verisini görerek programı ayarlar. Aynı sürede daha çok danışan yönetebilir; "
     "PDF gelişim raporu PT paket yenilemelerinde somut bir satış argümanıdır."),
    ("Hazır içerik ve teknoloji",
     "1.900+ egzersiz, 40.000+ besin, yapay zekâ tanıma ve giyilebilir cihaz entegrasyonu sıfırdan geliştirilse aylar ve "
     "ciddi bütçe gerektirir. Entegrasyonla bu içerik hızla devreye alınır."),
    ("Farklılaşma ve pazarlama",
     "Yerel rakipler yönetim yazılımında yarışıyor. \"Yapay zekâ koçlu salon\" söylemi, reklamlarda ve sosyal medyada güçlü bir mesaj. "
     "Anonim, onaylı başarı hikâyeleri (\"3 ayda ortalama X kg\") pazarlama içeriğine dönüşür."),
    ("Birleşik veriyle yönetim",
     "Giriş sıklığı ile gelişim verisinin birleşimi; hangi ders ya da programın sonuç verdiğini, hangi PT'nin danışanlarının "
     "daha iyi ilerlediğini, hangi üyenin bırakma riski taşıdığını gösterir."),
    ("Salon dışına uzanma",
     "Ev antrenmanı ve tatil modu; kış, bayram ve yaz tatillerinde üyeyle bağın kopmasını engeller. Üyelik dondurma "
     "yerine \"evden devam\" seçeneği sunulabilir."),
    ("Bırakma riskini erken fark etme",
     "Hem salona gelmeyen hem uygulamada kayıt tutmayı bırakan üye yüksek risk grubudur. Bu sinyal otomatik hatırlatma, "
     "PT araması ya da kampanya tetikleyebilir."),
]
for i, (h, b) in enumerate(adv, 1):
    story.append(KeepTogether([P(f"7.{i} {h}", "h2"), P(b)]))
story.append(PageBreak())

# 8
story.append(P("8. Handikaplar ve Riskler", "h1"))
hand = [
    ("KVKK ve sağlık verisi (kritik)",
     "Kilo, vücut yağı, beslenme ve uyku verisi sağlıkla ilgili olduğundan özel nitelikli kişisel veri kapsamına girer. "
     "Alp Fit bugün \"veri toplamıyor\" beyanında; entegrasyonla bu durum değişir. Aydınlatma metni, açık rıza, VERBİS, "
     "veri işleyen sözleşmesi, teknik güvenlik önlemleri ve sunucular yurt dışındaysa aktarım prosedürü gerekir. "
     "Ayrıntı için bkz. Bölüm 12."),
    ("Veri sahipliği ve rekabet sızıntısı",
     "Üye salondan ayrıldığında verisi kimde kalacak? Kunaz aynı bölgede rakip salonlarla da çalışırsa Alp Fit'in "
     "üye ilişkisi dolaylı olarak üçüncü tarafa taşınmış olur. Sözleşmede açık hüküm olmadan bu risk yönetilemez."),
    ("İki tedarikçiye bağımlılık",
     "Gymsoft ve Saintsun ayrı firmalar. Fiyat artışı, API değişikliği, firma kapanması ya da öncelik değişikliği "
     "entegrasyonu bozabilir. Destek talebinde sorumluluğun birbirine atılması riski de var."),
    ("Maliyet ve ölçek uyumsuzluğu",
     "Tek salonlu, kullanıcı kitlesi henüz küçük bir uygulama için, global bir ürünün lisans maliyeti üye başına getiriyi "
     "aşabilir. \"Herkese ücretsiz Pro\" kararı maliyeti tamamen salona yükler. Aktif kullanıma göre ücretlendirme şart."),
    ("Marka erimesi",
     "Üyenin günlük ilişkisi Kunaz ile kurulursa sadakat salona değil uygulamaya gelişir. Alp Fit, yalnızca kapı açan bir "
     "araca dönüşebilir. Markanın ön planda olduğu bir kurgu gerekir."),
    ("Parçalı kullanıcı deneyimi",
     "İki ayrı uygulama, iki giriş, iki bildirim akışı üyeyi yorar ve kullanımı düşürür. Tek uygulama ise pahalı bir mühendislik işi "
     "(Senaryo C)."),
    ("Düşük kullanım (adoption) riski",
     "Kalori takip uygulamalarında kullanıcıların önemli bölümü ilk haftalarda kayıt tutmayı bırakır. Ödenen lisansların bir "
     "kısmı boşa gidebilir; PT takibi ve topluluk mekanikleri olmadan kullanım düşük kalır."),
    ("Sorumluluk ve itibar",
     "Yapay zekâ koçun önerisi bir sağlık sorununa yol açarsa ya da PT'nin tavsiyesiyle çelişirse itibar ve hukuki risk "
     "doğar. Kunaz değerlerin tahmin olduğunu belirtiyor; salonun da açık bir sorumluluk reddi ve PT öncelik kuralı olmalı."),
    ("Personel değişimi ve eğitim",
     "PT'ler Max panelini kullanmazsa \"veri var ama kimse bakmıyor\" durumu oluşur. Eğitim, iş tanımı güncellemesi ve "
     "teşvik (örn. danışan gelişimine bağlı prim) gerekir."),
    ("Avantajın kopyalanabilirliği",
     "Kunaz herkese açık; münhasırlık alınmazsa rakip salonlar aynı hikâyeyi birkaç haftada kurabilir. Kalıcı fark, salona özgü "
     "süreçler, topluluk ve veriyle yaratılmalıdır."),
    ("Teknik entegrasyon belirsizliği",
     "Kunaz'ın kurumsal API'si ve Gymsoft'un dışa açık entegrasyon olanakları kamuya açık değil. Teknik fizibilite "
     "doğrulanmadan taahhüt verilmemeli."),
]
for i, (h, b) in enumerate(hand, 1):
    story.append(KeepTogether([P(f"8.{i} {h}", "h2"), P(b)]))
story.append(PageBreak())

# 9 SWOT
story.append(P("9. SWOT Analizi (Birleşik Yapı, Alp Fit Bakışı)", "h1"))


def quad(title, items, bg):
    content = [Paragraph(f"<b>{title}</b>", S["cell"])] + [Paragraph("• " + x, S["cell"]) for x in items]
    t = Table([[c] for c in content], colWidths=[8.3 * cm])
    t.setStyle(TableStyle([("BACKGROUND", (0, 0), (-1, -1), bg), ("LEFTPADDING", (0, 0), (-1, -1), 7),
                           ("TOPPADDING", (0, 0), (-1, -1), 2), ("BOTTOMPADDING", (0, 0), (-1, -1), 2)]))
    return t


swot = Table([
    [quad("GÜÇLÜ YÖNLER", [
        "Fiziksel salon + dijital koçluk birleşimi",
        "Hazır, olgun içerik (1.900+ egzersiz, 40.000+ besin)",
        "Yapay zekâ ile besin tanıma ve koçluk",
        "Kunaz Max ile hazır PT/diyetisyen paneli",
        "Giriş + gelişim verisinin tek resimde birleşmesi"], GREEN),
     quad("ZAYIF YÖNLER", [
        "Alp Fit'in küçük, yeni kullanıcı tabanı",
        "İki ayrı uygulama, parçalı deneyim",
        "Sağlık verisi yönetiminde deneyimsizlik",
        "API ve B2B fiyatlarının belirsizliği",
        "PT'lerin dijital araç alışkanlığı sınırlı olabilir"], AMBER)],
    [quad("FIRSATLAR", [
        "Premium beslenme/PT paketleri",
        "Salona gelmeyen kitleye online koçluk",
        "Rakip salonlardan ayrışma (yapay zekâ koçlu salon)",
        "Kurumsal (şirket çalışanı) wellness paketleri",
        "İleride Gymsoft ağındaki diğer salonlara ölçeklenme"], LIGHT),
     quad("TEHDİTLER", [
        "KVKK ihlali; idari para cezası ve itibar kaybı",
        "Rakiplerin aynı entegrasyonu kopyalaması",
        "Tedarikçi fiyat artışı ya da ürün değişikliği",
        "Global uygulamaların (ücretsiz) rekabeti",
        "Yapay zekâ önerilerinden doğan sorumluluk"], RED)],
], colWidths=[8.5 * cm, 8.5 * cm])
swot.setStyle(TableStyle([("VALIGN", (0, 0), (-1, -1), "TOP"), ("LEFTPADDING", (0, 0), (-1, -1), 2),
                          ("RIGHTPADDING", (0, 0), (-1, -1), 2), ("TOPPADDING", (0, 0), (-1, -1), 2),
                          ("BOTTOMPADDING", (0, 0), (-1, -1), 2)]))
story.append(swot)

# 10 Risk matrix
story.append(P("10. Risk Matrisi", "h1"))
risks = [
    ("KVKK uyumsuzluğu", 3, 5, "Uzman desteği, açık rıza akışı, DPA, VERBİS, aktarım prosedürü"),
    ("Düşük kullanım", 4, 3, "PT takibi, 30 günlük meydan okumalar, ödül; aktif kullanıma göre lisans"),
    ("Tedarikçi bağımlılığı", 3, 4, "Fiyat sabitleme, çıkış maddesi, veri taşınabilirliği"),
    ("Rakiplerin kopyalaması", 4, 3, "Bölgesel münhasırlık, salona özgü süreç ve topluluk"),
    ("Marka erimesi", 3, 3, "Ortak marka (\"Alp Fit Beslenme\"), salon içeriği ön planda"),
    ("Maliyetin getiriyi aşması", 3, 4, "Pilot + başa baş takibi, kademeli yayılım"),
    ("Yapay zekâ sorumluluğu", 2, 4, "Sorumluluk reddi, sağlık beyanı, PT önceliği kuralı"),
    ("Teknik entegrasyon başarısızlığı", 2, 3, "Önce fizibilite, manuel köprü (B senaryosu) ile başla"),
]
rows = [["Risk", "Olasılık (1–5)", "Etki (1–5)", "Skor", "Önlem"]]
extra = []
for i, (r, o, e, m) in enumerate(sorted(risks, key=lambda x: -x[1] * x[2]), 1):
    sc = o * e
    rows.append([r, str(o), str(e), f"<b>{sc}</b>", m])
    bg = RED if sc >= 15 else AMBER if sc >= 10 else GREEN
    extra.append(("BACKGROUND", (3, i), (3, i), bg))
story.append(table(rows, [4 * cm, 2.1 * cm, 1.8 * cm, 1.3 * cm, 7.8 * cm], zebra=False, extra=extra))
story.append(P("Skor = olasılık × etki. Kırmızı ≥ 15, sarı 10–14, yeşil < 10.", "note"))
story.append(PageBreak())

# 11 Financial
story.append(P("11. Finansal Etki Modeli (Örnek)", "h1"))
story.append(callout("<b>Önemli:</b> Aşağıdaki rakamlar Alp Fit'in gerçek verisi değildir. Mekanizmayı göstermek için "
                     "makul varsayımlarla kurulmuş örnek bir modeldir. Gerçek üye sayısı, fiyat ve bırakma oranı girilerek "
                     "yeniden hesaplanmalıdır.", AMBER, colors.HexColor("#D97706")))
story.append(Spacer(1, 6))
story.append(P("11.1 Varsayımlar", "h2"))
story.append(table([
    ["Parametre", "Değer", "Açıklama"],
    ["Başlangıç aktif üye", "400", "Orta ölçekli tek salon"],
    ["Aylık yeni kayıt", "32", "Mevcut durumda üye sayısını sabit tutan seviye"],
    ["Ortalama aylık üyelik ücreti", tl(FEE), "Varsayım"],
    ["Aylık bırakma oranı (bugün)", "%8", "Ortalama üyelik süresi ~12,5 ay"],
    ["Kunaz'ı aktif kullanan üye", f"{ADOPT} (~%40)", "Lisans yalnız aktif kullanıcıya"],
    ["Lisans maliyeti", f"{tl(LIC)} / kullanıcı / ay", "Varsayım; B2B fiyatı tedarikçiden alınmalı"],
    ["Kurulum, eğitim, KVKK danışmanlığı", tl(SETUP), "Tek seferlik"],
    ["Yıllık toplam maliyet", f"<b>{tl(COST)}</b>", f"{ADOPT} × {LIC} TL × 12 + kurulum"],
    ["Premium beslenme koçluğu eki", f"{tl(PREM)} / ay", "Üyeliğe ek paket"],
], [5.5 * cm, 4 * cm, 7.5 * cm]))
story.append(Spacer(1, 6))
story.append(P("11.2 Senaryolar (12 ay)", "h2"))
rows = [["Senaryo", "Bırakma oranı", "Ay 12 üye", "Ek üye-ay", "Ek üyelik geliri", "Premium geliri", "Net etki"]]
extra = []
for i, (name, d, pr) in enumerate(SCEN, 1):
    end, mm, rr, pv, net = scenario(d, pr)
    rows.append([f"<b>{name}</b> ({"−" if d else ""}{d:g} puan, premium %{int(pr*100)})", f"%{8 - d:g}", f"{end:.0f}", f"{mm:.0f}",
                 tl(rr), tl(pv), f"<b>{tl(net)}</b>"])
    extra.append(("BACKGROUND", (6, i), (6, i), GREEN if net > 0 else RED))
story.append(table(rows, [4.3 * cm, 1.9 * cm, 1.7 * cm, 1.8 * cm, 2.6 * cm, 2.3 * cm, 2.4 * cm], zebra=False, extra=extra))
story.append(Spacer(1, 6))
be_mm = COST / FEE
story.append(P("11.3 Yorum", "h2"))
story += bullets([
    f"<b>Başa baş:</b> Premium geliri hiç olmasa bile yıllık maliyetin karşılanması için ~{be_mm:.0f} ek üye-ay gerekir. "
    "Bu, aylık bırakma oranında yaklaşık <b>0,4 puanlık</b> iyileşmeye denk gelir (%8 → ~%7,6).",
    "Etkinin asıl kaynağı lisans değil, <b>elde tutma</b>dır. Bırakma oranındaki küçük değişimler, üye tabanını kalıcı olarak büyütür; "
    "etki 12. aydan sonra da birikerek artar.",
    "Kötümser senaryo (hiç iyileşme yok) zararın sınırlı kaldığını gösterir; bu, pilotla başlamanın mantığıdır: kayıp riski küçük, "
    "olası kazanç büyük.",
    "Model; PT paket satış artışı, yeni üye kazanımındaki pazarlama etkisi ve kurumsal paketleri <b>içermez</b>. Bunlar ek yukarı yönlü potansiyeldir.",
])
story.append(PageBreak())

# 12 KVKK
story.append(P("12. KVKK ve Hukuki Çerçeve", "h1"))
story.append(callout("Bu bölüm genel bilgilendirme amaçlıdır, hukuki görüş değildir. Uygulamaya geçmeden önce KVKK "
                     "konusunda uzman bir avukat ya da danışmanla doğrulanmalıdır.", AMBER, colors.HexColor("#D97706")))
story.append(Spacer(1, 6))
story += bullets([
    "<b>Veri sınıfı:</b> Kilo, vücut yağ oranı, beslenme, uyku ve sağlık beyanı gibi veriler 6698 sayılı KVKK kapsamında "
    "<b>sağlık verisi</b>, yani özel nitelikli kişisel veridir. İşlenmesi kural olarak <b>açık rızaya</b> ya da kanunda sayılan "
    "sınırlı istisnalara dayanır; salon üyeliği için bu istisnalar büyük olasılıkla uygulanmaz.",
    "<b>Açık rıza akışı:</b> Belirli konuya ilişkin, bilgilendirmeye dayalı, özgür iradeyle. Üyelik sözleşmesine gömülmemeli; "
    "entegrasyon <b>isteğe bağlı</b> olmalı ve rıza geri alınabilmeli.",
    "<b>Roller:</b> Salon, PT'lerin gördüğü veri için veri sorumlusu; Kunaz ve Gymsoft ise rollerine göre veri işleyen ya da "
    "ayrı veri sorumlusu olabilir. Bu roller yazılı sözleşmeyle (veri işleme sözleşmesi) belirlenmeli.",
    "<b>VERBİS:</b> Salonun kayıt yükümlülüğü ve envanteri, sağlık verisi kategorisi eklenecek şekilde gözden geçirilmeli.",
    "<b>Yurt dışı aktarım:</b> Sunucular Türkiye dışındaysa KVKK'nın 2024 değişikliğiyle güncellenen aktarım kuralları "
    "(yeterlilik kararı, standart sözleşme ve Kurum'a bildirim vb.) uygulanır. Sunucu konumu tedarikçiden yazılı alınmalı.",
    "<b>Özel nitelikli veri güvenlik önlemleri:</b> Şifreleme, erişim yetkilendirmesi (PT yalnızca kendi danışanını görür), "
    "erişim kayıtları, personel gizlilik taahhüdü ve eğitim.",
    "<b>Saklama ve imha:</b> Üyelik bitince ya da rıza geri alınınca verinin ne zaman ve nasıl silineceği tanımlanmalı.",
    "<b>Pazarlama kullanımı:</b> Başarı hikâyeleri yalnızca ayrı onayla ve tercihen anonimleştirilerek kullanılmalı.",
    "<b>App Store beyanları:</b> Alp Fit'in \"veri toplanmıyor\" beyanı entegrasyonla güncellenmeli; aksi hâlde mağaza politikası ihlali doğabilir.",
    "<b>Sağlık iddiaları:</b> Yapay zekâ önerileri için \"tıbbi tavsiye değildir\" uyarısı; kronik hastalık, hamilelik gibi durumlarda "
    "doktor onayı yönlendirmesi.",
])

# 13 Contract
story.append(P("13. Sözleşme Kontrol Listesi", "h1"))
story.append(table([
    ["Madde", "Neden önemli", "Hedef"],
    ["Veri sahipliği", "Üye ayrılınca veri ve ilişki kimde?", "Salon verisi salona ait; ayrılınca dışa aktarım ve silme"],
    ["Bölgesel münhasırlık", "Rakiplerin kopyalamasını engeller", "Belirli yarıçapta 12–24 ay münhasırlık"],
    ["Fiyatlandırma modeli", "Boşa lisans ödememek", "Yalnızca aylık aktif kullanıcı başına ücret"],
    ["Fiyat sabitleme", "Sürpriz zammı önler", "En az 12 ay sabit; artışa üst sınır"],
    ["Gelir paylaşımı", "Pro/Max satışından pay", "Salon üzerinden gelen kullanıcılarda komisyon"],
    ["KVKK rolleri ve DPA", "Hukuki sorumluluk netliği", "Yazılı veri işleme sözleşmesi, ihlal bildirim süresi"],
    ["Sunucu konumu ve güvenlik", "Yurt dışı aktarım yükümlülükleri", "Yazılı beyan, sertifikalar, denetim hakkı"],
    ["Hizmet seviyesi (SLA)", "Kesintide üye mağduriyeti", "Erişilebilirlik hedefi, destek süresi, tazmin"],
    ["Marka kullanımı", "Marka erimesini önler", "Ortak marka; salon logosu ve renkleri ön planda"],
    ["Çıkış maddesi", "Bağımlılığı sınırlar", "Pilot sonunda cezasız çıkış; veri taşınabilirliği"],
    ["Sorumluluk sınırları", "Yapay zekâ ve sağlık riski", "Tedarikçinin ürün kaynaklı sorumluluğu, sigorta"],
], [3.8 * cm, 5.4 * cm, 7.8 * cm]))
story.append(PageBreak())

# 14 Roadmap
story.append(P("14. Uygulama Yol Haritası", "h1"))
story.append(table([
    ["Aşama", "Süre", "Faaliyetler", "Çıktı / karar kapısı"],
    ["0. Hazırlık", "2–4 hafta", "Saintsun ve Gymsoft ile görüşme; B2B fiyat, API ve sunucu bilgisi; KVKK danışmanı; "
     "mevcut bırakma oranı, gelme sıklığı ve PT satışlarının ölçülmesi (karşılaştırma tabanı)", "İmzalı pilot sözleşmesi, rıza metinleri, ölçüm tabanı"],
    ["1. Pilot kurulum", "2 hafta", "Kunaz Max hesapları, PT eğitimi, rıza akışı, ortak marka materyalleri, "
     "50–100 gönüllü üye seçimi + benzer bir karşılaştırma grubu", "Hazır pilot grubu"],
    ["2. Pilot (90 gün)", "12 hafta", "Haftalık PT kontrolleri, 30 günlük meydan okuma, ilk/son vücut analizi, "
     "aylık gelişim raporu, premium paket teklif testi", "Pilot ve karşılaştırma grubunun KPI kıyası"],
    ["3. Karar", "2 hafta", "Finansal modelin gerçek veriyle yeniden hesaplanması; üye ve PT anketleri", "Yaygınlaştır / revize et / durdur"],
    ["4. Yaygınlaştırma", "3–6 ay", "API entegrasyonu (tek tıkla bağlanma, giriş verisi paylaşımı), bırakma riski uyarıları, "
     "tüm üyelere isteğe bağlı açılış", "Senaryo A + B tam devrede"],
    ["5. Stratejik seçenek", "12+ ay", "Senaryo C (tek uygulama) ya da D (kurumsal ortaklık) değerlendirmesi", "Yatırım kararı"],
], [3 * cm, 2 * cm, 7 * cm, 5 * cm]))

# 15 KPI
story.append(P("15. Başarı Ölçütleri (KPI)", "h1"))
story.append(table([
    ["KPI", "Tanım", "Pilot hedefi (öneri)"],
    ["Aylık bırakma oranı", "Pilot ve karşılaştırma grubu arasındaki fark", "≥ 1 puan daha düşük"],
    ["Salona gelme sıklığı", "Üye başına aylık giriş", "%10–15 artış"],
    ["Uygulama kullanımı", "Haftada ≥ 4 gün kayıt tutan üye oranı", "≥ %40"],
    ["Premium dönüşüm", "Premium paketi satın alan pilot üye oranı", "≥ %5"],
    ["PT paket satışı", "Pilot gruptaki PT paket yenileme / yeni satış", "%20 artış"],
    ["Üye memnuniyeti (NPS)", "Pilot sonu anket", "Karşılaştırma grubundan ≥ 10 puan yüksek"],
    ["PT benimsemesi", "Panelde haftalık aktif PT oranı", "≥ %80"],
    ["KVKK uyumu", "Rıza oranı, şikâyet ve ihlal sayısı", "0 ihlal"],
    ["Maliyet / getiri", "Net etki ÷ toplam maliyet", "> 1 (başa baş üstü)"],
], [4 * cm, 7.5 * cm, 5.5 * cm]))
story.append(PageBreak())

# 16 Conclusion
story.append(P("16. Sonuç ve Öneri", "h1"))
story.append(P(
    "Alp Fit ile Kunaz'ın birleşmesi, doğru kurgulanırsa Alp Fit için <b>yüksek getiri potansiyeli ve sınırlı başlangıç riski</b> "
    "taşıyan bir fırsattır. Değer, iki uygulamanın yan yana konmasından değil; salona giriş verisi, vücut gelişimi ve PT "
    "takibinin tek bir üye deneyiminde birleşmesinden doğar."))
story.append(P(
    "Buna karşın değer, kendiliğinden oluşmaz. Üç koşul belirleyicidir: <b>(1)</b> KVKK uyumunun baştan tasarlanması, "
    "<b>(2)</b> sözleşmeyle veri sahipliği, münhasırlık ve çıkış hakkının güvenceye alınması, <b>(3)</b> PT'lerin süreci "
    "gerçekten sahiplenmesi. Bunlar olmadan proje ya hukuki risk ya da kullanılmayan bir lisans maliyetine dönüşür."))
story.append(callout(
    "<b>Önerilen karar</b><br/>"
    "1. Tam birleşme (C/D) yerine <b>Senaryo B ile hemen başla</b>: Kunaz Max üzerinden PT destekli premium beslenme paketi.<br/>"
    "2. Aynı anda Senaryo A için teknik ve ticari fizibiliteyi tamamla.<br/>"
    "3. <b>90 günlük pilotu karşılaştırma grubuyla</b> yürüt; kararı tahmine değil veriye göre ver.<br/>"
    "4. Pilot öncesi KVKK danışmanlığı, rıza akışı ve DPA'yı tamamla.<br/>"
    "5. Sözleşmede bölgesel münhasırlık, aktif kullanıcı başına fiyat ve cezasız çıkış maddesi iste.<br/>"
    "6. Markayı koru: üyenin gözünde bu, \"Alp Fit'in beslenme koçluğu\" olmalı; Kunaz arka planda altyapı.", GREEN))

# Appendix
story.append(P("Ek A. Varsayımlar ve Belirsizlikler", "h1"))
story += bullets([
    "Alp Fit'in Gymsoft altyapısını kullandığı App Store bilgisine dayanır; Gymsoft'un kurumsal yapısı doğrulanmamıştır.",
    "Finansal model rakamları (400 üye, 1.500 TL ücret, %8 aylık bırakma, 60 TL lisans, %40 kullanım) örnek varsayımdır.",
    "Kunaz'ın B2B fiyatı, API olanakları ve sunucu konumu bilinmemektedir.",
    "Senaryo puanları uzman değerlendirmesine dayalıdır, ölçülmüş veri değildir.",
    "KVKK değerlendirmesi genel bilgi niteliğindedir.",
])
story.append(P("Ek B. Kaynaklar", "h1"))
story += bullets([
    "Alp Fit – App Store: apps.apple.com/us/app/alp-fit/id6755318924",
    "Kunaz – resmi site ve SSS (Kunaz Pro, Kunaz Max): kunaz.tr",
    "Gymsoft+ – App Store: apps.apple.com/us/app/id6618157675",
    "OxyFitClub: oxyfitclub.com · GymTekno: gymtekno.com · FitAPP: fitapp.com.tr",
    "SporSalonum.net: sporsalonum.net · BulutGym: bulutgym.com",
    "6698 sayılı Kişisel Verilerin Korunması Kanunu (2024 değişiklikleriyle): kvkk.gov.tr",
])

doc = SimpleDocTemplate(OUT, pagesize=A4, leftMargin=2 * cm, rightMargin=2 * cm, topMargin=1.8 * cm, bottomMargin=2 * cm,
                        title="Alp Fit × Kunaz — Stratejik Birleşme / Entegrasyon Analizi",
                        author="Claude Code", subject="Alp Fit ve Kunaz birleşme analizi")
doc.build(story, onFirstPage=on_page, onLaterPages=on_page)
print("OK", OUT)
