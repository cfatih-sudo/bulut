# Jet Bilişim – Google Ads Stratejisi ve Aylık 300.000 TL Satış Planı

- **Tarih:** 28.10.2026
- **Para birimi:** Tüm tutarlar TL ve KDV hariçtir.
- **Kaynaklar:** Fiyatlar jetbilisim.com.tr/paketler/ ve /jet-buyume/ sayfalarından alındı.
- **Tahminler:** Tıklama maliyetleri ve dönüşüm oranları sektör tahminidir. İlk 30 günün gerçek verisiyle güncellenmelidir.

## Kısa cevap

**Evet, aylık 300.000 TL'ye ulaşmak mümkün. Ama bu tek başına reklamla olmaz ve ilk ay da olmaz.** Gerçekçi süre 6–12 aydır.

Hedef üç kaynağın toplamıyla tutar:
1. **Yeni site satışları:** Google Ads, SEO ve referanslardan ayda yaklaşık 7 site.
2. **Aylık gelir (Jet Büyüme):** Biriken abonelik geliri.
3. **Mevcut 1200+ referans:** Yenileme, yeniden tasarım ve Büyüme paketine geçiş. En ucuz ve en hızlı kaynak budur.

Belirleyici üç şart:
- **Ölçüm:** Reklamın hangi satışı getirdiğini görebilmek.
- **Hızlı geri dönüş:** Gelen talebi aynı gün aramak.
- **Kapasite:** Ayda 7–8 siteyi ve 25–30 aylık müşteriyi kaliteden ödün vermeden teslim edebilmek.

---

## 1. Hedefin matematiği

### Ortalama site siparişi
| Paket | Fiyat | Tahmini pay | Katkı |
|---|---|---|---|
| Jet Başla | 14.990 | %30 | 4.497 |
| Jet KOBİ | 27.990 | %30 | 8.397 |
| Jet KOBİ Premium | 36.990 | %25 | 9.248 |
| Katalog / İhracat (ort.) | ~50.000 | %15 | 7.500 |
| Dil + eklenti ortalaması | | | ~2.500 |
| **Ortalama sipariş** | | | **≈ 32.000** |

### 12. ay hedef karışımı (aylık)
| Kaynak | Hesap | Aylık |
|---|---|---|
| Yeni site satışı | 7 site × 32.000 | 224.000 |
| Jet Büyüme aboneliği (birikmiş) | 20 müşteri × ort. 3.500 | 70.000 |
| Yenilemeler ve ek eklentiler | mevcut müşteri tabanından | 20.000+ |
| **Toplam** | | **≈ 314.000** |

> **Bilmediğim rakam:** Kaç sitenin aktif olarak yenileme ödediğini bilmiyorum. 1200+ referansın 300'ü aktifse, yıllık yenileme ortalaması 3.300 TL'den aylık yaklaşık 80.000 TL eder. Gerçek sayı bu planı büyük ölçüde değiştirir.

### Ayda 7 site için gereken huni
Varsayım: satışların yaklaşık %60'ı reklamdan, kalanı SEO, referans ve eski müşterilerden gelir.

| Adım | İyimser | Temkinli |
|---|---|---|
| Hedef satış (toplam) | 7 | 7 |
| Talep → satış oranı | %20 | %12 |
| Gereken talep (form, arama, WhatsApp, sipariş) | 35 | 58 |
| Reklamdan gelen talep (%60) | 21 | 35 |
| Tıklama → talep oranı | %5 | %3 |
| Gereken tıklama | 420 | 1.170 |
| Ortalama tıklama maliyeti | 50 TL | 90 TL |
| **Aylık reklam bütçesi** | **≈ 21.000 TL** | **≈ 105.000 TL** |
| Reklamdan satış | 4,2 | 4,2 |
| Satış başı reklam maliyeti | ≈ 5.000 TL | ≈ 25.000 TL |

