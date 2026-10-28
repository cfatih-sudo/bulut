# Jet Bilişim – Ölçüm ve Satış Süreci Entegrasyonları (kendi siteniz için)

- **Tarih:** 28.10.2026
- **Kapsam:** jetbilisim.com.tr, demo.jetbilisim.com.tr, merkez.jetbilisim.com.tr ve JET Core.
- **Amaç:** `ADS-VE-BUYUME-PLANI.md` dosyasındaki ölçüm, satış ve büyüme hedeflerinin teknik altyapısı.
- **Kullanım:** Her madde işaretlenebilir. "Kabul testi" satırı işin bitip bitmediğini kontrol etmek içindir.
- **Uyarı:** Tahmini süreler kaba geliştirici saatidir; mevcut JET Core yapısını görmeden verildi.

## Öncelik ve sıra

| Faz | Kapsam | Neden önce | Tahmini süre |
|---|---|---|---|
| **Faz 1 – Ölçüm** (1. hafta) | 1.1 – 1.9 | Reklam bu olmadan kör çalışır | 24–40 saat |
| **Faz 2 – Satış süreci** (2–3. hafta) | 2.x PayTR, 3.x Fatura, 4.1 – 4.4 CRM/bildirim | Talep geldiğinde hızlı dönüş ve otomatik fatura | 40–70 saat |
| **Faz 3 – Geri kazanım** (4–6. hafta) | 1.10 – 1.12, 4.5 – 4.7, 5.x | Yarıda bırakılan siparişler, yeniden pazarlama, alan adı otomasyonu | 40–60 saat |
| **Faz 4 – Büyüme hizmeti** (sürekli) | 6.x, 7.x | Jet Büyüme müşterilerine teslimat ve raporun otomatikleşmesi | 30–50 saat |

---

## 0. Ön koşullar

- [ ] **0.1 Hesap sahipliği:** Google Ads, GA4, Tag Manager, Search Console, Google İşletme Profili, Meta Business ve PayTR hesaplarının sahibi şirket hesabı olmalı. Çalışanlar ve ajanslar yalnızca kullanıcı olarak eklenmeli. Kişisel bir Gmail hesabı sahip olmamalı.
- [ ] **0.2 Test ortamı:** PayTR test modu, GA4 DebugView, Tag Manager önizleme modu ve Google Ads "Test dönüşümü" kullanılacak.
- [ ] **0.3 Sipariş numarası biçimi:** PayTR `merchant_oid` alanı özel karakter kabul etmez. Şu anki biçim `S-2026-00001`. Ekranda bu biçim kalabilir, ama PayTR'ye `S202600001` gibi tire içermeyen bir karşılık gönderilmeli.
- [ ] **0.4 Ortak dataLayer sözleşmesi:** Tüm olaylar Bölüm 1.3'teki adlarla ve parametrelerle gönderilecek. Üç alt alan adında aynı adlar kullanılacak.

---

## 1. Ölçüm ve reklam entegrasyonları

### 1.1 Google Tag Manager (3 alan adı)
- [ ] Üç alan adında da tek bir web container kullan. Container `<head>`'e, noscript kısmı `<body>` başına eklenecek.
- [ ] GA4 → Admin → Veri akışı → "Alan adlarınızı yapılandırın" bölümüne şunları ekle: `jetbilisim.com.tr`, `demo.jetbilisim.com.tr`, `merkez.jetbilisim.com.tr`. Bu, alan adları arası (cross-domain) izlemeyi açar.
- [ ] İstenmeyen yönlendirme listesine `merkez.jetbilisim.com.tr`, `demo.jetbilisim.com.tr` ve PayTR alan adlarını ekle (`www.paytr.com`). Ödeme dönüşünde oturum kırılmasın.
- **Kabul testi:** Ana siteden demoya, demodan siparişe geçişte GA4 DebugView'da `session_id` aynı kalmalı.

### 1.2 Çerez bandı ↔ Google Consent Mode v2
- [ ] Sayfa yüklenmeden önce varsayılan izin durumunu ayarla:
  ```js
  gtag('consent','default',{ad_storage:'denied',ad_user_data:'denied',ad_personalization:'denied',analytics_storage:'denied',functionality_storage:'granted',security_storage:'granted',wait_for_update:500});
  ```
- [ ] Çerez bandındaki seçimlere göre güncelle:
  - "Tümünü kabul et": tüm izinler `granted`
  - "Tümünü reddet": varsayılan (`denied`) kalır
  - "Tercihleri düzenle": seçilen kategoriler `granted`
  ```js
  gtag('consent','update',{...})
  ```
