# JET Core / Mimar Builder – Editör Testi: Hata ve Kullanım Sorunları İş Listesi

- **Sürüm:** JET Core v1.0.44 · Mimar Builder 1.3.0
- **Tarih:** 29.10.2026
- **Test eden:** Claude, `claude-test` kullanıcısıyla. Rolü yönetici değil.
- **Kapsam:**
  - 80 eleman tipi
  - 3874 ayar gerçek arayüzden değiştirildi
  - 61 içerik incelendi (36 sayfa, 18 yazı, 7 blok)
  - Kullanım akışları, kaydet → yeniden aç karşılaştırması
- **Canlı içerik değiştirilmedi.** Testler test sayfalarında yapıldı: 602, 603, 604 (İletişim kopyası), 605 (Paketler kopyası). Bu dört taslak ve `claude-test` kullanıcısı test bitince silinmeli.

## Özet (ne kesin, ne değil)

**Kesin ve tekrar üretilebilen hatalar:**
- **BUG-01** · Kayıtta HTML/Kod elemanı ve Özel CSS siliniyor.
  - Kaydet → yeniden aç karşılaştırmasında 150 elemandan yalnızca `mb_html` kayboldu.
  - 67 elemanın tamamında `x_css` silindi.
  - Bunun dışında **hiçbir değer değişmedi.**
- **BUG-02** · Sayfa kopyalama içerik siliyor.
- **BUG-03** · Ham HTML'li Metin bloğunda tek harf tasarımı siliyor ve Geri al bunu düzeltemiyor.
- **UX-01** · Panelden Sil'den sonra Ctrl+Z çalışmıyor (3/3 tekrar).
- **UX-02** · Başlıkta çift tıklayarak yazma çalışmıyor.

**Ayar paneli:**
- 3874 ayardan 3760'ü otomatik testte ilk seferde doğrulandı.
- Otomatik testin doğrulayamadığı kalemlerden **19 temsili örnek elle denendi**; hepsi doğru çalıştı. Bu örnekler slider, buton grubu, anahtar, liste, renk, metin, tekrarlayıcı, görsel seçici ve koşullu alan türlerini kapsıyor.
- **Ayar panelinde değeri modele yazmayan bir kontrol bulunmadı.**
- Otomatik testin takıldığı yerler test aracının sınırlarıydı: hazır düzen seçimi, koşullu alanlar ve değişen panel yapısı.

**Eksik özellikler (FEAT) ve kullanım zorlukları (UX):** ölçüme dayalı. Ayrıntıları aşağıda.

## Nasıl kullanılır

Bu dosya bir iş listesidir. Her madde tek başına uygulanabilir. Sıra önceliğe göredir.

Her madde şu bölümlerden oluşur:
- **Kod yeri:** Hatanın bulunduğu dosya ve satır. Satırlar JET Core v1.0.44 ve Mimar Builder 1.3.0 sürümüne göredir.
- **Tekrar üret:** Hatayı görmek için izlenecek adımlar.
- **Beklenen:** Doğru davranış.
- **Kabul testi:** Düzeltmenin bitmiş sayılması için geçmesi gereken kontroller.

Sunucu tarafı (PHP) kodu bu testte görülemedi. PHP kaynaklı maddelerde olası yer tarif edilmiştir.

Test ortamı:
- Kullanıcı: `claude-test`. Rolü yönetici değil. Menüsünde Özelleştir ve Ayarlar yok.
- Test sayfaları: `post=602` ve `post=603`.
- Kopyalar: `604` (İletişim), `605` (Paketler).

---

## P0 – Veri kaybı (önce bunlar)

### BUG-01 · Yönetici olmayan rolde kayıt, HTML/Kod elemanlarını ve Özel CSS'i sessizce siliyor
- **Kod yeri:** Sunucu tarafı. `mimar_save` ajax işleyicisi. Muhtemelen rol yetkisi `unfiltered_html` olmayan kullanıcılar için kısa kod içeriğini/özniteliklerini temizleyen filtre (kses benzeri). İstemci: `editor.js:1472` `save()` → `ajax('mimar_save', …)`.
- **Tekrar üret:**
  1. `claude-test` ile giriş yap.
  2. Test sayfasında `</>` (Kod: içe / dışa aktar) penceresine aşağıdaki kodu yapıştır.
  3. "Sayfayı değiştir" de, Ctrl+S ile kaydet.
  4. Sayfayı yeniden aç.
  ```
  [mb_section][mb_row][mb_col]
  [mb_heading text="A" x_css="selector{color:red}"]
  [mb_heading text="B" x_css="color:blue"]
  [mb_html]<div id="h1">html</div><style>.x{color:red}</style><script>window.__t=1</script>[/mb_html]
  [/mb_col][/mb_row][/mb_section]
  ```
- **Gerçekleşen:**
  - Bütün `x_css` öznitelikleri silindi.
  - `[mb_html]` elemanı içeriğiyle birlikte tamamen kayboldu.
  - Hiçbir uyarı veya bildirim çıkmadı.
