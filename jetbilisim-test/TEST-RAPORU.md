# jetbilisim.com.tr – Müşteri Testi Bulguları

- **Tarih:** 28.10.2026
- **Test eden:** Claude (otomatik tarayıcı, Chromium 1366×850)
- **Kapsam:**
  - `jetbilisim.com.tr`
  - `demo.jetbilisim.com.tr`
  - `merkez.jetbilisim.com.tr/musteri/demo-siparis/`

## Özet

- Akış uçtan uca çalışıyor: ana site → paketler → demo vitrini → demo düzenleyici → paket seçimi → 3 adımlı sipariş.
- Test siparişi oluşturuldu: **S-2026-00001**.
  - İçerik: Jet KOBİ Premium + İngilizce dil + Yapay zekâ asistanı, demo JD-801
  - Toplam **55.728,00 TL**: (36.990 + 5.550 + 3.900) × 1,20. Hesap doğru.
- Ödeme yapılmadı.
- Sistem "özet e-posta gönderildi" diyor. `cfatih@gmail.com` gelen kutusu ve spam klasörü kontrol edilmeli.

**Temizlik:**
- S-2026-00001 siparişini ve oluşan test müşteri hesabını silin. Test bilgileri:
  - Firma: "TEST - Claude Otomatik Test Ltd."
  - Vergi no: 1111111111
- Üç sitede de "kopyalama botlarını engelle" ayarını tekrar açın.

## Bulgular

### 1. [YÜKSEK] T.C./Vergi no sunucuda zorunlu, formda değil
- **Yer:** merkez → demo-siparis, 2. adım (Bilgileriniz)
- **Adımlar:**
  1. Bireysel seçin.
  2. T.C. alanını boş bırakın, diğer alanları doldurun.
  3. "Devam et"e basın.
  4. "Siparişi onaya gönder"e basın.
- **Beklenen:** 2. adımda "Devam et"e basınca hata çıkmalı.
- **Gerçekleşen:**
  - 3. adıma geçiliyor.
  - Gönderince sunucu "Vergi numarası ya da T.C. kimlik numarası gerekli." diyerek 2. adıma geri atıyor.
  - Parola alanları siliniyor.
- **Öneri:**
  - Bireyselde `tc_no`, firmada `tax_no` alanını `required` yapın.
  - "Devam et" sırasında JS ile kontrol edin. 11 hane ve T.C. algoritması, 10 hane VKN.

### 2. [YÜKSEK] Geçersiz alan adı kabul ediliyor
- **Yer:** 1. adım, "Alan adım var" → `alan` alanı
- **Adım:** `bu bir alan adi degil` yazıp "Devam et"e basın.
- **Gerçekleşen:** 2. adıma geçiliyor.
- **Öneri:** İstemcide ve sunucuda doğrulama yapın. Örnek desen:
  ```
  pattern="^(?!-)[a-z0-9-]{1,63}(?<!-)(\.[a-z0-9-]{1,63})+$"
  ```
  Ayrıca küçük harfe çevirip `http://` ve `www.` önekini kırpın.

### 3. [ORTA] Toplam tutar sipariş verilene kadar görünmüyor
- Dil veya eklenti seçince sağdaki özet kutusu değişmiyor.
- 3. adımda kalemler listeleniyor ama ara toplam, KDV ve genel toplam yok.
- Toplam ilk kez sipariş sonrası "Şimdi öde (55.728,00 TL)" düğmesinde görünüyor.
- 3. adımda Yapay zekâ asistanı `+3.900 TL +KDV` olarak yazıyor. 1. adımdaki "/ yıl" bilgisi kayboluyor.
- **Öneri:** Özet kutusunda canlı ara toplam, KDV ve genel toplam gösterin. Yıllık kalemleri ayrıca belirtin.

### 4. [ORTA] Demo bölüm düzeni siparişe taşınmıyor
- **Adımlar:**
  1. JD-801'de header'ı Ortalı logo, footer'ı Bülten odaklı yapın.
  2. "Projeler" bölümünü değiştirin (🔀).
  3. "Yorumlar" bölümünü silin.
  4. Paket seçin.
- **Sipariş adresi:** `...demo-siparis/?demo=JD-801&paket=jet_premium&duzen=header%3Dcentered%26footer%3Dnewsletter`
- **Sorun:** Bölüm düzeni (`hero:fullslider,work:bannergrid,price:list,contact:split`) adreste yok.
- **Karşılaştırma:** "Bağlantıyı paylaş" linki hepsini taşıyor: `?header=centered&footer=newsletter&duzen=hero%3A...`
- **Öneri:** Paket linklerine paylaşım linkindeki tam düzen kodunu ekleyin. Sipariş kaydında da saklayın.

### 5. [ORTA] Demo'da dil değişince özelleştirmeler sıfırlanıyor
- EN'e geçince header, footer ve bölümler varsayılana dönüyor. Dil linkleri yalnızca `?dil=en` taşıyor.
- İngilizce içerik gösterilirken üstte hâlâ **TR** seçili görünüyor.
- **Öneri:**
  - Dil linklerine mevcut `header`, `footer` ve `duzen` parametrelerini ekleyin.
  - Aktif dil sınıfını `dil` parametresine göre verin.

