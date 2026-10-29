# JET Core / Mimar Builder – Kısa Kod Kılavuzu

Bu kılavuz editördeki her elemanın **kısa kodunu**, editörde **nerede** bulunduğunu, **ne işe yaradığını** ve sitede **hangi sayfalarda kullanıldığını** gösterir. Editörün kendi tanımlarından otomatik üretildi (JET Core v1.0.44, 29.10.2026).

## Önce bilinmesi gerekenler (amatör kullanıcı için)

1. **Kısa kodu elle yazmanız gerekmez.** Editörde sol menüden **Ekle** sekmesini açın, elemanı tıklayın veya tuvale sürükleyin. Editör kısa kodu kendisi üretir.
2. **Bir sayfanın tüm kısa kodlarını görmek için:** Editörün üst çubuğundaki **`</>` (Kod: içe / dışa aktar)** düğmesine basın. Açılan pencerede sayfanın tamamı kısa kod olarak görünür. **Kopyala** ile başka bir sayfaya taşıyabilirsiniz; **Sona ekle** kodu sayfanın sonuna ekler; **Sayfayı değiştir** sayfanın tamamını değiştirir (dikkat).
3. **Bir elemanın kısa kodunu almak için:** Elemanı seçin, **Ctrl + C** yapın. Kısa kodu panoya kopyalanır, başka bir sayfada **Ctrl + V** ile yapıştırabilirsiniz.
4. **Ayarlar = kısa kodun özellikleri.** Paneldeki her ayar kısa kodda `anahtar="değer"` olarak saklanır. Örneğin Başlık'ta yazı boyutunu 32 yaparsanız kısa koda `size="32"` eklenir. Tablet ve mobil için ayrı değerler `__md` (tablet) ve `__sm` (mobil) ekiyle saklanır: `size__sm="22"`.
5. **Katmanlar** sekmesi sayfadaki tüm elemanları ağaç halinde gösterir. Hangi bölümün içinde neyin olduğunu buradan görebilirsiniz.
6. **Dikkat:** *HTML / Kod* elemanı ve *Gelişmiş → Özel CSS* alanı yalnızca yönetici yetkisinde korunur. Editör yetkisinde bu alanlar kayıtta silinir (bkz. test raporu). Ham HTML içeren bir *Metin* bloğunu yan paneldeki editörle değiştirmeyin; tasarım bozulabilir.

## Özel (sunucu tarafı) kısa kodlar

Bunlar editör paletinde yok; sayfa içine metin olarak yazılır ve site görüntülenirken sunucu tarafından doldurulur. Şu an panelde bunların listesi yoktur. Tanımları tema veya eklenti dosyalarındadır.

| Kısa kod | Ne yapar | Nasıl kullanılır | Kullanıldığı yerler |
|---|---|---|---|
| `[jet_eklenti anahtar="seo_pro"]` | Bir eklentinin fiyat/özellik kutusunu basar. Anahtarlar: seo_pro, coklu_dil, ai, sosyal, sitekit, canli_takip, katalog_pro, toplu_aktarim, urun_akislari, ek_urun | Bir **Metin** elemanının içine yazın | Site Kit: ölçüm ve çerez onayı, +SEO ve yapay zekâ görünürlüğü, Sosyal akışlar, Ürün XML akışları, Ek ürün kapasitesi, Excel / CSV aktarımı, Yapay zekâ asistanı, Çoklu dil, Canlı ziyaretçi takibi, Gelişmiş katalog |
| `[jet_eklentiler]` | Tüm eklentileri liste halinde basar | Metin içine yazın | Eklentiler |
| `[jet_demo_sayisi]` | Canlı demo sayısını yazar (örn. 213). Demo eklendikçe kendiliğinden güncellenir. | Metin içine: `[jet_demo_sayisi] canlı demo` | Paketler, Demolar, Güven şeridi |
| `[mt_year]` | Bulunulan yılı yazar | Footer telif satırında: `© [mt_year] [mt_site_name]` | Footer – Jet Bilişim |
| `[mt_site_name]` | Site adını yazar | Metin içine | Sitede şu an kullanılmıyor. |
| `[mimar_block id="597"]` | **Bloklar** ekranındaki bir bloğu gömer (597 = Güven şeridi). Blok değişince her yerde değişir. | Tercihen editörde **Blok** elemanını ekleyip listeden seçin | Paketler, Ana Sayfa |

## Editör elemanları

### Mega menü

#### Menü bağlantıları — `[mb_mega_links]`
- Paletteki yeri: **Ekle → Mega menü → Menü bağlantıları**
- Ayarlar: İçerik 5+ · Stil 20 · Gelişmiş 23 · tablet/mobil ayrı ayarlanabilen 7
- Ana ayarlar: Sütun başlığı (`title`), Başlık bağlantısı (isteğe bağlı) (`title_url`), Bağlantılar (`items`), Görünüm (`style`), Sütun (`columns`)
- Örnek: `[mb_mega_links title="Başlık" title_url="…"]`
- Kullanıldığı yerler: Sitede şu an kullanılmıyor.

#### Dikey sekmeler (mega) — `[mb_mega_tabs]`
- Paletteki yeri: **Ekle → Mega menü → Dikey sekmeler (mega)**
- Ayarlar: İçerik 2+ · Stil 21 · Gelişmiş 24 · tablet/mobil ayrı ayarlanabilen 6
- Ana ayarlar: Sol liste genişliği (`nav_w`), Sekme değişimi (`trigger`)
- Örnek: `[mb_mega_tabs nav_w="260" trigger="…"]`
- Kullanıldığı yerler: Sitede şu an kullanılmıyor.

#### Sekme (mega) — `[mb_mega_tab]`
- Paletteki yeri: **Ekle → Mega menü → Sekme (mega)**
- Ayarlar: İçerik 5+ · Stil 18 · Gelişmiş 24 · tablet/mobil ayrı ayarlanabilen 6
- Ana ayarlar: Sekme adı (`title`), İkon (`icon`), Kısa açıklama (`desc`), Sekme bağlantısı (`link`), Rozet (`badge`)
- Örnek: `[mb_mega_tab title="Kategori" icon="…" desc="…"]`
- Kullanıldığı yerler: Sitede şu an kullanılmıyor.

#### Son yazılar (menü) — `[mb_mega_posts]`
- Paletteki yeri: **Ekle → Mega menü → Son yazılar (menü)**
- Ayarlar: İçerik 8+ · Stil 17 · Gelişmiş 23 · tablet/mobil ayrı ayarlanabilen 7
- Ana ayarlar: Başlık (`title`), Yazı sayısı (`count`), Kategori (`category`), Düzen (`layout`), Sütun (`columns`), Öne çıkan görsel (`thumb`), Tarih (`date`), Özet (`excerpt`)
- Örnek: `[mb_mega_posts title="Son yazılar" count="3" category="…"]`
- Kullanıldığı yerler: Sitede şu an kullanılmıyor.

#### Görsel ızgara (menü) — `[mb_mega_tiles]`
- Paletteki yeri: **Ekle → Mega menü → Görsel ızgara (menü)**
- Ayarlar: İçerik 4+ · Stil 19 · Gelişmiş 23 · tablet/mobil ayrı ayarlanabilen 7
- Ana ayarlar: Kutular (`items`), Görünüm (`style`), Sütun (`columns`), Görsel oranı (`ratio`)
- Örnek: `[mb_mega_tiles style="…" columns="4"]`
- Kullanıldığı yerler: Mega menü – Demolar, Mega menü – Hizmetler

### Gelişmiş

#### Blok — `[mb_block]`
- Paletteki yeri: **Ekle → Gelişmiş → Blok**
- Ayarlar: İçerik 1+ · Stil 17 · Gelişmiş 23 · tablet/mobil ayrı ayarlanabilen 6
- Ana ayarlar: Blok (`block_id`)
- Örnek: `[mb_block block_id="…"]`
- Kullanıldığı yerler: Sitede şu an kullanılmıyor.

### İçerik