- [ ] Tercihi çerezde 6–12 ay sakla. Her sayfada `update` komutunu, dataLayer'daki diğer olaylardan önce gönder.
- [ ] Meta Pixel, LinkedIn ve Clarity etiketleri yalnızca ilgili izin `granted` olduğunda tetiklensin.
- **Kabul testi:** "Tümünü reddet" seçilince ağ trafiğinde `_ga`, `_gcl_*` ve `_fbp` çerezleri oluşmamalı. GA4'e yalnızca çerezsiz (cookieless) ping gitmeli.

### 1.3 GA4 olay şeması

| Olay | Nerede / ne zaman | Parametreler | Anahtar etkinlik |
|---|---|---|---|
| `view_item` | /paketler/ kart görünümü, demo detay açılışı | `item_id` (paket kodu veya JD-xxx), `item_name`, `item_category` (paket/demo), `price` | – |
| `demo_ac` | demo detay sayfası yüklenince | `demo_kodu`, `kategori` | – |
| `demo_duzen_degistir` | header/footer/bölüm değişimi | `demo_kodu`, `tur` (header/footer/bolum), `deger` | – |
| `demo_paylas` | "Bağlantıyı paylaş" | `demo_kodu` | – |
| `paket_sec` | "Paket seçin" → paket linki | `demo_kodu`, `paket`, `value` | – |
| `begin_checkout` | sipariş adım 1 açılışı | `paket`, `value`, `currency:'TRY'`, `items[]` | – |
| `siparis_adim` | adım 2 ve 3'e geçiş | `adim` (2/3), `paket`, `value` | – |
| `add_payment_info` | adım 3 açılışı | `value`, `currency`, `diller`, `eklentiler` | – |
| `generate_lead` | "Siparişi onaya gönder" başarılı | `transaction_id` (sipariş no), `value` (genel toplam, KDV hariç), `currency`, `paket`, `demo_kodu` | **Evet** |
| `purchase` | PayTR başarılı bildiriminden sonra (sunucu tarafı, bkz. 1.5) | `transaction_id`, `value`, `tax`, `currency`, `items[]`, `payment_type` (kart/havale) | **Evet** |
| `form_gonder` | iletişim ve SEO analiz formu başarılı | `form_adi`, `sayfa` | **Evet** |
| `tel_tikla` | `tel:` link tıklaması | `konum` (header/footer/sayfa) | Evet |
| `whatsapp_tikla` | `wa.me` link tıklaması | `konum`, `demo_kodu` (varsa) | Evet |
| `siparis_hata` | sunucu veya doğrulama hatası | `adim`, `alan`, `mesaj` | – |
| `buyume_siparis` | Jet Büyüme siparişi gönderildi | `paket`, `donem`, `value` | **Evet** |

- [ ] Özel parametreleri GA4'te özel boyut olarak tanımla: `demo_kodu`, `paket`, `adim`, `form_adi`.
- [ ] `value` her zaman KDV hariç tutar olsun. KDV `tax` parametresinde ayrı gitsin.
- **Kabul testi:** Test siparişinde DebugView'da olaylar şu sırayla görülmeli: `begin_checkout` → `siparis_adim` → `add_payment_info` → `generate_lead`.

### 1.4 Google Ads dönüşümleri ve gelişmiş dönüşümler
- [ ] Google Ads → Hedefler bölümünde şu dönüşümleri **birincil** yap:
  - `generate_lead` (değer: dinamik)
  - `purchase` (dinamik)
  - `buyume_siparis` (dinamik)
  - `form_gonder` (sabit değer, örn. 3.000 TL)
  - `whatsapp_tikla` (sabit değer, örn. 1.000 TL)
  - telefon aramaları (bkz. 1.7)
- [ ] `demo_ac` ve `paket_sec` **ikincil** olsun: yalnızca gözlem için, teklif optimizasyonuna girmez.
- [ ] Gelişmiş dönüşümleri (Enhanced Conversions) aç. Sipariş ve form gönderiminde e-posta ve telefon `user_data` ile gönderilir. E-posta küçük harfe çevrilip boşlukları temizlenir. Telefon E.164 biçimine çevrilir: `+905550000000`. Etiket bu verileri SHA-256 ile şifreler.
- [ ] Mükerrer sayımı önlemek için `transaction_id` gönder.
- **Kabul testi:** Google Ads → Dönüşümler → Tanılama ekranında gelişmiş dönüşümler "Etkin" ve eşleşme oranı görünmeli.

