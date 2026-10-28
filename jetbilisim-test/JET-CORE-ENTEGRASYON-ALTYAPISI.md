# JET Core – Kurumsal Site Entegrasyon Altyapısı

Muhasebe, e-belge, ERP (SAP, Logo, Mikro, Netsis, Nebim…), ödeme, kargo, pazaryeri, B2B, CRM, iletişim ve diğer sistemler.

- **Tarih:** 28.10.2026
- **Amaç:** JET Core ile kurulan kurumsal, katalog, ihracat ve mağaza sitelerinin, müşterinin kullandığı iş yazılımlarıyla iki yönlü haberleşebilmesi için gereken altyapı.
- **Ürünleştirme:** Liste, entegrasyonları paket eklentisi olarak satılabilecek şekilde gruplar (Bölüm 13).
- **Uyarı:** Üçüncü taraf API adları ve yöntemleri sürüme, lisansa ve müşterinin kurulumuna göre değişir. Her entegrasyondan önce ilgili sistemin güncel dokümanı ve müşterinin ERP bayisi ile teyit edilmeli.

---

## 1. Önce mimari: tek tek bağlantı değil, bir "entegrasyon katmanı"

Her ERP veya kargo firması için ayrı ayrı kod yazılırsa birkaç müşteri sonra sistem yönetilemez hale gelir. JET Core'a bir kez ortak bir katman kurulmalı. Her yeni sistem bu katmana "bağlayıcı" (connector) olarak eklenmeli.

```
            ┌──────────────── JET Core ────────────────┐
 Site/Panel │  Ürün · Stok · Fiyat · Cari · Sipariş    │
            │  Fatura · Sevkiyat · Ödeme · İade        │  ← ortak veri modeli
            └──────────────┬───────────────────────────┘
                           │  olaylar (siparis.olustu, stok.degisti…)
            ┌──────────────▼───────────────────────────┐
            │   ENTEGRASYON KATMANI                     │
            │   kuyruk · zamanlayıcı · eşleme tabloları │
            │   tekrar deneme · log · hata paneli       │
            └──┬──────┬──────┬──────┬──────┬──────┬────┘
               │      │      │      │      │      │   bağlayıcılar
            ERP   Muhasebe  e-Belge Kargo Pazaryeri Ödeme/CRM/SMS…
                     │
         (yerel sunucudaki ERP için)  ← JET Ajan (Windows servisi)
```

### 1.1 Katmanın zorunlu parçaları
- [ ] **Ortak veri modeli.** Bütün bağlayıcılar aynı nesnelerle konuşur: Ürün, Varyant, Stok (depo bazlı), Fiyat listesi, Cari, Adres, Sipariş, Sipariş satırı, Fatura, İrsaliye, Sevkiyat, Tahsilat, İade.
- [ ] **Olay ve kuyruk sistemi.** Örnekler: `siparis.olustu`, `siparis.odendi`, `stok.degisti`, `fiyat.degisti`, `sevkiyat.olustu`. Bu olaylar bir kuyruğa yazılır (veritabanı tablosu, Redis veya RabbitMQ). Böylece bir dış sistem çöktüğünde veri kaybolmaz.
- [ ] **Zamanlayıcı.** Değişen kayıtların düzenli aralıklarla çekilmesi (delta senkronizasyonu). Örnek aralıklar: stok her 5 dk, fiyat her 15 dk, ürün kartı gece.
- [ ] **Eşleme tabloları:**
  - Kimlik eşleme: JET ürün ID ↔ ERP stok kodu ↔ pazaryeri ürün ID
  - Kategori ve özellik eşleme (pazaryerleri için)
  - Birim eşleme (adet, kg, m², koli)
  - KDV oranı eşleme
  - Depo eşleme
  - Kargo firması eşleme
  - Ödeme tipi eşleme
