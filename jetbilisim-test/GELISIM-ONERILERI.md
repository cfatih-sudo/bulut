# jetbilisim.com.tr – Gelişim Önerileri ve Yapılacaklar

Hazırlanma tarihi: 28.10.2026.

Kaynak: 28.10.2026 tarihli müşteri testi (`TEST-RAPORU.md`, test siparişi S-2026-00001).

Her madde bir iş. `[ ]` tamamlanınca `[x]` yapın.

---

## Öncelik 1 – Bu hafta (satışı doğrudan etkiler)

### 1.1 Sipariş formu: T.C./Vergi no kontrolü
- [ ] Bireysel müşteride `tc_no`, firmada `tax_no` alanını 2. adımda zorunlu yap. Alanlar şu an `required` değil.
- [ ] "Devam et" basılınca istemci tarafında doğrula:
  - T.C. no: 11 hane ve T.C. algoritması
  - Vergi no: 10 hane
- [ ] Sunucu hata verip formu geri döndürdüğünde parola alanları da korunsun. Ya da hata hiç son adıma kalmasın.

**Neden:** Müşteri hatayı ancak son adımda "Siparişi onaya gönder"e basınca görüyor ve parolası siliniyor.

### 1.2 Sipariş formu: alan adı doğrulaması
- [ ] `alan` alanında biçim kontrolü yap. İstemcide ve sunucuda örnek desen:
  ```
  ^(?!-)[a-z0-9-]{1,63}(?<!-)(\.[a-z0-9-]{1,63})+$
  ```
- [ ] Girişi küçük harfe çevir. `http://`, `https://`, `www.` öneklerini ve sondaki `/` işaretini kırp.

**Neden:** Testte "bu bir alan adi degil" yazısı kabul edildi.

### 1.3 Sipariş formu: canlı toplam tutar
- [ ] Sağdaki özet kutusunu dil veya eklenti seçildikçe güncelle:
  - Kurulum bedeli
  - Diller
  - Eklentiler
  - Ara toplam
  - KDV (%20)
  - Genel toplam
- [ ] 3. adımda (Kontrol ve onay) ara toplamı, KDV'yi ve genel toplamı göster.
- [ ] Yıllık kalemleri ayrıca belirt (ör. "Yapay zekâ asistanı +3.900 TL / yıl"). 3. adımda "/ yıl" bilgisi şu an kayboluyor.

**Neden:** Testteki toplam 55.728 TL'ydi ve ilk kez sipariş verildikten sonra "Şimdi öde" düğmesinde görüldü.

### 1.4 Taksit bilgisi
- [ ] PayTR taksit seçeneklerini paket kartlarında ve sipariş özetinde göster (ör. "12 aya varan taksit, aylık X TL'den").

### 1.5 Bozuk linkler
- [ ] `demo.jetbilisim.com.tr` üzerindeki "Paketleri incele" ve "Paketler" linklerini düzelt. Şu an `https://yeni.jetbilisim.com.tr/paketler/` adresine gidiyorlar ve 404 dönüyor. Doğrusu `https://jetbilisim.com.tr/paketler/`.
- [ ] "İletişim" linkini `https://www.jetbilisim.com.tr/iletisim/` yerine `https://jetbilisim.com.tr/iletisim/` yap.
- [ ] Ana sitede `/demolar/` sayfasındaki 9 kategori kartını ilgili adrese yönlendir: `?kategori=kurumsal|endustriyel|magaza|insaat|otomotiv|perakende|saglik|gida|egitim`.

### 1.6 Güvenlik duvarı ve arama/yapay zekâ botları
- [ ] "Kopyalama botlarını engelle" kuralının aşağıdaki botları engellemediğini doğrula: Googlebot, Bingbot, GPTBot, OAI-SearchBot, ChatGPT-User, ClaudeBot, PerplexityBot, Google-Extended.
- [ ] Doğrulanmış arama ve yapay zekâ botları için izin listesi ekle. Doğrulamayı user-agent'a değil, ters DNS veya resmi IP listesine göre yap.
- [ ] Panel → Güvenlik → "Son engellenen istekler" listesini düzenli kontrol et.
- [ ] Üç sitede de (ana site, demo, merkez) kuralın tekrar açık olduğunu kontrol et.
- [ ] Test siparişi S-2026-00001'i ve test müşteri hesabını sil.

**Neden:** KOBİ Premium paketi "yapay zekâ aramalarında bulunun" diye satılıyor. Sitenin kendisi bu botlara kapalıysa sattığınız vaat kendi sitenizde çalışmamış olur.

---

## Öncelik 2 – Bu ay (dönüşümü artırır)

### 2.1 Demo düzeni siparişe tam taşınsın
- [ ] "Paket seçin, başlayın" linklerine paylaşım linkindeki tam düzen kodunu ekle. Şu an sipariş adresi yalnızca header ve footer'ı taşıyor:
  ```
  duzen=header=centered&footer=newsletter
  ```
  Bölüm düzeni de eklenmeli (ör. `hero:fullslider,work:bannergrid,price:list,contact:split`).
- [ ] Seçilen düzeni sipariş kaydına ve sipariş e-postasına "Seçtiğiniz düzen" olarak yaz.

### 2.2 Demoda dil değişimi
- [ ] Dil linklerine (`?dil=en` vb.) mevcut `header`, `footer` ve `duzen` parametrelerini ekle. Şu an dil değişince tüm özelleştirmeler sıfırlanıyor.
- [ ] Aktif dil vurgusunu `dil` parametresine göre ver. Şu an EN içerik açıkken TR seçili görünüyor.

