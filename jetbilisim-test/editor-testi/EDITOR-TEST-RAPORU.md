# JET Core / Mimar Builder – Editör Tam Test (v1.0.44, 29.10.2026)

- Eleman tipi: 80 · Ayar testi: 2798/2894 doğru · İncelenen içerik: 36 sayfa, 18 yazı, 7 blok
- Test sayfaları (silinebilir): 602, 603, 604 (İletişim kopya), 605 (Paketler kopya). claude-test kullanıcısı silinmeli.

> **Durum (ara rapor):** Otomatik ayar testi 80 elemandan 60'ında tamamlandı; kalan 20 eleman (Yorumlar, Menü/Fiyat Listesi, Çevrilen Kutu, İçindekiler, Zaman Çizelgesi, CTA, Alıntı, Katmanlı slider, Dil Değiştirici, Breadcrumb, Google Yorumları, Instagram, TikTok, Logo, Menü, Sosyal İkonlar, Yan Panel, Son Yazılar, Paket demoları, Jet Büyüme) tabloda "test edilmedi" görünüyor.
> Sorunlu ayarlar sütunundaki `error`, `picker-not-found`, `cond-not-reached`, `tab-missing` sonuçlarının çoğu test düzeneğinin kontrolü bulamamasından kaynaklanıyor olabilir; henüz tek tek doğrulanmadı. `_content` için görülen `NOT-SAVED-TO-MODEL` sonucu ise doğrulandı ve **hata değil**: editör metni 0,3–0,5 sn gecikmeyle kaydediyor.
> Kısa kod listesi ve her elemanın panelde nerede olduğu için ayrıca **KISA-KOD-KILAVUZU.md** dosyasına bakın.

## Bulgular (yapılacaklar)

### 1. [KRITIK] Editör yetkisiyle kaydetme ve kopyalamada içerik sessizce siliniyor
- [ ] **Düzelt:** Sunucu bu rol için HTML/CSS'i temizliyorsa: (1) bu alanlar ve HTML/Kod elemanı bu role hiç gösterilmesin veya kilitli (salt okunur) gösterilsin; (2) kayıt sırasında mevcut HTML/CSS bloklarına dokunulmasın (yalnızca değiştirilen alanlar temizlensin); (3) bir şey silinecekse kaydetmeden önce "Şu 8 blok kaldırılacak" uyarısı çıksın; (4) Kopyala işlemi içeriği filtrelemeden birebir kopyalasın.
- **Sorun:** Bu kullanıcı rolüyle (claude-test) kaydedilen sayfalarda tüm HTML / Kod elemanları (içindeki style, script, iframe ile) ve tüm Gelişmiş → Özel CSS değerleri hiçbir uyarı olmadan siliniyor. Aynısı Kopyala işleminde de oluyor: İletişim sayfasının kopyasında 1 HTML elemanı kayboldu; Paketler sayfasının kopyası 69.322 → 36.258 karaktere düştü (8 HTML elemanı ve sekmeleri çalıştıran  etiketleri gitti). Bu yetkideki biri canlı bir sayfada tek bir başlığı düzeltip kaydederse aynı kayıp canlı sayfada yaşanır.

### 2. [KRITIK] Ham HTML içeren Metin bloklarında tek harf yazmak tasarımı yok ediyor
- [ ] **Düzelt:** Ham HTML içeren Metin blokları seçildiğinde zengin editör yerine uyarı + "Kod olarak düzenle" görünümü açılsın; ya da bu bloklar özel elemanlara (Paket demoları, Fiyat Paketleri, Sekmeler …) dönüştürülsün. Editör, tanımadığı etiket/sınıfları silmemeli (izin listesine class, div, label, input eklenmeli).
- **Sorun:** Yan paneldeki metin editörüne tek bir harf yazıldığında bloktaki 109 CSS sınıfı, 18 div, 7 label ve 8 stil siliniyor; tasarlanmış bölüm (ör. Paketler → "Paketlere göre örnek demolar" sekmeleri) düz metne dönüşüyor. Sadece seçmek güvenli; yazınca bozuluyor. Bu tür blok sitede çok yaygın (aşağıdaki tablo).