- **Neden kritik:** Bu roldeki biri canlı bir sayfada (Ana Sayfa'da 7, Paketler'de 8 HTML elemanı var) tek bir başlığı düzeltip kaydederse, o sayfadaki bütün HTML blokları ve özel CSS kaybolur.
- **Beklenen (ikisinden biri):**
  - **(a)** Kullanıcının **değiştirmediği** mevcut `mb_html` ve `x_css` içeriği kayıtta olduğu gibi korunur. Sadece bu kullanıcının yeni girdiği veya değiştirdiği değer temizlenir.
  - **(b)** Bu roldeki kullanıcıya HTML/Kod elemanı ve Özel CSS alanı salt okunur gösterilir. Alanda "Bu alanı yalnızca yönetici değiştirebilir" yazar. Eleman paletten eklenemez.
  - Her iki durumda da bir şey temizlenecekse kayıttan önce bir onay penceresi çıkar. Örnek: "3 HTML bloğu ve 2 özel CSS kaldırılacak. Devam?"
- **Kabul testi:**
  - Yönetici, `mb_html` + `x_css` içeren bir sayfa oluşturur.
  - Editör rolü aynı sayfada yalnızca bir başlık metnini değiştirip kaydeder.
  - Kayıttan sonra `mb_html` ve `x_css` birebir aynı kalır. Bayt bayt karşılaştırma yapılır.

### BUG-02 · "Kopyala" (sayfa çoğaltma) içeriği filtreleyerek kopyalıyor
- **Kod yeri:** Sunucu tarafı. `admin/index.php?p=pages&do=duplicate&id=…` işleyicisi. Kopyalanan içerik, kopyalayan kullanıcının yetkisine göre temizleniyor gibi görünüyor.
- **Tekrar üret:** `claude-test` ile Sayfalar listesinden şu iki sayfayı "Kopyala" ile çoğalt:
  - İletişim (`id=4`)
  - Paketler (`id=28`)
- **Gerçekleşen:**
  - İletişim: orijinalde 1 `[mb_html]` var, kopyada 0. İçerik 3.658 → 3.376 karakter.
  - Paketler: içerik 69.322 → 36.258 karakter.
    - 8 `[mb_html]` silindi.
    - `mb_text` içindeki `<input>` etiketleri silindi. "Paketlere göre örnek demolar" sekmeleri bu yüzden çalışmıyor.
- **Beklenen:** Kopyalama, kaynak içeriği **olduğu gibi** kopyalar (yalnızca başlık "(kopya)" ve durum "taslak" olur).
- **Kabul testi:** Aynı sayfa, kopyalanan sayfayla `post_content` üzerinden birebir aynı (başlık/slug hariç), her iki rol için.

### BUG-03 · Ham HTML içeren Metin bloklarında yan panel editörüne tek harf yazmak bütün yapıyı siliyor
- **Kod yeri:** `admin/assets/writer.js`
  - `:128` `CLASS_OK = /^(align…|mt-[a-z0-9-]+|size-[a-z]+)$/`: `mtpk-…`, `mtx-…` gibi sınıflar `mt-` ile başlamadığı için siliniyor.
  - `:142` `input`, `button`, `svg`, `form` etiketleri tamamen kaldırılıyor.
  - `:190` `mt-box`, `mt-embed` ya da `mt-cols` sınıfı olmayan bütün `DIV`'ler `P`'ye çevriliyor veya açılıyor.
  - `:135` `cleanHTML(html, false)`, normal düzenlemede de bu kuralları uyguluyor.
  - Çağıran: `admin/assets/richtext.js:103`, `:159`, `:196` (`clean(area.innerHTML)`) ve `writer.js:425`.
- **Tekrar üret:**
  1. Paketler kopyasını (605) aç.
  2. "Paketlere göre örnek demolar" Metin bloğunu seç.
  3. Sol paneldeki metin editöründe ilk başlığa tıklayıp bir harf yaz.
- **Gerçekleşen:** Blok içeriği:
  - `class=` sayısı 109 → 0
  - `<div` 18 → 0
  - `<label` 7 → 0
  - `style=` 8 → 0

  Tasarım düz metne dönüşüyor. Yalnızca bloğu seçmek içeriği değiştirmiyor; bozulma ilk tuşta başlıyor.
- **Beklenen:**
  - **(a)** Editör içeriği açarken, temizleyicinin silebileceği yapı içeriyor mu diye kontrol etsin. Sınıf, div, input, svg, data-* öznitelikleri böyle yapılardır. Bu durumda zengin editörü açmasın. Bunun yerine "Bu blok özel HTML içeriyor. Kod görünümünde düzenleyin" uyarısıyla kod görünümünü (`HTML` düğmesi) açsın.
  - **(b)** Ya da normal düzenlemede (`paste=false`) yalnızca güvenlik temizliği yapılsın: script, on*, javascript: kaldırılsın. Sınıf ve yapı korunsun.