- **Tıklama maliyeti:** Google Planlayıcı verisine göre "web tasarım" için sayfa üstü teklifler 41–164 TL arasında. Uzun ve yerel aramalar (ör. "tuzla web tasarım", "restoran web sitesi") genelde daha ucuzdur.
- **Sonuç:** Temkinli senaryoda bir satışın reklam maliyeti, sipariş tutarının çoğunu yer. Bu yüzden başarıyı bütçe değil, **tıklama → talep** ve **talep → satış** oranları belirler. Aşağıdaki planın çoğu bu iki oranı yükseltmeye yöneliktir.

---

## 2. Önce ölçüm (reklamdan önce, 1. hafta)

Ölçüm olmadan Google'ın otomatik teklif sistemi doğru müşteriyi bulamaz.

- [ ] **GA4 olayları:**
  - demo_ac
  - paket_sec
  - siparis_adim1, siparis_adim2, siparis_adim3
  - siparis_gonder (tutar ile)
  - odeme_tamam (tutar ile)
  - form_gonder
  - tel_tikla
  - whatsapp_tikla
- [ ] **Google Ads dönüşümleri:**
  - **Birincil:** siparis_gonder (değer = genel toplam), form_gonder, tel_tikla (60 sn üzeri arama), whatsapp_tikla.
  - **İkincil, yalnızca gözlem için:** demo_ac, paket_sec.
- [ ] **Gelişmiş dönüşümler (enhanced conversions):** Sipariş ve form e-postasını şifreli olarak iletin.
- [ ] **Çevrimdışı dönüşüm aktarımı:** Onay görüşmesinden sonra gerçekleşen satışı GCLID ile Google Ads'e geri yükleyin. Bu adım reklamı "form dolduranı" değil "satın alanı" bulmaya yönlendirir. **En önemli adım budur.**
- [ ] **Çağrı takibi:** Reklamdan gelen aramalar için Google yönlendirme numarası kullanın.
- [ ] **Basit bir CRM:** Her talep için kaynak, tarih, arama saati, sonuç ve tutar kaydedin. Bir tablo da olur.

---

## 3. Kampanya yapısı

| # | Kampanya | Amaç | Bütçe payı | Açılış sayfası |
|---|---|---|---|---|
| 1 | **Arama – Fiyat/Paket** | Satın almaya hazır kişi | %35 | /paketler/ |
| 2 | **Arama – Yerel** | Tuzla, Pendik, Gebze, Kocaeli OSB'ler | %20 | /tuzla-web-tasarim/, /gebze-osb-web-tasarim/ (+ yeni bölge sayfaları) |
| 3 | **Arama – Sektör** | "restoran web sitesi", "makine firması web sitesi" | %15 | Filtrelenmiş demo vitrini veya sektör sayfası |
| 4 | **Arama – İhracat/Çok dil** | Yüksek tutarlı sipariş | %10 | Jet İhracat paketi, /eklenti-coklu-dil/ |
| 5 | **Yeniden pazarlama** | Demo açıp sipariş vermeyenler | %10 | Ziyaret edilen demo + "aynı gün arıyoruz" |
| 6 | **Demand Gen / YouTube** | Demo düzenleyici videosu | %10 (2. aydan sonra) | demo.jetbilisim.com.tr |

**Ayarlar:**
- **Konum:** "Konumdaki kişiler" seçeneği. Başta İstanbul Anadolu Yakası ve Kocaeli, ikinci aydan sonra Türkiye geneli (internetten sipariş olduğu için).
- **Zaman:** Hafta içi 08:00–20:00 teklif +%20, gece −%40, pazar −%30. Aramalara cevap verilemeyen saatlerde arama uzantısını kapatın.
- **Cihaz:** Mobil açık kalsın. Mobilde arama ve WhatsApp, masaüstünde sipariş öne çıkar.
- **Ağ:** Yalnızca Arama ağı. Arama iş ortakları ve Görüntülü Reklam Ağı kapalı.