### 3. [YÜKSEK] Kısa kodlar panelin hiçbir yerinde görünmüyor
- [ ] **Düzelt:** Panelde "Kısa kodlar" ekranı: her kısa kod için ad, açıklama, parametreler (ör. anahtar=seo_pro, id=597), örnek, canlı önizleme, hangi sayfalarda kullanıldığı (bu rapordaki tablo gibi) ve tanımın bulunduğu dosya. Metin editörüne "Kısa kod ekle" düğmesi ve tuvalde kısa kodun üstüne gelince etiket ("[jet_demo_sayisi] → 213").
- **Sorun:** Sayfalarda 6 özel kısa kod kullanılıyor ([jet_eklenti], [jet_eklentiler], [jet_demo_sayisi], [mt_year], [mt_site_name], [mimar_block]). Editörün kodunda tanımları yok; Ctrl+K aramasında "kısa kod" sonuç vermiyor; Metin editöründe "kısa kod ekle" menüsü yok. Kullanıcı bunların ne yaptığını, nereden geldiğini ve hangi sayfada kullanıldığını göremiyor.

### 4. [YÜKSEK] Sayfaların büyük kısmı editörden düzenlenemeyen ham HTML
- [ ] **Düzelt:** En çok ziyaret alan sayfalardan başlayarak ham HTML bölümlerini editör elemanlarına dönüştürün (Ana Sayfa, Paketler, Referanslar). Yasal metinler için tablo destekli Metin elemanı yeterli; div/class temizlenirse amatör düzenleyebilir.
- **Sorun:** Ana Sayfa %68, Paketler %71, Sosyal Medya %77, Referanslar %72, Hosting %69, SEO Danışmanlığı %62; yasal sayfalar %85–97 oranında Metin/HTML elemanı içine yazılmış HTML. Bu içerikteki renk, boşluk, ikon, kart düzeni editör ayarlarıyla değiştirilemez; amatör kullanıcı ancak metni değiştirebilir (o da Kritik-2 nedeniyle riskli). Oysa editörde karşılığı olan özel elemanlar var (ör. "Paket demoları", "Fiyat Paketleri", "İkonlu Liste", "Sayaç") ama kullanılmamış.

### 5. [ORTA] Bazı temel ayarlar editörde yok (müdahale edilemeyen alanlar)
- [ ] **Düzelt:** Tüm url alanlarının yanına ortak bir “Bağlantı seçenekleri” kontrolü (yeni sekme, nofollow, sponsored, aria-label) ekleyin; Görsel Kutu'ya alt metin alanı ekleyin; global font/renk ayarlarının yerini editörde “Site ayarları → Yazı tipleri” bağlantısıyla gösterin.
- **Sorun:** Bağlantılarda nofollow / sponsored / rel seçeneği hiçbir elemanda yok. Görsel Kutu'da alternatif metin (alt) alanı yok. Yeni sekmede aç yalnızca Buton'da var; İkon, Görsel, Görsel Kutu, Eylem Kartı (CTA) butonları, Banner ve Slayt bağlantılarında yok. Sadece ikondan oluşan bağlantılar (İkon, Sosyal İkonlar, Video Butonu) için erişilebilirlik etiketi (aria-label) verilemiyor. Yazı tipi seçimi eleman bazında yalnızca “site başlık/metin fontu” ve 3 genel aile ile sınırlı (bu rol Özelleştir/global font ayarına erişemiyor).

### 6. [ORTA] Yan panelden Sil'den sonra Ctrl+Z çalışmıyor
- [ ] **Düzelt:** Kısayol dinleyicisi panel düğmesine odaklanılmışken de çalışsın (sadece input/textarea/contenteditable içindeyken devre dışı kalsın). Silme sonrası "Silindi – Geri al" bildirimi gösterin.
- **Sorun:** Elemanı paneldeki "Sil" düğmesiyle silip hemen Ctrl+Z'ye basınca hiçbir şey olmuyor (odak panelde kaldığı için). Üstteki Geri al düğmesi ve tuvale tıklayıp Ctrl+Z çalışıyor.