- **Ek doğrulama (orijinal içerikle, kaydetmeden):** Paketler sayfasının orijinal bloğu test sayfasına kod olarak alındı (input 7, label 7, class 116, div 18). Tek harf yazılınca hepsi **0** oldu. **Ne yan editörün kendi Geri al'ı ne de üstteki Geri al bu kaybı geri getiriyor.** Amatör kullanıcı hatasını kendi başına düzeltemez.
- **Kabul testi:**
  - Paketler (orijinal) içeriğindeki her Metin bloğunda bir harf ekleyip silince içerik birebir aynı kalır. Fark yalnızca eklenen harf olur.
  - İlk tuştan önceki hal, üstteki Geri al ile tek adımda geri gelir.

---

## P1 – Kullanıcının göremediği / değiştiremediği şeyler

### FEAT-01 · Kısa kodlar panelde listelenmiyor
- **Durum:**
  - Sayfalarda şu sunucu tarafı kısa kodlar kullanılıyor: `[jet_eklenti anahtar="…"]`, `[jet_eklentiler]`, `[jet_demo_sayisi]`, `[mt_year]`, `[mt_site_name]`, `[mimar_block id="…"]`.
  - Bunlar `editor.js`'de tanımlı değil.
  - Ctrl+K komut aramasında "kısa kod" sonuç vermiyor.
  - Metin editöründe "kısa kod ekle" yok.
  - Hangi sayfada kullanıldıkları görülemiyor.
- **İstenen:**
  1. **Yönetim → Kısa kodlar sayfası.** PHP tarafında kayıtlı tüm kısa kodlar listelenir. Her biri için şunlar gösterilir:
     - ad ve açıklama
     - parametreler (ad, tür, varsayılan, izin verilen değerler; örn. `anahtar`: seo_pro, coklu_dil, ai, sosyal, sitekit, canli_takip, katalog_pro, toplu_aktarim, urun_akislari, ek_urun)
     - örnek kullanım
     - canlı önizleme (sunucuda render edilmiş çıktı)
     - tanımın bulunduğu dosya ve fonksiyon
     - **kullanıldığı sayfalar** (`post_content` içinde arama, bağlantılı liste)
  2. **Metin editörü araç çubuğuna "Kısa kod ekle" menüsü.** Kısa kod seçilir, parametre formu doldurulur, ekle denir.
  3. **Tuvalde rozet.** Kısa kodun render edildiği yerin üstüne gelince küçük bir etiket çıkar. Örnek: `[jet_demo_sayisi] → 213`.
  4. **Komut paletinde arama.** Ctrl+K'da "kısa kod" ve kısa kod adlarıyla arama yapılabilir.
- **Kabul testi:** `[jet_demo_sayisi]` arandığında Ana Sayfa, Paketler, Demolar ve "Güven şeridi" bloğu listelenir. Tıklanınca ilgili sayfanın editörü açılır.

### FEAT-02 · Bağlantı ayarları eksik
- **Durum:**
  - `nofollow` / `sponsored` / `rel` seçeneği hiçbir elemanda yok. 80 elemanın tanımında bu kelimeler hiç geçmiyor.
  - "Yeni sekmede aç" yalnızca Buton ve Görsel'de var.
  - İkon (`link`), Görsel Kutu (`link`), Eylem Kartı (`btn_url`, `btn2_url`), Banner (`link`), Slayt (`link`) ve diğer `type:url` alanlarında yok.
  - Sadece ikondan oluşan bağlantılarda `aria-label` verilemiyor: İkon, Sosyal İkonlar, Video Butonu. Tanımlarda `aria` kelimesi hiç geçmiyor. Render tarafında otomatik ekleniyor olabilir; bu ayrıca kontrol edilmeli.
- **İstenen:** Ortak bir `link` kontrolü. Seçenekler: URL, yeni sekme, nofollow, sponsored, erişilebilir ad (aria-label). Bütün `type:url` alanlarında bu kontrol kullanılsın; `editor.js` `controls.url` genişletilsin.
- **Kabul testi:** Her bağlantılı elemanda bu 4 seçenek görünür. Render'da `target="_blank" rel="noopener nofollow sponsored"` ve `aria-label` doğru basılır.

### FEAT-03 · Görsel Kutu'da alt metin alanı yok
- **Kod yeri:** `MimarData.elements.mb_imagebox.options`. Görsel'deki (`mb_image`) `alt` alanının benzeri eklenmeli.
- **Kabul testi:** Alt metin girilince render edilen `<img alt="…">` doğru gelir.

### FEAT-04 · Sayfaların büyük kısmı editör ayarlarıyla düzenlenemeyen ham HTML (içerik işi)
- **Durum:** Metin/HTML elemanı içine yazılmış ham HTML oranları:

  | Sayfa | Ham HTML oranı |
  |---|---|
  | Ana Sayfa | %68 |
  | Paketler | %71 |
  | Sosyal Medya | %77 |
  | Referanslar | %72 |
  | Hosting | %69 |
  | SEO Danışmanlığı | %62 |
  | Yasal sayfalar | %85–97 |

  Tam tablo aşağıda. Editörde karşılığı olan elemanlar kullanılmamış: `[mb_paket_demolari]`, `[mb_pricing]`, `[mb_counter]`, `[mb_iconlist]`, `[mb_tabs]` vb.
