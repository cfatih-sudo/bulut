# jetbilisim.com.tr — Güvenlik Değerlendirme Raporu

**Hazırlanma tarihi:** 2026-10-29
**Hedef:** `jetbilisim.com.tr` ve alt alan adları
**Test türü:** Pasif / müdahalesiz dış değerlendirme (OWASP Top 10 ve ASVS temelli)
**Yetki:** Site sahibi tarafından sözlü olarak verildi (yazılı kapsam belgesi önerilir)

> **Önemli not — kapsam sınırı:** Bu değerlendirme yalnızca **pasif ve müdahalesiz** tekniklerle yapılmıştır: normal bir ziyaretçinin erişebileceği herkese açık HTTP yanıtları, başlıklar, DNS/alt alan adı yoklaması ve dosya varlık kontrolü. **Aktif sömürü, port taraması, kaba kuvvet (brute-force), zafiyet tarayıcısı, fuzzing veya kimlik doğrulama denemesi yapılmamıştır.** Gerçek bir sızma testi (pentest) için bunların kontrollü bir ortamda, yazılı kapsam ve zaman penceresiyle ayrıca yürütülmesi gerekir. Ayrıca TLS/sertifika katmanı test ortamının ağ vekili nedeniyle doğrulanamamıştır (bkz. Bölüm 6.8).

---

## 1. Yönetici Özeti

Jet Bilişim web varlığı **olgun bir güvenlik temeline** sahip: site Cloudflare arkasında, modern HTTP güvenlik başlıklarının çoğu mevcut, hassas dosyalar (`.env`, `.git`, yedekler, veritabanı) dışarıya kapatılmış ve oturum çerezleri doğru bayraklarla (`Secure`, `HttpOnly`, `SameSite`) işaretlenmiş durumda. Bu, pek çok KOBİ sitesinin üzerinde bir seviyedir.

Buna karşılık, **öncelikli olarak ele alınması gereken** birkaç konu var:

| # | Bulgu | Önem | Durum |
|---|-------|------|-------|
| B-01 | cPanel ve Webmail alt alan adları internete açık | **Orta** | İnceleme gerek |
| B-02 | `/admin/` yönetim paneli girişi tüm internete açık | **Orta** | İnceleme gerek |
| B-03 | İçerik Güvenlik Politikası (CSP) çok dar — XSS'e karşı koruma zayıf | **Orta** | İyileştir |
| B-04 | `security.txt` alan adı uyuşmuyor ve süresi yakında doluyor | **Düşük** | İyileştir |
| B-05 | HSTS'te `includeSubDomains` ve `preload` yok | **Düşük** | İyileştir |
| B-06 | `robots.txt` yönetim dizinlerini ifşa ediyor | **Bilgi** | Kabul edilebilir |
| B-07 | Sayfada WordPress (`wp-content`) izleri — CMS özel olmasına rağmen | **Bilgi** | Doğrula |
| B-08 | TLS/sertifika yapılandırması bu ortamdan doğrulanamadı | **Bilgi** | Dış test gerek |

**Genel değerlendirme:** Orta-düşük risk. Kritik bir açık **tespit edilmedi**; ancak yönetim yüzeylerinin (cPanel, webmail, admin) erişim kısıtlaması en yüksek getirili iyileştirmedir.

---

## 2. Kapsam ve Metodoloji

**Değerlendirilen varlıklar:**
- Ana site: `https://jetbilisim.com.tr`
- Alt alan adları (yoklanan): `merkez`, `demo`, `lisans`, `www`, `cpanel`, `webmail`, ayrıca `api, app, panel, portal, admin, login, test, dev, staging, mail, crm, erp, mobil, blog, shop, bayi, destek, vpn, ns1, ns2`

**Kullanılan teknikler (hepsi pasif):**
1. HTTP yanıt başlığı analizi (güvenlik başlıkları, çerezler, sunucu parmak izi)
2. HTTP→HTTPS ve www yönlendirme kontrolü
3. Alt alan adı canlılık yoklaması (tek GET isteği)
4. `robots.txt`, `sitemap.xml`, `security.txt`, `llms.txt` incelemesi
5. Yaygın hassas dosya/dizin varlık kontrolü (yalnızca durum kodu — içerik indirilmedi)
6. Çerez güvenlik bayrağı analizi

**Yöntem referansları:** OWASP Web Security Testing Guide (WSTG), OWASP Top 10 (2021), OWASP Secure Headers Project, Mozilla Observatory ölçütleri.

---

## 3. Keşif Bulguları (Varlık Envanteri)