### 7. [ORTA] Başlık elemanında "çift tıklayarak yazın" ipucu çalışmıyor
- [ ] **Düzelt:** Başlık (ve Bölüm Başlığı, Buton metni) için satır içi düzenlemeyi açın ya da ipucunu kaldırın.
- **Sorun:** Başlık panelinde "İpucu: metni tuvalde çift tıklayarak doğrudan yazabilirsiniz" yazıyor ama başlıkta çift tıklama düzenleme açmıyor. Metin elemanında çalışıyor (✓, dışarı tıklama ve Esc ile değişiklik korunuyor).

### 8. [ORTA] Sürüm geçmişi ve otomatik kayıt yok
- [ ] **Düzelt:** Her kayıtta sürüm saklayın (son 20 sürüm, "Bu sürüme dön"), 60 sn'de bir yerel taslak, açılışta "Kaydedilmemiş taslağınız var" önerisi.
- **Sorun:** Editörde revizyon/geçmiş, otomatik kayıt veya taslak kurtarma yok. Yanlış bir kayıt (ör. Kritik-1) geri alınamaz; tarayıcı kapanırsa kaydedilmemiş iş kaybolur (çıkışta uyarı var, bu iyi).

### 9. [ORTA] "Yeni sayfa" tıklanınca boş kayıt hemen oluşuyor
- [ ] **Düzelt:** Kaydı ilk kaydetmede oluşturun ya da 24 saatte boş taslakları otomatik temizleyin.
- **Sorun:** Başlık girilmeden "Başlıksız" kayıt açılıyor; vazgeçilirse listede kalıyor (listede 2 gün önceden kalan "Başlıksız" taslak var).

### 10. [DÜŞÜK] AI Blog Yazarı'nda ham HTML görünüyor
- [ ] **Düzelt:** Çıktıyı escape etmeden link olarak basın.
- **Sorun:** "Önce yapay zekâyı ayarlayın: Ayarlar → Yapay zekâ" metni link yerine kod olarak görünüyor.

### 11. [DÜŞÜK] Medya penceresinin arka planı yarı saydam
- [ ] **Düzelt:** Pencereye opak arka plan verin.
- **Sorun:** Görsel seç penceresi açıkken arkadaki sayfa önizlemesi pencerenin içinden görünüyor (arama kutusunun ve Kullan düğmesinin üstünde yazılar). Tıklama çalışıyor ama okunurluk düşük.

### 12. [DÜŞÜK] Sayfa içine gömülü <style> ve <script>
- [ ] **Düzelt:** Ortak CSS'i tema/"Özel CSS" ayarına, JS'yi tema dosyasına taşıyın; sayfaya özel kodu tek bir "Sayfa kodu" alanında toplayın.
- **Sorun:** 23 içerikte , 9 içerikte  var (sayfa içi CSS/JS). Bunlar Kritik-1 nedeniyle bu rolde kayıtta siliniyor; ayrıca hangi sayfanın hangi CSS'e bağlı olduğu görünmüyor.

## Özel kısa kodlar (panelde görünmüyor)

| Kısa kod | Ne yapar | Tanım / panel | Kullanıldığı yer |
|---|---|---|---|
| `[jet_eklenti]` | Eklenti sayfasındaki fiyat/özellik kutusu (anahtar="seo_pro", "ai" …) | Sunucu tarafı (tema/eklenti PHP). Panelde listesi ve düzenleme ekranı yok. | Site Kit: ölçüm ve çerez onayı, +SEO ve yapay zekâ görünürlüğü, Sosyal akışlar, Ürün XML akışları, Ek ürün kapasitesi, Excel / CSV aktarımı … |
| `[jet_eklentiler]` | Tüm eklentilerin listesi | Sunucu tarafı. Panelde yok. | Eklentiler |
| `[jet_demo_sayisi]` | Canlı demo sayısını (213) yazar | Sunucu tarafı. Panelde yok. | Paketler, Demolar, Güven şeridi |
| `[mt_year]` | Bulunulan yılı yazar (© 2026) | Tema kısa kodu. Panelde yok; yalnızca şablon metinlerinde geçiyor. | Footer – Jet Bilişim |
| `[mt_site_name]` | Site adını yazar | Tema kısa kodu. Panelde yok. |  |
| `[mimar_block]` | Bloklar ekranındaki bir bloğu (id) sayfaya gömer | Editörde "Blok" elemanı ile seçilebilir; ama Metin içine elle yazılmış hali (Paketler, Ana Sayfa) görünmez. | Paketler, Ana Sayfa |