#### Form — `[mb_form]`
- Paletteki yeri: **Ekle → İçerik → Form**
- Ayarlar: İçerik 8+ · Stil 17 · Gelişmiş 24 · tablet/mobil ayrı ayarlanabilen 6
- Ana ayarlar: Form adı (`title`), Bildirim e-postası (`email`), Başarı mesajı (`success`), Gönderimden sonra yönlendir (`redirect`), Buton metni (`button_text`), Tam genişlik buton (`button_full`), Onay kutusu metni (KVKK) (`consent`), Alan stili (`style`)
- Örnek: `[mb_form title="İletişim formu" email="…" success="…"]`
- Kullanıldığı yerler: İletişim, SEO Analiz Raporu

#### Form Alanı — `[mb_field]`
- Paletteki yeri: **Ekle → İçerik → Form Alanı**
- Ayarlar: İçerik 6+ · Stil 0 · Gelişmiş 0 · tablet/mobil ayrı ayarlanabilen 0
- Ana ayarlar: Alan türü (`type`), Etiket (`label`), Yer tutucu (`placeholder`), Seçenekler (`choices`), Zorunlu (`required`), Genişlik (`width`)
- Örnek: `[mb_field type="text" label="Alan" placeholder="…"]`
- Kullanıldığı yerler: SEO Analiz Raporu (×6), İletişim (×5)

#### Başlık — `[mb_heading]`
- Paletteki yeri: **Ekle → İçerik → Başlık**
- Ayarlar: İçerik 3+ · Stil 24 · Gelişmiş 32 · tablet/mobil ayrı ayarlanabilen 8
- Ana ayarlar: Metin (`text`), Etiket (`tag`), Bağlantı (`link`)
- Örnek: `[mb_heading text="Yeni başlık" tag="h2" link="…"]`
- Kullanıldığı yerler: SEO Analiz Raporu (×12), Tuzla Web Tasarım (×11), Gebze OSB Web Tasarım (×11), Google Ads (×11), Hizmetler (×10), Paketler (×6), Ana Sayfa (×6), Referanslar (×5), Hosting ve Bakım (×3), İletişim (×3), SEO Danışmanlığı (×3), Sosyal Medya Yönetimi (×3), Hakkımızda (×3), Footer – Jet Bilişim (×3), Jet Büyüme – Aylık Bakım, Sosyal Medya, SEO ve Google Ads Paketleri (×2), Site Kit: ölçüm ve çerez onayı (×2), +SEO ve yapay zekâ görünürlüğü (×2), Sosyal akışlar (×2), Ürün XML akışları (×2), Ek ürün kapasitesi (×2), Excel / CSV aktarımı (×2), 404 Sayfası (×2), Demolar (×2), Yapay zekâ asistanı (×2), Çoklu dil (×2), Canlı ziyaretçi takibi (×2), Gelişmiş katalog (×2), Eklentiler (×2), Gizlilik Politikası, KVKK Aydınlatma Metni, İptal, İade ve Teslimat Koşulları, Kullanım Koşulları, Mega menü – Hizmetler, Ön Bilgilendirme Formu, Çerez Politikası, Blog, Hizmet Sözleşmesi

#### Metin — `[mb_text]`
- Paletteki yeri: **Ekle → İçerik → Metin**
- Ayarlar: İçerik 1+ · Stil 21 · Gelişmiş 30 · tablet/mobil ayrı ayarlanabilen 8
- Ana ayarlar: Hizalama (`align`)
- Örnek: `[mb_text align="…"]…[/mb_text]`
- Kullanıldığı yerler: Paketler (×30), Tuzla Web Tasarım (×16), Gebze OSB Web Tasarım (×15), Google Ads (×10), SEO Danışmanlığı (×9), SEO Analiz Raporu (×9), Ana Sayfa (×8), Hakkımızda (×7), Hizmetler (×7), Hosting ve Bakım (×6), Sosyal Medya Yönetimi (×6), Referanslar (×6), Jet Büyüme – Aylık Bakım, Sosyal Medya, SEO ve Google Ads Paketleri (×3), Site Kit: ölçüm ve çerez onayı (×3), +SEO ve yapay zekâ görünürlüğü (×3), Sosyal akışlar (×3), Ürün XML akışları (×3), Ek ürün kapasitesi (×3), Excel / CSV aktarımı (×3), Demolar (×3), Yapay zekâ asistanı (×3), Çoklu dil (×3), Canlı ziyaretçi takibi (×3), Gelişmiş katalog (×3), Eklentiler (×3), İletişim (×2), Mega menü – Hizmetler (×2), Footer – Jet Bilişim (×2), Gizlilik Politikası, KVKK Aydınlatma Metni, İptal, İade ve Teslimat Koşulları, Mega menü – Demolar, Kullanım Koşulları, Ön Bilgilendirme Formu, 404 Sayfası, Çerez Politikası, Blog, Hizmet Sözleşmesi

#### Buton — `[mb_button]`
- Paletteki yeri: **Ekle → İçerik → Buton**
- Ayarlar: İçerik 8+ · Stil 22 · Gelişmiş 24 · tablet/mobil ayrı ayarlanabilen 6
- Ana ayarlar: Metin (`text`), Bağlantı (`link`), Yeni sekmede aç (`target`), Stil (`style`), Tam genişlik (`full`), İkon (`icon`), İkon konumu (`icon_pos`), Alt satır metni (`sub_text`)
- Örnek: `[mb_button text="Tıklayın" link="…" target="…"]`
- Kullanıldığı yerler: Ana Sayfa (×10), Paketler (×7), Tuzla Web Tasarım (×5), SEO Danışmanlığı (×4), Gebze OSB Web Tasarım (×4), Jet Büyüme – Aylık Bakım, Sosyal Medya, SEO ve Google Ads Paketleri (×3), Demolar (×3), SEO Analiz Raporu (×3), Hosting ve Bakım (×2), Sosyal Medya Yönetimi (×2), Site Kit: ölçüm ve çerez onayı (×2), +SEO ve yapay zekâ görünürlüğü (×2), Sosyal akışlar (×2), Ürün XML akışları (×2), Hakkımızda (×2), Mega menü – Hizmetler (×2), Hizmetler (×2), Ek ürün kapasitesi (×2), Excel / CSV aktarımı (×2), Google Ads (×2), Yapay zekâ asistanı (×2), Çoklu dil (×2), Canlı ziyaretçi takibi (×2), Gelişmiş katalog (×2), Eklentiler (×2), İletişim, Header – Jet Bilişim, 404 Sayfası, Referanslar

#### Boşluk — `[mb_spacer]`
- Paletteki yeri: **Ekle → İçerik → Boşluk**
- Ayarlar: İçerik 0+ · Stil 18 · Gelişmiş 22 · tablet/mobil ayrı ayarlanabilen 6
- Ana ayarlar: —
- Örnek: `[mb_spacer]`
- Kullanıldığı yerler: Paketler (×24), Ana Sayfa (×12), Sosyal Medya Yönetimi (×9), SEO Analiz Raporu (×6), Hosting ve Bakım (×5), SEO Danışmanlığı (×5), Jet Büyüme – Aylık Bakım, Sosyal Medya, SEO ve Google Ads Paketleri (×5), Hizmetler (×5), Google Ads (×5), Referanslar (×5), Tuzla Web Tasarım (×4), Gebze OSB Web Tasarım (×3), Demolar (×2), İletişim, Hakkımızda, Eklentiler, Footer – Jet Bilişim

#### Ayraç — `[mb_divider]`
- Paletteki yeri: **Ekle → İçerik → Ayraç**
- Ayarlar: İçerik 4+ · Stil 18 · Gelişmiş 23 · tablet/mobil ayrı ayarlanabilen 8
- Ana ayarlar: Genişlik (`width`), Kalınlık (`thickness`), Çizgi (`style`), Hizalama (`align`)
- Örnek: `[mb_divider width="60px" thickness="3" style="…"]`
- Kullanıldığı yerler: Footer – Jet Bilişim