### 1.5 GCLID yakalama ve çevrimdışı dönüşüm aktarımı (en önemli madde)
- [ ] URL'deki `gclid`, `gbraid`, `wbraid`, `utm_source`, `utm_medium`, `utm_campaign`, `utm_term` değerlerini birinci taraf çerezde sakla. Çerez adı `jet_src`, süre 90 gün, alan `.jetbilisim.com.tr` (üç alt alan adında da geçerli).
- [ ] Sipariş formuna, iletişim formuna ve Jet Büyüme formuna bu değerleri gizli alan olarak ekle. Sipariş ve talep kaydıyla birlikte veritabanına yaz.
- [ ] Siparişin durumu değiştiğinde Google Ads'e gönder:
  - **Onaylandı:** "Satış – Onaylı" dönüşümü
  - **Ödendi:** "Satış – Ödendi" dönüşümü (değer = KDV hariç tahsil edilen tutar)
- [ ] Gönderim yöntemi, ikisinden biri:
  - **A) Google Ads API.** `ConversionUploadService.UploadClickConversions` kullanılır. Alanlar: `gclid`, `conversion_action`, `conversion_date_time` (`2026-10-28 14:05:00+03:00`), `conversion_value`, `currency_code: TRY`, `order_id`. Gelişmiş dönüşüm için şifrelenmiş e-posta da eklenir.
  - **B) Zamanlanmış Google Sheets yüklemesi.** Google Ads → Araçlar → Dönüşümler → Yüklemeler → Planlamalar. JET Core her gece bir tabloya şu sütunları yazar: `Google Click ID`, `Conversion Name`, `Conversion Time`, `Conversion Value`, `Conversion Currency`.
- [ ] Tıklama ile yükleme arasında en fazla **90 gün** olabilir. Aynı `order_id` iki kez gönderilmemeli.
- [ ] İptal veya iade olursa "dönüşüm düzeltmesi" (geri çekme) gönder.
- **Kabul testi:** Test siparişi `?gclid=TEST123` parametresiyle verilir ve panelde "ödendi" yapılır. Ertesi gün Yüklemeler ekranında satır işlenmiş görünmeli.

### 1.6 Search Console
- [ ] DNS TXT kaydıyla **alan adı mülkü** doğrula (`jetbilisim.com.tr`). Bu, tüm alt alan adlarını kapsar.
- [ ] Site haritalarını gönder: `https://jetbilisim.com.tr/sitemap.xml` ve `https://demo.jetbilisim.com.tr/sitemap.xml`. merkez noindex yapıldıktan sonra merkez haritasını kaldır.
- [ ] Search Console'u GA4'e ve Google Ads'e bağla. "Ücretli ve organik" raporu için gerekli.
- **Kabul testi:** "Sayfalar" raporunda 53 sayfa dizinlenmiş görünmeli. merkez sayfaları "noindex ile hariç tutuldu" olarak görünmeli.

### 1.7 Telefon araması takibi
- [ ] Google Ads'te **web sitesi arama dönüşümü** oluştur. Google yönlendirme numarası, reklamdan gelen ziyaretçide sitedeki `+90 216 446 17 66` numarasının yerine dinamik olarak gösterilir. Etikete numara biçimi tanıtılmalı.
- [ ] Arama uzantılarında 60 sn üzeri aramaları dönüşüm say.
- [ ] Organik ziyaretçiler için `tel_tikla` olayı (1.3) yeterli.
- **Kabul testi:** `?gclid=test` ile açılan sayfada numaranın değiştiği görülmeli.

### 1.8 WhatsApp
- [ ] Sabit WhatsApp düğmesini tüm sayfalara ve demo sayfasına ekle. Mesaj hazır dolu gelsin:
  `https://wa.me/902164461766?text=Merhaba%2C%20JD-801%20demosu%20hakk%C4%B1nda%20bilgi%20almak%20istiyorum.`
- [ ] Mesaja kaynak kodu ekle (örn. "(ref: g-ads)"). Böylece satış ekibi talebin nereden geldiğini görür ve CRM'e doğru kaynakla kaydeder.
- [ ] Tıklamada `whatsapp_tikla` olayını gönder (1.3).

