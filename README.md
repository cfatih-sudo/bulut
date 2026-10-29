# ☁️ Bulut — Yerel PHP / Java / Python Kod Asistanı

Bulut, **tamamen kendi bilgisayarında çalışan**, Claude benzeri bir kod asistanıdır.
İnternete veri göndermez; yapay zekâ modeli [Ollama](https://ollama.com) ile senin makinende çalışır.

- 💬 Tarayıcıda sohbet arayüzü (ve isteyene terminal modu)
- 🧠 PHP (Laravel, Symfony, PDO), Java (Spring Boot, Maven) ve Python (Django, FastAPI, pandas) için ayarlanmış talimatlar
- ▶️ Cevaptaki PHP / Java / Python kodunu tek tıkla **kendi bilgisayarında çalıştırma**
- 📁 **Proje klasörünü açıp tüm projeyi anlama**: "giriş neden çalışmıyor?" diye sor, ilgili dosyaları kendisi bulur
- 📎 Tek tek dosya ekleyip inceletme / hata ayıklatma
- Ek Python paketi gerekmez (sadece standart kütüphane)

## Kurulum (bir kerelik)

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