### 3.1 Teknoloji yığını
- **CDN/WAF:** Cloudflare (`server: cloudflare`, `cf-ray`, NEL/`report-to` raporlaması aktif)
- **CMS:** Özel geliştirme — "Mimar CMS" / "JET Core" (admin çerezi `mimarcms=...`, `x-cms-cache: HIT`)
- **İş tanımı (llms.txt'ten):** Tuzla/İstanbul merkezli web + dijital reklam ajansı; Mimar CMS ile kurumsal site ve ürün kataloğu, SEO, Google Ads, hosting.

### 3.2 Canlı alt alan adları

| Alt alan | HTTP | Açıklama |
|----------|------|----------|
| `merkez.` | 301 → ana site | Ana siteye yönleniyor |
| `demo.` | 200 | "JET Core Demo Vitrini – 213 hazır kurumsal web sitesi tasarımı" |
| `lisans.` | 404 | İçerik yok / yapılandırılmamış (ama DNS'te mevcut) |
| `www.` | 301 → apex | Normal yönlendirme |
| `cpanel.` | 200 | cPanel arayüzü ("Shared IP" varsayılan sayfası) |
| `webmail.` | 200 | Webmail arayüzü ("Shared IP" varsayılan sayfası) |

### 3.3 Açık dosyalar
- `robots.txt`: `/admin/`, `/data/`, `/*?s=`, `/*?ara=` disallow; `llms.txt` ve `sitemap.xml` işaret ediliyor.
- `sitemap.xml`: sayfa, yazı ve kategori alt haritaları.
- `.well-known/security.txt`: `Contact: mailto:info@jetbilgisayar.com`, `Expires: 2026-11-29`.
- `llms.txt`: şirket özeti, iletişim ve sayfa listesi (kasıtlı, sorun değil).

---

## 4. Olumlu Bulgular (Doğru Yapılanlar)

Bunlar korunmalı; bir sonraki değişiklikte yanlışlıkla geri alınmamalı:

- ✅ **Cloudflare önünde** — DDoS yutma, WAF ve bot yönetimi imkânı.
- ✅ **HTTP→HTTPS** zorlu, **HSTS** aktif (`max-age=31536000`).
- ✅ **Güçlü başlık seti:** `X-Content-Type-Options: nosniff`, `X-Frame-Options: SAMEORIGIN`, `Referrer-Policy: strict-origin-when-cross-origin`, `Permissions-Policy` (kamera/mikrofon/konum kapalı, `interest-cohort=()`), `Cross-Origin-Opener-Policy`, `Cross-Origin-Resource-Policy: same-site`, `X-Permitted-Cross-Domain-Policies: none`.
- ✅ **Hassas dosyalar kapalı:** `.env`, `.git/config`, `.htaccess`, `wp-config.php`, `backup.zip`, `server-status`, `data/db.sqlite` → **403**; `config.php`, `phpinfo.php` → 404. Açık bir sızıntı görülmedi.
- ✅ **`/data/` dizini** robots'ta listelenmesine rağmen **403** ile kapalı.
- ✅ **Oturum çerezi doğru:** `mimarcms=...; Secure; HttpOnly; SameSite=Lax` — XSS ile çerez çalınmasına ve birçok CSRF senaryosuna karşı dirençli.
- ✅ **Admin'de ek CSP:** `/admin/` yanıtında `form-action 'self'` de var.
- ✅ **Sunucu sürüm bilgisi sızmıyor** (`Server: cloudflare`, arkadaki yazılım sürümü gizli).

---

## 5. Bulgular ve Giderme Önerileri

### B-01 — cPanel / Webmail internete açık · **Orta**
`cpanel.jetbilisim.com.tr` ve `webmail.jetbilisim.com.tr` tüm dünyaya 200 dönüyor ("Shared IP" = cPanel/WHM varsayılan açılış sayfası). Yönetim arayüzleri (cPanel 2083, Webmail 2096, WHM 2087) ne kadar yamalı olursa olsun, internete açık her giriş ekranı kaba kuvvet ve 0-gün için hedeftir.

**Alınacak tedbirler:**
- Bu arayüzlere erişimi **IP beyaz listesi** (ofis/VPN IP'leri) ile sınırlayın; mümkünse **Cloudflare Access** (Zero Trust) arkasına alın.
- Alternatif olarak yönetim portlarını firewall'da yalnızca VPN'e açın.
- cPanel/WHM'de **2FA'yı zorunlu** kılın, `cPHulk` kaba kuvvet korumasını açın.
- `cpanel`/`webmail` alt alan adlarını herkese açık DNS'te tutmak zorunda değilseniz kaldırın; erişenler doğrudan `sunucu-ip:2083` kullanır.

### B-02 — `/admin/` paneli internete açık · **Orta**
`https://jetbilisim.com.tr/admin/` → 200, "Giriş – Jet Bilişim" (Mimar CMS giriş ekranı). Çerez bayrakları iyi, ancak giriş ekranı herkese açık olduğundan kimlik bilgisi doldurma (credential stuffing) ve kaba kuvvet yüzeyi oluşturur.

**Alınacak tedbirler:**
- Panele **Cloudflare Access** veya IP kısıtı ekleyin (müşteri panelleri hariç ise yönetici paneli için).
- **Başarısız giriş hız sınırı** (rate limiting) ve geçici hesap kilidi; Cloudflare WAF Rate Limiting kuralı ekleyin.
- **2FA/TOTP** desteği ekleyin ve yöneticiler için zorunlu kılın.
- Giriş hatalarında **kullanıcı var/yok ayrımı yapan mesaj vermeyin** (kullanıcı adı enumerasyonu önlemi).
- CAPTCHA / Turnstile ekleyin (otomasyon caydırıcı).
- Oturum süresi ve yeniden kimlik doğrulama politikası tanımlayın.

### B-03 — İçerik Güvenlik Politikası (CSP) çok dar · **Orta**
Mevcut CSP yalnızca: `object-src 'none'; base-uri 'self'; frame-ancestors 'self'` (admin'de + `form-action 'self'`). **`default-src`/`script-src`/`style-src` yok** → sayfaya enjekte edilen bir script'i CSP engellemez. Yani XSS'e karşı tarayıcı seviyesinde ikinci savunma katmanı neredeyse yok.

**Alınacak tedbirler (aşamalı):**
1. Önce **Report-Only** modda yayınlayıp ihlalleri toplayın:
   `Content-Security-Policy-Report-Only: default-src 'self'; script-src 'self'; ...; report-uri /csp-report`
2. İhlaller temizlenince zorunlu CSP'ye geçin. Hedef iskelet:
   `default-src 'self'; script-src 'self' https://(gerekli-cdn'ler); style-src 'self' 'unsafe-inline'; img-src 'self' data: https:; connect-src 'self'; object-src 'none'; base-uri 'self'; frame-ancestors 'self'; form-action 'self'; upgrade-insecure-requests`
3. Mümkünse inline script'leri kaldırıp **nonce tabanlı** CSP'ye geçin (`script-src 'self' 'nonce-...'`).
4. Google Analytics/Tag Manager/piksel gibi üçüncü taraflar için yalnızca gerekli alan adlarını ekleyin.

### B-04 — `security.txt` alan adı uyuşmazlığı ve yakın bitiş · **Düşük**
`Contact` olarak `info@jetbilgisayar.com` (farklı alan adı — site `jetbilisim.com.tr`) yazıyor ve `Expires: 2026-11-29` çok yakın.

**Alınacak tedbirler:**
- İletişim adresini site ile aynı alan adına taşıyın veya farklılığı açıklayın.
- `Expires`'ı 1 yıl ileri alın ve yenileme için takvim hatırlatıcısı kurun.
- `Canonical`, `Encryption` (PGP) ve `Policy` alanlarını ekleyin.

### B-05 — HSTS eksik direktifler · **Düşük**
`strict-transport-security: max-age=31536000` var ama `includeSubDomains` ve `preload` yok. Alt alan adları (demo, merkez vb.) HSTS kapsamı dışında kalabilir.

**Alınacak tedbirler:**
- Tüm alt alanlar HTTPS ise `includeSubDomains; preload` ekleyin:
  `Strict-Transport-Security: max-age=63072000; includeSubDomains; preload`
- Önce tüm alt alan adlarının HTTPS'te sorunsuz çalıştığını doğrulayın, sonra preload listesine başvurun (geri dönüşü zordur).

### B-06 — `robots.txt` yönetim yolu ifşası · **Bilgi**
`Disallow: /admin/` ve `/data/` saldırganlara dizin ipucu verir. Güvenlik `robots.txt`'e dayanmamalı; bu yollar zaten tahmin edilebilir ve erişim kontrolü (B-01/B-02) asıl savunmadır. Düşük etkili, kabul edilebilir.

**Öneri:** Gerçek koruma erişim kısıtında olduğu sürece bırakılabilir; istenirse `/admin/` satırını kaldırıp yalnızca erişim kontrolüne güvenin.

### B-07 — `wp-content` izleri · **Bilgi/Doğrula**
Ana sayfada 26 kez `wp-content` yolu görüldü; oysa CMS özel ("Mimar CMS"). Bu, ya eski WordPress varlık yollarının taşınması ya da yan yana çalışan bir WordPress olabilir. Gerçek bir WordPress varsa saldırı yüzeyi (eklenti açıkları, `xmlrpc.php`, `wp-login.php`) ciddi şekilde genişler.

**Alınacak tedbirler:**
- İçeride doğrulayın: gerçek bir WordPress kurulu mu, yoksa yalnızca CSS/JS yol ismi mi?
- WordPress varsa: çekirdek+eklenti güncel mi, `xmlrpc.php` kapalı mı, `wp-login.php` korumalı mı kontrol edin; yoksa kaldırın.

### B-08 — TLS bu ortamdan doğrulanamadı · **Bilgi**
Test ağının HTTPS vekili araya girdiği için gerçek sertifika, protokol sürümleri (TLS 1.0/1.1 kapalı mı?) ve şifre takımları **doğrulanamadı**. Yalnızca HSTS'in gönderildiği teyit edildi.

**Alınacak tedbirler:**
- Dışarıdan **SSL Labs** (ssllabs.com/ssltest) ve **Mozilla Observatory** ile tarama yapın; hedef en az **A** notu.
- TLS 1.0/1.1'i kapatın, TLS 1.2+ (tercihen 1.3) kullanın; zayıf şifre takımlarını devre dışı bırakın.
- Cloudflare SSL/TLS modunu **Full (Strict)** yapın ve origin sertifikasının geçerli olduğundan emin olun.

---

## 6. Saldırı Senaryoları ve Karşı Önlemler

| Senaryo | Giriş noktası | Karşı önlem |
|---------|---------------|-------------|
| **Yönetici paneline kaba kuvvet / kimlik doldurma** | `/admin/`, cPanel, webmail | IP kısıtı + Cloudflare Access, 2FA, hız sınırı, CAPTCHA/Turnstile, hesap kilidi |
| **XSS (depolanmış/yansıyan)** | Form girdileri, URL parametreleri (`?s=`, `?ara=`) | Girdi doğrulama + çıktı kodlama (asıl savunma), sıkı CSP (B-03), `HttpOnly` çerez (mevcut ✅) |
| **CSRF** | Panel/form işlemleri | `SameSite=Lax` (mevcut ✅) + sunucu tarafı CSRF token; `form-action 'self'` (admin'de ✅) |
| **Origin IP ifşası ile Cloudflare atlatma** | Doğrudan sunucu IP'si | Origin firewall'u yalnızca Cloudflare IP aralıklarına açın; mail/cpanel üzerinden IP sızıntısını önleyin; Authenticated Origin Pulls |
| **SQL Injection** | Arama ve katalog sorguları (`?ara=`) | Parametreli sorgular/ORM, Cloudflare WAF OWASP kural seti |
| **Dosya yükleme istismarı** | Katalog/medya yükleme | Tür+boyut doğrulama, yürütülebilir uzantı engeli, yükleme dizininde script çalıştırmayı kapatma |
| **Clickjacking** | iframe gömme | `X-Frame-Options: SAMEORIGIN` + `frame-ancestors 'self'` (mevcut ✅) |
| **DDoS / bot kazıma** | Tüm yüzey | Cloudflare rate limiting + bot yönetimi (mevcut altyapı) |
| **Hassas veri sızıntısı** | Yedek/konfig dosyaları | Mevcut 403'ler korunmalı (✅); yeni dosya eklerken kontrol edin |

---

## 7. Öncelikli Yapılacaklar Listesi

**Hemen (bu hafta):**
- [ ] cPanel/webmail ve `/admin/` erişimini IP/Cloudflare Access ile kısıtla (B-01, B-02)
- [ ] Admin girişine hız sınırı + 2FA + CAPTCHA ekle (B-02)
- [ ] `wp-content` izlerini doğrula; WordPress varsa güncelle/sıkılaştır (B-07)

**Kısa vade (bu ay):**
- [ ] CSP'yi Report-Only ile başlatıp sıkı CSP'ye geç (B-03)
- [ ] Dışarıdan SSL Labs + Observatory taraması, TLS sertleştirme (B-08)
- [ ] Cloudflare SSL modunu Full (Strict) + Authenticated Origin Pulls

**Orta vade:**
- [ ] HSTS'e `includeSubDomains; preload` (tüm alt alanlar HTTPS doğrulandıktan sonra) (B-05)
- [ ] `security.txt` güncelle (alan adı, Expires, Canonical, Encryption) (B-04)
- [ ] Düzenli yama/yedek politikası ve yıllık dış pentest planı

---

## 8. Yasal ve Metodolojik Notlar

- Bu rapor yalnızca pasif, müdahalesiz tekniklerle hazırlanmıştır; sistemlere **giriş denenmemiş**, veri **değiştirilmemiştir**.
- Tam kapsamlı bir sızma testi için: yazılı yetki/kapsam belgesi, test zaman penceresi, yedek alınmış ortam ve tercihen ayrı bir **staging** kopyası önerilir.
- Bulgular rapor tarihindeki duruma aittir; yapılandırma değiştikçe tekrar değerlendirilmelidir.
- Türkiye'de yetkisiz erişim TCK 243–245 kapsamındadır; testler yalnızca sahibi olunan/yazılı izin alınan varlıklarda yapılmalıdır.

---

*Bu rapor Jet Bilişim'in kendi varlığı için, sahibinin talebiyle hazırlanmıştır.*