### 1.9 Google İşletme Profili
- [ ] Profili Google Ads'e bağla (konum öğeleri için).
- [ ] Doğrudan yorum linkini (`https://g.page/r/.../review`) sipariş tamamlandı e-postasına ve teslim e-postasına ekle.
- [ ] Puan ve yorum sayısını siteye otomatik çekmek için Places API kullan. Günde bir kez çekip önbellekte tutmak yeterli.

### 1.10 Meta Pixel + Conversions API (Faz 3)
- [ ] Tarayıcıda Pixel: `PageView`, `ViewContent` (demo), `InitiateCheckout`, `Lead`, `Purchase`.
- [ ] Sunucuda Conversions API: aynı olaylar, aynı `event_id` ile (çift sayımı önler). `em` ve `ph` alanları SHA-256 ile şifrelenir. `fbp` ve `fbc` çerezleri iletilir.
- [ ] Yalnızca pazarlama çerezi izni verildiğinde çalışsın (1.2).
- **Kabul testi:** Events Manager → Test Events ekranında tarayıcı ve sunucu olayları "Deduplicated" görünmeli.

### 1.11 LinkedIn Insight Tag (isteğe bağlı, ihracat/OSB kampanyaları için)
- [ ] Insight Tag ekle ve `generate_lead` için dönüşüm tanımla. Pazarlama çerezi iznine bağlı çalışsın.

### 1.12 Oturum kaydı (Microsoft Clarity veya Hotjar)
- [ ] Sipariş formunda nerede takılındığını görmek için kur.
- [ ] Tüm form alanlarını maskele. T.C. no, telefon, e-posta ve parola kesinlikle kayda girmemeli.
- [ ] Analiz çerezi iznine bağlı çalışsın.
- [ ] KVKK metnine aktarım alıcısı olarak ekle (Microsoft veya Hotjar, yurt dışı).

---

## 2. PayTR ödeme entegrasyonu

### 2.1 iFrame API (mevcut akış: kontrol listesi)
- [ ] `paytr_token` = `base64(hmac_sha256(merchant_id + user_ip + merchant_oid + email + payment_amount + user_basket + no_installment + max_installment + currency + test_mode, merchant_key + merchant_salt))`
  - Alan sırası PayTR dokümanıyla birebir kontrol edilmeli.
- [ ] **`user_ip` alanı:** Site Cloudflare arkasında. Bu yüzden `REMOTE_ADDR` değil, `CF-Connecting-IP` başlığı kullanılmalı. Yanlış IP kullanılırsa PayTR'nin risk kontrolü yanlış çalışır.
- [ ] `payment_amount` kuruş cinsinden gönderilir (55.728,00 TL → `5572800`). KDV dahil tutar.
- [ ] `user_basket`: ürün adı, birim fiyat ve adetten oluşan JSON, base64 kodlanmış. Satırlar: paket, dil, eklenti.
- [ ] `max_installment`: paket bazında belirle (örn. Başla 6, diğerleri 12).
- [ ] `merchant_ok_url` ve `merchant_fail_url`: merkezdeki teşekkür ve hata sayfaları. **Bu sayfalarda sipariş "ödendi" yapılmaz.** Ödeme durumu yalnızca bildirim URL'sinden (2.2) güncellenir.

### 2.2 Bildirim URL'si (callback) – kritik
- [ ] PayTR panelinde tek bir bildirim URL'si tanımla: `https://merkez.jetbilisim.com.tr/odeme/paytr-bildirim`
- [ ] Gelen isteğin imzasını doğrula:
  `hash == base64(hmac_sha256(merchant_oid + merchant_salt + status + total_amount, merchant_key))`
  İmza uyuşmazsa işlem yapılmaz ve kayıt tutulur.
- [ ] Başarılı ve başarısız her durumda gövdesi yalnızca `OK` olan düz metin cevap dön. Aksi halde PayTR bildirimi tekrar gönderir.
- [ ] **Tekrarlanan bildirimlere karşı koruma:** Aynı `merchant_oid` ikinci kez gelirse sipariş tekrar işlenmesin.
- [ ] `total_amount` taksit vade farkını içerebilir. Sipariş tutarı ile karşılaştır, farkı "vade farkı" olarak kaydet.
- [ ] Başarılı ödemede tetiklenecekler:
  - sipariş durumu = Ödendi
  - fatura oluştur (3.1)
  - GA4 `purchase` olayı (Measurement Protocol ile sunucudan)
  - Google Ads çevrimdışı dönüşüm (1.5)
  - CRM aşaması güncellemesi (4.1)
  - müşteriye ve ekibe bildirim (4.3)
