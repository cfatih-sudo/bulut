# jetbilisim.com.tr – 2. İnceleme (28.10.2026)

Kapsam: jetbilisim.com.tr (53 sayfa, masaüstü + mobil), demo.jetbilisim.com.tr (213 demonun tamamı), merkez.jetbilisim.com.tr (sipariş akışı gönderilmeden, giriş, Jet Büyüme), 293 link, güvenlik başlıkları.

**Sonuç:** Önceki 12 bulgudan 10'i düzeltildi, 2'si kısmen. 16 yeni bulgu var: 2 yüksek, 7 orta, 7 düşük.

## Önceki bulguların durumu

| # | Bulgu | Durum | Not |
|---|---|---|---|
| 1 | T.C./Vergi no kontrolü | ✅ Düzeltildi | T.C. alanı zorunlu; boşken ve algoritmaya uymayan numarada (12345678901) 2. adımda “T.C. kimlik numarası geçerli değil (11 hane)” uyarısı çıkıyor. |
| 2 | Geçersiz alan adı | ✅ Düzeltildi | “bu bir alan adi degil” reddediliyor: “Geçerli bir alan adı yazın”. “https://www.Ornek-Firma.com.tr/” otomatik olarak “ornek-firma.com.tr” yapılıyor. |
| 3 | Toplam tutar görünmüyordu | ✅ Düzeltildi | Özet kutusu canlı: dil ve eklenti seçilince ara toplam 46.440, KDV 9.288, genel toplam 55.728 TL anında güncelleniyor; taksit notu ve “(yıllık)” ibaresi var. |
| 4 | Demo düzeni siparişe taşınmıyordu | 🟡 Kısmen | Bölüm düzeni artık adreste. Ancak adreste iki ayrı “duzen” parametresi gidiyor ve header değeri kodlanmamış (yeni bulgu 3). 3. adımda seçilen düzen gösterilmiyor. |
| 5 | Dil değişince düzen sıfırlanıyordu | ✅ Düzeltildi | EN’e geçince header, footer ve bölüm düzeni korunuyor; EN aktif görünüyor. |
| 6 | Vitrinde 404 veren “Paketler” linki | ✅ Düzeltildi | Tüm linkler https://jetbilisim.com.tr/paketler/ ve /iletisim/ adresine gidiyor. |
| 7 | Header/Footer seçicide boş önizlemeler | ✅ Düzeltildi | Kartlar canlı önizleme gösteriyor; büyük önizleme ekran içinde kalıyor. |
| 8 | /demolar/ kartları filtrelemiyordu | ✅ Düzeltildi | Kartlar çoklu kategoriyle filtreliyor (ör. ?kategori=egitim,spor,turizm). |
| 9 | Menü kategori eşleşmesi | ✅ Düzeltildi | “Eğitim, Spor & Turizm” ve “Perakende & Butik” artık tüm ilgili kategorileri açıyor. |
| 10 | Demo sayısı tutarsızdı | ✅ Düzeltildi | Her yerde 213 / “200’den fazla” kullanılıyor; çelişki kalmadı. |
| 11 | Demo düzenleyicide JS hatası | ✅ Düzeltildi | 213 demonun ve 53 sayfanın hiçbirinde JavaScript hatası yok. |
| 12 | Performans | 🟡 Kısmen | Ana site sunucu cevabı çoğunlukla 0,3–0,7 sn, ama ara ara 2–4 sn’ye çıkıyor; sayfalar Cloudflare’de önbelleğe alınmıyor (DYNAMIC). Demo detay sayfası tam yüklenme ortalaması 7,6 sn. |

## Yeni bulgular (yapılacaklar)