- [ ] **Mükerrer kayıt koruması.** Her dış çağrıda bir mükerrer kayıt koruma anahtarı (idempotency key) kullanılır. Aynı sipariş ERP'ye iki kez yazılmaz.
- [ ] **Tekrar deneme.** Başarısız çağrı artan aralıklarla tekrar denenir: 1 dk, 5 dk, 30 dk, 2 sa. 5 denemeden sonra "hatalı" kutusuna düşer ve e-posta veya Telegram ile alarm verir.
- [ ] **İşlem logu.** Her çağrı için istek, cevap (maskelenmiş), süre ve sonuç kaydedilir. Saklama süresi en az 90 gün.
- [ ] **Hata paneli (müşteri ve Jet ekibi için).** "Hangi sipariş ERP'ye gitmedi, neden" ekranı. "Tekrar gönder" ve "Elle eşle" düğmeleri.
- [ ] **Kaynak sistem (ana kaynak) kuralı.** Her alan için tek bir ana kaynak belirlenir. Örnek: stok ve fiyatın kaynağı ERP; ürün açıklaması ve görseli JET Core; sipariş JET Core'dan ERP'ye.
- [ ] **Gizli bilgilerin saklanması.** API anahtarları ve parolalar veritabanında şifreli tutulur. Panelde maskelenir. Anahtar yenileme ekranı olur.
- [ ] **Dışarıya açık API ve webhook (JET Core'un kendi API'si).** Müşterinin kendi yazılımcısı veya bir iPaaS aracı bağlanabilsin. REST + JSON, OAuth2 veya API anahtarıyla erişim, istek sınırı (rate limit), webhook imzası (HMAC).
- [ ] **İzleme.** Her bağlayıcı için durum gösterilir: son başarılı senkron zamanı, bekleyen ve hatalı kayıt sayısı.

### 1.2 Bağlantı yöntemleri (Türkiye gerçekliği)

| Yöntem | Ne zaman | Not |
|---|---|---|
| **REST/OData API** | Bulut sistemler: SAP S/4HANA Cloud, Business Central, Paraşüt, pazaryerleri | En temiz yol |
| **SOAP web servis** | Bazı kargo firmaları, eski ERP servisleri, NVI/GİB tarafı | XML şablonları ve WSDL yönetimi gerekir |
| **JET Ajan (yerel servis)** | Müşterinin ofis sunucusundaki Logo, Mikro, Netsis veya Nebim kurulumu internete kapalıysa | Türkiye'deki KOBİ'lerin çoğu böyle. Ajan, müşteri sunucusuna kurulan bir Windows servisidir. Dışarıya port açmadan, JET Core'a **giden** bağlantıyla (HTTPS ile kuyruk sorgulayarak) veri taşır. |
| **Veritabanı görünümü (salt okunur SQL)** | ERP'nin API lisansı yoksa ve stok/fiyat okumak yeterliyse | ERP tablolarına **yazma yapılmaz**, sadece okunur. Yazma işi ERP'nin kendi nesneleriyle (Logo Objects vb.) yapılır, aksi halde ERP bütünlüğü bozulur. |
| **Dosya (XML/CSV/Excel – SFTP veya e-posta)** | Çok eski sistemler, tek seferlik aktarımlar | Zamanlanmış içe ve dışa aktarma; "Excel/CSV aktarımı" eklentisiyle aynı motor |
| **iPaaS** (n8n, Make, Zapier; kurumsal tarafta SAP Integration Suite/CPI, Celigo, Boomi) | Müşteri zaten kullanıyorsa veya hazır bağlayıcı yoksa | JET Core'un webhook ve API'si (1.1) bunları mümkün kılar |
| **EDI** (EDIFACT, ANSI X12) | Büyük zincir market ve otomotiv tedarikçileri | Genelde bir EDI sağlayıcısı üzerinden yapılır |

---

## 2. ERP entegrasyonları

### 2.1 Ortak veri akışları (her ERP için aynı)