- [ ] Güvenlik duvarı ayarı: Bildirim URL'si PayTR'nin IP'lerinden gelen POST isteklerine açık olmalı. "Kopyalama botu" ve saldırı kuralları bu adresi engellememeli.
- **Kabul testi:** Test modunda başarılı kart ve başarısız kart denenir. İkisinde de sipariş durumu doğru değişmeli, bildirim tekrar gönderildiğinde mükerrer kayıt oluşmamalı.

### 2.3 Taksit tablosu
- [ ] PayTR taksit oranları servisinden oranları günde bir kez çek. Paketler sayfasında ve sipariş özetinde "12 taksit × X TL'den başlayan" bilgisini göster.

### 2.4 İade (cayma ve iptal)
- [ ] PayTR iade API'sini panele bağla. Tam veya kısmi iade yapılabilsin.
- [ ] Her iade için şunları kaydet: tarih, tutar, sebep (cayma, iptal veya diğer), işlemi yapan kişi.
- [ ] İade sonrası tetiklenecekler: Google Ads dönüşüm düzeltmesi, iade faturası veya iptal faturası (3.2), CRM aşaması güncellemesi.
- **Kabul testi:** Test modunda yapılan iade, panelde ve muhasebe kaydında görünmeli.

### 2.5 Havale / EFT
- [ ] Sipariş sonrası ekranda ve e-postada şunları göster: IBAN, alıcı adı, açıklamaya yazılacak sipariş no (`S202600001`).
- [ ] Panelde "Havale geldi" düğmesi olsun. Basılınca 2.2'deki başarılı ödeme akışı aynen çalışsın.
- [ ] İsteğe bağlı: banka hesap hareketi API'si ile otomatik eşleştirme (bankaya göre değişir).

### 2.6 Jet Büyüme için tekrarlayan ödeme
- [ ] Seçenek A: 3 aylık veya yıllık **peşin** ödeme (mevcut model). Dönem bitmeden 10 gün önce yenileme linki gönderilir.
- [ ] Seçenek B: PayTR kart saklama ve tekrarlayan ödeme hizmeti. PayTR'den ayrıca aktif edilmesi gerekir. Kart sahibine açık onay metni gösterilmeli.
- [ ] Başarısız tahsilatta: 3 gün arayla 2 tekrar deneme, ardından müşteriye bildirim, ardından sözleşmedeki askı süreci (Hizmet Sözleşmesi 8.6).

---

## 3. Fatura entegrasyonu (e-Arşiv / e-Fatura)

### 3.1 Özel entegratör API'si
- [ ] Bir entegratör seç. Örnekler: Paraşüt, BirFatura, Uyumsoft, Logo İşbaşı, Nilvera. Önce mali müşavirinizin kullandığıyla uyumlu olanı tercih edin.
- [ ] Ödeme tamamlanınca (2.2) otomatik fatura oluştur:
  1. Müşterinin VKN/TCKN numarasını entegratörün **e-Fatura mükellef sorgusu** ile kontrol et. Mükellefse e-Fatura, değilse e-Arşiv fatura kesilir.
  2. Fatura satırları: kurulum bedeli, diller, eklentiler. Her satırda %20 KDV.
  3. Taksit vade farkı ayrı satır olarak mı yazılacak, yoksa finansman gideri olarak mı ayrılacak? Mali müşavirle netleştir.
- [ ] Fatura PDF'ini müşteriye e-postayla gönder ve müşteri paneline ekle.
- [ ] Fatura numarasını sipariş kaydına yaz.
- **Kabul testi:** Test ortamında bir bireysel (TCKN) ve bir firma (VKN) siparişi denenir. Doğru fatura türü oluşmalı.

### 3.2 İade ve iptal faturası
- [ ] e-Arşiv faturada iptal kuralı ile e-Fatura'da iade faturası akışını entegratör dokümanına göre bağla.

### 3.3 Yıllık yenileme
- [ ] Yenileme tarihinden 45 gün önce bildirim gönder (Sözleşme 9.3). Bildirim e-postasında ödeme linki olsun. Ödeme yapılınca fatura otomatik kesilsin.

---

## 4. Satış, CRM ve iletişim

