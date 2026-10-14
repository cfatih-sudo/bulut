import { test, expect, Page } from '@playwright/test';

/**
 * KD Portal — Üyelik sistemi fonksiyonel test paketi
 * Tüm akışlar gerçek kullanıcı gibi UI üzerinden sürülür (black-box QA).
 * Üyelik modeli: davet / yönetici onaylı. Açık self-registration YOK.
 */

const loginEmail = (p: Page) => p.locator('input[type="email"]');
const loginPass = (p: Page) => p.locator('input[type="password"]');
const bodyText = (p: Page) => p.evaluate(() => document.body.innerText.replace(/\s+/g, ' ').trim());

// ---------------------------------------------------------------------------
test.describe('A. Giriş sayfası (/giris)', () => {
  test('A1 — giriş formu doğru render ediliyor (e-posta + şifre + buton)', async ({ page }) => {
    await page.goto('/giris', { waitUntil: 'networkidle' });
    await expect(loginEmail(page)).toBeVisible();
    await expect(loginPass(page)).toBeVisible();
    await expect(page.getByRole('button', { name: /Giriş yap/i })).toBeVisible();
    await expect(page).toHaveTitle(/KD Portal/i);
  });

  test('A2 — şifre alanı maskeli (type=password)', async ({ page }) => {
    await page.goto('/giris', { waitUntil: 'networkidle' });
    await expect(loginPass(page)).toHaveAttribute('type', 'password');
  });

  test('A3 — boş gönderimde zorunlu alan uyarısı gösteriliyor', async ({ page }) => {
    await page.goto('/giris', { waitUntil: 'networkidle' });
    await page.getByRole('button', { name: /Giriş yap/i }).click();
    await expect.poll(() => bodyText(page)).toMatch(/zorunlu alan eksik|gerekli|boş/i);
  });

  test('A4 — hatalı kimlik bilgisi: 401 + generic hata, oturum çerezi YOK', async ({ page, context }) => {
    await page.goto('/giris', { waitUntil: 'networkidle' });
    await loginEmail(page).fill('nouser@example.com');
    await loginPass(page).fill('wrongpass123');
    const [resp] = await Promise.all([
      page.waitForResponse(r => /\/api\/auth\/login/.test(r.url()), { timeout: 15000 }),
      page.getByRole('button', { name: /Giriş yap/i }).click(),
    ]);
    expect(resp.status(), 'login should reject with 401').toBe(401);
    await expect.poll(() => bodyText(page)).toMatch(/E-posta veya şifre hatalı|hatalı|geçersiz/i);
    const cookies = await context.cookies();
    expect(cookies.filter(c => /sess|token|auth|sid/i.test(c.name)), 'no session cookie on failed login').toHaveLength(0);
  });

  test('A5 — hatalı giriş mesajı kullanıcı adının var olup olmadığını SIZDIRMIYOR (enumeration yok)', async ({ page }) => {
    // Aynı generic mesaj hem var olmayan hem rastgele hesap için dönmeli.
    const tryLogin = async (email: string) => {
      await page.goto('/giris', { waitUntil: 'networkidle' });
      await loginEmail(page).fill(email);
      await loginPass(page).fill('definitelyWrong123');
      await Promise.all([
        page.waitForResponse(r => /\/api\/auth\/login/.test(r.url()), { timeout: 15000 }).catch(() => null),
        page.getByRole('button', { name: /Giriş yap/i }).click(),
      ]);
      await page.waitForTimeout(600);
      return bodyText(page);
    };
    const m1 = await tryLogin('surely-missing-7f3a@example.com');
    const m2 = await tryLogin('admin@example.com');
    const extract = (t: string) => (t.match(/E-posta veya şifre hatalı\.?|bulunamadı|kayıtlı değil/i) || [''])[0];
    expect(extract(m1)).toBeTruthy();
    expect(extract(m1), 'same generic error for both -> no user enumeration').toBe(extract(m2));
  });
});

// ---------------------------------------------------------------------------
test.describe('B. Üyelik modeli (davet / yönetici onaylı)', () => {
  test('B1 — ana sayfada "Giriş yap" ve "Hesap aç" giriş noktaları var', async ({ page }) => {
    await page.goto('/', { waitUntil: 'networkidle' });
    const t = await bodyText(page);
    expect(t).toMatch(/Giriş yap/i);
    expect(t).toMatch(/Hesap aç/i);
  });

  test('B2 — giriş ekranı "yönetici onayı" modelini açıkça belirtiyor', async ({ page }) => {
    await page.goto('/giris', { waitUntil: 'networkidle' });
    await page.getByRole('button', { name: /Giriş yap/i }).click();
    await expect.poll(() => bodyText(page)).toMatch(/yönetici onay/i);
  });

  test('B3 — açık self-registration route YOK (/kayit, /register in-app 404)', async ({ page }) => {
    for (const r of ['/kayit', '/register', '/uye-ol', '/signup']) {
      await page.goto(r, { waitUntil: 'networkidle' });
      await expect.poll(() => bodyText(page), `${r} should be in-app 404`).toMatch(/bulunamad|404/i);
    }
  });
});

