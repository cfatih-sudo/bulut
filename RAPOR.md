# KD Portal — Üyelik Sistemi Tam Test Raporu

**Hedef:** https://kdportal.com.tr
**Tarih:** 2026-10-14
**Kapsam:** Üyelik / kimlik doğrulama akışları (fonksiyonel QA + pasif güvenlik gözlemi)
**Yöntem:** Black-box, canlı siteye karşı; akışlar gerçek kullanıcı gibi arayüz (UI) üzerinden sürüldü (Playwright + Chromium). Site sahibi yetkilendirmesiyle.

> Not: Uçlara elle hazırlanmış istek gönderen aktif/istismar tarzı prob, otomatik güvenlik sınıflandırıcısı tarafından engellendi; bu nedenle güvenlik tarafı **pasif gözlem** (TLS, yanıt başlıkları, UI/bundle analizi, normal kullanıcı akışları) ile sınırlı tutuldu. Derinlemesine yetki/istismar testi için kod tabanlı inceleme (VS Code kaynakları) önerilir.

---

## 1. Sistem profili

| Özellik | Değer |
|---|---|
| Ön yüz | Expo (React Native Web) SPA, expo-router |
| Arka uç | PHP 8.1.34 (REST, `/api/*`), tek origin |
| Hosting | jetwebhosting (cPanel) |
| Üyelik modeli | **Davet + yönetici onaylı** — açık self-registration yok |
| Roller | Malik, Müteahhit, Tedarikçi, Emlak danışmanı, Yönetici (admin), Demo |

**Üyelik route haritası** (`/_sitemap` üzerinden):
`index`, `giris` (login), `sifre` (şifre değiştirme), `kurulum` (setup), `dashboard`, `admin/*` (index, approvals, activity, icerikler, anasayfa, guncelleme, demo), `projects/new`, `projects/[id]`.