- **İstenen:** En çok ziyaret alan sayfalardan başlayarak (Ana Sayfa, Paketler, Referanslar) ham HTML bölümlerini editör elemanlarıyla yeniden kurmak. Örnek: Paketler'deki "Paketlere göre örnek demolar" bloğu için `[mb_paket_demolari]` elemanı kullanılmalı. Sayfaya gömülü `<style>` (23 içerik) ve `<script>` (9 içerik) tema CSS/JS dosyasına taşınmalı.
- **Kabul testi:** Bu sayfalarda ham HTML oranı %10'un altına iner.

---

## P2 – Kullanım zorlukları

### UX-01 · Paneldeki "Sil" düğmesinden sonra Ctrl+Z çalışmıyor (3/3 tekrar üretildi)
- **Kök neden:**
  - Panelden "Sil" yapılınca seçim kalkıyor ve sol panel "Ekle" görünümüne dönüyor.
  - Klavye odağı (`document.activeElement`) **"Eleman ara…" arama kutusuna** (`input.mb-input.mb-search`) geçiyor.
  - `editor.js:1279` satırındaki `typing` kontrolü bunu "kullanıcı yazı yazıyor" sayıyor.
  - `:1292` satırındaki `if (typing) return;` Ctrl+Z'yi yok sayıyor.
  - Silme düğmesinin ipucu ise "Ctrl+Z ile geri alınabilir" diyor (`:1892`).
- **Tekrar üret:**
  1. Tuvalde bir başlığa tıkla.
  2. Sol paneldeki "Sil"e bas.
  3. Ctrl+Z'ye bas.

  Sonuç: eleman geri gelmiyor. Üstteki Geri al düğmesi çalışıyor.
- **Beklenen:**
  - Silme veya panel değişiminden sonra odak arama kutusuna otomatik verilmesin. Ya da `onKey`, arama kutusu boşken Ctrl+Z/Ctrl+Y'yi editöre iletsin.
  - Silme sonrası "Silindi · Geri al" bildirimi (toast) gösterilsin.
- **Kabul testi:**
  - Panelden Sil → Ctrl+Z ile eleman 3/3 denemede geri gelir.
  - Aynı test Delete tuşu, sağ tık menüsü ve Katmanlar panelinden silme için de tekrarlanır.

### UX-02 · Başlık'ta "çift tıklayarak yazın" ipucu var ama satır içi düzenleme açılmıyor
- **Kod yeri:**
  - İpucu `editor.js:1933` (`hasInline(n)` doğruysa basılıyor).
  - Çift tıklama `:4597` `onCanvasDblClick()`. Bu fonksiyon `[data-mb-inline]` arıyor.
  - Tuvalde başlığın HTML'i: `<h2 class="mb-heading mb-el …" data-mb-id="…">`. `data-mb-inline` özniteliği **yok**.
  - Metin elemanında var (`mb-inline-wrap`).
- **Beklenen:** `mb_heading` (ve `mb_title`, `mb_button` metni) sunucu render şablonunda metin düğümüne `data-mb-inline` eklensin. Ya da ipucu yalnızca `ownInline()` gerçekten bir alan bulduğunda gösterilsin.
- **Kabul testi:**
  - Tuvalde başlığa çift tıkla, yaz, dışarı tıkla. `attrs.text` güncellenir.
  - ✓ düğmesi, dışarı tıklama ve Esc'nin üçü de çalışır. Metin elemanında bu üç yol zaten çalışıyor.

### UX-03 · Sürüm geçmişi ve otomatik kayıt yok
- **Durum:** `editor.js`'de revizyon ya da otomatik kayıt yok. Kaydetmeden çıkış uyarısı var (`beforeunload` ve Çıkış düğmesinde `confirm`), bu iyi.
- **İstenen:**
  - Her `mimar_save` çağrısında önceki içerik revizyon olarak saklansın (son 20).
  - Editörde "Geçmiş" penceresi olsun: tarih, kullanıcı, fark, "Bu sürüme dön".
  - 60 saniyede bir `localStorage`'a taslak yazılsın. Açılışta "Kaydedilmemiş taslağınız var: geri yükle / yok say" sorulsun.
- **Kabul testi:** BUG-01 gibi bir veri kaybından sonra bir önceki sürüm tek tıkla geri yüklenebilir.

### UX-04 · "Yeni sayfa" tıklanınca boş kayıt hemen oluşuyor
- **Kod yeri:** `admin/index.php?p=page-new&type=page&_token=…` → hemen `post-edit&id=NNN&new=1`.
- **Durum:** Vazgeçilen denemeler "Başlıksız" taslak olarak listede kalıyor (`id=546` iki gündür duruyor).
- **İstenen:** Kayıt ilk "Taslak kaydet" ile oluşturulsun, ya da 24 saatten eski boş "Başlıksız" taslaklar otomatik silinsin.