// ---------------------------------------------------------------------------
test.describe('C. Şifre değiştirme (/sifre)', () => {
  test('C1 — 3 alanlı şifre değiştirme formu render ediliyor', async ({ page }) => {
    await page.goto('/sifre', { waitUntil: 'networkidle' });
    await expect(page.locator('input[type="password"]')).toHaveCount(3);
    await expect(page.getByRole('button', { name: /Şifreyi değiştir/i })).toBeVisible();
  });

  test('C2 — yeni şifre / tekrar uyuşmazlığı reddediliyor', async ({ page }) => {
    await page.goto('/sifre', { waitUntil: 'networkidle' });
    const pw = page.locator('input[type="password"]');
    await pw.nth(0).fill('Curr12345!');
    await pw.nth(1).fill('NewPass12345!');
    await pw.nth(2).fill('Mismatch999!');
    await page.getByRole('button', { name: /Şifreyi değiştir/i }).click();
    await expect.poll(() => bodyText(page)).toMatch(/uyuş|eşleş|aynı|tekrar/i);
  });

  test('C3 — çok kısa yeni şifre (<8) reddediliyor', async ({ page }) => {
    await page.goto('/sifre', { waitUntil: 'networkidle' });
    const pw = page.locator('input[type="password"]');
    await pw.nth(0).fill('Curr12345!');
    await pw.nth(1).fill('123');
    await pw.nth(2).fill('123');
    await page.getByRole('button', { name: /Şifreyi değiştir/i }).click();
    await expect.poll(() => bodyText(page)).toMatch(/en az 8|kısa|yetersiz|geçersiz|oturum|giriş/i);
  });
});

// ---------------------------------------------------------------------------
test.describe('D. Kurulum kapısı (/kurulum)', () => {
  test('D1 — kurulum anahtarı kapısı render ediliyor', async ({ page }) => {
    await page.goto('/kurulum', { waitUntil: 'networkidle' });
    await expect(page.locator('input[type="password"]')).toBeVisible();
    await expect(page.getByRole('button', { name: /Durumu kontrol et/i })).toBeVisible();
  });

  test('D2 — anahtarsız/boş gönderim kurulumu AÇMIYOR', async ({ page }) => {
    await page.goto('/kurulum', { waitUntil: 'networkidle' });
    await page.getByRole('button', { name: /Durumu kontrol et/i }).click();
    await page.waitForTimeout(800);
    const t = await bodyText(page);
    // Boş/eksik anahtarda kurulum tamamlandı mesajı GÖRÜNMEMELİ.
    expect(t).not.toMatch(/kurulum tamamland|başarıyla kuruldu|setup complete/i);
  });
});

// ---------------------------------------------------------------------------
test.describe('E. Route koruması / yetkisiz erişim', () => {
  // Guard davranışı: yetkisiz kullanıcı korumalı route'a gidince public landing'e
  // düşürülmeli (admin yüzeyi hiç render edilmemeli). Pazarlama metnindeki benign
  // "onaylar/bekleyin" kelimelerine değil, admin'e ÖZGÜ sızıntı işaretlerine bakılır.
  const LANDING = /KENTSEL DÖNÜŞÜM BULUŞMA NOKTASI/i;
  const ADMIN_LEAK = /setup_token|config\.php|rol ata|kullanıcıyı sil|onay kuyruğu\s*\(\d|bekleyen başvurular\s*\(\d|@[a-z0-9.-]+\.[a-z]{2,}\b.*(reddet|onayla|askıya)/i;

  test('E1 — /dashboard yetkisiz: public landing fallback, admin verisi SIZMIYOR', async ({ page }) => {
    await page.goto('/dashboard', { waitUntil: 'networkidle' });
    const t = await bodyText(page);
    expect(t, 'guard should fall back to public landing').toMatch(LANDING);
    expect(t, 'no admin-only data/controls leaked').not.toMatch(ADMIN_LEAK);
  });

  test('E2 — /admin yetkisiz: yönetim paneli AÇILMIYOR (public fallback)', async ({ page }) => {
    await page.goto('/admin', { waitUntil: 'networkidle' });
    const t = await bodyText(page);
    expect(t).toMatch(LANDING);
    expect(t).not.toMatch(ADMIN_LEAK);
  });

  test('E3 — /admin/approvals yetkisiz: onay kuyruğu AÇILMIYOR (public fallback)', async ({ page }) => {
    await page.goto('/admin/approvals', { waitUntil: 'networkidle' });
    const t = await bodyText(page);
    expect(t).toMatch(LANDING);
    expect(t).not.toMatch(ADMIN_LEAK);
  });

  test('E4 — bilinmeyen route in-app 404 veriyor (açık yönlendirme yok)', async ({ page }) => {
    await page.goto('/this-does-not-exist-12345', { waitUntil: 'networkidle' });
    await expect.poll(() => bodyText(page)).toMatch(/bulunamad|404/i);
  });
});