### Anahtar kelimeler (sıralı ve tam eşleme ile başlayın)

**1. Fiyat/Paket:**
- "web sitesi fiyatları"
- "kurumsal web sitesi fiyatları"
- "web sitesi yaptırmak"
- "web sitesi yaptırma fiyatları"
- "firma web sitesi"
- "kurumsal web sitesi paketleri"
- "hazır kurumsal web sitesi"
- "web tasarım fiyatları"

**2. Yerel:**
- "tuzla web tasarım", "pendik web tasarım", "kartal web tasarım"
- "gebze web tasarım", "kocaeli web tasarım", "çayırova web tasarım"
- "dilovası web tasarım"
- "anadolu yakası web tasarım"

**3. Sektör (her biri ayrı reklam grubu):**
- "restoran web sitesi"
- "klinik web sitesi"
- "makine firması web sitesi"
- "inşaat firması web sitesi"
- "otel web sitesi"
- "avukat web sitesi"
- "güzellik salonu web sitesi"
- "oto galeri web sitesi"

**4. İhracat:**
- "ihracat web sitesi"
- "çok dilli web sitesi"
- "ingilizce web sitesi yaptırmak"
- "b2b katalog sitesi"
- "ürün katalog sitesi"

### Negatif anahtar kelimeler (ilk günden ekleyin)
- **Ücretsiz arayanlar:** ücretsiz, bedava
- **Kendin yap:** nasıl yapılır, kendin yap, öğren, kurs, eğitim, ders, udemy
- **İş arayanlar:** iş ilanı, staj, maaş, freelancer ol, kariyer
- **Hazır platformlar:** wordpress tema, themeforest, şablon indir, wix, ideasoft, ticimax, shopify, ikas
- **Ödev/proje:** ödev, proje ödevi, html css
- **Kapsam dışı:** mobil uygulama, oyun, crack, apk
- **Farklı niyetler:** domain sorgulama, hosting ücretsiz, cpanel

Arama terimleri raporunu ilk ay **her gün**, sonrasında haftada bir kontrol edin.

### Reklam metni örnekleri (Duyarlı Arama Reklamı)

**Başlıklar** (her biri en fazla 30 karakter):
1. Kurumsal Web Sitesi 14.990 TL
2. 3–10 İş Gününde Yayında
3. 213 Demo, Kendiniz Düzenleyin
4. 1998'den Beri 1200+ Referans
5. İnternetten Sipariş, Taksit
6. Fiyatlar Açık, Sürpriz Yok
7. Çok Dilli İhracat Sitesi
8. Tuzla'da Web Tasarım Ekibi
9. Kendi Yazılımımız: JET Core
10. Aynı Gün Sizi Arıyoruz

**Açıklamalar** (her biri en fazla 90 karakter):
1. 213 hazır tasarımı canlı inceleyin, düzeni kendiniz seçin. 3–10 iş gününde yayında.
2. Paket fiyatları sitede açık. Kartla taksit veya havale. Kurulumu ve içeriği biz yaparız.
3. Hosting, güncelleme ve destek dahil yıllık yenileme. Alan adı her zaman sizin adınıza.

**Fiyat uyarısı:** Fiyat yazan reklamlarda "+KDV" ifadesini açılış sayfasında da açıkça gösterin. Google'ın politikası bunu gerektirir.

**Uzantılar:**
- **Site bağlantıları:** Paketler, Demo Vitrini, İhracat Sitesi, Referanslar
- **Fiyat uzantısı:** 3 paket
- **Arama uzantısı:** Mesai saatlerinde
- **Konum uzantısı:** Google İşletme Profili bağlantısı
- **Açıklama metinleri:** "Kendi yazılımı", "28 yıl", "Taksit"
- **Görsel uzantısı:** Demo görselleri