### 4.1 CRM
- [ ] Bir CRM seç. Örnekler: HubSpot (ücretsiz plan), Pipedrive, Bitrix24, Zoho. Başlangıç için Google Sheets de olur, ama sonradan taşımak gerekir.
- [ ] Şu kaynaklardan otomatik kayıt oluşsun: sipariş formu, iletişim formu, SEO analiz formu, Jet Büyüme siparişi. WhatsApp ve telefon talepleri satış ekibi tarafından manuel girilir.
- [ ] Her kayıtta tutulacak alanlar:
  - ad, firma, e-posta, telefon
  - kaynak: `gclid`, `utm_*`, organik / referans / eski müşteri
  - demo kodu, paket, tutar
  - geliş zamanı, ilk dönüş zamanı
- [ ] Satış aşamaları: Yeni → Arandı → Teklif / Onay görüşmesi → Onaylandı → Ödendi → Kurulumda → Yayında → Kayıp (sebep zorunlu).
- [ ] Aşama değişimleri 1.5'teki çevrimdışı dönüşüm aktarımını tetiklesin.
- **Kabul testi:** Test formu gönderildikten sonra 1 dakika içinde CRM'de kaynak bilgisiyle birlikte kayıt görünmeli.

### 4.2 İlk dönüş süresi takibi
- [ ] CRM'de "ilk dönüş" süresi otomatik hesaplansın. Hedef: mesai içinde 15 dakika veya daha kısa.
- [ ] 15 dakikayı geçen talepler için sorumluya ve yöneticiye otomatik uyarı gitsin.

### 4.3 Anlık bildirim
- [ ] Yeni sipariş veya talep geldiğinde ekibe anında bildirim gitsin. Seçenekler: Telegram botu, Slack, WhatsApp Business API veya e-posta.
- [ ] Bildirimde şunlar olsun: tutar, paket, demo, telefon, kaynak, CRM linki.

### 4.4 İşlem e-postaları ve teslim edilebilirlik
- [ ] İşlem e-postaları (sipariş özeti, ödeme, fatura, parola sıfırlama) bir SMTP sağlayıcısı üzerinden gönderilsin. Örnekler: Amazon SES, Postmark, Brevo, Mailgun.
- [ ] `jetbilisim.com.tr` alan adında şu kayıtlar kontrol edilsin:
  - **SPF**
  - **DKIM**
  - **DMARC:** Önce `p=none` ile başla, raporları inceledikten sonra `p=quarantine` yap.
- [ ] Sipariş özeti e-postasına şunlar eklensin (Sözleşme Ek-1 ve Madde 4.3): sözleşme sürümünün PDF'i, Ön Bilgilendirme Formu PDF'i, sipariş özeti.
- **Kabul testi:** mail-tester.com puanı 9/10 veya üstü olmalı. Gmail'de mesaj → "Orijinali göster" ekranında SPF, DKIM ve DMARC "PASS" görünmeli. Not: İlk test siparişinin e-postasının gelip gelmediğini siz kontrol edecektiniz. Gelmediyse ilk bakılacak yer burası.

### 4.5 Yarıda bırakılan sipariş akışı (Faz 3)
- [ ] Adım 2'de e-posta alanı doldurulduğunda taslak sipariş kaydı oluştur. Bunu yapmak için açık onay gerekmez ama KVKK metninde amaç olarak belirtilmeli.
- [ ] Sipariş 1 saat içinde tamamlanmazsa CRM'e "Yarım sipariş" görevi düşsün ve satış ekibi arasın.
- [ ] 24 saat sonra bilgilendirme e-postası gönder: "Siparişiniz yarım kaldı, kaldığınız yerden devam edin". Bu bir işlem e-postasıdır, kampanya içermemeli. Kampanya içerirse ticari ileti onayı (İYS) gerekir.

### 4.6 SMS
- [ ] Bir SMS sağlayıcısı API'si bağla. Örnekler: Netgsm, İleti Merkezi, Verimor.
- [ ] Bilgilendirme SMS'leri İYS onayı gerektirmez: sipariş alındı, ödeme alındı, siteniz yayında.
- [ ] Kampanya SMS'leri yalnızca İYS'de onayı olan numaralara gönderilir (4.7).

### 4.7 İYS (İleti Yönetim Sistemi)
- [ ] Sipariş formundaki "ticari elektronik ileti" onaylarını İYS'ye API ile kaydet. Doğrudan veya bir İYS entegratörü (SMS ve e-posta sağlayıcılarının çoğu sunar) üzerinden. Yasal süre: onaydan sonra **3 iş günü** içinde.
- [ ] Kampanya göndermeden önce her alıcının İYS'deki onay durumunu sorgula.
- [ ] Ret talepleri İYS'den gelir. Webhook veya düzenli sorgu ile kendi listende de güncelle.
- **Kabul testi:** Test onayı İYS panelinde görünmeli. Ret verildikten sonra o numara kampanya listesinden düşmeli.