### 1. [YÜKSEK] Kullanım Koşulları başka firmanın şablonu
- [ ] **Düzelt:** Sayfayı kısa bir “site kullanım koşulları” metniyle değiştirin; satış/cayma bölümlerini tamamen kaldırıp Hizmet Sözleşmesi ve İptal-İade sayfalarına bağlantı verin. Tüm yanlış linkleri silin.
- **Sorun:** /kullanim-kosullari/ sayfasında “jetbilisim.com.tr” yazan 37 link aslında http://www.ledaydinlatmamarketi.com adresine gidiyor. Metin bir e-ticaret şablonu: “ürün alımı”, kargo, “ezik, kırık, ambalajı yırtılmış” ifadeleri, “…. adresinde ….’a teslim” boşlukları, yürürlükten kalkmış 4077 sayılı Kanun ve 7 günlük cayma hakkı. Yeni Hizmet Sözleşmesi ve İptal-İade sayfasındaki 14 gün ve 6502 sayılı Kanun ile çelişiyor.

### 2. [YÜKSEK] merkez.jetbilisim.com.tr şablon site olarak yayında ve Google’a açık
- [ ] **Düzelt:** merkez’in ana sayfası ve /hakkimizda/, /hizmetler/, /iletisim/ sayfalarını jetbilisim.com.tr’deki karşılıklarına 301 yönlendirin ya da noindex yapın; sitemap’ten çıkarın. buyume-siparis sayfasında demo-siparis’teki sade başlığı (logo + Güvenli sipariş) kullanın.
- **Sorun:** merkez.jetbilisim.com.tr ana sayfası “JET WEB MERKEZ — GENEL İŞLETME” başlıklı hazır şablon içerik gösteriyor (Hakkımızda: “Küçük bir ekip ve büyük bir hedefle…”, süreç: “Uygulama 2–12 hafta”). İletişim sayfasında telefon ve adres boş. Sayfalar “index, follow” ve sitemap’te. Jet Büyüme sipariş sayfasının üst menüsü müşteriyi bu sayfalara götürüyor.

### 3. [ORTA] Sipariş adresinde çift “duzen” parametresi
- [ ] **Düzelt:** Tek parametrede birleştirip kodlayın: duzen=header%3Dcentered%26footer%3D…%26bolumler%3D… (veya header=, footer=, duzen= ayrı isimlerle). 3. adımdaki özete “Demo ve düzen” satırı ekleyin; siparişte saklandığını panelden doğrulayın.
- **Sorun:** Demo → paket seçimi adresi: ?demo=JD-801&paket=jet_premium&duzen=header=centered&duzen=hero%3A… Aynı isimde iki parametre var ve ilki kodlanmamış. PHP gibi sistemler genelde sonuncusunu alır; bu durumda header/footer seçimi kaybolabilir. 3. adımda seçilen düzen müşteriye gösterilmiyor.

### 4. [ORTA] 3. adımda T.C. “Vergi dairesi / no” olarak gösteriliyor
- [ ] **Düzelt:** Bireyselde etiketi “T.C. kimlik no” yapın; numarayı maskeli gösterin (ör. 111******10).
- **Sorun:** Bireysel müşteride özet tablosunda “Vergi dairesi / no: 11111111110” yazıyor.

### 5. [ORTA] Yenileme bedeli ifadesi sözleşmeyle çelişiyor
- [ ] **Düzelt:** Sipariş sayfası ve ön bilgilendirme metnini sözleşmeyle aynı yapın: “İlk yenileme X TL + KDV; sonraki yıllarda değişiklik 45 gün önce bildirilir.”
- **Sorun:** Sipariş sayfası: “Yenileme bedeli, yenileme tarihindeki güncel fiyat listesine göre belirlenir.” Hizmet Sözleşmesi 9.3(a): “İlk yenilemede, sipariş tarihinde ilan edilen yıllık yenileme bedeli uygulanır.”