### Teklif stratejisi
1. **1–3. hafta:** Tıklamaları en üst düzeye çıkar (tıklama başı üst sınır 80 TL) veya manuel tıklama başı maliyet. Amaç veri toplamak.
2. **30 dönüşümden sonra:** Dönüşümleri en üst düzeye çıkar.
3. **Çevrimdışı satış verisi oturunca (genelde 2–3. ay):** Hedef ROAS ile değer bazlı teklif. Başlangıç hedefi %300–400.

---

## 4. Dönüşüm oranını artıracak işler (reklam parasını boşa harcamamak için)

| İş | Neden önemli | Durum |
|---|---|---|
| Talebe **15 dakika içinde** dönüş, mesai dışında ertesi sabah 09:00 | B2B'de ilk arayan firma satışı alır. En büyük etki burada. | Süreç kararı |
| Sabit WhatsApp düğmesi ve demo sayfasında "Bu demo hakkında sor (JD-xxx)" | Mobil kullanıcı form doldurmaz, yazar | Yok (2. incelemede bulgu 14) |
| Demo sayfasında "Bu tasarımı e-postama gönder" | Hazır olmayan ziyaretçiden iletişim bilgisi alır; yeniden pazarlama listesi oluşur | Yok |
| Paketler sayfasının üstünde Google puanı ve 3 gerçek yorum | Fiyat görünce tereddüt edeni ikna eder | Puan yok |
| 3 vaka çalışması (ör. "OSB makine firması: 6 ayda ayda 20 teklif formu") | Reklamda ve açılış sayfasında güven | Yok |
| Sipariş formunu yarıda bırakana 24 saat içinde e-posta ve arama | Siparişin %10–20'si buradan kurtarılabilir | Gerekirse geliştirme |
| Kullanım Koşulları ve merkez şablon sitesini düzeltmek (2. inceleme, bulgu 1–2) | Reklamla gelen dikkatli müşteri bu sayfaları görürse güven kaybı olur | Acil |

---

## 5. Reklam dışı büyüme (300 bine asıl buradan ulaşılır)

### 5.1 Mevcut 1200+ referans
- **Yeniden tasarım kampanyası:** Eski sitesi olan müşterilere "Sitenizi yeni JET Core'a taşıyın: mevcut müşteriye kurulumda %20 indirim, içerik taşıma bizden" teklifi.
  - Hesap: 1.000 kişiye ulaşılırsa ve yılda %2'si dönerse 20 site eder. Bu da ayda ortalama 1,7 site × 32.000 ≈ **53.000 TL** demek, reklam maliyeti neredeyse sıfır.
- **Jet Büyüme'ye geçiş:** Mevcut müşteriye "Jet Bakım" (1.490 TL/ay) teklifi. Müşterilerin %3'ü bile geçse yaklaşık 30 müşteri olur, bu da ayda ≈ **45.000–100.000 TL** düzenli gelir.
- **Tavsiye programı:** "Bir firma önerin, o sipariş verirse yıllık yenilemeniz bizden."

### 5.2 İş birlikleri
- **Mali müşavirler:** Yeni şirket kuranların ilk ihtiyacı web sitesi ve kurumsal e-postadır. Komisyon veya karşılıklı tavsiye.
- **OSB yönetimleri, ticaret odaları, sanayici dernekleri:** Üyelere özel paket ve "ihracat için web sitesi" semineri.
- **Matbaa, reklam ve tabela firmaları:** Kendi müşterilerine web sitesi satabilirler (bayi modeli).

### 5.3 SEO ve içerik
- Yerel sayfalar (Pendik, Kartal, Çayırova, Dilovası…) ve sektör sayfaları. Reklamdaki anahtar kelimelerle birebir eşleşsin; reklamda iyi çalışan kelimeler SEO'ya taşınsın.
- Ayda 2 blog yazısı. Reklamda kazanan sorulara cevap veren yazılar seçilsin.

