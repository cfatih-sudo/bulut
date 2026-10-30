# ☁️ Bulut — Yerel PHP / Java / Python Kod Asistanı

Bulut, **tamamen kendi bilgisayarında çalışan**, Claude benzeri bir kod asistanıdır.
İnternete veri göndermez; yapay zekâ modeli [Ollama](https://ollama.com) ile senin makinende çalışır.

- 💬 Tarayıcıda sohbet arayüzü (ve isteyene terminal modu)
- 🧠 PHP (Laravel, Symfony, PDO), Java (Spring Boot, Maven) ve Python (Django, FastAPI, pandas) için ayarlanmış talimatlar
- ▶️ Cevaptaki PHP / Java / Python kodunu tek tıkla **kendi bilgisayarında çalıştırma**
- 📁 **Proje klasörünü açıp tüm projeyi anlama**: "giriş neden çalışmıyor?" diye sor, ilgili dosyaları kendisi bulur
- 💾 **Önerilen değişiklikleri onayınla dosyalara yazma** (önce farkı gösterir, tek tıkla geri alınır)
- 📎 Tek tek dosya ekleyip inceletme / hata ayıklatma
- Ek Python paketi gerekmez (sadece standart kütüphane)

## ⚡ Tek tıkla kurulum (önerilen)

`kurulum/` klasöründen işletim sistemine uygun dosyayı indir:

| Sistem | Dosya | Nasıl çalıştırılır |
|---|---|---|
| **Windows 10/11** | [`Bulut-Kurulum-Windows.bat`](kurulum/Bulut-Kurulum-Windows.bat) | Çift tıkla |
| **macOS** | [`Bulut-Kurulum-Mac.command`](kurulum/Bulut-Kurulum-Mac.command) | Terminal'de: `bash ~/Downloads/Bulut-Kurulum-Mac.command` |
| **Linux** | [`Bulut-Kurulum-Linux.sh`](kurulum/Bulut-Kurulum-Linux.sh) | Terminal'de: `bash ~/İndirilenler/Bulut-Kurulum-Linux.sh` |

Kurulum dosyası her şeyi kendisi yapar:
1. Bulut'u kurar (Windows: `%LOCALAPPDATA%\Bulut`, macOS: `~/Library/Application Support/Bulut`, Linux: `~/.local/share/bulut`)
2. Python yoksa hazırlar (Windows'ta sadece Bulut'a özel, sistemine dokunmayan bir Python indirir)
3. Ollama yoksa indirip kurar
4. Bilgisayarının RAM'ine göre modeli seçip indirir (12 GB altı → `3b`, 28 GB altı → `7b`, üstü → `14b`)
5. Masaüstüne ve Başlat menüsüne / Uygulamalar'a **Bulut** simgesi koyar ve Bulut'u açar

Sonra her seferinde masaüstündeki **Bulut** simgesine tıklaman yeterli; tarayıcıda kendiliğinden açılır.
Kapatmak için sağ üstteki **⏻** düğmesi.

İnternet hızına göre ilk kurulum 5–30 dakika sürebilir (model ~2–9 GB). Kurulum dosyasını tekrar çalıştırmak Bulut'u günceller; inmiş model tekrar inmez.

**Windows uyarısı:** İnternetten indirilen dosyalar için "Windows bilgisayarınızı korudu" çıkabilir → **Ek bilgi** → **Yine de çalıştır**.

**Kaldırma:** Windows: `%LOCALAPPDATA%\Bulut\Kaldir.bat` · macOS/Linux: kurulum klasöründeki `kaldir.sh`.
Ollama ve modeller ayrıca kaldırılır (Windows: Ayarlar → Uygulamalar → Ollama).

## Elle kurulum

1. **Ollama'yı kur:** https://ollama.com/download (Windows / macOS / Linux)
2. **Kod modelini indir** (~4.7 GB):
   ```bash
   ollama pull qwen2.5-coder:7b
   ```
3. **Python 3.9+** kurulu olsun. Kodları çalıştırmak istiyorsan **PHP 8** ve **JDK 17+** de PATH'te olsun (isteğe bağlı).

## Çalıştırma

Windows: `baslat.bat` dosyasına çift tıkla.

macOS / Linux:
```bash
./baslat.sh
```

ya da elle:
```bash
python bulut.py
```
Sonra tarayıcıda **http://127.0.0.1:8765** adresini aç.

Terminal modu:
```bash
python bulut.py cli
```
Terminalde `/dosya yol/dosya.php` ile dosya okutabilir, `/temizle` ile sohbeti sıfırlayabilir, `/cik` ile çıkabilirsin.

## Proje klasörüyle çalışma

Web arayüzünde sağ üstteki **📁 Proje** düğmesine bas, klasörün tam yolunu yaz (örn. `C:\xampp\htdocs\sitem`) ve **Aç**'a tıkla.
Ya da açılışta ver:
```bash
python bulut.py --proje C:\projelerim\sitem
```
Terminal modunda: `/proje C:\projelerim\sitem`, kapatmak için `/projekapat`.

Bulut nasıl okuyor:
- Klasörü tarar; `vendor`, `node_modules`, `target`, `.git`, `.gitignore`'daki yollar ve `.env`, `*.key` gibi **gizli dosyalar atlanır**.
- Laravel / Symfony / Spring Boot / Maven / Gradle / Django / Flask / FastAPI gibi yapıları otomatik tanır.
- **Küçük projelerde** tüm dosyaları her soruda modele verir.
- **Büyük projelerde** her soru için önce arama kelimeleri çıkarır (Türkçe "fatura" → `invoice`), sonra en ilgili dosya ve satırları bulup sadece onları verir. Her cevabın üstünde "📄 İncelenen dosyalar" listesi görünür.
- Mesajda **`@`** yazınca dosya önerileri çıkar; `@app/Http/Controllers/LoginController.php` gibi seçilen dosya tam olarak eklenir. Terminalde de `@dosya` yazabilirsin.
- Dosyaları sen değiştirdikçe indeks her soruda otomatik güncellenir.

İpucu: Büyük projelerde soruda sınıf, fonksiyon veya dosya adı geçirirsen (`UserService`, `routes/web.php`) çok daha isabetli cevap alırsın.

## Değişiklikleri dosyalara uygulama

Proje açıkken Bulut bir dosyada değişiklik önerdiğinde kod bloğunun üstünde dosya yolu ve **💾 Uygula** düğmesi çıkar.

1. **💾 Uygula**'ya bas → hangi satırların silinip ekleneceğini gösteren (kırmızı/yeşil) bir pencere açılır.
2. **Onayla ve dosyaya yaz** dersen dosya güncellenir (yoksa oluşturulur). Onaylamadan hiçbir şey yazılmaz.
3. Beğenmezsen üstteki **↶ Geri al** ile son değişiklikten başlayarak geri alırsın.

- Büyük dosyalarda model sadece değişen kısmı (`ARA / DEĞİŞTİR` bloğu) gönderir; Bulut bunu dosyada bulup yerine koyar. Bulamazsa yazmaz ve uyarır.
- Model kodu `// ... mevcut kod ...` gibi kısaltmışsa veya yeni içerik eskisinden çok kısaysa pencerede **⚠️ uyarı** çıkar — kod silinmesin diye dikkatle bak.
- Dosya yolu olmayan bloklarda **💾 Dosyaya yaz…** ile yolu kendin seçebilirsin.
- Proje dışına, `.git`, `vendor`, `node_modules` içine ve `.env` gibi gizli dosyalara **asla yazılmaz**.
- Her değişiklikten önce dosyanın eski hali `~/.bulut/yedekler/` klasörüne kopyalanır (projenin içine çöp dosya bırakmaz).
- Windows satır sonları (CRLF) korunur.

Terminal modunda cevaptaki değişiklikler renkli farkla gösterilir ve her dosya için `(e/h)` diye sorulur. Geri almak için `/geri`.

> Yine de projen git ile takip ediliyorsa, büyük değişikliklerden önce commit atmanı öneririm.

## Hangi modeli seçmeliyim?

| Bilgisayarın | Önerilen model | Komut |
|---|---|---|
| 8 GB RAM, ekran kartı yok | `qwen2.5-coder:3b` | `ollama pull qwen2.5-coder:3b` |
| 16 GB RAM veya 6–8 GB VRAM | `qwen2.5-coder:7b` (varsayılan) | `ollama pull qwen2.5-coder:7b` |
| 32 GB RAM veya 12+ GB VRAM | `qwen2.5-coder:14b` | `ollama pull qwen2.5-coder:14b` |
| 64 GB RAM veya 24+ GB VRAM | `qwen2.5-coder:32b` (en iyisi) | `ollama pull qwen2.5-coder:32b` |

İndirdiğin tüm modeller arayüzün sağ üstündeki listede görünür. Varsayılanı değiştirmek için:
```bash
python bulut.py --model qwen2.5-coder:14b
```
veya `BULUT_MODEL` ortam değişkenini ayarla.

## Ayarlar

| Ortam değişkeni | Varsayılan | Açıklama |
|---|---|---|
| `BULUT_MODEL` | `qwen2.5-coder:7b` | Kullanılacak Ollama modeli |
| `OLLAMA_URL` | `http://127.0.0.1:11434` | Ollama adresi (başka bir makinedeki Ollama'yı da kullanabilirsin) |
| `BULUT_CTX` | `16384` | Modelin bağlam penceresi (token). Büyütürsen daha çok dosya okur ama daha çok RAM/VRAM kullanır. `--ctx 32768` ile de verilebilir. |

Asistanın kişiliğini/uzmanlığını değiştirmek için `bulut.py` içindeki `SYSTEM_PROMPT` metnini düzenle.

## Güvenlik notu

"Çalıştır" düğmesi kodu **senin bilgisayarında, senin kullanıcı yetkilerinle** çalıştırır (20 sn zaman sınırı ile).
Modelin yazdığı kodu çalıştırmadan önce göz at. Sunucu sadece `127.0.0.1` üzerinde dinler, ağdaki başka cihazlar erişemez.

## Sorun giderme

- **"Ollama'ya bağlanılamadı"** → Ollama uygulamasını aç veya terminalde `ollama serve` çalıştır.
- **"Model bulunamadı"** → `ollama pull qwen2.5-coder:7b`
- **Cevaplar çok yavaş** → Daha küçük model seç (`3b`) veya `--ctx 8192` ile bağlamı küçült.
- **Proje sorularında yanlış dosyalara bakıyor** → Soruda dosya/sınıf adını geçir ya da `@dosya` ile ekle.
- **Java "çalıştır" hata veriyor** → JDK 11+ gerekir; kodda `public class Main` ve `main` metodu olmalı.

## Geliştirici notu

Kodu değiştirdikten sonra kurulum dosyalarını yeniden üret:
```bash
python paket/olustur.py
```
Simgeyi değiştirmek için `paket/ikon.py` düzenlenip çalıştırılır.
