# bulut — Claude Code notları

Bu depo, frontend geliştirme için seçilmiş açık kaynak depoları **başvuru kaynağı** olarak kullanır.
Liste `repos.txt` içindedir. Depolar `vendor/<kategori>/<ad>` altına indirilir ve git'e eklenmez.

## Kaynakları kullanma
- Kullanıcıyla Türkçe konuş.
- Bir soruya veya göreve ilgili bir kaynak varsa, tahmin etmek yerine önce `vendor/` altındaki kaynak koda ve dokümana bak.
- İhtiyaç duyulan depo `vendor/` altında yoksa sadece onu indir: `./scripts/clone-all.sh <ad>`
  (Windows: `powershell -ExecutionPolicy Bypass -File scripts\clone-all.ps1 <ad>`).
  Tüm kategoriyi indirmek için `<ad>` yerine `araclar`, `algoritma` veya `stil` yaz. Büyük depoları (storybook, hoppscotch, nw.js) gerekmedikçe indirme.
- `vendor/` içindeki dosyaları düzenleme. Oradan alınan kodu projeye uyarlayarak kopyala ve lisansına dikkat et.

## Hangi durumda hangi kaynak
| İhtiyaç | Bakılacak yer |
|---|---|
| Kod stili / isimlendirme kararı | `vendor/stil/airbnb-javascript` (varsayılan), `vendor/stil/google-styleguide` (TS, HTML/CSS), `vendor/stil/standard`, `vendor/stil/node-style-guide` |
| Algoritma / veri yapısı uygulaması | `vendor/algoritma/javascript-algorithms`, `vendor/algoritma/TheAlgorithms-JavaScript`, `vendor/algoritma/dsa.js` |
| Mülakat tipi problem ve testleri | `vendor/algoritma/problem-solving-javascript` |
| Örnek uygulama mimarisi (auth, CRUD, routing) | `vendor/araclar/realworld` |
| UI bileşen geliştirme / dokümantasyon | `vendor/araclar/storybook` |
| Kod biçimlendirme ayarları | `vendor/araclar/prettier` |
| Test/sahte veri | `vendor/araclar/faker` |
| Tarih işlemleri | `vendor/araclar/date-fns` |
| Paket boyutu bütçesi | `vendor/araclar/size-limit` |
| Ücretsiz API arayışı | `vendor/araclar/public-apis/README.md` |
| Elle çizilmiş görünümlü grafik | `vendor/araclar/rough` |
| Yazıyı kutuya sığdırma | `vendor/araclar/fitty` |
| Masaüstü uygulama (HTML/JS) | `vendor/araclar/nw.js` |

## Güncel olmayan kaynaklar
- `create-react-app` artık önerilmiyor. Yeni React projesi için Vite veya Next.js öner, CRA'yı yalnızca eski projeleri anlamak için kullan.
- `vscode-browser-preview` arşivlenmiş. VS Code'un yerleşik "Simple Browser" özelliği veya Live Preview eklentisi tercih edilmeli.
- Faker.js'in asıl deposu 2022'de silindi. Burada topluluk sürümü `faker-js/faker` kullanılıyor.

## Yeni depo eklemek
`repos.txt` dosyasına `<sahip/depo> <fork-adı> <kategori> <açıklama>` biçiminde satır ekle. Ardından kullanıcıya `./scripts/fork-all.sh` komutunu çalıştırmasını hatırlat ve bu dosyadaki tabloyu güncelle.
