# bulut

Frontend geliştirme için seçilmiş açık kaynak depoları Claude Code ile (VS Code ve claude.ai/code) kullanmak için bir başlangıç deposu.

## Kurulum (bir kez)

1. [GitHub CLI](https://cli.github.com) kurun ve giriş yapın: `gh auth login`
2. Depoyu klonlayın: `git clone https://github.com/cfatih-sudo/bulut.git && cd bulut`
3. Tüm kaynak depoları GitHub hesabınıza fork edin:
   - macOS/Linux/Git Bash: `./scripts/fork-all.sh`
   - Windows PowerShell: `powershell -ExecutionPolicy Bypass -File scripts\fork-all.ps1`
4. Kaynakları bilgisayarınıza indirin (`vendor/` klasörüne, git'e eklenmez):
   - `./scripts/clone-all.sh`, ya da sadece bir kategori için `./scripts/clone-all.sh stil`
   - Windows: `powershell -ExecutionPolicy Bypass -File scripts\clone-all.ps1`
5. VS Code'da `frontend-kaynaklar.code-workspace` dosyasını açın (*File → Open Workspace from File*).
   Claude Code eklentisi `CLAUDE.md` dosyasını okur ve hangi durumda hangi kaynağa bakacağını bilir.

## Dosyalar

| Dosya | Ne işe yarar |
|---|---|
| `repos.txt` | Depo listesi: kategori ve açıklamalarıyla 22 depo |
| `scripts/fork-all.*` | Listedeki depoları hesabınıza fork eder. Tekrar çalıştırmak güvenlidir, var olanları atlar. |
| `scripts/clone-all.*` | Depoları `vendor/` klasörüne indirir veya günceller |
| `frontend-kaynaklar.code-workspace` | VS Code çalışma alanı: proje ve kaynaklar tek pencerede açılır |
| `CLAUDE.md` | Claude Code için talimatlar |

Kaynak: "Frontend Geliştiricileri için En Yararlı 57 Github Reposu" (blog.codimis.com). Makalenin şu bölümleri eklendi: *Araçlar ve Kütüphaneler*, *Algoritma ve Veri Yapıları*, *Stil Rehberleri*.