### 5.4 Instagram / Meta
- **İçerik:** Demo düzenleyicinin 15 saniyelik ekran videoları ("Header'ı değiştir, footer'ı değiştir, 10 günde yayında").
- **Yayın:** KOBİ sahiplerine Reels olarak.
- **Hedefleme:** Meta'da form reklamı yerine yeniden pazarlama ve WhatsApp'a tıklama.

---

## 6. 90 günlük uygulama planı

| Hafta | İş |
|---|---|
| 1 | Ölçüm kurulumu (Bölüm 2). Kullanım Koşulları ve merkez düzeltmeleri. WhatsApp düğmesi. CRM tablosu. |
| 2 | Kampanya 1 ve 2 yayına (günlük 700–1.000 TL). Negatif listesi. Arama uzantısı. |
| 3–4 | Günlük arama terimi temizliği. Reklam metni testi. Sektör kampanyası (3). Eski müşteri e-posta kampanyası. |
| 5–8 | 30+ dönüşümle "Dönüşümleri en üst düzeye çıkar". Yeniden pazarlama (5). Çevrimdışı satış aktarımı. İlk vaka çalışması. |
| 9–12 | Değer bazlı teklif. İhracat kampanyası (4). Demand Gen videoları (6). Bütçeyi satış başı maliyete göre artırma veya azaltma. |

### Bütçe önerisi
| Dönem | Aylık reklam bütçesi | Beklenti |
|---|---|---|
| 1. ay | 20.000–30.000 TL | Veri toplama. 1–3 satış normaldir. |
| 2–3. ay | 30.000–45.000 TL | Satış başı maliyet 15.000 TL'nin altına inmeli |
| 4. ay ve sonrası | Satış başı maliyet 10.000 TL'nin altındaysa artırın | Reklamdan ayda 4–6 satış |

### Haftalık takip edilecek göstergeler
| Gösterge | Hedef |
|---|---|
| Tıklama oranı (Arama) | %6 ve üstü |
| Tıklama → talep | %4 ve üstü |
| Talep → satış | %15 ve üstü |
| Talebe ilk dönüş süresi | 15 dakika veya daha az |
| Satış başı reklam maliyeti | 10.000 TL veya daha az |
| Sipariş formu terk oranı (adım 1 → gönder) | %70 veya daha az |
| Jet Büyüme aboneliği (toplam aylık) | Her ay +3 müşteri |

---

## 7. Riskler ve dürüst notlar
- **Kapasite:** Ayda 7–8 site ve 20–30 Büyüme müşterisi yaklaşık 200 Instagram tasarımı, aylık raporlar ve SEO işi demek. Bu iş yükü mevcut ekibi aşabilir. Ekip büyütülmeden reklam artırılırsa teslim süreleri (3/5/10 iş günü vaadi) bozulur.
- **Tıklama maliyeti:** Tıklama maliyetleri dalgalıdır ve rakipler aynı kelimelere teklif verir. Bu plandaki rakamlar ilk 30 günün gerçek verisiyle yeniden hesaplanmalıdır.
- **Sezon:** Yılbaşı öncesi ve bayram dönemlerinde B2B talebi düşer. Bütçeyi bu dönemlerde azaltın.
- **Taban veri:** Mevcut aylık ciroyu, aktif yenileme sayısını ve geçmiş reklam verisini paylaşırsanız bu plan sizin rakamlarınızla netleşir.

## Kaynaklar
- [Triple Works – Google'da reklam vermek ne kadar? (2026 tıklama maliyetleri)](https://tripleworks.com.tr/google-reklam-verme-maliyetleri-ne-kadar/)
- [Longway Media – Google reklam tıklama ücretleri 2026](https://longwaymedia.com/google-reklam-tiklama-ucretleri/)
- [CDCO – Google reklam fiyatları 2026](https://cdco.com.tr/blog/google-reklam-fiyatlari-2026-google-ads-maliyet-rehberi)