**Üyelik API yüzeyi** (bundle'dan): `auth/login`, `auth/logout`, `auth/me`, `auth/password`, `auth/register`, `owners/invite`, `owners/invite/respond`, `owners/invites`, `admin/user/password`, `password_reset_by_admin`, `setup`, `authenticateDemoAccount`.

---

## 2. Fonksiyonel test sonuçları — 17/17 GEÇTİ ✅

Paket: `tests/membership.spec.ts` (`npx playwright test`)

### A. Giriş (/giris)
- **A1** ✅ Form doğru render (e-posta + şifre + buton)
- **A2** ✅ Şifre alanı maskeli (`type=password`)
- **A3** ✅ Boş gönderimde zorunlu alan uyarısı ("Zorunlu alan eksik: email")
- **A4** ✅ Hatalı giriş → API **401** + "E-posta veya şifre hatalı." + **oturum çerezi set edilmiyor**
- **A5** ✅ **Kullanıcı enumerasyonu yok** — var olmayan ve tahmini hesap için aynı generic hata

### B. Üyelik modeli
- **B1** ✅ Ana sayfada "Giriş yap" ve "Hesap aç" giriş noktaları var
- **B2** ✅ Model açıkça belirtiliyor: *"Yeni hesaplar yönetici onayından sonra etkinleştirilir."*
- **B3** ✅ Açık self-registration route yok (`/kayit`, `/register`, `/uye-ol`, `/signup` → in-app 404)

### C. Şifre değiştirme (/sifre)
- **C1** ✅ 3 alanlı form (mevcut / yeni / yeni tekrar)
- **C2** ✅ Yeni şifre uyuşmazlığı reddediliyor
- **C3** ✅ Çok kısa (<8) yeni şifre reddediliyor

### D. Kurulum kapısı (/kurulum)
- **D1** ✅ Kurulum anahtarı kapısı render ediliyor
- **D2** ✅ Anahtarsız/boş gönderim kurulumu açmıyor

### E. Route koruması
- **E1** ✅ `/dashboard` yetkisiz → public landing fallback, admin verisi sızmıyor
- **E2** ✅ `/admin` yetkisiz → yönetim paneli açılmıyor
- **E3** ✅ `/admin/approvals` yetkisiz → onay kuyruğu açılmıyor
- **E4** ✅ Bilinmeyen route → in-app 404 (açık yönlendirme yok)

**Olumlu güvenlik tespitleri:** generic login hatası (enumerasyon yok), başarısız girişte çerez yok, temiz JSON hata yönetimi (`missing_field`, `invalid_credentials`, `bad_json`), auth-gated uçlar yetkisiz çağrıda 401, admin route'ları client-side guard ile public'e düşüyor.

---

## 3. Güvenlik bulguları (pasif gözlem)

| # | Önem | Bulgu | Kanıt | Öneri |
|---|------|-------|-------|-------|
| 1 | **Yüksek** | **Geçersiz TLS sertifikası** — kendinden imzalı (subject=issuer=`kdportal.com.tr.jetwebhosting.com.tr`, 13 Eki 2026). Ziyaretçiler tarayıcıda sertifika uyarısı alır; MITM riski. | `openssl s_client` | cPanel AutoSSL / Let's Encrypt ile geçerli sertifika kurun. |
| 2 | **Orta** | **HSTS yok** — `Strict-Transport-Security` başlığı eksik. SSL-strip / downgrade riski. | `GET /` başlıkları | `Strict-Transport-Security: max-age=31536000; includeSubDomains` ekleyin (geçerli sertifikadan sonra). |
| 3 | **Orta** | **CSP yok** — `Content-Security-Policy` eksik. XSS etki alanını sınırlayan savunma yok. | `GET /` | SPA'ya uygun bir CSP tanımlayın. |
| 4 | **Orta** | **X-Frame-Options / frame-ancestors yok** — clickjacking'e açık. | `GET /` | `X-Frame-Options: DENY` veya CSP `frame-ancestors 'none'`. |
| 5 | **Düşük** | **Bilgi ifşası:** `X-Powered-By: PHP/8.1.34` ve `Server` sürüm bilgisi açıkça dönüyor. | yanıt başlıkları | `expose_php=Off`, sunucu imzasını kapatın. |
| 6 | **Düşük** | **/kurulum ipucu sızıntısı:** input placeholder'ı `config.php → setup_token` — backend dosya adını ve token konumunu kullanıcıya/saldırgana söylüyor. | `/kurulum` UI | Placeholder'ı generic yapın (ör. "Kurulum anahtarı"). |
| 7 | Bilgi | **Permissions-Policy yok** — tarayıcı özellik kısıtlaması tanımsız. | `GET /` | İhtiyaç dışı özellikleri kapatan bir `Permissions-Policy` ekleyin. |

Mevcut iyi başlıklar: `X-Content-Type-Options: nosniff`, `Referrer-Policy: strict-origin-when-cross-origin`, HTTP/3 (`alt-svc`).

---

## 4. UI üzerinden test edilemeyenler (yetki/kaynak gerektirir)

Aşağıdakiler geçerli bir hesap veya kaynak kodu olmadan uçtan uca doğrulanamadı:

- Başarılı giriş sonrası **oturum çerezi bayrakları** (`HttpOnly`, `Secure`, `SameSite`) — başarısız girişte çerez yok; başarılı akış için test hesabı gerekli.
- **Davet akışı** (`owners/invite` → e-posta → `owners/invite/respond` → `kurulum`) uçtan uca.
- **Rol bazlı yetkilendirme sınırları** (malik vs müteahhit vs admin; yatay/dikey yetki yükseltme).
- **Şifre sıfırlama** (admin tarafından: `password_reset_by_admin`) ve kilitlenme/rate-limit politikası.
- **Demo hesap** (`authenticateDemoAccount`) davranışı ve yetkileri.

---

## 5. Öncelikli aksiyonlar

1. **Geçerli TLS sertifikası kur** (Bulgu #1) — en acil; şu an her ziyaretçi uyarı alıyor.
2. Güvenlik başlıklarını ekle: HSTS, CSP, X-Frame-Options, Permissions-Policy (#2–#4, #7).
3. Sürüm/dosya ifşasını kapat (#5, #6).
4. Kimliği doğrulanmış akışlar için: bir **test hesabı** (veya rol başına hesap) sağlayın; davet/onay/rol/şifre-sıfırlama senaryolarını ekleyeyim. Alternatif: **VS Code'daki kaynak kodla** kod tabanlı inceleme (en derin kapsam).

---

### Çalıştırma

```bash
npm install
npx playwright test            # 17 senaryo
npx playwright show-report artifacts/html-report
```

Artefaktlar: `artifacts/` (ekran görüntüleri, HTML rapor, keşif script'leri).