#### HTML / Kod — `[mb_html]`
- Paletteki yeri: **Ekle → İçerik → HTML / Kod**
- Ayarlar: İçerik 0+ · Stil 17 · Gelişmiş 23 · tablet/mobil ayrı ayarlanabilen 6
- Ana ayarlar: —
- Örnek: `[mb_html]…[/mb_html]`
- Kullanıldığı yerler: Paketler (×8), Ana Sayfa (×7), Sosyal Medya Yönetimi (×7), Hosting ve Bakım (×4), SEO Danışmanlığı (×3), Jet Büyüme – Aylık Bakım, Sosyal Medya, SEO ve Google Ads Paketleri (×3), Referanslar (×3), Footer – Jet Bilişim (×3), Hakkımızda (×2), Gizlilik Politikası, İletişim, KVKK Aydınlatma Metni, İptal, İade ve Teslimat Koşulları, Kullanım Koşulları, Ön Bilgilendirme Formu, Hizmetler, Google Ads, Güven şeridi, Çerez Politikası, Hizmet Sözleşmesi

#### Özellik Kutusu — `[mb_iconbox]`
- Paletteki yeri: **Ekle → İçerik → Özellik Kutusu**
- Ayarlar: İçerik 7+ · Stil 26 · Gelişmiş 24 · tablet/mobil ayrı ayarlanabilen 6
- Ana ayarlar: Başlık (`title`), İkon (`icon`), Görsel (ikon yerine) (`image`), Görsel konumu (`position`), Hizalama (`align`), Başlık etiketi (`title_tag`), Bağlantı (`link`)
- Örnek: `[mb_iconbox title="Özellik başlığı" icon="…" image="…"]…[/mb_iconbox]`
- Kullanıldığı yerler: Google Ads (×10), Demolar (×9), Ana Sayfa (×6), Tuzla Web Tasarım (×6), Gebze OSB Web Tasarım (×6), SEO Analiz Raporu (×6), İletişim (×4), Sosyal Medya Yönetimi (×4), Hakkımızda (×4), Hizmetler (×4)

#### Akordeon — `[mb_accordion]`
- Paletteki yeri: **Ekle → İçerik → Akordeon**
- Ayarlar: İçerik 1+ · Stil 17 · Gelişmiş 24 · tablet/mobil ayrı ayarlanabilen 6
- Ana ayarlar: Stil (`style`)
- Örnek: `[mb_accordion style="…"]`
- Kullanıldığı yerler: Hosting ve Bakım, Paketler, SEO Danışmanlığı, Jet Büyüme – Aylık Bakım, Sosyal Medya, SEO ve Google Ads Paketleri, Sosyal Medya Yönetimi, Tuzla Web Tasarım, Gebze OSB Web Tasarım, Hizmetler, Google Ads, SEO Analiz Raporu

#### Akordeon Maddesi — `[mb_accordion_item]`
- Paletteki yeri: **Ekle → İçerik → Akordeon Maddesi**
- Ayarlar: İçerik 2+ · Stil 17 · Gelişmiş 24 · tablet/mobil ayrı ayarlanabilen 6
- Ana ayarlar: Başlık (`title`), Açık başlasın (`open`)
- Örnek: `[mb_accordion_item title="Başlık" open="…"]`
- Kullanıldığı yerler: Paketler (×10), Jet Büyüme – Aylık Bakım, Sosyal Medya, SEO ve Google Ads Paketleri (×7), SEO Analiz Raporu (×6), Hosting ve Bakım (×5), SEO Danışmanlığı (×5), Sosyal Medya Yönetimi (×5), Tuzla Web Tasarım (×5), Gebze OSB Web Tasarım (×5), Google Ads (×5), Hizmetler (×4)

#### Sekmeler — `[mb_tabs]`
- Paletteki yeri: **Ekle → İçerik → Sekmeler**
- Ayarlar: İçerik 2+ · Stil 17 · Gelişmiş 24 · tablet/mobil ayrı ayarlanabilen 6
- Ana ayarlar: Stil (`style`), Sekme başlıkları (`align`)
- Örnek: `[mb_tabs style="…" align="…"]`
- Kullanıldığı yerler: Paketler

#### Sekme — `[mb_tab]`
- Paletteki yeri: **Ekle → İçerik → Sekme**
- Ayarlar: İçerik 1+ · Stil 17 · Gelişmiş 24 · tablet/mobil ayrı ayarlanabilen 6
- Ana ayarlar: Başlık (`title`)
- Örnek: `[mb_tab title="Sekme"]`
- Kullanıldığı yerler: Paketler (×4)

#### İkon — `[mb_icon]`
- Paletteki yeri: **Ekle → İçerik → İkon**
- Ayarlar: İçerik 3+ · Stil 21 · Gelişmiş 23 · tablet/mobil ayrı ayarlanabilen 8
- Ana ayarlar: İkon (`icon`), Bağlantı (`link`), Hizalama (`align`)
- Örnek: `[mb_icon icon="star" link="…" align="…"]`
- Kullanıldığı yerler: Sitede şu an kullanılmıyor.

#### İkonlu Liste — `[mb_iconlist]`
- Paletteki yeri: **Ekle → İçerik → İkonlu Liste**
- Ayarlar: İçerik 4+ · Stil 21 · Gelişmiş 23 · tablet/mobil ayrı ayarlanabilen 8
- Ana ayarlar: İkon (`icon`), Yan yana (üst bilgi çubuğu gibi) (`inline`), Sütun (`columns`), Hizalama (`justify`)
- Örnek: `[mb_iconlist icon="circle-check-big" inline="…" columns="…"]…[/mb_iconlist]`
- Kullanıldığı yerler: Hosting ve Bakım, Ana Sayfa, Sosyal Medya Yönetimi, Google Ads, Footer – Jet Bilişim

#### Bölüm Başlığı — `[mb_title]`
- Paletteki yeri: **Ekle → İçerik → Bölüm Başlığı**
- Ayarlar: İçerik 8+ · Stil 20 · Gelişmiş 32 · tablet/mobil ayrı ayarlanabilen 8
- Ana ayarlar: Başlık (`text`), Üst yazı (`overline`), Alt açıklama (`subtitle`), Etiket (`tag`), Stil (`style`), Hizalama (`align`), Sağdaki bağlantı (`link_text`), Bağlantı adresi (`link`)
- Örnek: `[mb_title text="Bölüm başlığı" overline="…" subtitle="…"]`
- Kullanıldığı yerler: Sosyal Medya Yönetimi (×9), Ana Sayfa (×8), Paketler (×7), Tuzla Web Tasarım (×7), SEO Danışmanlığı (×6), Gebze OSB Web Tasarım (×6), Hosting ve Bakım (×5), Hizmetler (×5), Google Ads (×5), SEO Analiz Raporu (×5), Jet Büyüme – Aylık Bakım, Sosyal Medya, SEO ve Google Ads Paketleri (×4), Hakkımızda (×3), Demolar (×3), Referanslar (×3), Eklentiler

#### Uyarı Kutusu — `[mb_message]`
- Paletteki yeri: **Ekle → İçerik → Uyarı Kutusu**
- Ayarlar: İçerik 4+ · Stil 17 · Gelişmiş 23 · tablet/mobil ayrı ayarlanabilen 6
- Ana ayarlar: Tür (`type`), Başlık (`title`), İkon (boşsa türe göre) (`icon`), Kapatılabilir (`dismissible`)
- Örnek: `[mb_message type="info" title="…" icon="…"]…[/mb_message]`
- Kullanıldığı yerler: Sitede şu an kullanılmıyor.

#### Arama Kutusu — `[mb_search]`
- Paletteki yeri: **Ekle → İçerik → Arama Kutusu**
- Ayarlar: İçerik 4+ · Stil 18 · Gelişmiş 23 · tablet/mobil ayrı ayarlanabilen 8
- Ana ayarlar: İpucu yazısı (`placeholder`), Buton yazısı (`button`), Stil (`style`), Hizalama (`align`)
- Örnek: `[mb_search placeholder="Sitede ara…" button="…" style="…"]`
- Kullanıldığı yerler: Sitede şu an kullanılmıyor.

#### Paylaş Butonları — `[mb_share]`
- Paletteki yeri: **Ekle → İçerik → Paylaş Butonları**
- Ayarlar: İçerik 4+ · Stil 17 · Gelişmiş 23 · tablet/mobil ayrı ayarlanabilen 7
- Ana ayarlar: Yazı (`label`), Ağlar (`networks`), Stil (`style`), Hizalama (`align`)
- Örnek: `[mb_share label="Paylaş:" networks="…" style="…"]`
- Kullanıldığı yerler: Sitede şu an kullanılmıyor.