### 6. [ORTA] Bazı demolarda 900–1023 px genişlikte yatay taşma
- [ ] **Düzelt:** JET Core grid’inde md kırılımında .mb-md-12 için genişliği calc(100% - gap) yapın veya satıra overflow-x:clip verin. Düzeltme tüm demolara ve müşteri sitelerine yansır.
- **Sorun:** 16 demoda ~80 px, ~20 demoda 4–7 px yatay kaydırma oluşuyor (ör. JD-704, JD-909, JD-409, JD-921, JD-716, JD-809, JD-721, JD-817, JD-607, JD-144, JD-903, JD-910, JD-939, JD-146, JD-403). Bu genişlik yatay tablet, küçük laptop ve demo düzenleyicinin önizleme alanıdır. Sebep: “mb-col mb-span-5 mb-md-12” sütunu md kırılımında %100 + gap genişliğinde kalıyor. Telefonda (390 px) ve 1024 px üzeri sorun yok.

### 7. [ORTA] Eski Gizlilik Politikası yeni KVKK metniyle çakışıyor
- [ ] **Düzelt:** Gizlilik Politikası’nı KVKK Aydınlatma Metni’ne 301 yönlendirin ya da tek paragraflık bir özet + bağlantıya indirin.
- **Sorun:** /gizlilik-politikasi/ “Son güncellenme: 01/08/2023” tarihli ayrı bir KVKK metni; yeni /kvkk-aydinlatma-metni/ ile iki farklı metin var. Sayfada iki H1 var; e-posta “info[@]jetbilisim.com.tr” yazılmış.

### 8. [ORTA] İletişim formunda zorunlu “kabul ediyorum” kutusu
- [ ] **Düzelt:** Kutu yerine bilgi notu: “Talebinizi yanıtlamak için verileriniz KVKK Aydınlatma Metni kapsamında işlenir.”
- **Sorun:** /iletisim/ formunda zorunlu kutu: “Kişisel verilerimin … işlenmesini kabul ediyorum.” Talebi yanıtlamak için açık rıza gerekmez; zorunlu rıza KVKK açısından sorunlu. merkez/iletisim formunda da aynı. (SEO analiz formundaki “aydınlatma metnini okudum” ifadesi daha doğru.)

### 9. [ORTA] Satıcı bilgilerinde vergi kimlik no görünmüyor
- [ ] **Düzelt:** Vergi dairesi ve vergi kimlik no (veya MERSİS), varsa KEP adresi Ön Bilgilendirme, sözleşme ve site altbilgisine eklensin. Avukatınızla teyit edin.
- **Sorun:** Hizmet Sözleşmesi ve Ön Bilgilendirme’de “Vergi dairesi ve numarası faturalarda yer alır.” yazıyor; MERSİS/vergi kimlik no ve KEP yok. E-ticaret mevzuatı (6563 s. Kanun ve ilgili yönetmelik, Mesafeli Sözleşmeler Yönetmeliği) internetten satışta bu bilgilerin sitede gösterilmesini istiyor.

### 10. [DÜŞÜK] Eklenti sayfalarında kırık görsel
- [ ] **Düzelt:** Boş img etiketini kaldırın veya görsel atayın.
- **Sorun:** 10 eklenti sayfasında (/eklenti-seo/, /eklenti-site-kit/ …) src="" boş bir görsel var (alt: “+SEO ve yapay zekâ görünürlüğü”).

### 11. [DÜŞÜK] Başlık (title) ve açıklama eksikleri
- [ ] **Düzelt:** Blog şablonunda markayı tek kez ekleyin; başlıkları 50–60 karakterde tutun; kategori sayfalarına açıklama yazın.
- **Sorun:** 15 sayfanın başlığı 65 karakterden uzun; blog yazılarında marka iki kez geçiyor (“| Jet Bilişim – Jet Bilişim”); 141 karakterlik başlık var. 5 kategori sayfasında açıklama yok. “Google Ads – Jet Bilişim” başlığı blog yazısı ve kategori sayfasında aynı.

### 12. [DÜŞÜK] robots.txt eski site haritalarını gösteriyor
- [ ] **Düzelt:** robots.txt’de tek satır bırakın: Sitemap: https://jetbilisim.com.tr/sitemap.xml
- **Sorun:** robots.txt’de http://www.jetbilisim.com.tr/sitemap.xml ve sitemap-1 … sitemap-19.xml satırları var. Gerçek harita https://jetbilisim.com.tr/sitemap.xml (3 alt harita).