### UX-05 · AI Blog Yazarı'nda link HTML olarak görünüyor
- **Kod yeri:** `admin/index.php?p=ai-writer` şablonu.
- **Durum:** Sayfada metin olarak `Önce yapay zekâyı ayarlayın: <a href="…p=settings&tab=ai">Ayarlar → Yapay zekâ</a>` görünüyor. Çıktı fazladan escape ediliyor.
- **Kabul testi:** Metin tıklanabilir bir link olarak görünür.

### UX-06 · Medya ("Görsel seç") penceresinin arka planı yarı saydam
- **Durum:** Pencere açıkken arkadaki tuval içeriği pencerenin içinden görünüyor. Arama kutusunun ve "Kullan" düğmesinin üstünde sayfa yazıları beliriyor. Tıklama çalışıyor, ama okunurluk düşük.
- **İstenen:** Pencere kutusuna opak bir arka plan verilsin (`admin/assets/media.css`).

---

### UX-07 · Amatör kullanıcı için ayar sayısı ve teknik dil fazla; Basit/Uzman modu yok
- **Ölçüm:** 80 eleman, toplam 3.878 ayar (eleman başına ortalama ~50). Yalnızca %19'unda (745) yardım metni var; 80 elemanın 32'sinde eleman açıklaması (ne işe yarar) yok. 155 etikette "CSS", 79'unda "HTML ID (çapa)", 77'sinde "margin", 75'inde "padding/z-index/opaklık" geçiyor. Palet kartlarının ipucu yalnızca varyant sayısını söylüyor ("Bölüm · 4 hazır düzen"), elemanın ne yaptığını değil.
- **İstenen:**
  1. Editör üst çubuğuna **"Basit / Uzman" anahtarı**: Basit modda yalnızca İçerik sekmesi + Stil'de renk, yazı boyutu, hizalama, boşluk (Küçük/Orta/Büyük hazır değerlerle) görünsün; Gelişmiş sekmesi gizlensin. Varsayılan rol bazlı olsun (editör = Basit).
  2. Her elemana 1 cümlelik açıklama ve palet kartı ipucuna bu açıklama ("Sayaç – rakamları sayarak gösterir, ör. 1200+ referans").
  3. Teknik etiketlerin yanında kısa Türkçe ipucu (ör. "İç boşluk – kutunun içindeki boşluk"), yardım oranı en az %60.
  4. Tehlikeli/yetki gerektiren alanlar (Özel CSS, HTML/Kod) Basit modda hiç görünmesin (BUG-01 ile birlikte).
- **Kabul testi:** Editör rolüyle açılan Başlık elemanında Basit modda ≤12 ayar görünür ve her birinde ipucu vardır.