### 6. [ORTA] Demo vitrinindeki "Paketleri incele" ve "Paketler" linkleri 404 veriyor
- `demo.jetbilisim.com.tr` sayfasındaki iki link de `https://yeni.jetbilisim.com.tr/paketler/` adresine gidiyor. Bu adres **404 Not Found** dönüyor.
- "İletişim" linki `https://www.jetbilisim.com.tr/iletisim/` adresine gidiyor. Diğer linklerle tutarlı olması için `https://jetbilisim.com.tr/...` kullanın.
- **Öneri:** Linkleri `https://jetbilisim.com.tr/paketler/` yapın.

### 7. [DÜŞÜK] Header/Footer seçicide önizlemeler boş
- Seçici açıldıktan 5 sn sonra bile kartlar çizgili yer tutucu olarak kalıyor.
- Fareyle üzerine gelince açılan büyük önizleme de boş geliyor. Ayrıca seçicinin dışına taşıp sağ paneli örtüyor.

### 8. [DÜŞÜK] /demolar/ sayfasındaki kategori kartları filtrelemiyor
- 9 kartın hepsi `https://demo.jetbilisim.com.tr/` adresine gidiyor.
- **Öneri:** Menüdeki gibi `?kategori=kurumsal|endustriyel|magaza|insaat|otomotiv|perakende|saglik|gida|egitim` ekleyin.

### 9. [DÜŞÜK] Menü kategori adları ile vitrin filtreleri uyuşmuyor
- "Eğitim, Spor & Turizm" (`?kategori=egitim`) yalnızca "Eğitim & Bilim" (11) kategorisini açıyor.
- "Perakende & Butik" (`?kategori=perakende`) yalnızca "Perakende & Showroom" (5) kategorisini açıyor.

### 10. [DÜŞÜK] Demo sayısı farklı yerlerde farklı
- Geçen ifadeler:
  - "100+"
  - "100'den fazla"
  - "200+ hazır tasarım"
  - paket kartlarında 166 ve 186
- Vitrinde ise 213 demo var.

### 11. [DÜŞÜK] Demo düzenleyicide ara sıra JS hatası
- Hata: `Failed to execute 'remove' on 'Element': The node to be removed is no longer a child of this node.`
- Bölüm değiştirme sırasında bir kez görüldü, ekranda bozulma olmadı.
- **Öneri:** `el.remove()` öncesinde `el.isConnected` kontrolü yapın.

### 12. [DÜŞÜK] Performans
- İlk (soğuk) açılış süreleri:
  - ana sayfa yaklaşık 10 sn
  - demo detay 5,7–12 sn
- `/paketler/` sunucu cevabı (TTFB) 1,7–2,5 sn. Ana sayfada bu süre 0,7 sn.
- `/paketler/` sayfasında 86 görsel var.
- **Öneri:**
  - Sayfa önbelleği
  - Görsellerde `loading="lazy"`
  - Demo iframe'ini geç yükleme

## Sorunsuz çalışanlar

- **Ana site:** Menüler, paket fiyatları ve çerez bandı.
- **Demo vitrini:** Kategori filtresi, arama, demo koduyla arama ve paket filtresi (166/213).
- **Demo düzenleyici:**
  - header/footer değişimi
  - bölüm karıştırma ve silme
  - geri al / ileri al
  - mobil ve tablet görünüm
  - paylaşım linki (yeni sekmede aynen açılıyor)
- **Sipariş formu:**
  - zorunlu alanlar, e-posta biçimi ve parola uzunluğu kontrol ediliyor
  - KVKK onayı zorunlu
  - CSRF `_token` var, bot tuzağı (honeypot) `website` alanı var
- **Sonuç:** Sipariş numarası ve teşekkür sayfası geliyor, toplam doğru hesaplanıyor.

## Not: Güvenlik duvarı
- Üç sitede de "kopyalama botlarını engelle" ayarı headless tarayıcıları (`HeadlessChrome` user-agent'ı) ve `curl`'ü 403 ile engelliyor.
- Test için bu ayar kapatıldı. Testten sonra tekrar açılmalı.
- Otomatik testleri ileride düzenli çalıştırmak isterseniz, ayarı açık tutup test makinesinin IP'sini izin listesine ekleyin. Bunun için izin listesinin bot kontrolünü de atlaması gerekir.

## Dosyalar

| Dosya | İçerik |
|---|---|
| `jetbilisim-musteri-testi.pdf` | 35 adımın ekran görüntüleri ve bulgular |
| `musteri-testi-video.mp4` | Tüm akışın 3 dakikalık videosu |
| `tests/musteri-akisi.js` | Testi tekrar çalıştırmak için Playwright script'i. `SUBMIT=1` verilmezse sipariş göndermez. |