## Ham HTML oranı

| İçerik | Oran | Blok |
|---|---|---|
| Hizmet Sözleşmesi | %97 | 1 |
| KVKK Aydınlatma Metni | %93 | 1 |
| Güven şeridi | %92 | 1 |
| İptal, İade ve Teslimat Koşulları | %89 | 1 |
| Ön Bilgilendirme Formu | %87 | 1 |
| Kullanım Koşulları | %85 | 1 |
| Çerez Politikası | %83 | 1 |
| Sosyal Medya Yönetimi | %77 | 7 |
| Gizlilik Politikası | %77 | 1 |
| Referanslar | %72 | 2 |
| Paketler | %71 | 8 |
| Hosting ve Bakım | %69 | 4 |
| Ana Sayfa | %68 | 7 |
| SEO Danışmanlığı | %62 | 3 |
| Footer – Jet Bilişim | %50 | 3 |
| Jet Büyüme – Aylık Bakım, Sosyal Medya, SEO ve Google Ads Paketleri | %37 | 2 |
| Hakkımızda | %11 | 2 |
| Hizmetler | %10 | 1 |
| Google Ads | %7 | 1 |

## Editör elemanları ve kısa kodları

| Kısa kod | Eleman | Kategori | Doğru ayar | Sorunlu ayarlar | Kullanım |
|---|---|---|---|---|---|
| [mb_mega_links] | Menü bağlantıları | Mega menü | 48/48 | — | — |
| [mb_mega_tabs] | Dikey sekmeler (mega) | Mega menü | 47/47 | — | — |
| [mb_mega_tab] | Sekme (mega) | Mega menü | 47/47 | — | — |
| [mb_mega_posts] | Son yazılar (menü) | Mega menü | 49/50 | columns (error) | — |
| [mb_mega_tiles] | Görsel ızgara (menü) | Mega menü | 46/46 | — | Mega menü – Demolar, Mega menü – Hizmetler |
| [mb_block] | Blok | Gelişmiş | 41/41 | — | — |
| [mb_form] | Form | İçerik | 49/49 | — | İletişim, SEO Analiz Raporu |
| [mb_field] | Form Alanı | İçerik | 4/8 | - (tab-missing); choices (cond-not-reached); placeholder (error) | SEO Analiz Raporu ×6, İletişim ×5 |
| [mb_section] | Bölüm | Yerleşim | 46/69 | bg_fixed (cond-not-reached); bg_fx (error); bg_fx_c1 (cond-not-reached); bg_fx_c2 (cond-not-reached); bg_fx_c3 (cond-not-reached); bg_fx_opacity (cond-not-reached); bg_fx_speed (cond-not-reached); bg_image (picker-not-found); bg_pos (cond-not-reached); bg_size | Ana Sayfa ×12, Sosyal Medya Yönetimi ×12, Paketler ×11, Tuzla Web Tasarım ×9, Hosting ve Bakım ×8, SEO Danışmanlığı ×8 … |
| [mb_row] | Satır | Yerleşim | 58/58 | — | Ana Sayfa ×22, Paketler ×21, Sosyal Medya Yönetimi ×17, Hosting ve Bakım ×13, SEO Danışmanlığı ×13, Tuzla Web Tasarım ×13 … |
| [mb_col] | Sütun | Yerleşim | 53/54 | span (unhandled) | Ana Sayfa ×29, Google Ads ×26, Tuzla Web Tasarım ×25, Hizmetler ×24, SEO Analiz Raporu ×24, Paketler ×22 … |
| [mb_scrolly] | Kaydırmalı anlatım | Yerleşim | 51/51 | — | — |
| [mb_scrolly_step] | Anlatım adımı | Yerleşim | 45/48 | _content (NOT-SAVED-TO-MODEL); image (picker-not-found); video (picker-not-found) | — |
| [mb_heading] | Başlık | İçerik | 59/59 | — | SEO Analiz Raporu ×12, Tuzla Web Tasarım ×11, Gebze OSB Web Tasarım ×11, Google Ads ×11, Hizmetler ×10, Paketler ×6 … |
| [mb_text] | Metin | İçerik | 52/53 | _content (NOT-SAVED-TO-MODEL) | Paketler ×30, Tuzla Web Tasarım ×16, Gebze OSB Web Tasarım ×15, Google Ads ×10, SEO Danışmanlığı ×9, SEO Analiz Raporu ×9 … |
| [mb_button] | Buton | İçerik | 58/58 | — | Ana Sayfa ×10, Paketler ×7, Tuzla Web Tasarım ×5, SEO Danışmanlığı ×4, Gebze OSB Web Tasarım ×4, Jet Büyüme – Aylık Bakım, Sosyal Medya, SEO ve Google Ads Paketleri ×3 … |
| [mb_spacer] | Boşluk | İçerik | 40/41 | - (tab-missing) | Paketler ×24, Ana Sayfa ×12, Sosyal Medya Yönetimi ×9, SEO Analiz Raporu ×6, Hosting ve Bakım ×5, SEO Danışmanlığı ×5 … |
| [mb_divider] | Ayraç | İçerik | 45/45 | — | Footer – Jet Bilişim |
| [mb_html] | HTML / Kod | İçerik | 41/41 | — | Paketler ×8, Ana Sayfa ×7, Sosyal Medya Yönetimi ×7, Hosting ve Bakım ×4, SEO Danışmanlığı ×3, Jet Büyüme – Aylık Bakım, Sosyal Medya, SEO ve Google Ads Paketleri ×3 … |
| [mb_iconbox] | Özellik Kutusu | İçerik | 51/54 | _content (NOT-SAVED-TO-MODEL); align (error); image (picker-not-found) | Google Ads ×10, Demolar ×9, Ana Sayfa ×6, Tuzla Web Tasarım ×6, Gebze OSB Web Tasarım ×6, SEO Analiz Raporu ×6 … |
| [mb_accordion] | Akordeon | İçerik | 42/42 | — | Hosting ve Bakım, Paketler, SEO Danışmanlığı, Jet Büyüme – Aylık Bakım, Sosyal Medya, SEO ve Google Ads Paketleri, Sosyal Medya Yönetimi, Tuzla Web Tasarım … |
| [mb_accordion_item] | Akordeon Maddesi | İçerik | 43/43 | — | Paketler ×10, Jet Büyüme – Aylık Bakım, Sosyal Medya, SEO ve Google Ads Paketleri ×7, SEO Analiz Raporu ×6, Hosting ve Bakım ×5, SEO Danışmanlığı ×5, Sosyal Medya Yönetimi ×5 … |
| [mb_image] | Görsel | Medya | 55/56 | image (picker-not-found) | Ana Sayfa ×5, Demolar ×5, Paketler ×3, Footer – Jet Bilişim ×2, Hosting ve Bakım, Sosyal Medya Yönetimi … |
| [mb_video] | Video | Medya | 48/50 | poster (picker-not-found); url (picker-not-found) | — |
| [mb_gallery] | Galeri | Medya | 53/56 | images (picker-not-found); ratio (error); row_height (cond-not-reached) | Referanslar |
| [mb_slider] | Slider | Medya | 52/59 | arrows_type (error); dots_type (error); gap (cond-not-reached); interval (error); pause_hover (error); per_view (error); progress (error) | — |
| [mb_slide] | Slayt | Medya | 47/55 | bg_image (picker-not-found); bg_video (picker-not-found); st_bg_h (error); st_border_color_h (error); st_color_h (error); st_duration (error); st_effect (error); st_shadow_h (error) | — |
| [mb_tabs] | Sekmeler | İçerik | 43/43 | — | Paketler |
| [mb_tab] | Sekme | İçerik | 42/42 | — | Paketler ×4 |
| [mb_icon] | İkon | İçerik | 47/47 | — | — |
| [mb_iconlist] | İkonlu Liste | İçerik | 48/49 | columns (error) | Hosting ve Bakım, Ana Sayfa, Sosyal Medya Yönetimi, Google Ads, Footer – Jet Bilişim |
| [mb_banner] | Banner | Yerleşim | 55/56 | image (picker-not-found) | — |
| [mb_counter] | Sayaç | Kurumsal | 54/54 | — | — |
| [mb_logos] | Logo Şeridi | Medya | 46/48 | images (picker-not-found); speed (error) | — |
| [mb_team] | Ekip Üyesi | Kurumsal | 49/51 | _content (NOT-SAVED-TO-MODEL); image (picker-not-found) | — |
| [mb_price] | Fiyat Tablosu | Kurumsal | 51/51 | — | Paketler ×10, SEO Analiz Raporu ×3 |
| [mb_map] | Harita | Medya | 49/50 | map_type (error) | İletişim |
| [mb_testimonial] | Müşteri Yorumu | Kurumsal | 47/48 | image (picker-not-found) | — |
| [mb_countdown] | Geri Sayım | Kurumsal | 46/46 | — | — |
| [mb_progress] | İlerleme Çubukları | Kurumsal | 44/44 | — | — |
| [mb_portfolio] | Proje Galerisi | Kurumsal | 55/62 | all_label (error); all_show (error); tab_count (error); tab_default (error); tab_hash (error); tab_scroll (error); tabs (unhandled) | — |
| [mb_portfolio_item] | Proje | Kurumsal | 9/11 | - (tab-missing); image (picker-not-found) | — |
| [mb_title] | Bölüm Başlığı | İçerik | 60/60 | — | Sosyal Medya Yönetimi ×9, Ana Sayfa ×8, Paketler ×7, Tuzla Web Tasarım ×7, SEO Danışmanlığı ×6, Gebze OSB Web Tasarım ×6 … |
| [mb_videobutton] | Video Butonu | Medya | 48/48 | — | — |
| [mb_imagebox] | Görsel Kutu | Medya | 53/54 | image (picker-not-found) | Hizmetler ×6 |
| [mb_bannergrid] | Banner Izgarası | Yerleşim | 45/45 | — | — |
| [mb_message] | Uyarı Kutusu | İçerik | 45/45 | — | — |
| [mb_search] | Arama Kutusu | İçerik | 45/45 | — | — |
| [mb_hotspot] | İşaretli Görsel | Medya | 44/45 | image (picker-not-found) | — |
| [mb_hotspot_pin] | İşaret | Medya | 10/11 | - (tab-missing) | — |
| [mb_share] | Paylaş Butonları | İçerik | 44/44 | — | — |
| [mb_marquee] | Kayan Şerit | Yerleşim | 62/70 | font_size (cond-not-reached); italic (cond-not-reached); items (error); link (error); pill (cond-not-reached); text_style (cond-not-reached); uppercase (cond-not-reached); weight (cond-not-reached) | — |
| [mb_compare_img] | Önce / Sonra | Medya | 52/54 | after (picker-not-found); before (picker-not-found) | — |
| [mb_badge_circle] | Dönen Rozet | Medya | 58/60 | icon (error); image (picker-not-found) | — |
| [mb_spec] | Teknik Tablo | Kurumsal | 56/56 | — | — |
| [mb_docs] | Belgeler / Katalog | Kurumsal | 52/52 | — | — |
| [mb_doc] | Belge | Kurumsal | 11/13 | thumb (picker-not-found); valid (error) | — |
| [mb_pricing] | Fiyat Paketleri | Kurumsal | 49/53 | discount (error); label_a (error); label_b (error); start_b (error) | — |
| [mb_price_plan] | Fiyat Paketi | Kurumsal | 56/56 | — | — |
| [mb_compare_table] | Karşılaştırma Tablosu | Kurumsal | 53/53 | — | — |
| [mb_testimonials] | Yorumlar (Kaydırmalı / Duvar) | Kurumsal | test edilmedi | — | — |
| [mb_pricelist] | Menü / Fiyat Listesi | Kurumsal | test edilmedi | — | — |
| [mb_flipbox] | Çevrilen Kutu | İçerik | test edilmedi | — | — |
| [mb_toc] | İçindekiler | İçerik | test edilmedi | — | — |
| [mb_timeline] | Zaman Çizelgesi | Kurumsal | test edilmedi | — | — |
| [mb_cta] | Eylem Kartı (CTA) | İçerik | test edilmedi | — | — |
| [mb_quote] | Alıntı | İçerik | test edilmedi | — | — |
| [mb_layerslider] | Katmanlı slider | Medya | test edilmedi | — | Ana Sayfa |
| [mb_lang_switcher] | Dil Değiştirici | İçerik | test edilmedi | — | — |
| [mb_breadcrumb] | Konum yolu (breadcrumb) | Site | test edilmedi | — | — |
| [mb_google_reviews] | Google Yorumları | Sosyal | test edilmedi | — | — |
| [mb_instagram_feed] | Instagram Akışı | Sosyal | test edilmedi | — | — |
| [mb_tiktok_feed] | TikTok Akışı | Sosyal | test edilmedi | — | — |
| [mb_logo] | Logo | Site | test edilmedi | — | Header – Jet Bilişim |
| [mb_menu] | Menü | Site | test edilmedi | — | Footer – Jet Bilişim ×3, Header – Jet Bilişim |
| [mb_social] | Sosyal İkonlar | Site | test edilmedi | — | İletişim |
| [mb_offcanvas] | Yan Panel | Site | test edilmedi | — | — |
| [mb_posts] | Son Yazılar | Site | test edilmedi | — | Ana Sayfa, Blog |
| [mb_paket_demolari] | Paket demoları | Jet | test edilmedi | — | — |
| [mb_jet_buyume] | Jet Büyüme paketleri | Jet | test edilmedi | — | Paketler, Jet Büyüme – Aylık Bakım, Sosyal Medya, SEO ve Google Ads Paketleri |