### 2.3 Demodan müşteri adayı toplama
- [ ] Demo sayfasına "Bu tasarımı e-postama gönder" düğmesi ekle. Ad, e-posta ve telefon alsın, paylaşım linkini e-postayla göndersin, kaydı panele düşürsün.
- [ ] "Bu demo hakkında WhatsApp'tan sorun" düğmesi ekle. Mesaj demo kodu ve düzen linkiyle hazır gelsin.

### 2.4 Demo düzenleyici düzeltmeleri
- [ ] Header ve footer seçicideki önizleme kartlarına görsel yükle. Görsel yoksa bir yer tutucu göster.
- [ ] Fareyle üzerine gelince açılan büyük önizlemeyi ekranın içinde konumlandır. Şu an seçicinin dışına taşıyıp sağ paneli örtüyor.
- [ ] JS hatasını gider: `Failed to execute 'remove' on 'Element'`. `el.remove()` öncesinde `el.isConnected` kontrolü yap.

### 2.5 Ölçüm (analiz olayları)
- [ ] Demo için olay ekle:
  - `demo_ac`
  - `header_degistir`
  - `footer_degistir`
  - `bolum_degistir`
  - `paylas`
  - `paket_sec`
- [ ] Sipariş için olay ekle:
  - `siparis_adim1`
  - `siparis_adim2`
  - `siparis_adim3`
  - `siparis_gonder`
  - `siparis_hata` (hata metniyle birlikte)
  - `odeme_baslat`
- [ ] Adım adım terk oranlarını gösteren bir huni raporu kur.

### 2.6 Menü ve sayıların tutarlılığı
- [ ] "Eğitim, Spor & Turizm" menü linki yalnızca Eğitim & Bilim'i açıyor. Spor & Fitness ve Turizm & Seyahat de gelmeli. Çoklu kategori filtresi kullan ya da menü adını değiştir.
- [ ] "Perakende & Butik" linki yalnızca Perakende & Showroom'u açıyor. Moda, Takı & Butik de dahil edilmeli.
- [ ] Demo sayısını her yerde aynı yaz. Şu an "100+", "100'den fazla", "200+" ve 213 geçiyor. Mümkünse sayıyı otomatik çek.

---

## Öncelik 3 – Sürekli (büyüme)

### 3.1 Güven ve sosyal kanıt
- [ ] Ana sayfada Google yorum puanını ve 3–5 gerçek yorumu göster.
- [ ] Referanslarda canlı site linki ve ekran görüntüsü kullan.
- [ ] Ölçülebilir sonuçlu 2–3 vaka çalışması yaz (ör. trafik, teklif formu, arama sayısı).
- [ ] "1998'den beri" ve "aynı iş günü arıyoruz" mesajlarını paket kartlarında ve sipariş sayfasında öne çıkar.

### 3.2 Yerel SEO
- [ ] Mevcut "Tuzla web tasarım" ve "Gebze OSB web tasarım" kalıbıyla yeni sayfalar aç:
  - Pendik
  - Kartal
  - Çayırova
  - Dilovası
  - Şekerpınarı
  - İMES OSB
  - İTOSB
- [ ] Her sayfaya o bölgeden referans, harita ve yerel iletişim bilgisi ekle.
- [ ] Google İşletme Profili'ni güncel tut: fotoğraflar, hizmetler, düzenli gönderi.

### 3.3 Sektör sayfaları
- [ ] Demo kategorileri için ayrı sektör sayfaları aç (ör. "Restoran web sitesi", "Makine firması web sitesi"). Her sayfada o sektörün demoları, uygun paket, fiyat ve sipariş düğmesi olsun.

### 3.4 Blog
- [ ] Ayda en az 2 yazı yayınla. Son yazı Haziran 2026 tarihli, öncekiler aylar arayla.
- [ ] Konu örnekleri:
  - İhracat sitesi kaç dilde olmalı
  - Katalog sitesi mi, e-ticaret mi
  - OSB firmaları için Google Ads bütçesi
  - Yapay zekâ aramalarında görünmek
- [ ] Her yazının sonunda ilgili paket ve demo bağlantısı olsun.

### 3.5 Hız
- [ ] Sayfa önbelleğini aç. `/paketler/` sunucu cevabı 1,7–2,5 sn, ana sayfa 0,7 sn.
- [ ] Görsellerde `loading="lazy"` kullan ve görselleri doğru boyutta sun. `/paketler/` sayfasında 86 görsel var.
- [ ] Demo detayında önizleme iframe'ini ve bölüm küçük resimlerini geç yükle. Demo detayın ilk açılışı 5,7–12 sn sürüyor.
- [ ] Hedef: mobilde LCP < 2,5 sn. PageSpeed Insights ile ölç.

### 3.6 Otomatik test
- [ ] `tests/musteri-akisi.js` testini her yayın öncesinde ve haftada bir çalıştır. `SUBMIT=1` verilmezse sipariş göndermez.
- [ ] Test makinesinin IP'sini güvenlik duvarı izin listesine ekle. İzin listesi bot kontrolünü de atlamalı.

---

## Özet takvim

| Dönem | İşler |
|---|---|
| Bu hafta | 1.1 – 1.6: sipariş formu, toplam tutar, taksit, bozuk linkler, bot izin listesi |
| Bu ay | 2.1 – 2.6: demodan siparişe düzen aktarımı, dil, aday toplama, ölçüm, tutarlılık |
| Sürekli | 3.1 – 3.6: sosyal kanıt, yerel SEO, sektör sayfaları, blog, hız, otomatik test |
