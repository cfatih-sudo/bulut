# bulut — YouTube İndirici

[yt-dlp](https://github.com/yt-dlp/yt-dlp) tabanlı, Türkçe arayüzlü YouTube video/ses indirici. Komut satırından ya da tarayıcıdan kullanılabilir.

## Kurulum

```bash
pip install -r requirements.txt
```

En iyi kalite (video+ses birleştirme) ve MP3 dönüştürme için **ffmpeg** gerekir:

- Windows: `winget install ffmpeg`
- macOS: `brew install ffmpeg`
- Linux: `sudo apt install ffmpeg`

## Komut satırı

```bash
# En iyi kalitede video (mp4)
python -m indirici "https://www.youtube.com/watch?v=..."

# Sadece ses, MP3
python -m indirici "https://youtu.be/..." --ses --format mp3

# 720p ile sınırla, altyazılarla birlikte
python -m indirici "https://youtu.be/..." -k 720 --altyazi

# Oynatma listesinin tamamı
python -m indirici "https://www.youtube.com/playlist?list=..." --liste

# Birden fazla bağlantı, farklı klasöre
python -m indirici URL1 URL2 -o ~/Videolar
```

| Seçenek | Açıklama |
|---|---|
| `-o, --klasor` | Kayıt klasörü (varsayılan: `indirilenler`) |
| `-s, --ses` | Sadece sesi indir |
| `-f, --format` | Ses formatı: mp3, m4a, opus, wav, flac |
| `-k, --kalite` | Azami çözünürlük: en-iyi, 2160, 1440, 1080, 720, 480, 360 |
| `-l, --liste` | Oynatma listesinin tamamını indir |
| `-a, --altyazi` | Türkçe/İngilizce altyazıları indir |
| `--web` | Web arayüzünü başlat |

## Web arayüzü

```bash
python -m indirici --web
```

Ardından tarayıcıda <http://127.0.0.1:5000> adresini aç. Bağlantıyı yapıştır, video/ses ve kaliteyi seç; indirme bitince dosya tarayıcıdan indirilebilir.

## Not

YouTube sık sık değiştiği için indirme bozulursa önce yt-dlp'yi güncelle:

```bash
pip install -U yt-dlp
```

Yalnızca indirme hakkına sahip olduğun içerikleri indir; YouTube Hizmet Şartları'na ve telif haklarına uy.