#### Çevrilen Kutu — `[mb_flipbox]`
- Paletteki yeri: **Ekle → İçerik → Çevrilen Kutu**
- Ayarlar: İçerik 8+ · Stil 24 · Gelişmiş 23 · tablet/mobil ayrı ayarlanabilen 7
- Ana ayarlar: İkon (`f_icon`), Başlık (`f_title`), Metin (`f_text`), Arka plan görseli (`f_image`), Arka plan rengi (`f_bg`), Görsel kaplaması (`f_overlay`), Yazı rengi (`f_text_color`), Başlık (`b_title`)
- Örnek: `[mb_flipbox f_icon="rocket" f_title="Hızlı teslimat" f_text="…"]`
- Kullanıldığı yerler: Sitede şu an kullanılmıyor.

#### İçindekiler — `[mb_toc]`
- Paletteki yeri: **Ekle → İçerik → İçindekiler**
- Ayarlar: İçerik 8+ · Stil 22 · Gelişmiş 23 · tablet/mobil ayrı ayarlanabilen 6
- Ana ayarlar: Başlık (`title`), Başlık seviyeleri (`levels`), Taranacak alan (CSS seçici) (`scope`), Numaralı (1, 1.1 …) (`numbered`), Açılır / kapanır (`collapsible`), Kapalı başlasın (`collapsed`), Kaydırınca yapışık kalsın (`sticky`), Okunan bölümü vurgula (`spy`)
- Örnek: `[mb_toc title="İçindekiler" levels="3" scope="…"]`
- Kullanıldığı yerler: Sitede şu an kullanılmıyor.

#### Eylem Kartı (CTA) — `[mb_cta]`
- Paletteki yeri: **Ekle → İçerik → Eylem Kartı (CTA)**
- Ayarlar: İçerik 8+ · Stil 27 · Gelişmiş 23 · tablet/mobil ayrı ayarlanabilen 10
- Ana ayarlar: Görsel (`image`), Üst yazı (`overline`), Başlık (`title`), Başlık etiketi (`tag`), Metin (`text`), Buton (`btn_text`), Buton bağlantısı (`btn_url`), 2. buton (`btn2_text`)
- Örnek: `[mb_cta image="…" overline="…" title="…"]`
- Kullanıldığı yerler: Sitede şu an kullanılmıyor.

#### Alıntı — `[mb_quote]`
- Paletteki yeri: **Ekle → İçerik → Alıntı**
- Ayarlar: İçerik 6+ · Stil 23 · Gelişmiş 23 · tablet/mobil ayrı ayarlanabilen 7
- Ana ayarlar: Kaynak / kişi (`cite`), Ünvan / eser (`role`), Fotoğraf (`image`), Kaynak bağlantısı (`url`), "X'te paylaş" bağlantısı (`share`), Stil (`style`)
- Örnek: `[mb_quote cite="Kurucu ortak" role="…" image="…"]…[/mb_quote]`
- Kullanıldığı yerler: Sitede şu an kullanılmıyor.

#### Dil Değiştirici — `[mb_lang_switcher]`
- Paletteki yeri: **Ekle → İçerik → Dil Değiştirici**
- Ayarlar: İçerik 3+ · Stil 17 · Gelişmiş 23 · tablet/mobil ayrı ayarlanabilen 7
- Ana ayarlar: Görünüm (`style`), Gösterim (`label`), Hizalama (`align`)
- Örnek: `[mb_lang_switcher style="…" label="…" align="…"]`
- Kullanıldığı yerler: Sitede şu an kullanılmıyor.

### Yerleşim

#### Bölüm — `[mb_section]`
- Paletteki yeri: **Ekle → Yerleşim → Bölüm**
- Ayarlar: İçerik 5+ · Stil 40 · Gelişmiş 26 · tablet/mobil ayrı ayarlanabilen 11
- Ana ayarlar: Yönetici etiketi (`label`), Bölümü sabitle (pin) (`pin`), Sabit kalma mesafesi (`pin_len`), Yatay kaydırma (`hscroll`), Kart genişliği (`hs_width`)
- Örnek: `[mb_section label="…" pin="…" pin_len="200"]`
- Kullanıldığı yerler: Ana Sayfa (×12), Sosyal Medya Yönetimi (×12), Paketler (×11), Tuzla Web Tasarım (×9), Hosting ve Bakım (×8), SEO Danışmanlığı (×8), Gebze OSB Web Tasarım (×8), Google Ads (×8), Hizmetler (×7), SEO Analiz Raporu (×7), Jet Büyüme – Aylık Bakım, Sosyal Medya, SEO ve Google Ads Paketleri (×6), Hakkımızda (×5), Demolar (×5), İletişim (×3), Site Kit: ölçüm ve çerez onayı (×3), +SEO ve yapay zekâ görünürlüğü (×3), Sosyal akışlar (×3), Ürün XML akışları (×3), Ek ürün kapasitesi (×3), Excel / CSV aktarımı (×3), Yapay zekâ asistanı (×3), Çoklu dil (×3), Canlı ziyaretçi takibi (×3), Referanslar (×3), Gelişmiş katalog (×3), Eklentiler (×3), Gizlilik Politikası (×2), KVKK Aydınlatma Metni (×2), İptal, İade ve Teslimat Koşulları (×2), Kullanım Koşulları (×2), Ön Bilgilendirme Formu (×2), Çerez Politikası (×2), Blog (×2), Hizmet Sözleşmesi (×2), Mega menü – Demolar, Mega menü – Hizmetler, Header – Jet Bilişim, 404 Sayfası, Güven şeridi, Footer – Jet Bilişim

#### Satır — `[mb_row]`
- Paletteki yeri: **Ekle → Yerleşim → Satır**
- Ayarlar: İçerik 8+ · Stil 18 · Gelişmiş 24 · tablet/mobil ayrı ayarlanabilen 9
- Ana ayarlar: Yönetici etiketi (`label`), Satır genişliği (`width`), Maksimum genişlik (`custom_width`), Dikey hizalama (`v_align`), Yatay hizalama (`h_align`), Mobilde sütun sırasını ters çevir (`reverse_sm`), Düzen (`layout`), Sütun sayısı (`grid_cols`)
- Örnek: `[mb_row label="…" width="…" custom_width="…"]`
- Kullanıldığı yerler: Ana Sayfa (×22), Paketler (×21), Sosyal Medya Yönetimi (×17), Hosting ve Bakım (×13), SEO Danışmanlığı (×13), Tuzla Web Tasarım (×13), Google Ads (×13), Hizmetler (×12), SEO Analiz Raporu (×12), Gebze OSB Web Tasarım (×11), Jet Büyüme – Aylık Bakım, Sosyal Medya, SEO ve Google Ads Paketleri (×10), Demolar (×7), Hakkımızda (×6), Referanslar (×5), İletişim (×3), Site Kit: ölçüm ve çerez onayı (×3), +SEO ve yapay zekâ görünürlüğü (×3), Sosyal akışlar (×3), Ürün XML akışları (×3), Ek ürün kapasitesi (×3), Excel / CSV aktarımı (×3), Yapay zekâ asistanı (×3), Çoklu dil (×3), Canlı ziyaretçi takibi (×3), Gelişmiş katalog (×3), Eklentiler (×3), Gizlilik Politikası (×2), KVKK Aydınlatma Metni (×2), İptal, İade ve Teslimat Koşulları (×2), Kullanım Koşulları (×2), Ön Bilgilendirme Formu (×2), Çerez Politikası (×2), Blog (×2), Footer – Jet Bilişim (×2), Hizmet Sözleşmesi (×2), Mega menü – Demolar, Mega menü – Hizmetler, Header – Jet Bilişim, 404 Sayfası, Güven şeridi

