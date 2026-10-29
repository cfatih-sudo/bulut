# bulut
bulut kredi testi

## email_spider.py — alan adından e-posta toplayıcı

Bir alan adının sayfalarını gezip içlerindeki e-posta adreslerini toplar.
Sadece Python 3 standart kütüphanesini kullanır, kurulum gerekmez.

```bash
python3 email_spider.py ornek.com
python3 email_spider.py ornek.com --max-pages 500 --depth 4 --subdomains -o sonuc.csv
python3 email_spider.py ornek.com --only-domain -o sonuc.json
```

Bulduğu adres türleri: düz metin, `mailto:` linkleri, HTML entity ile yazılmış
adresler (`ali&#64;ornek.com`), `ali [at] ornek [dot] com` gibi gizlenmiş
adresler ve Cloudflare e-posta koruması (`data-cfemail`).

Varsayılan olarak robots.txt'ye uyar, istekler arasında 0.5 sn bekler ve
yalnızca hedef alan adı içinde kalır. Sadece sahibi olduğunuz ya da tarama
izniniz olan siteleri tarayın; toplanan adresler kişisel veri sayılır
(KVKK/GDPR) ve izinsiz toplu e-posta göndermek için kullanılmamalıdır.

| Seçenek | Açıklama |
|---|---|
| `--max-pages N` | Taranacak en fazla sayfa (200) |
| `--depth N` | En fazla link derinliği (3) |
| `--delay S` | İstekler arası bekleme, saniye (0.5) |
| `--workers N` | Eşzamanlı istek sayısı (4) |
| `--subdomains` | Alt alan adlarını da tara |
| `--only-domain` | Sadece hedef alan adına ait e-postaları raporla |
| `--ignore-robots` | robots.txt'yi yok say |
| `-o DOSYA` | `.csv` (kaynak sayfalarla), `.json` veya `.txt` çıktı |
| `-v` | Ayrıntılı günlük |