| Akış | Yön | Sıklık | İçerik |
|---|---|---|---|
| Ürün / stok kartı | ERP → Site | Gece + değişiklikte | Stok kodu, ad, birim, barkod, KDV, marka, grup, varyant (renk/beden) |
| Stok miktarı | ERP → Site (→ Pazaryeri) | 1–5 dk | Depo bazlı kullanılabilir stok = eldeki − rezerve |
| Fiyat | ERP → Site | 5–15 dk | Liste fiyatı, bayi ve özel fiyat listeleri, döviz cinsi |
| Cari (müşteri) | İki yönlü | Sipariş anında | Unvan, VKN/TCKN, vergi dairesi, adresler, e-Fatura mükellefiyeti |
| Sipariş | Site → ERP | Anlık (kuyruk) | Başlık, satırlar, iskonto, kargo bedeli, ödeme tipi, not |
| Sipariş durumu, sevk, irsaliye | ERP → Site | 5–15 dk | Hazırlanıyor, sevk edildi, kargo takip no, e-İrsaliye no |
| Fatura | ERP → Site | Kesildiğinde | Fatura no, PDF/UBL linki (pazaryerine de yüklenir) |
| Tahsilat | Site → ERP | Ödeme anında | Kart/havale tahsilat fişi, POS banka hesabı, komisyon |
| Cari bakiye ve ekstre | ERP → Site (B2B) | Talep anında / saatlik | Bakiye, vade, risk limiti, açık faturalar |
| İade | Site → ERP | Anlık | İade talebi, iade irsaliyesi/faturası |

### 2.2 Sistem bazında