#### Sütun — `[mb_col]`
- Paletteki yeri: **Ekle → Yerleşim → Sütun**
- Ayarlar: İçerik 5+ · Stil 29 · Gelişmiş 26 · tablet/mobil ayrı ayarlanabilen 10
- Ana ayarlar: Yönetici etiketi (`label`), Sütun genişliği (satır içindeki payı) (`span`), Yatay kaplama (`g_col`), Dikey kaplama (`g_row`), Hizalama (`align`)
- Örnek: `[mb_col label="…" span="12" g_col="…"]`
- Kullanıldığı yerler: Ana Sayfa (×29), Google Ads (×26), Tuzla Web Tasarım (×25), Hizmetler (×24), SEO Analiz Raporu (×24), Paketler (×22), Sosyal Medya Yönetimi (×22), Gebze OSB Web Tasarım (×22), Demolar (×20), SEO Danışmanlığı (×16), Hosting ve Bakım (×15), Hakkımızda (×12), Jet Büyüme – Aylık Bakım, Sosyal Medya, SEO ve Google Ads Paketleri (×11), Referanslar (×8), Footer – Jet Bilişim (×5), İletişim (×4), Site Kit: ölçüm ve çerez onayı (×4), +SEO ve yapay zekâ görünürlüğü (×4), Sosyal akışlar (×4), Ürün XML akışları (×4), Ek ürün kapasitesi (×4), Excel / CSV aktarımı (×4), Yapay zekâ asistanı (×4), Çoklu dil (×4), Canlı ziyaretçi takibi (×4), Gelişmiş katalog (×4), Eklentiler (×4), Header – Jet Bilişim (×3), Gizlilik Politikası (×2), KVKK Aydınlatma Metni (×2), İptal, İade ve Teslimat Koşulları (×2), Kullanım Koşulları (×2), Mega menü – Hizmetler (×2), Ön Bilgilendirme Formu (×2), Çerez Politikası (×2), Blog (×2), Hizmet Sözleşmesi (×2), Mega menü – Demolar, 404 Sayfası, Güven şeridi

#### Kaydırmalı anlatım — `[mb_scrolly]`
- Paletteki yeri: **Ekle → Yerleşim → Kaydırmalı anlatım**
- Ayarlar: İçerik 8+ · Stil 19 · Gelişmiş 24 · tablet/mobil ayrı ayarlanabilen 6
- Ana ayarlar: Yönetici etiketi (`label`), Görsel konumu (`media_pos`), Görsel genişliği (`media_width`), Görsel yüksekliği (`media_h`), Görsel geçişi (`effect`), Adım yüksekliği (`step_h`), Adım numaraları (`numbers`), İlerleme çizgisi (`rail`)
- Örnek: `[mb_scrolly label="…" media_pos="…" media_width="50"]`
- Kullanıldığı yerler: Sitede şu an kullanılmıyor.

#### Anlatım adımı — `[mb_scrolly_step]`
- Paletteki yeri: **Ekle → Yerleşim → Anlatım adımı**
- Ayarlar: İçerik 7+ · Stil 17 · Gelişmiş 23 · tablet/mobil ayrı ayarlanabilen 6
- Ana ayarlar: Başlık (`title`), Numara / etiket (`number`), Görsel (`image`), Alternatif metin (`alt`), Video (MP4) (`video`), Bağlantı metni (`link_text`), Bağlantı (`link`)
- Örnek: `[mb_scrolly_step title="Adım başlığı" number="…" image="…"]…[/mb_scrolly_step]`
- Kullanıldığı yerler: Sitede şu an kullanılmıyor.

#### Banner — `[mb_banner]`
- Paletteki yeri: **Ekle → Yerleşim → Banner**
- Ayarlar: İçerik 6+ · Stil 27 · Gelişmiş 27 · tablet/mobil ayrı ayarlanabilen 10
- Ana ayarlar: Yönetici etiketi (`label`), Arka plan görseli (`image`), Tüm banner bağlantısı (`link`), Dikey konum (`v_align`), Yatay konum (`h_align`), İçerik genişliği (`content_width`)
- Örnek: `[mb_banner label="…" image="…" link="…"]`
- Kullanıldığı yerler: Sitede şu an kullanılmıyor.

#### Banner Izgarası — `[mb_bannergrid]`
- Paletteki yeri: **Ekle → Yerleşim → Banner Izgarası**
- Ayarlar: İçerik 1+ · Stil 20 · Gelişmiş 24 · tablet/mobil ayrı ayarlanabilen 7
- Ana ayarlar: Düzen (`pattern`)
- Örnek: `[mb_bannergrid pattern="a"]`
- Kullanıldığı yerler: Sitede şu an kullanılmıyor.

#### Kayan Şerit — `[mb_marquee]`
- Paletteki yeri: **Ekle → Yerleşim → Kayan Şerit**
- Ayarlar: İçerik 8+ · Stil 36 · Gelişmiş 24 · tablet/mobil ayrı ayarlanabilen 9
- Ana ayarlar: İçerik (`mode`), Metinler (her satır bir öğe) (`items`), 2. satır metinleri (boş: aynısı) (`items2`), Şerit bağlantısı (isteğe bağlı) (`link`), Hız (`speed`), Yön (`direction`), Satır (`rows`), Üzerine gelince dursun (`pause_hover`)
- Örnek: `[mb_marquee mode="…" items="…" items2="…"]`
- Kullanıldığı yerler: Sitede şu an kullanılmıyor.

### Medya

#### Görsel — `[mb_image]`
- Paletteki yeri: **Ekle → Medya → Görsel**
- Ayarlar: İçerik 5+ · Stil 25 · Gelişmiş 26 · tablet/mobil ayrı ayarlanabilen 7
- Ana ayarlar: Görsel (`image`), Alternatif metin (`alt`), Genişlik (`width`), Hizalama (`align`), En-boy oranı (`ratio`)
- Örnek: `[mb_image image="…" alt="…" width="…"]`
- Kullanıldığı yerler: Ana Sayfa (×5), Demolar (×5), Paketler (×3), Footer – Jet Bilişim (×2), Hosting ve Bakım, Sosyal Medya Yönetimi, Google Ads

#### Video — `[mb_video]`
- Paletteki yeri: **Ekle → Medya → Video**
- Ayarlar: İçerik 8+ · Stil 19 · Gelişmiş 23 · tablet/mobil ayrı ayarlanabilen 6
- Ana ayarlar: Video (`url`), Kapak görseli (`poster`), Oran (`ratio`), Otomatik oynat (sessiz) (`autoplay`), Döngü (`loop`), Oynatıcı kontrolleri (`controls`), Başlangıç saniyesi (`start`), Hızlı yükleme (tıklayınca oynatıcıyı yükle) (`lazy`)
- Örnek: `[mb_video url="…" poster="…" ratio="16/9"]`
- Kullanıldığı yerler: Sitede şu an kullanılmıyor.

#### Galeri — `[mb_gallery]`
- Paletteki yeri: **Ekle → Medya → Galeri**
- Ayarlar: İçerik 8+ · Stil 21 · Gelişmiş 23 · tablet/mobil ayrı ayarlanabilen 8
- Ana ayarlar: Görseller (`images`), Düzen (`layout`), Sütun / görünen öğe (`columns`), En-boy oranı (`ratio`), Kategori filtresi (`filter`), “Tümü” düğmesi (`filter_all`), İlk gösterilecek sayı (`limit`), Daha fazla butonu (`more_text`)
- Örnek: `[mb_gallery layout="…" columns="3"]`
- Kullanıldığı yerler: Referanslar

#### Slider — `[mb_slider]`
- Paletteki yeri: **Ekle → Medya → Slider**
- Ayarlar: İçerik 8+ · Stil 20 · Gelişmiş 24 · tablet/mobil ayrı ayarlanabilen 8
- Ana ayarlar: Geçiş efekti (`effect`), Geçiş hızı (`speed`), Aynı anda görünen slayt (`per_view`), Tam ekran yükseklik (`full_screen`), Otomatik geçiş (`autoplay`), Slayt süresi (sn) (`interval`), Fare üzerindeyken dur (`pause_hover`), Süre çubuğu (`progress`)
- Örnek: `[mb_slider effect="…" speed="900" per_view="1"]`
- Kullanıldığı yerler: Sitede şu an kullanılmıyor.

#### Slayt — `[mb_slide]`
- Paletteki yeri: **Ekle → Medya → Slayt**
- Ayarlar: İçerik 8+ · Stil 24 · Gelişmiş 24 · tablet/mobil ayrı ayarlanabilen 10
- Ana ayarlar: Yönetici etiketi (`label`), Ken Burns (görsel hareketi) (`kenburns`), Ken Burns süresi (`kb_dur`), Bu slaytın geçiş efekti (`transition`), Bu slaytın süresi (sn) (`duration`), Slayt bağlantısı (`link`), Sekme alt yazısı (`subtitle`), Dikey hizalama (`v_align`)
- Örnek: `[mb_slide label="…" kenburns="…" kb_dur="10"]`
- Kullanıldığı yerler: Sitede şu an kullanılmıyor.