## Kullanım akışları

| Test | Sonuç | Not |
|---|---|---|
| Geri al / Yinele (Ctrl+Z / Ctrl+Y) | ✅ |  |
| Kopyala / yapıştır (Ctrl+C / V) | ✅ |  |
| Çoğalt (Ctrl+D) | ✅ |  |
| Mobil için ayrı değer (ör. yazı boyutu 40 / mobil 22) | ✅ | size / size__sm ayrı saklanıyor |
| Stili kopyala / yapıştır | ✅ |  |
| Komut paleti ile eleman ekleme (Ctrl+K) | ✅ |  |
| Şablon kütüphanesi (230 bölüm, 776 sayfa şablonu) → Ekle | ✅ |  |
| Pencereyi Esc ile kapatma | ✅ |  |
| Yeni sekmede önizleme (kaydedilmemiş değişikliklerle) | ✅ |  |
| Sil + üstteki Geri al düğmesi | ✅ |  |
| Sil + paneldeyken Ctrl+Z | ❌ | odak panelde kalınca kısayol çalışmıyor |
| Metin: tuvalde çift tıklayıp yazma (✓ / dışarı tıklama / Esc) | ✅ | üç yolla da korunuyor |
| Başlık: tuvalde çift tıklayıp yazma | ❌ | ipucu var, özellik yok |
| Katman taşıma (Alt + ↑/↓, tuval ve Katmanlar paneli) | ✅ |  |
| Tuval ↔ model uyumu (sil / geri al / yinele) | ✅ |  |
| Kaydetmeden çıkış uyarısı (kodda var) | ✅ | “Kaydedilmemiş değişiklikler var…” |
| Sürüm geçmişi / otomatik kayıt | ❌ | yok |
| Ham HTML Metin bloğunu sadece seçmek | ✅ | içerik değişmiyor |
| Ham HTML Metin bloğuna tek harf yazmak | ❌ | yapı siliniyor |
| Kayıt sonrası Özel CSS ve HTML/Kod korunuyor mu | ❌ | bu rolde siliniyor |
| Kopyala ile sayfa birebir kopyalanıyor mu | ❌ | HTML ve form etiketleri siliniyor |