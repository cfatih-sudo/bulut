# jetbilisim.com.tr — Uygulama Dosyaları

`guvenlik-raporu.md` bulgularını canlı siteye uygulamak için hazır dosyalar.
Değişiklikleri **siz** kendi panellerinizde yaparsınız; burada kopyala-yapıştır hazır içerik ve adımlar var.

| Dosya | Ne yapar | Nereye |
|-------|----------|--------|
| `.htaccess-guvenlik-basliklari.txt` | CSP (B-03) + HSTS (B-05) + hassas dosya kilidi | cPanel → `public_html/.htaccess` en üstüne |
| `cloudflare-access-kurulum.md` | cPanel/webmail/`admin` erişim kısıtı (B-01, B-02) | Cloudflare Zero Trust paneli |

## Önerilen sıra
1. **Yedek al:** cPanel'de mevcut `.htaccess` dosyasını yedekle.
2. **Cloudflare Access** kur (en yüksek getirili, sunucuya dokunmaz) — `cloudflare-access-kurulum.md`.
3. **.htaccess başlıkları** ekle; CSP'yi önce **Report-Only** bırak.
4. Birkaç gün site + konsol temizse CSP'yi **zorunlu** moda al.
5. **Dışarıdan doğrula:** SSL Labs (ssllabs.com/ssltest) ve Mozilla Observatory (observatory.mozilla.org) ile tara; hedef ≥ A.

## Hâlâ gereken (panel/kod tarafı)
- cPanel'de cPHulk + 2FA zorunlu.
- Mimar CMS `/admin/` için hız sınırı + 2FA + Turnstile (geliştiriciden).
- `wp-content` izlerini doğrula (B-07): gerçek WordPress varsa güncelle, yoksa sorun yok.
- `security.txt` güncelle (B-04): alan adı, Expires +1 yıl, Canonical/Encryption.