#### Logo Şeridi — `[mb_logos]`
- Paletteki yeri: **Ekle → Medya → Logo Şeridi**
- Ayarlar: İçerik 4+ · Stil 21 · Gelişmiş 23 · tablet/mobil ayrı ayarlanabilen 8
- Ana ayarlar: Logolar (`images`), Görünüm (`mode`), Sütun (`columns`), Kayma süresi (tur) (`speed`)
- Örnek: `[mb_logos mode="…" columns="6"]`
- Kullanıldığı yerler: Sitede şu an kullanılmıyor.

#### Harita — `[mb_map]`
- Paletteki yeri: **Ekle → Medya → Harita**
- Ayarlar: İçerik 7+ · Stil 20 · Gelişmiş 23 · tablet/mobil ayrı ayarlanabilen 7
- Ana ayarlar: Harita (`provider`), Adres veya yer adı (`address`), Enlem (isteğe bağlı) (`lat`), Boylam (isteğe bağlı) (`lng`), Görünüm (`map_type`), “Yol tarifi al” butonu (`directions`), Yakınlık (`zoom`)
- Örnek: `[mb_map provider="…" address="İstanbul" lat="…"]`
- Kullanıldığı yerler: İletişim

#### Video Butonu — `[mb_videobutton]`
- Paletteki yeri: **Ekle → Medya → Video Butonu**
- Ayarlar: İçerik 5+ · Stil 19 · Gelişmiş 24 · tablet/mobil ayrı ayarlanabilen 8
- Ana ayarlar: Video adresi (`url`), Yanındaki yazı (`label`), Stil (`style`), Dalga efekti (`pulse`), Hizalama (`align`)
- Örnek: `[mb_videobutton url="…" label="…" style="…"]`
- Kullanıldığı yerler: Sitede şu an kullanılmıyor.

#### Görsel Kutu — `[mb_imagebox]`
- Paletteki yeri: **Ekle → Medya → Görsel Kutu**
- Ayarlar: İçerik 8+ · Stil 19 · Gelişmiş 26 · tablet/mobil ayrı ayarlanabilen 6
- Ana ayarlar: Görsel (`image`), Başlık (`title`), Üst yazı / kategori (`subtitle`), Bağlantı (`link`), Bağlantı yazısı (`link_text`), Stil (`style`), Görsel oranı (`ratio`), Hizalama (`align`)
- Örnek: `[mb_imagebox image="…" title="Kutu başlığı" subtitle="…"]…[/mb_imagebox]`
- Kullanıldığı yerler: Hizmetler (×6)

#### İşaretli Görsel — `[mb_hotspot]`
- Paletteki yeri: **Ekle → Medya → İşaretli Görsel**
- Ayarlar: İçerik 2+ · Stil 19 · Gelişmiş 24 · tablet/mobil ayrı ayarlanabilen 6
- Ana ayarlar: Görsel (`image`), Oran (görsel yoksa) (`ratio`)
- Örnek: `[mb_hotspot image="…" ratio="16/9"]`
- Kullanıldığı yerler: Sitede şu an kullanılmıyor.

#### İşaret — `[mb_hotspot_pin]`
- Palette yok; **İşaretli Görsel** içinde “Öğe ekle / +” ile eklenir
- Ayarlar: İçerik 5+ · Stil 0 · Gelişmiş 4 · tablet/mobil ayrı ayarlanabilen 1
- Ana ayarlar: Başlık (`title`), Yatay konum (`x`), Dikey konum (`y`), Bağlantı (`link`), Kutucuk yönü (`side`)
- Örnek: `[mb_hotspot_pin title="Özellik" x="50" y="50"]…[/mb_hotspot_pin]`
- Kullanıldığı yerler: Sitede şu an kullanılmıyor.

#### Önce / Sonra — `[mb_compare_img]`
- Paletteki yeri: **Ekle → Medya → Önce / Sonra**
- Ayarlar: İçerik 8+ · Stil 23 · Gelişmiş 23 · tablet/mobil ayrı ayarlanabilen 6
- Ana ayarlar: Önce görseli (`before`), Sonra görseli (`after`), Önce etiketi (`before_label`), Sonra etiketi (`after_label`), Başlangıç konumu (`start`), Yön (`orientation`), Fareyle üzerinde gezinince kaysın (`hover_move`), Oran (`ratio`)
- Örnek: `[mb_compare_img before="…" after="…" before_label="Önce"]`
- Kullanıldığı yerler: Sitede şu an kullanılmıyor.

#### Dönen Rozet — `[mb_badge_circle]`
- Paletteki yeri: **Ekle → Medya → Dönen Rozet**
- Ayarlar: İçerik 8+ · Stil 26 · Gelişmiş 23 · tablet/mobil ayrı ayarlanabilen 8
- Ana ayarlar: Çevre yazısı (`text`), Merkez (`center`), İkon (`icon`), Merkez görseli / logo (`image`), Merkez yazısı (`center_text`), Bağlantı (`link`), Bir tur süresi (`speed`), Ters yöne dönsün (`reverse`)
- Örnek: `[mb_badge_circle text="…" center="…" icon="arrow-up-right"]`
- Kullanıldığı yerler: Sitede şu an kullanılmıyor.

#### Katmanlı slider — `[mb_layerslider]`
- Paletteki yeri: **Ekle → Medya → Katmanlı slider**
- Ayarlar: İçerik 2+ · Stil 17 · Gelişmiş 23 · tablet/mobil ayrı ayarlanabilen 6
- Ana ayarlar: Slider bloğu (`block`), Otomatik oynat (`autoplay`)
- Örnek: `[mb_layerslider block="…" autoplay="true"]`
- Kullanıldığı yerler: Ana Sayfa

### Kurumsal

#### Sayaç — `[mb_counter]`
- Paletteki yeri: **Ekle → Kurumsal → Sayaç**
- Ayarlar: İçerik 7+ · Stil 24 · Gelişmiş 23 · tablet/mobil ayrı ayarlanabilen 9
- Ana ayarlar: Sayı (`number`), Ön ek (`prefix`), Son ek (`suffix`), Açıklama (`label`), İkon (isteğe bağlı) (`icon`), Sayma süresi (`duration`), Hizalama (`align`)
- Örnek: `[mb_counter number="250" prefix="…" suffix="+"]`
- Kullanıldığı yerler: Sitede şu an kullanılmıyor.

#### Ekip Üyesi — `[mb_team]`
- Paletteki yeri: **Ekle → Kurumsal → Ekip Üyesi**
- Ayarlar: İçerik 8+ · Stil 17 · Gelişmiş 24 · tablet/mobil ayrı ayarlanabilen 6
- Ana ayarlar: Fotoğraf (`image`), Ad soyad (`name`), Ünvan (`role`), Stil (`style`), LinkedIn (`linkedin`), Instagram (`instagram`), E-posta (`email`), Telefon (`phone`)
- Örnek: `[mb_team image="…" name="Ad Soyad" role="Kurucu"]…[/mb_team]`
- Kullanıldığı yerler: Sitede şu an kullanılmıyor.

#### Fiyat Tablosu — `[mb_price]`
- Paletteki yeri: **Ekle → Kurumsal → Fiyat Tablosu**
- Ayarlar: İçerik 8+ · Stil 18 · Gelişmiş 24 · tablet/mobil ayrı ayarlanabilen 6
- Ana ayarlar: Paket adı (`title`), Kısa açıklama (`description`), Fiyat (`price`), Dönem (`period`), Özellikler (`features`), Buton metni (`button_text`), Buton bağlantısı (`button_link`), Öne çıkan paket (`featured`)
- Örnek: `[mb_price title="Standart" description="…" price="₺1.990"]`
- Kullanıldığı yerler: Paketler (×10), SEO Analiz Raporu (×3)