---

## 5. Alan adı, DNS ve barındırma otomasyonu (Faz 3)

### 5.1 Alan adı uygunluk sorgusu
- [ ] Sipariş adım 1'de "Yeni alan adı alacağım" seçilince uygunluğu anında sorgula. Bunun için kullandığınız kayıt firmasının bayi API'si kullanılır. `.tr` uzantıları TRABİS kurallarına tabi; belge gerektiren uzantılar için kullanıcıyı uyar.
- [ ] Uygun değilse 3 alternatif öner (`-tr`, `.com.tr`/`.com`, kısaltma).

### 5.2 DNS ve SSL (Cloudflare API)
- [ ] Müşteri sitesi kurulurken Cloudflare API ile otomatik olarak:
  - zone ekle
  - A/CNAME ve MX/SPF/DKIM kayıtlarını oluştur
  - SSL modunu "Full (strict)" yap
- [ ] Mevcut alan adı olan müşteriye nameserver veya DNS yönlendirme talimatını otomatik e-postayla gönder (Sipariş sayfasındaki "3 gün içinde yönlendirme" notu).
- [ ] Yönlendirme yapılınca CRM'de görevi otomatik tamamla.

### 5.3 E-posta hesabı oluşturma
- [ ] Paket hakkı kadar (3/5/10) kurumsal e-posta hesabını mail sunucusu API'siyle aç. Örnekler: cPanel UAPI, Plesk, Google Workspace veya Microsoft 365 bayi API'si. İlk parola güvenli bir kanalla iletilsin.

### 5.4 Çalışırlık izleme ve yedek
- [ ] Tüm müşteri siteleri için çalışırlık izleme kur. Örnekler: UptimeRobot, Better Stack, Uptime Kuma. 1 dakikalık kontrol, kesintide ekibe bildirim. Bu, Jet Büyüme paketlerindeki "Çalışırlık izleme" vaadinin altyapısı.
- [ ] Yedekler başka bir sağlayıcıya otomatik kopyalansın. Örnekler: S3, Backblaze B2, Wasabi. Saklama süresi sözleşmeye yazılan süreyle aynı olmalı (Madde 5.2-c).
- [ ] Ayda bir **yedekten geri yükleme testi** yap ve kaydet.

---

## 6. Jet Büyüme hizmet teslimatı entegrasyonları (Faz 4)

| Hizmet | Entegrasyon | Not |
|---|---|---|
| Instagram post tasarımı ve planlama | Meta Business Suite / Instagram Graph API (içerik yayınlama) | Müşterinin parolası istenmez. İşletme hesabına "ortak" olarak eklenilir. Sitedeki "Parolanızı istemeyiz" vaadiyle uyumlu. |
| Google İşletme Profili gönderileri | Business Profile API (localPosts) | Müşteri profilinde "Yönetici" erişimi. |
| GA4 trafik analizi | GA4 Data API | Müşteri GA4 mülküne "Görüntüleyen" erişimi. |
| SEO takibi | Search Console API + sıralama takip aracı (ör. SE Ranking, Ahrefs, Semrush API) | Müşteri alan adı mülkünde "Tam" kullanıcı. |
| Google Ads yönetimi | Google Ads yönetici hesabı (MCC) | Müşteri hesapları MCC'ye bağlanır. Ödeme müşterinin kartıyla yapılır (paket notu: bütçe Google'a ödenir). |
| İçerik güncelleme saati | JET Core panelinde iş kaydı (süre girişi) | "Kullanılmayan saatler devreder mi" kuralına göre bakiye tutulur. |

---

## 7. Raporlama

### 7.1 Jet Bilişim yönetim paneli (Looker Studio)
- [ ] **Kaynaklar:** GA4, Google Ads, Search Console, CRM (Sheets veya bağlayıcı).
- [ ] **Sayfa 1 – Huni:** ziyaret → demo açma → paket seçimi → adım 1/2/3 → onaya gönderilen → ödenen. Kanallara göre kırılımlı.
- [ ] **Sayfa 2 – Reklam:** harcama, tıklama başı maliyet, talep başı maliyet, **satış başı maliyet**, ROAS (çevrimdışı satış değeriyle).
- [ ] **Sayfa 3 – Gelir:** yeni site cirosu, Büyüme aylık abonelik geliri, yenilemeler. Hedef çizgisi: 300.000 TL.
- [ ] **Sayfa 4 – Operasyon:** ilk dönüş süresi, kurulumdaki site sayısı, teslim süresi aşımları.