### UX-08 · "Bir şeyi bozdum, nasıl geri dönerim?" yolu yok
- BUG-01/02/03 ve UX-03 birleşince amatör kullanıcı için en büyük risk: hata yapıldığında geri dönüş yolu yok (sürüm geçmişi yok, BUG-03'te geri al çalışmıyor).
- **İstenen:** UX-03'teki sürüm geçmişi + kayıttan önce "değişiklik özeti" penceresi (ör. "2 başlık metni değişti, 1 bölüm silindi") + yayındaki sayfada yapılan kayıtlar için isteğe bağlı "önce taslak olarak kaydet, sonra yayınla" akışı.

## Doğrulanmış ve sorunsuz çalışanlar (dokunmayın)

- **Arayüz → model bağlantısı:** 80 eleman tipi. Her ayar gerçek arayüzden değiştirildi, değerin `Mimar.state.tree` içine yazıldığı doğrulandı (sayılar aşağıdaki tabloda).
- **Kayıt sonrası korunma:** Kaydet → yeniden aç sonrası, BUG-01 dışındaki bütün öznitelikler birebir korunuyor.
- **Geri al / yinele:** Ctrl+Z / Ctrl+Y ve üst düğmeler çalışıyor.
- **Kopyalama işlemleri:** Kopyala / yapıştır (Ctrl+C / V, sayfalar arası) ve çoğalt (Ctrl+D) çalışıyor.
- **Katman taşıma:** Alt + ↑/↓ ile katman taşıma, hem tuvalde hem Katmanlar panelinde çalışıyor.
- **Cihaza özel değerler:** Masaüstü, tablet ve mobil için ayrı değerler saklanıyor (`size` / `size__md` / `size__sm`).
- **Stil kopyalama:** Stili kopyala / yapıştır (Ctrl+Shift+C / V) çalışıyor.
- **Komut paleti:** Ctrl+K ile eleman eklenebiliyor.
- **Şablon kütüphanesi:** Ctrl+L. 230 bölüm, 776 sayfa şablonu. "Ekle" çalışıyor, Esc pencereyi kapatıyor.
- **Önizleme:** Yeni sekmede, kaydedilmemiş değişikliklerle açılıyor.
- **Metin elemanında satır içi düzenleme:** ✓, dışarı tıklama ve Esc'nin üçü de değişikliği koruyor.
- **Kaydetmeden çıkış uyarısı** var.
- **Tuval–model uyumu:** Sil / geri al / yinele sonrasında tuval ve model uyumlu kalıyor.
- **Metin editörü kayıt gecikmesi:** Değişiklik ~0,3–0,5 sn gecikmeyle modele yazılıyor. Bu normal, hata değil.


---

## Ek A · Ham HTML oranı (editör ayarlarıyla düzenlenemeyen kısım)

| İçerik | Ham HTML oranı | Ham HTML blok sayısı |
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

## Ek B · Özel kısa kodlar (panelde görünmüyor; FEAT-01)

| Kısa kod | Ne yapar | Kullanıldığı içerikler |
|---|---|---|
| `[jet_eklenti]` | Eklenti kutusu. `anahtar` parametresiyle: seo_pro, coklu_dil, ai, sosyal, sitekit, canli_takip, katalog_pro, toplu_aktarim, urun_akislari, ek_urun | Site Kit: ölçüm ve çerez onayı, +SEO ve yapay zekâ görünürlüğü, Sosyal akışlar, Ürün XML akışları, Ek ürün kapasitesi |
| `[jet_eklentiler]` | Tüm eklentilerin listesi | Eklentiler |
| `[jet_demo_sayisi]` | Canlı demo sayısını yazar (213) | Paketler, Demolar, Güven şeridi |
| `[mt_year]` | Bulunulan yıl | Footer – Jet Bilişim |
| `[mt_site_name]` | Site adı | — |
| `[mimar_block]` | Bloklar ekranındaki bloğu `id` ile gömer (ör. 597 = Güven şeridi) | Paketler, Ana Sayfa |

## Ek C · Editör elemanları: kısa kod, test sonucu ve kullanım

Sonuç sütunu otomatik testte ilk seferde doğrulanan ayar sayısını gösterir. Kalan ayarlar için yukarıdaki elle doğrulama notu geçerlidir.

İki durum her elemanı etkiler:
- `x_css` (Gelişmiş → Özel CSS) yönetici olmayan rolde kayıtta siliniyor (BUG-01).
- `[mb_html]` elemanı yönetici olmayan rolde kayıtta tamamen siliniyor (BUG-01).

| Kısa kod | Eleman | Kategori | Test edilen / ilk seferde doğrulanan | Kullanıldığı içerikler |
|---|---|---|---|---|
| `[mb_mega_links]` | Menü bağlantıları | Mega menü | 48 / 48 | — |
| `[mb_mega_tabs]` | Dikey sekmeler (mega) | Mega menü | 47 / 47 | — |
| `[mb_mega_tab]` | Sekme (mega) | Mega menü | 47 / 47 | — |
| `[mb_mega_posts]` | Son yazılar (menü) | Mega menü | 50 / 49 | — |
| `[mb_mega_tiles]` | Görsel ızgara (menü) | Mega menü | 46 / 46 | Mega menü – Demolar, Mega menü – Hizmetler |
| `[mb_block]` | Blok | Gelişmiş | 41 / 41 | — |
| `[mb_form]` | Form | İçerik | 49 / 49 | İletişim, SEO Analiz Raporu |
| `[mb_field]` | Form Alanı | İçerik | 6 / 4 | SEO Analiz Raporu ×6, İletişim ×5 |
| `[mb_section]` | Bölüm | Yerleşim | 69 / 49 | Ana Sayfa ×12, Sosyal Medya Yönetimi ×12, Paketler ×11, Tuzla Web Tasarım ×9, Hosting ve Bakım ×8 |
| `[mb_row]` | Satır | Yerleşim | 58 / 58 | Ana Sayfa ×22, Paketler ×21, Sosyal Medya Yönetimi ×17, Hosting ve Bakım ×13, SEO Danışmanlığı ×13 |
| `[mb_col]` | Sütun | Yerleşim | 54 / 53 | Ana Sayfa ×29, Google Ads ×26, Tuzla Web Tasarım ×25, Hizmetler ×24, SEO Analiz Raporu ×24 |
| `[mb_scrolly]` | Kaydırmalı anlatım | Yerleşim | 51 / 51 | — |
| `[mb_scrolly_step]` | Anlatım adımı | Yerleşim | 48 / 45 | — |
| `[mb_heading]` | Başlık | İçerik | 59 / 59 | SEO Analiz Raporu ×12, Tuzla Web Tasarım ×11, Gebze OSB Web Tasarım ×11, Google Ads ×11, Hizmetler ×10 |
| `[mb_text]` | Metin | İçerik | 53 / 53 | Paketler ×30, Tuzla Web Tasarım ×16, Gebze OSB Web Tasarım ×15, Google Ads ×10, SEO Danışmanlığı ×9 |
| `[mb_button]` | Buton | İçerik | 58 / 58 | Ana Sayfa ×10, Paketler ×7, Tuzla Web Tasarım ×5, SEO Danışmanlığı ×4, Gebze OSB Web Tasarım ×4 |
| `[mb_spacer]` | Boşluk | İçerik | 40 / 40 | Paketler ×24, Ana Sayfa ×12, Sosyal Medya Yönetimi ×9, SEO Analiz Raporu ×6, Hosting ve Bakım ×5 |
| `[mb_divider]` | Ayraç | İçerik | 45 / 45 | Footer – Jet Bilişim |
| `[mb_html]` | HTML / Kod | İçerik | 41 / 41 | Paketler ×8, Ana Sayfa ×7, Sosyal Medya Yönetimi ×7, Hosting ve Bakım ×4, SEO Danışmanlığı ×3 |
| `[mb_iconbox]` | Özellik Kutusu | İçerik | 54 / 52 | Google Ads ×10, Demolar ×9, Ana Sayfa ×6, Tuzla Web Tasarım ×6, Gebze OSB Web Tasarım ×6 |
| `[mb_accordion]` | Akordeon | İçerik | 42 / 42 | Hosting ve Bakım, Paketler, SEO Danışmanlığı, Jet Büyüme – Aylık Bakım, Sosyal Medya, SEO ve Google Ads Paketleri, Sosyal Medya Yönetimi |
| `[mb_accordion_item]` | Akordeon Maddesi | İçerik | 43 / 43 | Paketler ×10, Jet Büyüme – Aylık Bakım, Sosyal Medya, SEO ve Google Ads Paketleri ×7, SEO Analiz Raporu ×6, Hosting ve Bakım ×5, SEO Danışmanlığı ×5 |
| `[mb_image]` | Görsel | Medya | 56 / 55 | Ana Sayfa ×5, Demolar ×5, Paketler ×3, Footer – Jet Bilişim ×2, Hosting ve Bakım |
| `[mb_video]` | Video | Medya | 50 / 48 | — |
| `[mb_gallery]` | Galeri | Medya | 56 / 53 | Referanslar |
| `[mb_slider]` | Slider | Medya | 59 / 52 | — |
| `[mb_slide]` | Slayt | Medya | 55 / 47 | — |
| `[mb_tabs]` | Sekmeler | İçerik | 43 / 43 | Paketler |
| `[mb_tab]` | Sekme | İçerik | 42 / 42 | Paketler ×4 |
| `[mb_icon]` | İkon | İçerik | 47 / 47 | — |
| `[mb_iconlist]` | İkonlu Liste | İçerik | 49 / 48 | Hosting ve Bakım, Ana Sayfa, Sosyal Medya Yönetimi, Google Ads, Footer – Jet Bilişim |
| `[mb_banner]` | Banner | Yerleşim | 56 / 55 | — |
| `[mb_counter]` | Sayaç | Kurumsal | 54 / 54 | — |
| `[mb_logos]` | Logo Şeridi | Medya | 48 / 46 | — |
| `[mb_team]` | Ekip Üyesi | Kurumsal | 51 / 50 | — |
| `[mb_price]` | Fiyat Tablosu | Kurumsal | 51 / 51 | Paketler ×10, SEO Analiz Raporu ×3 |
| `[mb_map]` | Harita | Medya | 50 / 49 | İletişim |
| `[mb_testimonial]` | Müşteri Yorumu | Kurumsal | 48 / 47 | — |
| `[mb_countdown]` | Geri Sayım | Kurumsal | 46 / 46 | — |
| `[mb_progress]` | İlerleme Çubukları | Kurumsal | 44 / 44 | — |
| `[mb_portfolio]` | Proje Galerisi | Kurumsal | 62 / 55 | — |
| `[mb_portfolio_item]` | Proje (alt öğe) | Kurumsal | 10 / 9 | — |
| `[mb_title]` | Bölüm Başlığı | İçerik | 60 / 60 | Sosyal Medya Yönetimi ×9, Ana Sayfa ×8, Paketler ×7, Tuzla Web Tasarım ×7, SEO Danışmanlığı ×6 |
| `[mb_videobutton]` | Video Butonu | Medya | 48 / 48 | — |
| `[mb_imagebox]` | Görsel Kutu | Medya | 54 / 53 | Hizmetler ×6 |
| `[mb_bannergrid]` | Banner Izgarası | Yerleşim | 45 / 45 | — |
| `[mb_message]` | Uyarı Kutusu | İçerik | 45 / 45 | — |
| `[mb_search]` | Arama Kutusu | İçerik | 45 / 45 | — |
| `[mb_hotspot]` | İşaretli Görsel | Medya | 45 / 44 | — |
| `[mb_hotspot_pin]` | İşaret (alt öğe) | Medya | 10 / 10 | — |
| `[mb_share]` | Paylaş Butonları | İçerik | 44 / 44 | — |
| `[mb_marquee]` | Kayan Şerit | Yerleşim | 70 / 62 | — |
| `[mb_compare_img]` | Önce / Sonra | Medya | 54 / 52 | — |
| `[mb_badge_circle]` | Dönen Rozet | Medya | 60 / 58 | — |
| `[mb_spec]` | Teknik Tablo | Kurumsal | 56 / 56 | — |
| `[mb_docs]` | Belgeler / Katalog | Kurumsal | 52 / 52 | — |
| `[mb_doc]` | Belge | Kurumsal | 13 / 11 | — |
| `[mb_pricing]` | Fiyat Paketleri | Kurumsal | 53 / 49 | — |
| `[mb_price_plan]` | Fiyat Paketi | Kurumsal | 56 / 56 | — |
| `[mb_compare_table]` | Karşılaştırma Tablosu | Kurumsal | 53 / 53 | — |
| `[mb_testimonials]` | Yorumlar (Kaydırmalı / Duvar) | Kurumsal | 59 / 51 | — |
| `[mb_pricelist]` | Menü / Fiyat Listesi | Kurumsal | 50 / 49 | — |
| `[mb_flipbox]` | Çevrilen Kutu | İçerik | 65 / 63 | — |
| `[mb_toc]` | İçindekiler | İçerik | 54 / 53 | — |
| `[mb_timeline]` | Zaman Çizelgesi | Kurumsal | 52 / 51 | — |
| `[mb_cta]` | Eylem Kartı (CTA) | İçerik | 63 / 60 | — |
| `[mb_quote]` | Alıntı | İçerik | 53 / 52 | — |
| `[mb_layerslider]` | Katmanlı slider | Medya | 42 / 42 | Ana Sayfa |
| `[mb_lang_switcher]` | Dil Değiştirici | İçerik | 43 / 43 | — |
| `[mb_breadcrumb]` | Konum yolu (breadcrumb) | Site | 41 / 41 | — |
| `[mb_google_reviews]` | Google Yorumları | Sosyal | 57 / 54 | — |
| `[mb_instagram_feed]` | Instagram Akışı | Sosyal | 53 / 52 | — |
| `[mb_tiktok_feed]` | TikTok Akışı | Sosyal | 52 / 51 | — |
| `[mb_logo]` | Logo | Site | 45 / 44 | Header – Jet Bilişim |
| `[mb_menu]` | Menü | Site | 58 / 54 | Footer – Jet Bilişim ×3, Header – Jet Bilişim |
| `[mb_social]` | Sosyal İkonlar | Site | 52 / 52 | İletişim |
| `[mb_offcanvas]` | Yan Panel | Site | 10 / 10 | — |
| `[mb_posts]` | Son Yazılar | Site | 50 / 50 | Ana Sayfa, Blog |
| `[mb_paket_demolari]` | Paket demoları | Jet | 45 / 44 | — |
| `[mb_jet_buyume]` | Jet Büyüme paketleri | Jet | 41 / 40 | Paketler, Jet Büyüme – Aylık Bakım, Sosyal Medya, SEO ve Google Ads Paketleri |

## Ek D · Kullanım akışı testleri

| Test | Sonuç | Not |
|---|---|---|
| Geri al / Yinele (Ctrl+Z / Y ve üst düğmeler) | ✅ | |
| Kopyala / yapıştır (Ctrl+C / V), çoğalt (Ctrl+D) | ✅ | |
| Panelden Sil → Ctrl+Z | ❌ | UX-01 (3/3) |
| Panelden Sil → üst Geri al | ✅ | |
| Katman taşıma Alt + ↑/↓ (tuval ve Katmanlar paneli) | ✅ | |
| Tablet / mobil için ayrı değer (`size` / `size__sm`) | ✅ | |
| Stili kopyala / yapıştır | ✅ | |
| Komut paleti ile eleman ekleme (Ctrl+K) | ✅ | |
| Şablon kütüphanesi (230 bölüm, 776 sayfa şablonu): Ekle ve Esc ile kapatma | ✅ | |
| Yeni sekmede önizleme (kaydedilmemiş değişikliklerle) | ✅ | |
| Metin elemanında tuvalde yazma (✓ / dışarı tıklama / Esc) | ✅ | |
| Başlık elemanında tuvalde yazma | ❌ | UX-02 |
| Kaydet → yeniden aç (150 eleman, binlerce ayar) | ⚠️ | Sadece `mb_html` ve `x_css` kayıp (BUG-01) |
| Ham HTML Metin bloğunu yalnızca seçmek | ✅ | İçerik değişmiyor |
| Ham HTML Metin bloğuna tek harf yazmak | ❌ | BUG-03, geri alınamıyor |
| Sayfa kopyalama | ❌ | BUG-02 |
| Medya seçici açılıyor, Esc ile kapanıyor | ✅ | Arka plan yarı saydam (UX-06) |
| Kaydetmeden çıkış uyarısı | ✅ | |
| Sürüm geçmişi / otomatik kayıt | ❌ | UX-03 |