#### Müşteri Yorumu — `[mb_testimonial]`
- Paletteki yeri: **Ekle → Kurumsal → Müşteri Yorumu**
- Ayarlar: İçerik 6+ · Stil 17 · Gelişmiş 24 · tablet/mobil ayrı ayarlanabilen 6
- Ana ayarlar: Ad (`name`), Ünvan / şirket (`role`), Fotoğraf (`image`), Puan (`rating`), Stil (`style`), Hizalama (`align`)
- Örnek: `[mb_testimonial name="Müşteri adı" role="…" image="…"]…[/mb_testimonial]`
- Kullanıldığı yerler: Sitede şu an kullanılmıyor.

#### Geri Sayım — `[mb_countdown]`
- Paletteki yeri: **Ekle → Kurumsal → Geri Sayım**
- Ayarlar: İçerik 3+ · Stil 20 · Gelişmiş 23 · tablet/mobil ayrı ayarlanabilen 6
- Ana ayarlar: Bitiş tarihi (`date`), Bitince yazı (`finish`), Hizalama (`align`)
- Örnek: `[mb_countdown date="2026-11-28 23:59" finish="Kampanya sona erdi" align="…"]`
- Kullanıldığı yerler: Sitede şu an kullanılmıyor.

#### İlerleme Çubukları — `[mb_progress]`
- Paletteki yeri: **Ekle → Kurumsal → İlerleme Çubukları**
- Ayarlar: İçerik 0+ · Stil 20 · Gelişmiş 23 · tablet/mobil ayrı ayarlanabilen 6
- Ana ayarlar: —
- Örnek: `[mb_progress]…[/mb_progress]`
- Kullanıldığı yerler: Sitede şu an kullanılmıyor.