| ERP | Bağlantı yolu | Not |
|---|---|---|
| **SAP S/4HANA (Cloud / Private)** | OData API'leri (SAP Business Accelerator Hub). Örnekler: Business Partner, Product, Sales Order, Material Stock, Billing Document servisleri. Kimlik doğrulama "Communication Arrangement" ile, OAuth2 veya sertifika. | Kurumsal müşteri. Genelde müşterinin SAP partneri kapsam ve yetki verir. SAP Integration Suite (CPI) varsa onun üzerinden gidilir. |
| **SAP ECC / S/4HANA on-premise** | RFC/BAPI (örn. satış siparişi oluşturma BAPI'leri), IDoc (ORDERS, MATMAS, DEBMAS), SAP PI/PO veya CPI ile REST'e dönüştürme. Buluta erişim SAP Cloud Connector ile. | Doğrudan RFC yerine müşterinin ara katmanı tercih edilmeli |
| **SAP Business One** | **Service Layer** (REST/OData: Items, BusinessPartners, Orders, Invoices, IncomingPayments). Eski yol DI API. | KOBİ'de yaygın, entegrasyonu görece kolay |
| **Logo Tiger / Go 3 / Tiger Wings** | Logo REST servisi / Logo Objects (LObjects), Logo Connect. Okuma için SQL görünümü. | Çoğu kurulum yerel sunucuda → **JET Ajan** gerekir. Logo lisansında entegrasyon modülü olup olmadığı kontrol edilmeli. |
| **Logo j-Platform / Netsis (Logo Netsis)** | Netsis için NetOpenX REST, j-Platform için REST servisleri | Bayi ile teyit |
| **Mikro (Fly, Jump, Run)** | Mikro API (REST) / Mikro web servisleri; okuma için SQL | Yerel kurulum → Ajan |
| **Nebim V3** | Nebim Integrator (REST) | Perakende, giyim ve mağazacılık müşterileri; pazaryeri ile birlikte istenir |
| **Microsoft Dynamics 365 Business Central** | REST API v2.0 / OData, Azure AD OAuth2 | Bulut, temiz API |
| **Oracle NetSuite** | SuiteTalk REST / SOAP, token tabanlı kimlik doğrulama | İhracatçı ve yabancı ortaklı firmalar |
| **Odoo** | JSON-RPC / XML-RPC (sürüme göre REST) | Açık kaynak kullanıcıları |
| **Canias, Uyumsoft ERP, ETA, Akınsoft, Workcube, IAS, Infor** | Üretici API'si, web servis veya SQL + dosya | Müşteri bazlı. Önce hazır bağlayıcı var mı bakılır. |

- [ ] Her ERP bağlayıcısı için **"Bağlantıyı test et"** ekranı. Örnek: 1 ürün çek, 1 test cari oluştur, 1 test siparişi gönder.
- [ ] **Eşleme sihirbazı.** KDV, depo, birim ve ödeme tipi eşlemeleri kurulumda adım adım yapılır.

---

## 3. Muhasebe (ön muhasebe) programları

KOBİ'ler genelde ERP yerine bunları kullanır.

| Program | Yöntem | Akış |
|---|---|---|
| **Paraşüt** | REST API (OAuth2) | Müşteri (contact), ürün, satış faturası, e-Arşiv/e-Fatura gönderimi, tahsilat |
| **Logo İşbaşı** | REST API | Cari, stok, fatura, tahsilat |
| **BizimHesap** | REST API | Cari, ürün, fatura |
| **Uyumsoft Ön Muhasebe, Mikro Fly, KolayBi, Zirve, Luca** | API / dosya | Program bazında doğrulanmalı |

- [ ] Sipariş ödenince fatura otomatik veya tek tıkla oluşturulsun. Fatura numarası ve PDF siteye geri dönsün.
- [ ] Mali müşavir için aylık satış ve tahsilat dökümü dışa aktarılabilsin (Excel ve muhasebe formatı).

---

## 4. e-Belge (GİB) entegrasyonları

| Belge | Ne zaman gerekir | Yol |
|---|---|---|
| **e-Fatura** | Alıcı e-Fatura mükellefiyse | Özel entegratör API'si. UBL-TR formatı. Mükellef sorgusu ile otomatik seçilir. |
| **e-Arşiv Fatura** | Alıcı mükellef değilse (bireysel ve çoğu küçük firma) | Aynı entegratör |
| **e-İrsaliye** | Mal sevkiyatı yapan, e-İrsaliye'ye geçmiş firmalar | Entegratör; kargo ve sevkiyatla bağlantılı |
| **e-SMM** | Serbest meslek erbabı (avukat, doktor, danışman) müşteriler | Entegratör |
| **e-Müstahsil** | Tarım ürünü alan firmalar | Entegratör |
| **e-İhracat faturası / ETGB** | Mikro ihracat yapan siteler (Jet İhracat) | Entegratör + kargo firması (DHL, UPS, FedEx, PTT) gümrük süreci |

**Özel entegratör örnekleri:** Nilvera, Uyumsoft, Sovos (Foriba), Logo e-Dönüşüm, İzibiz, QNB e-Solutions, EDM, Turkcell e-Şirket, Kolaysoft, Paraşüt (kendi içinde).

- [ ] **Tek arayüz, çok entegratör.** JET Core'da "e-belge sağlayıcısı" soyut bir sınıf olsun, her entegratör bir sürücü (driver) olarak eklensin. Müşteri hangi entegratörü kullanıyorsa onu seçer.
- [ ] VKN/TCKN ile mükellef sorgusu ve sonucun önbelleğe alınması.
- [ ] İptal ve iade kurallarının (e-Arşiv iptal süresi, e-Fatura'da iade faturası) entegratör dokümanına göre uygulanması.

---

## 5. Ödeme altyapıları

| Sağlayıcı | Tür | Not |
|---|---|---|
| **PayTR** | Ödeme kuruluşu (iFrame/Direct API) | Şu an kullanılan. Taksit, iade, kart saklama. |
| **iyzico** | Ödeme kuruluşu | Pazaryeri modeli (alt üye işyeri), kart saklama, abonelik |
| **Param, Sipay, Paycell, Moka, Papara** | Ödeme kuruluşu | Komisyon ve vadeye göre alternatif |
| **Banka sanal POS** (Garanti BBVA, İş Bankası, Yapı Kredi, Akbank, Ziraat, QNB, Halkbank, VakıfBank, Denizbank…) | 3D Secure, doğrudan banka | Büyük ciroda komisyon avantajı. Banka bazında farklı API'ler (NestPay/EST, Garanti GVP, Posnet vb.). |
| **Masterpass, BKM Express** | Kayıtlı kart cüzdanı | Mobil dönüşüm |
| **Stripe, PayPal** | Yurt dışı kart | Jet İhracat siteleri için. Türkiye'de şirket hesabı kısıtları kontrol edilmeli. |
| **Havale/EFT + banka hesap hareketi** | Açık bankacılık (TCMB düzenlemeli hesap bilgisi hizmeti) / banka API'si | Otomatik ödeme eşleştirme |
| **DBS (Doğrudan Borçlandırma Sistemi)** | B2B bayi tahsilatı | Banka entegrasyonu |

- [ ] **Çoklu POS yönlendirmesi.** Kart bankasına göre en düşük komisyonlu POS'u otomatik seç. Bir POS çökerse diğerine geç.
- [ ] Ortak "ödeme sağlayıcısı" arayüzü: ödeme başlat, bildirim/callback doğrula, iade, taksit tablosu, kart sakla.

---

## 6. Kargo ve lojistik

### 6.1 Yurt içi

| Firma | Yöntem (sürüme göre doğrula) |
|---|---|
| Yurtiçi Kargo | Web servis (gönderi oluşturma, sorgulama) |
| Aras Kargo | Web servis / REST |
| MNG Kargo | REST API |
| Sürat Kargo | Web servis |
| PTT Kargo | Web servis |
| HepsiJet | REST API |
| Trendyol Express, Kolay Gelsin, Sendeo | REST API (bazıları pazaryeri bağlantılı) |
| **Kargo entegratörleri** (Geliver, Kargonomi, Shipentegra vb.) | Tek API ile çok firma | Küçük müşteri için hızlı başlangıç |

### 6.2 Yurt dışı (Jet İhracat)
- UPS, DHL Express, FedEx, Aramex, PTT Global: gönderi, etiket, gümrük beyanı, ETGB.
- Navlun ve konteyner tarafı için forwarder API'leri genelde teklif bazlıdır (B2B ihracatçıda manuel kalabilir).

### 6.3 Kargo modülünün işlevleri
- [ ] Desi ve ağırlık hesabı, kargo ücreti hesaplama (firma tarifesi veya API'den).
- [ ] Gönderi oluşturma. Etiket ve barkodun PDF ve ZPL (termal yazıcı) olarak alınması. Toplu etiket basımı.
- [ ] Takip numarası ve durum güncellemesi: webhook veya 30 dk'da bir sorgu. Müşteriye otomatik SMS ve e-posta.
- [ ] Kapıda ödeme (tahsilatlı gönderi) tutarı ve mutabakatı.
- [ ] İade kodu üretimi ve iade gönderisi takibi.
- [ ] e-İrsaliye ile bağlantı (gerekiyorsa).
- [ ] Mağaza, depo ve şube bazında gönderici adresi.

---

## 7. Pazaryerleri ve fiyat karşılaştırma

### 7.1 Pazaryerleri

| Pazaryeri | Yöntem | Ana işlemler |
|---|---|---|
| **Trendyol** | Partner/Satıcı REST API | Ürün oluşturma (kategori + özellik eşleme), toplu stok/fiyat güncelleme (batch request takibi), sipariş paketi çekme, kargo, fatura linki yükleme, iade, soru-cevap |
| **Hepsiburada** | Satıcı (Merchant) API | Katalog/listing, stok ve fiyat, sipariş, paketleme, kargo, iade |
| **Amazon (TR ve global)** | Selling Partner API (SP-API) | Listing, stok, sipariş, FBA/FBM, yurt dışı pazarlar |
| **N11** | Satıcı API | Ürün, stok, sipariş |
| **ÇiçekSepeti, Pazarama, PttAVM, Idefix, Koçtaş vb.** | Satıcı API'leri | Benzer işlemler |
| **Etsy, eBay** | REST API | El yapımı ve ihracat ürünleri |

- [ ] **Merkezi stok.** Tek stok; her kanal için "satışa açık miktar" ve güvenlik stoğu ayarlanabilir.
- [ ] **Kanal bazlı fiyat kuralı.** Örnek: Trendyol = site fiyatı × 1,15 (komisyon farkı). Yuvarlama kuralları.
- [ ] **Kategori ve özellik eşleme ekranı.** En çok emek isteyen kısım; arama destekli olmalı.
- [ ] Siparişler tek ekranda toplansın. Kanal etiketi görünsün. Hepsi ERP'ye aynı akışla gitsin (2.1).
- [ ] API istek sınırlarına uyum. Toplu (batch) işlemlerin sonucunun takibi.
- [ ] **Hazır ürün alternatifi.** Pazaryeri entegrasyonu çok bakım ister. Başlangıçta Entegra, Sentos, Dopigo, SoPyo gibi pazaryeri entegratörleriyle bağlantı kurup sonra kendi bağlayıcınıza geçmek düşünülebilir. Yap veya satın al kararı müşteri sayısına göre verilmeli.

### 7.2 Ürün akışları (mevcut "Ürün XML akışları" eklentisi)
- Google Merchant Center (Merchant API / feed), Meta (Facebook/Instagram) Katalog, TikTok Shop / Katalog, Pinterest.
- Fiyat karşılaştırma siteleri: Akakçe, Cimri, Epey (XML formatları).
- [ ] Akışlar ERP stok ve fiyatından beslensin. Stoksuz ürün otomatik çıksın.

---

## 8. B2B ve bayi altyapısı (Katalog Pro, İhracat ve sanayi müşterileri)

- [ ] **Bayi girişi.** Cari koduyla eşleşen kullanıcı ve alt kullanıcılar, yetki rolleri.
- [ ] **Bayiye özel fiyat.** Fiyat listesi, iskonto grupları ve döviz bazlı fiyat ERP'den gelir.
- [ ] **Cari ekstre, bakiye, vade ve risk limiti.** ERP'den anlık gelir. Risk limiti aşılınca sipariş onaya düşer.
- [ ] **Hızlı sipariş.** Stok koduyla veya Excel yükleyerek. Tekrar sipariş.
- [ ] **Teklif iste.** Teklif ERP'de veya CRM'de oluşturulur, PDF teklif siteye döner, onaylanınca siparişe çevrilir.
- [ ] **Ödeme.** Açık hesap, DBS, kartla cari ödeme (sanal POS üzerinden "cari tahsilat").
- [ ] **Belge merkezi.** Faturalar, irsaliyeler, sertifikalar, teknik föyler ve CE belgeleri.
- [ ] **Döviz kurları.** TCMB günlük kurları otomatik çekilir (today.xml). Kur kuralı belirlenir: alış, satış veya efektif.

---

## 9. CRM, iletişim ve pazarlama

| Alan | Sistemler | İşlev |
|---|---|---|
| CRM | HubSpot, Salesforce, Zoho, Pipedrive, Bitrix24, Microsoft Dynamics 365 Sales | Form ve sipariş → talep/fırsat, aşama senkronu, kaynak bilgisi |
| SMS | Netgsm, İleti Merkezi, Verimor, Mutlucell, Turkcell | Bilgilendirme ve OTP; kampanya SMS'i İYS kontrolüyle |
| İYS | İYS API / entegratör | Ticari ileti onaylarının 3 iş günü içinde kaydı, ret senkronu |
| WhatsApp | WhatsApp Business Platform (Cloud API) | Sipariş, kargo ve randevu bildirimi (onaylı şablon mesaj), canlı destek |
| E-posta | Amazon SES, Brevo, Postmark, Mailgun; pazarlama: Mailchimp, Klaviyo | İşlem e-postaları; bülten segmentleri |
| Santral | Verimor, Netgsm, Alotech, 3CX | Arayan numarayla CRM kaydını açma, arama kaydı linki |
| Canlı destek | Tawk.to, Crisp, Intercom, Zendesk | Site içi sohbet, talep oluşturma |
| Yorum | Google İşletme Profili, Trustpilot, Şikayetvar (izleme) | Puanı siteye çekme, yorum isteme e-postası |

---

## 10. Sektöre özel entegrasyonlar (demo kategorilerine göre)

| Sektör | Entegrasyon |
|---|---|
| Restoran, kafe | QR menü, rezervasyon, Google ile rezervasyon (Reserve with Google ortağı üzerinden), paket servis platformları (Yemeksepeti, Getir, Trendyol Yemek). Bu platformların API'leri iş ortaklığı gerektirir. |
| Otel, turizm | Kanal yöneticisi (HotelRunner, Elektraweb, Reseliva vb.), rezervasyon motoru, ödeme. Booking ve Expedia'ya doğrudan bağlantı genelde kanal yöneticisi üzerinden. |
| Klinik, güzellik, sağlık | Randevu (Google/Outlook takvim senkronu), SMS hatırlatma. **Sağlık verisi özel nitelikli kişisel veridir:** formda ayrıca açık rıza ve sıkı güvenlik gerekir. |
| Eğitim, spor | Ders ve üyelik takvimi, abonelik ödemesi, online toplantı (Zoom, Google Meet, Teams) |
| Emlak, inşaat | İlan portalı XML (sahibinden ve Hepsiemlak kurumsal iş ortaklığıyla), harita, 360° tur |
| Otomotiv | Araç ilanı aktarımı (portal iş ortaklığı), servis randevusu, ekspertiz raporu PDF |
| Kurumsal, holding | Kariyer: ilan ve CV başvurusu (Kariyer.net, LinkedIn); yatırımcı ilişkileri (KAP bağlantıları) |
| Sanayi, ihracat | Ürün kataloğu PDF üretimi, teknik doküman merkezi, çok dil (DeepL / Google Translate API ile ilk çeviri + insan kontrolü), çoklu döviz, B2B (Bölüm 8) |

---

## 11. Kimlik, doğrulama ve yardımcı servisler

- [ ] **TCKN doğrulama.** NVI'nin kimlik doğrulama web servisi (ad, soyad, doğum yılı ile). Yalnızca gerçekten gerekli olduğunda ve KVKK metninde belirtilerek kullanılmalı.
- [ ] **VKN ve mükellef sorgusu.** e-Belge entegratörü üzerinden.
- [ ] **Adres verisi.** İl, ilçe, mahalle listeleri. Kargo firmalarının adres kodlarıyla eşleşmeli.
- [ ] **Harita.** Google Maps / Yandex: bayi ve şube bulucu, adres otomatik tamamlama.
- [ ] **Giriş.** Google ile giriş, Microsoft ile giriş, Apple ile giriş. İki adımlı doğrulama (TOTP veya SMS OTP).
- [ ] **e-İmza ve KEP.** Sözleşme ve ihtar süreçleri için (E-Güven, TÜRKTRUST, KEP sağlayıcıları).
- [ ] **Dosya.** Google Drive, OneDrive, S3: müşteri içerik yükleme, yedekleme.
- [ ] **Bot koruması.** Cloudflare Turnstile veya reCAPTCHA v3 (formlarda bot tuzağı alanına ek olarak).

---

## 12. Ortak teknik gereksinimler (her bağlayıcı için kabul kriterleri)

- [ ] **Mükerrer kayıt yok.** Aynı sipariş veya fatura iki kez oluşmaz. Test: aynı olay 3 kez gönderilir.
- [ ] **Veri kaybı yok.** Dış sistem 2 saat kapalıyken gelen siparişler, sistem açılınca sırayla ve eksiksiz aktarılır.
- [ ] **Stok tutarlılığı.** ERP'de stok 0 olunca site ve pazaryerlerinde en geç 5 dk içinde satışa kapanır. Test: aynı ürünün son adedi iki kanalda aynı anda satılmaya çalışılır.
- [ ] **Saat dilimi ve para.** Tarihler `+03:00` ile, tutarlar ondalık (decimal) tipte, kuruş yuvarlaması ERP kuralıyla aynı.
- [ ] **KDV ve iskonto.** Satır iskontosu ve genel iskonto ERP'deki hesapla birebir tutar. Test: 3 farklı KDV oranlı karma sepet.
- [ ] **Log ve maskeleme.** Kart bilgisi asla loglanmaz. T.C. no ve telefon maskeli tutulur.
- [ ] **Performans.** Senkron işler site hızını etkilemez (arka planda kuyrukla çalışır). 10.000 ürünlük stok senkronu 5 dk içinde biter.
- [ ] **Sürüm uyumu.** Dış API sürüm değişiklikleri için bağlayıcı bazında sürüm numarası ve test paketi.
- [ ] **Belgeleme.** Her bağlayıcı için tek sayfalık doküman: kurulum adımları, gerekli yetkiler, eşlemeler, bilinen kısıtlar.

---

## 13. Ürünleştirme önerisi (eklenti olarak satış)

Mevcut eklenti yapısıyla uyumlu bir paketleme önerisi. Fiyatlar örnektir; maliyet ve rakip araştırmasıyla netleştirilmeli.

| Eklenti | İçerik | Öneri model |
|---|---|---|
| **Jet Entegrasyon – Muhasebe** | Paraşüt, Logo İşbaşı veya BizimHesap + e-Arşiv/e-Fatura | Kurulum + yıllık |
| **Jet Entegrasyon – ERP** | Logo, Mikro, Netsis, Nebim, SAP B1 veya Business Central bağlayıcısı + JET Ajan | Kurulum (proje bazlı) + yıllık bakım |
| **Jet Entegrasyon – Kurumsal ERP** | SAP S/4HANA, NetSuite, Dynamics | Teklif bazlı proje |
| **Jet Kargo** | 1–3 kargo firması, etiket, takip, SMS | Yıllık |
| **Jet Pazaryeri** | Trendyol, Hepsiburada, Amazon, N11 (kanal başına) | Kanal başına yıllık |
| **Jet B2B Bayi** | Bayi portalı, cari ekstre, özel fiyat, risk limiti | Kurulum + yıllık |
| **Jet Ödeme+** | Çoklu sanal POS, kart saklama, abonelik | Yıllık |
| **Jet API** | Müşterinin kendi yazılımcısı için REST API ve webhook | Yıllık |

> Not: Mağaza ve pazaryeri paketi sitede "yakında" olarak duruyor. Bu altyapı o paketin temelidir.

---

## 14. Yol haritası

| Faz | Süre (tahmini) | Kapsam | Neden |
|---|---|---|---|
| **0 – Temel** | 4–6 hafta | Entegrasyon katmanı (1.1), ortak veri modeli, kuyruk, log, hata paneli, JET Core REST API ve webhook | Sonraki her şey bunun üstüne kurulur |
| **1 – En çok istenen** | 4–6 hafta | Paraşüt + 1 e-belge entegratörü, Logo (Ajan + SQL okuma + Objects ile yazma), 2 kargo firması (Yurtiçi, Aras veya MNG) | Türkiye KOBİ'sinde en yaygın üçlü |
| **2 – Satış kanalları** | 6–8 hafta | Trendyol + Hepsiburada, Google Merchant ve Meta katalog, merkezi stok | Mağaza paketinin açılması |
| **3 – B2B ve sanayi** | 4–6 hafta | Bayi portalı, Mikro/Netsis, TCMB kurları, teklif modülü | Katalog Pro, İhracat ve OSB müşterileri |
| **4 – Kurumsal** | Proje bazlı | SAP S/4HANA / B1, Dynamics, NetSuite, EDI | Büyük müşteri; partner iş birliği |

Her fazın sonunda en az bir **pilot müşteriyle** canlı test yapılmalı. Pilot müşteriye indirim karşılığı geri bildirim alınması önerilir.

---

## 15. Hukuki ve uyum notları
- **KVKK aydınlatma metni:** Her yeni bağlayıcı, müşterinin kendi aydınlatma metninde yeni bir "alıcı grubu" demektir (kargo firması, pazaryeri, entegratör). JET Core'da bu alıcıları listeleyen bir ekran olursa müşterinin işi kolaylaşır.
- **Yurt dışına aktarım:** Yurt dışı sunuculu servislerde (Stripe, Amazon, HubSpot, Meta vb.) yurt dışına aktarım hükümleri geçerlidir (KVKK m.9).
- **Kart verisi:** Kart bilgisi JET Core'da tutulmamalı. Sadece ödeme kuruluşunun "kart saklama" anahtarı tutulur. Bu, PCI-DSS kapsamını küçültür.
- **e-Belge zorunlulukları:** e-Fatura ve e-Arşiv geçiş zorunlulukları ve sınırları GİB tarafından değiştirilebilir. Müşterinin mali müşaviriyle teyit edilmeli.
- **Sözleşme:** Entegrasyon eklentileri için Hizmet Sözleşmesi'ne bir ek madde eklenmeli. İçeriği: üçüncü taraf API'lerinin değişmesi veya kapanması halinde sorumluluk sınırı, müşterinin üçüncü taraf lisans ve ücretlerinden kendisinin sorumlu olması.