### 7.2 Müşteri aylık raporu (Jet Büyüme)
- [ ] Müşteri başına Looker Studio şablonu: GA4, Search Console, Ads ve GBP verileri. JET Core'dan yapılan işler listesi de eklenir.
- [ ] Ayın ilk iş günü PDF olarak otomatik e-posta gönderilsin ve müşteri paneline eklensin.

---

## 8. Güvenlik duvarı ve tarayıcı izinleri (entegrasyonların çalışması için şart)

Site "kopyalama botlarını engelle" kuralıyla headless tarayıcıları ve basit istekleri engelliyor. Aşağıdaki servisler engellenirse reklamlar reddedilir veya veriler eksik gelir.

| Servis | Neden gerekli | İzin yöntemi |
|---|---|---|
| **AdsBot-Google**, AdsBot-Google-Mobile | Reklam açılış sayfası kontrolü. Engellenirse reklam "Hedef çalışmıyor" gerekçesiyle reddedilir. | Ters DNS doğrulaması: `*.googlebot.com` veya `*.google.com` |
| Googlebot, Google-InspectionTool | Dizinleme ve Search Console URL denetimi | Aynı yöntem |
| Google Lighthouse / PageSpeed (`Chrome-Lighthouse`) | Sayfa hızı raporları, Ads açılış sayfası deneyimi | Google IP aralıkları |
| Bingbot, Applebot | Arama motorları | Ters DNS doğrulaması |
| GPTBot, OAI-SearchBot, ChatGPT-User, ClaudeBot, PerplexityBot | "Yapay zekâ aramalarında görünürlük" vaadi | Yayımlanan resmi IP listeleri |
| facebookexternalhit, LinkedInBot, WhatsApp | Link paylaşım önizlemesi | User-agent + IP doğrulaması |
| PayTR bildirim istekleri | Ödeme sonucu | Yalnızca `/odeme/paytr-bildirim` yoluna izin, PayTR IP'leri |
| Çalışırlık izleme servisi | Kesinti alarmı | Servisin IP listesi |

- **Kabul testi:**
  - Search Console URL Denetimi'nde "Canlı URL'yi test et" başarılı olmalı.
  - Google Ads'te açılış sayfası hatası olmamalı.
  - PageSpeed Insights sayfayı ölçebilmeli.
  - WhatsApp'ta paylaşılan link önizleme göstermeli.

---

## 9. KVKK ve sözleşme güncellemeleri (entegrasyonlar eklendikçe)

- [ ] KVKK Aydınlatma Metni'ne eklenen her yeni alıcıyı ekle: CRM, SMS, SMTP, fatura entegratörü, Clarity/Hotjar, Meta, LinkedIn, yedekleme sağlayıcısı. Yurt dışında olanlar için aktarım dayanağı (standart sözleşme) belirtilmeli.
- [ ] Çerez Politikası'nı güncelle: GA4, Google Ads, Meta, LinkedIn ve Clarity çerezleri. Ad, amaç, süre ve sağlayıcı bilgisiyle tablo halinde.
- [ ] Hizmet Sözleşmesi 13.2-d'deki alt veri işleyen listesini güncelle.
- [ ] Tekrarlayan kart ödemesi açılırsa (2.6-B), sipariş formuna ayrı bir onay kutusu ekle.

---

## Özet kontrol listesi (yönetici için)

- [ ] Ölçüm: Tag Manager, Consent Mode, GA4 olayları, Ads dönüşümleri, GCLID ve çevrimdışı satış aktarımı
- [ ] Ödeme: PayTR bildirim URL'si doğrulaması, mükerrer kayıt koruması, iade, havale eşleştirme
- [ ] Fatura: e-Fatura/e-Arşiv otomatik kesimi
- [ ] Satış: CRM kaydı, 15 dakika dönüş uyarısı, anlık bildirim
- [ ] E-posta: SPF/DKIM/DMARC; sipariş e-postasına sözleşme PDF'i
- [ ] İYS: ticari ileti onaylarını 3 iş günü içinde kaydetme
- [ ] Güvenlik duvarı: AdsBot, Googlebot ve PayTR izinleri
- [ ] Rapor: Looker Studio paneli ve müşteri aylık raporu
- [ ] KVKK ve çerez metinlerinin yeni alıcılarla güncellenmesi