#### Proje Galerisi — `[mb_portfolio]`
- Paletteki yeri: **Ekle → Kurumsal → Proje Galerisi**
- Ayarlar: İçerik 8+ · Stil 26 · Gelişmiş 24 · tablet/mobil ayrı ayarlanabilen 7
- Ana ayarlar: Sütun (`columns`), Kategori sekmeleri (`filter`), Sekmeler (`tabs`), "Tümü" sekmesini göster (`all_show`), "Tümü" sekmesinin adı (`all_label`), Açılışta seçili sekme (`tab_default`), Sekmelerde proje sayısını göster (`tab_count`), Seçili sekme adreste görünsün (#kategori, paylaşılabilir) (`tab_hash`)
- Örnek: `[mb_portfolio columns="3" filter="true" tabs="…"]`
- Kullanıldığı yerler: Sitede şu an kullanılmıyor.

#### Proje — `[mb_portfolio_item]`
- Palette yok; **Proje Galerisi** içinde “Öğe ekle / +” ile eklenir
- Ayarlar: İçerik 5+ · Stil 0 · Gelişmiş 5 · tablet/mobil ayrı ayarlanabilen 1
- Ana ayarlar: Görsel (`image`), Başlık (`title`), Kategori (`category`), Alt yazı (`subtitle`), Bağlantı (`link`)
- Örnek: `[mb_portfolio_item image="…" title="Proje adı" category="…"]`
- Kullanıldığı yerler: Sitede şu an kullanılmıyor.

#### Teknik Tablo — `[mb_spec]`
- Paletteki yeri: **Ekle → Kurumsal → Teknik Tablo**
- Ayarlar: İçerik 7+ · Stil 26 · Gelişmiş 23 · tablet/mobil ayrı ayarlanabilen 6
- Ana ayarlar: Başlık (`title`), Satırlar (`rows`), Düzen (`layout`), Birim ayrı sütunda (`unit_col`), Teknik föy butonu (`btn_text`), Föy dosyası adresi (`btn_url`), Yapısal veri (Ürün özellikleri) (`schema`)
- Örnek: `[mb_spec title="Teknik özellikler" layout="…"]`
- Kullanıldığı yerler: Sitede şu an kullanılmıyor.

#### Belgeler / Katalog — `[mb_docs]`
- Paletteki yeri: **Ekle → Kurumsal → Belgeler / Katalog**
- Ayarlar: İçerik 5+ · Stil 23 · Gelişmiş 24 · tablet/mobil ayrı ayarlanabilen 7
- Ana ayarlar: Düzen (`layout`), Sütun (`columns`), "İndir" yazısı (`dl_text`), "Görüntüle" yazısı (`view_text`), PDF önizlemesi pencerede açılsın (`view_modal`)
- Örnek: `[mb_docs layout="…" columns="3" dl_text="İndir"]`
- Kullanıldığı yerler: Sitede şu an kullanılmıyor.

#### Belge — `[mb_doc]`
- Paletteki yeri: **Ekle → Kurumsal → Belge**
- Ayarlar: İçerik 8+ · Stil 1 · Gelişmiş 4 · tablet/mobil ayrı ayarlanabilen 1
- Ana ayarlar: Başlık (`title`), Dosya (`file`), Kısa açıklama (`desc`), Kapak / logo (`thumb`), Belge / sertifika no (`cert_no`), Geçerlilik tarihi (`valid`), Veren kuruluş (`issuer`), Tür (otomatik) (`ext`)
- Örnek: `[mb_doc title="Belge adı" file="…" desc="…"]`
- Kullanıldığı yerler: Sitede şu an kullanılmıyor.

#### Fiyat Paketleri — `[mb_pricing]`
- Paletteki yeri: **Ekle → Kurumsal → Fiyat Paketleri**
- Ayarlar: İçerik 7+ · Stil 22 · Gelişmiş 24 · tablet/mobil ayrı ayarlanabilen 7
- Ana ayarlar: Dönem anahtarı (`toggle`), 1. dönem adı (`label_a`), 2. dönem adı (`label_b`), İndirim rozeti (`discount`), 2. dönem seçili başlasın (`start_b`), Sütun (`columns`), Öne çıkan paket büyük görünsün (`v_center`)
- Örnek: `[mb_pricing toggle="true" label_a="Aylık" label_b="Yıllık"]`
- Kullanıldığı yerler: Sitede şu an kullanılmıyor.

#### Fiyat Paketi — `[mb_price_plan]`
- Paletteki yeri: **Ekle → Kurumsal → Fiyat Paketi**
- Ayarlar: İçerik 8+ · Stil 19 · Gelişmiş 23 · tablet/mobil ayrı ayarlanabilen 6
- Ana ayarlar: Paket adı (`name`), Kısa açıklama (`desc`), İkon (`icon`), Fiyat (1. dönem) (`price`), Dönem yazısı (1.) (`period`), Fiyat (2. dönem) (`price_b`), Dönem yazısı (2.) (`period_b`), Eski fiyat (üstü çizili) (`old`)
- Örnek: `[mb_price_plan name="Standart" desc="…" icon="…"]`
- Kullanıldığı yerler: Sitede şu an kullanılmıyor.

#### Karşılaştırma Tablosu — `[mb_compare_table]`
- Paletteki yeri: **Ekle → Kurumsal → Karşılaştırma Tablosu**
- Ayarlar: İçerik 7+ · Stil 23 · Gelişmiş 23 · tablet/mobil ayrı ayarlanabilen 6
- Ana ayarlar: Paketler (sütunlar) (`plans`), Özellikler (satırlar) (`rows`), Öne çıkan sütun (`highlight`), Öne çıkan etiketi (`hl_label`), İlk sütun başlığı (`feature_h`), Başlık satırı yapışkan (`sticky`), Başlıkta butonlar (`buttons`)
- Örnek: `[mb_compare_table highlight="2"]`
- Kullanıldığı yerler: Sitede şu an kullanılmıyor.

#### Yorumlar (Kaydırmalı / Duvar) — `[mb_testimonials]`
- Paletteki yeri: **Ekle → Kurumsal → Yorumlar (Kaydırmalı / Duvar)**
- Ayarlar: İçerik 8+ · Stil 21 · Gelişmiş 24 · tablet/mobil ayrı ayarlanabilen 7
- Ana ayarlar: Düzen (`layout`), Görünen kart sayısı (`columns`), Otomatik geçiş (`autoplay`), Geçiş süresi (`interval`), Oklar (`arrows`), Noktalar (`dots`), Şerit hızı (`speed`), Kart genişliği (`card_w`)
- Örnek: `[mb_testimonials layout="…" columns="3" autoplay="true"]`
- Kullanıldığı yerler: Sitede şu an kullanılmıyor.

#### Menü / Fiyat Listesi — `[mb_pricelist]`
- Paletteki yeri: **Ekle → Kurumsal → Menü / Fiyat Listesi**
- Ayarlar: İçerik 3+ · Stil 24 · Gelişmiş 23 · tablet/mobil ayrı ayarlanabilen 7
- Ana ayarlar: Ürünler (`items`), Sütun (`columns`), Görselleri göster (`images`)
- Örnek: `[mb_pricelist columns="1" images="true"]`
- Kullanıldığı yerler: Sitede şu an kullanılmıyor.

#### Zaman Çizelgesi — `[mb_timeline]`
- Paletteki yeri: **Ekle → Kurumsal → Zaman Çizelgesi**
- Ayarlar: İçerik 6+ · Stil 23 · Gelişmiş 23 · tablet/mobil ayrı ayarlanabilen 6
- Ana ayarlar: Olaylar (`items`), Yön (`orientation`), Yerleşim (`layout`), İşaret (`bubble`), Çizgi kaydırdıkça çizilsin (`draw`), Olaylar belirerek gelsin (`reveal`)
- Örnek: `[mb_timeline orientation="…" layout="…"]`
- Kullanıldığı yerler: Sitede şu an kullanılmıyor.

### Site

#### Konum yolu (breadcrumb) — `[mb_breadcrumb]`
- Paletteki yeri: **Ekle → Site → Konum yolu (breadcrumb)**
- Ayarlar: İçerik 1+ · Stil 17 · Gelişmiş 23 · tablet/mobil ayrı ayarlanabilen 6
- Ana ayarlar: Hizalama (`align`)
- Örnek: `[mb_breadcrumb align="…"]`
- Kullanıldığı yerler: Sitede şu an kullanılmıyor.

#### Logo — `[mb_logo]`
- Paletteki yeri: **Ekle → Site → Logo**
- Ayarlar: İçerik 3+ · Stil 19 · Gelişmiş 23 · tablet/mobil ayrı ayarlanabilen 8
- Ana ayarlar: Logo genişliği (`width`), Sloganı göster (`tagline`), Açık renk logo (şeffaf header) (`light_logo`)
- Örnek: `[mb_logo width="160" tagline="…" light_logo="…"]`
- Kullanıldığı yerler: Header – Jet Bilişim

#### Menü — `[mb_menu]`
- Paletteki yeri: **Ekle → Site → Menü**
- Ayarlar: İçerik 8+ · Stil 22 · Gelişmiş 23 · tablet/mobil ayrı ayarlanabilen 6
- Ana ayarlar: Menü türü (`type`), Menü (`menu`), Yön (`direction`), Hizalama (`align`), Hamburger menüye dönüş (`collapse`), Mobilde açılış (`mobile`), Panel yönü (`side`), Düğme yazısı (`trigger_label`)
- Örnek: `[mb_menu type="…" menu="…" direction="horizontal"]`
- Kullanıldığı yerler: Footer – Jet Bilişim (×3), Header – Jet Bilişim

#### Sosyal İkonlar — `[mb_social]`
- Paletteki yeri: **Ekle → Site → Sosyal İkonlar**
- Ayarlar: İçerik 8+ · Stil 19 · Gelişmiş 23 · tablet/mobil ayrı ayarlanabilen 6
- Ana ayarlar: Stil (`style`), Hizalama (`align`), Facebook (`facebook`), Instagram (`instagram`), X (Twitter) (`x`), LinkedIn (`linkedin`), YouTube (`youtube`), WhatsApp (`whatsapp`)
- Örnek: `[mb_social style="…" align="…" facebook="…"]`
- Kullanıldığı yerler: İletişim

#### Yan Panel — `[mb_offcanvas]`
- Paletteki yeri: **Ekle → Site → Yan Panel**
- Ayarlar: İçerik 4+ · Stil 2 · Gelişmiş 4 · tablet/mobil ayrı ayarlanabilen 1
- Ana ayarlar: Panel kimliği (`oc_id`), Panel başlığı (`title`), Yön (`side`), Genişlik (`width`)
- Örnek: `[mb_offcanvas oc_id="panel" title="…" side="right"]`
- Kullanıldığı yerler: Sitede şu an kullanılmıyor.

#### Son Yazılar — `[mb_posts]`
- Paletteki yeri: **Ekle → Site → Son Yazılar**
- Ayarlar: İçerik 8+ · Stil 17 · Gelişmiş 23 · tablet/mobil ayrı ayarlanabilen 7
- Ana ayarlar: Yazı sayısı (`count`), Sütun (`columns`), Kategori (`category`), Sıralama (`orderby`), Kart stili (`style`), Öne çıkan görsel (`image`), Özet (`excerpt`), Tarih ve okuma süresi (`meta`)
- Örnek: `[mb_posts count="3" columns="3" category="…"]`
- Kullanıldığı yerler: Ana Sayfa, Blog

### Sosyal

#### Google Yorumları — `[mb_google_reviews]`
- Paletteki yeri: **Ekle → Sosyal → Google Yorumları**
- Ayarlar: İçerik 8+ · Stil 23 · Gelişmiş 23 · tablet/mobil ayrı ayarlanabilen 7
- Ana ayarlar: Düzen (`layout`), Kaynak (`source`), En düşük puan (`min_rating`), En fazla yorum (`max`), Sıralama (`sort`), Sütun / görünen kart (`columns`), Köşe (`position`), Üstte puan özeti (`header`)
- Örnek: `[mb_google_reviews layout="carousel" source="auto" min_rating="0"]`
- Kullanıldığı yerler: Sitede şu an kullanılmıyor.

#### Instagram Akışı — `[mb_instagram_feed]`
- Paletteki yeri: **Ekle → Sosyal → Instagram Akışı**
- Ayarlar: İçerik 8+ · Stil 20 · Gelişmiş 23 · tablet/mobil ayrı ayarlanabilen 7
- Ana ayarlar: Düzen (`layout`), Gönderi sayısı (`count`), Sütun (`columns`), Tıklayınca (`click`), Profil başlığı (`header`), Takip et düğmesi (`follow`), Düğme yazısı (`follow_text`), Yalnızca bu etiketler (`hashtag`)
- Örnek: `[mb_instagram_feed layout="grid" count="8" columns="4"]`
- Kullanıldığı yerler: Sitede şu an kullanılmıyor.

#### TikTok Akışı — `[mb_tiktok_feed]`
- Paletteki yeri: **Ekle → Sosyal → TikTok Akışı**
- Ayarlar: İçerik 8+ · Stil 18 · Gelişmiş 23 · tablet/mobil ayrı ayarlanabilen 7
- Ana ayarlar: Düzen (`layout`), Kaynak (`source`), Video adresleri (`urls`), Video sayısı (`count`), Sütun / görünen kart (`columns`), Oynatma (`play`), Açıklama (`caption`), İzlenme / beğeni (varsa) (`stats`)
- Örnek: `[mb_tiktok_feed layout="grid" source="auto" urls="…"]`
- Kullanıldığı yerler: Sitede şu an kullanılmıyor.

### Jet

#### Paket demoları — `[mb_paket_demolari]`
- Paletteki yeri: **Ekle → Jet → Paket demoları**
- Ayarlar: İçerik 4+ · Stil 17 · Gelişmiş 23 · tablet/mobil ayrı ayarlanabilen 6
- Ana ayarlar: Her sekmede gösterilecek demo sayısı (`adet`), Açılışta seçili paket (`secili`), Başlık (`baslik`), Açıklama (`alt`)
- Örnek: `[mb_paket_demolari adet="5" secili="…" baslik="Paketlere göre örnek demolar"]`
- Kullanıldığı yerler: Sitede şu an kullanılmıyor.

#### Jet Büyüme paketleri — `[mb_jet_buyume]`
- Paletteki yeri: **Ekle → Jet → Jet Büyüme paketleri**
- Ayarlar: İçerik 0+ · Stil 17 · Gelişmiş 23 · tablet/mobil ayrı ayarlanabilen 6
- Ana ayarlar: —
- Örnek: `[mb_jet_buyume]`
- Kullanıldığı yerler: Paketler, Jet Büyüme – Aylık Bakım, Sosyal Medya, SEO ve Google Ads Paketleri
