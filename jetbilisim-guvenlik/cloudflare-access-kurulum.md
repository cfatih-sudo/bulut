# Cloudflare Access ile Yönetim Panellerini Kapatma

**Giderdiği bulgular:** B-01 (cPanel/Webmail açık), B-02 (`/admin/` açık)

Cloudflare Access (Zero Trust), bir URL'ye ulaşmadan **önce** araya bir kimlik doğrulama (e-posta kodu / Google / 2FA) ekler. Sabit IP gerektirmez, her yerden güvenle girersiniz, yetkisiz herkes giriş ekranını bile göremez. Ücretsiz plan 50 kullanıcıya kadar yeterlidir.

Korunacak hedefler:
- `jetbilisim.com.tr/admin` (ve `/admin/*`)
- `cpanel.jetbilisim.com.tr`
- `webmail.jetbilisim.com.tr`
- (opsiyonel) `demo.jetbilisim.com.tr` sadece ekip görsünse

> **Önemli:** `/admin/` hem yönetici hem müşteri girişi için kullanılıyorsa Access'i oraya koymadan önce düşünün — müşteriler de kilitlenir. O durumda `/admin/`'i IP kısıtına bırakıp Access'i yalnızca cpanel/webmail'e uygulayın. Yöneticiye özel ayrı bir yol (ör. `/admin/`) varsa en idealdir.

---

## Adım 1 — Zero Trust'ı açın
1. https://dash.cloudflare.com → sol menüde **Zero Trust**.
2. İlk kez giriyorsanız bir takım adı (team name) belirleyin, **Free** planı seçin (kart istenebilir, ücret çıkmaz).

## Adım 2 — Giriş yöntemini ekleyin (Authentication)
1. Zero Trust → **Settings → Authentication → Login methods**.
2. En hızlısı: **One-time PIN** (e-postaya kod gelir, ek kurulum yok). Dilerseniz **Google / Microsoft / GitHub** da ekleyebilirsiniz.

## Adım 3 — cPanel ve Webmail için uygulama (Application) oluşturun
Her biri için tekrarlayın (cpanel, webmail):
1. Zero Trust → **Access → Applications → Add an application → Self-hosted**.
2. **Application name:** `cPanel` (sonra `Webmail`).
3. **Subdomain/Domain:** `cpanel` / `jetbilisim.com.tr` (webmail için `webmail`).
   - Path boş (tüm uygulama korunur).
4. **Next** → **Add a policy**:
   - Policy name: `Sadece ekip`
   - Action: **Allow**
   - **Include → Emails** → yöneticilerin e-posta adreslerini tek tek ekleyin
     (veya **Emails ending in** → `@jetbilisim.com.tr`).
5. **Next → Add application**.

## Adım 4 — `/admin/` için uygulama (sadece yolu korur)
1. **Access → Applications → Add an application → Self-hosted**.
2. **Application name:** `Yönetim Paneli`
3. **Subdomain:** boş, **Domain:** `jetbilisim.com.tr`, **Path:** `admin`
   (Cloudflare `jetbilisim.com.tr/admin*` adresini kapsar.)
4. Policy: Adım 3'teki gibi **Allow → Emails** (yönetici e-postaları).
5. **Add application.**

## Adım 5 — Test edin
1. Gizli (incognito) pencere açın.
2. `https://cpanel.jetbilisim.com.tr` → artık **Cloudflare giriş ekranı** çıkmalı, cPanel değil.
3. Yetkili e-postanızla kod alıp girin → cPanel açılmalı.
4. Yetkisiz bir e-posta ile reddedilmeli.

---

## Önemli: Origin IP sızıntısını kapatın (yoksa Access atlatılır)
Cloudflare Access, trafik Cloudflare üzerinden geçtiği sürece korur. Saldırgan sunucunun **gerçek IP'sini** bulursa doğrudan bağlanıp Access'i atlayabilir.

1. **Turuncu bulut:** Cloudflare DNS panelinde `cpanel`, `webmail`, `@`, `www`, `demo`, `merkez` kayıtlarının **Proxied (turuncu bulut)** olduğundan emin olun. Gri bulut = korumasız.
2. **Origin firewall:** Sunucu (cPanel) firewall'unda 80/443'ü **yalnızca Cloudflare IP aralıklarına** açın:
   https://www.cloudflare.com/ips/ (cPanel'de CSF/APF ile whitelist).
3. **Authenticated Origin Pulls:** Cloudflare → SSL/TLS → Origin Server → **Authenticated Origin Pulls** açın; origin yalnızca Cloudflare'den gelen istekleri kabul etsin.
4. **SSL/TLS modu:** Cloudflare → SSL/TLS → **Full (Strict)** yapın.
5. **E-posta kaynaklı sızıntı:** `cpanel`/`webmail` yerine mümkünse mail için ayrı, proxy'siz bir ad kullanmayın; MX ve mail başlıkları origin IP'yi ifşa edebilir. Mail sunucusu ayrı IP'de olmalı.

---

## Ek sertleştirme (Access dışında, panel içinde)
- **cPanel:** WHM → Security Center → **cPHulk Brute Force Protection** açık; cPanel/WHM için **2FA** zorunlu.
- **Webmail:** Mümkünse Webmail'i tamamen kapatıp masaüstü/mobil IMAP istemcisi kullanın.
- **Mimar CMS `/admin/`:** Geliştiriciden şunları isteyin → başarısız giriş **hız sınırı** + geçici kilit, **2FA/TOTP**, **Turnstile/CAPTCHA**, kullanıcı adı enumerasyonu yapmayan hata mesajı ("kullanıcı adı veya parola hatalı").

## Doğrulama komutları (dışarıdan)
```bash
# Access devredeyse giriş ekranı yerine Cloudflare yönlendirmesi/403 dönmeli
curl -sSI https://cpanel.jetbilisim.com.tr/ | head -5
curl -sSI https://jetbilisim.com.tr/admin/ | head -5
```