### 13. [DÜŞÜK] Blogda doldurulmamış yer tutucu
- [ ] **Düzelt:** Yer tutucuyu tel: linkiyle değiştirin; iç linkleri son adreslere güncelleyin.
- **Sorun:** /blog/web-tasarim-seo-ve-google-ads-ile-buyume-rehberiniz/ yazısında “📞 [Bizi Hemen Arayın]” metni link olmadan duruyor. İki blog yazısı iç linkleri yönlendirmeli (301) eski adreslere veriyor.

### 14. [DÜŞÜK] WhatsApp sadece iletişim sayfasında
- [ ] **Düzelt:** Sabit (yüzen) WhatsApp düğmesi ve demo sayfasında “Bu demo hakkında sor (JD-xxx)” düğmesi.
- **Sorun:** 53 sayfanın yalnızca birinde WhatsApp bağlantısı var; demo sayfalarında yok.

### 15. [DÜŞÜK] Demolar site haritasında yok
- [ ] **Düzelt:** Demoların Google’da görünmesini istiyorsanız haritaya ekleyin; istemiyorsanız noindex verin. İkisinden birine bilinçli karar verin.
- **Sorun:** demo.jetbilisim.com.tr/sitemap.xml yalnızca ana sayfayı içeriyor; 213 demo sayfası yok.

### 16. [DÜŞÜK] Güvenlik başlıklarında küçük iyileştirme
- [ ] **Düzelt:** Tüm alt alanlar HTTPS olduğu için includeSubDomains ekleyin; zamanla script-src içeren bir CSP’ye geçin.
- **Sorun:** HSTS “max-age=31536000” (includeSubDomains/preload yok). CSP yalnızca object-src/base-uri/frame-ancestors içeriyor.

## İyi çalışanlar

- 53 sayfanın hepsi 200 dönüyor; sayfalarda JavaScript hatası ve kırık kaynak (4xx/5xx) yok.
- Mobilde (390 px) hiçbir sayfada yatay taşma yok; tüm görsellerde alt metni var.
- Her sayfada canonical, og:image ve yapılandırılmış veri var (ProfessionalService, BreadcrumbList, FAQPage, BlogPosting).
- 213 demonun hepsi açılıyor: hata yok, kırık görsel yok, her demoda tek H1.
- Sipariş formu: T.C. algoritması, alan adı doğrulaması ve normalizasyonu, canlı toplam/KDV/taksit, ayrılmış onay kutuları (sözleşme zorunlu, cayma onayı ve ticari ileti isteğe bağlı), KVKK bilgi notu.
- Yeni yasal sayfalar: Hizmet Sözleşmesi (sürüm ve yürürlük tarihli), Ön Bilgilendirme, İptal-İade, KVKK, Çerez politikası. Cayma istisnası doğru bende (m.15/1-h) dayandırılmış.
- Yeni Jet Büyüme aylık paketleri (1.490–14.900 TL/ay) ve internetten sipariş.
- Sosyal kanıt: “1998’den beri · 28 yıllık deneyim · 1200+ referans · 213 canlı demo · internetten sipariş”.
- Güvenlik: HSTS, X-Frame-Options, nosniff, Referrer-Policy, Permissions-Policy; çerezler Secure + HttpOnly + SameSite; .git, .env, /admin/, yedek dosyaları dışarıya kapalı; http→https ve www→alan adı yönlendirmeleri doğru; 404 sayfası doğru çalışıyor.
- Linkler: 293 linkin 278’i doğrudan 200; kırık iç link yok (dış sitelerin bot engelleri hariç).

---
Notlar: Sipariş gönderilmedi. Performans bulut sunucudan ölçüldü. Yasal maddeler hukuki görüş değildir; avukat teyidi önerilir.