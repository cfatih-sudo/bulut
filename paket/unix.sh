#!/usr/bin/env bash
# Bulut - macOS / Linux kurulum betigi.
# paket/olustur.py bu dosyanin sonuna uygulama dosyalarini (base64 tar.gz) ekler.
set -euo pipefail

mavi() { printf '\n\033[36m==> %s\033[0m\n' "$1"; }
yesil() { printf '    \033[32m%s\033[0m\n' "$1"; }
hata() { printf '\n  \033[31mHATA: %s\033[0m\n\n' "$1"; exit 1; }

OS="$(uname -s)"
if [ "$OS" = "Darwin" ]; then
  HEDEF="$HOME/Library/Application Support/Bulut"
else
  HEDEF="${XDG_DATA_HOME:-$HOME/.local/share}/bulut"
fi
UYGULAMA="$HEDEF/uygulama"

echo
echo "  ==========================================="
echo "     Bulut - PHP / Java / Python Kod Asistani"
echo "  ==========================================="
echo "  Kurulum klasoru: $HEDEF"

# ------------------------------------------------------------ 1. dosyalar
mavi "1/5  Bulut dosyalari kopyalaniyor"
rm -rf "$UYGULAMA"
mkdir -p "$UYGULAMA"
sed -n '/^__PAYLOAD_BASLA__$/,$p' "$0" | tail -n +2 | base64 -d 2>/dev/null | tar xz -C "$UYGULAMA" \
  || sed -n '/^__PAYLOAD_BASLA__$/,$p' "$0" | tail -n +2 | base64 -D | tar xz -C "$UYGULAMA"
yesil "Tamam"

# ------------------------------------------------------------ 2. python
mavi "2/5  Python kontrol ediliyor"
PY=""
for p in python3 python; do
  if command -v "$p" >/dev/null 2>&1 && "$p" -c 'import sys; sys.exit(0 if sys.version_info >= (3, 9) else 1)' 2>/dev/null; then
    PY="$(command -v "$p")"; break
  fi
done
if [ -z "$PY" ]; then
  if [ "$OS" = "Darwin" ]; then
    echo "    Python 3 yok. Acilan pencereden 'Komut Satiri Araclari'ni (Command Line Tools) kurun,"
    echo "    sonra bu kurulumu tekrar calistirin."
    xcode-select --install 2>/dev/null || true
    hata "Python 3.9+ gerekli (veya https://www.python.org/downloads/ adresinden kurun)."
  elif command -v apt-get >/dev/null 2>&1; then
    echo "    Python 3 kuruluyor (sifreniz istenebilir)..."
    sudo apt-get update -qq && sudo apt-get install -y -qq python3
  elif command -v dnf >/dev/null 2>&1; then
    sudo dnf install -y -q python3
  elif command -v pacman >/dev/null 2>&1; then
    sudo pacman -S --noconfirm python
  else
    hata "Python 3.9+ gerekli. Paket yoneticinizle python3 kurup tekrar deneyin."
  fi
  PY="$(command -v python3)"
fi
yesil "Tamam ($PY)"

# ------------------------------------------------------------ 3. ollama
mavi "3/5  Ollama (yapay zeka motoru) kontrol ediliyor"
ollama_yolu() {
  command -v ollama 2>/dev/null && return
  for p in "/Applications/Ollama.app/Contents/Resources/ollama" "$HOME/Applications/Ollama.app/Contents/Resources/ollama"; do
    [ -x "$p" ] && { echo "$p"; return; }
  done
  return 0
}
hazir() { curl -fsS -m 3 http://127.0.0.1:11434/api/tags >/dev/null 2>&1; }

OLLAMA="$(ollama_yolu)"
if [ -z "$OLLAMA" ]; then
  if [ "$OS" = "Darwin" ]; then
    echo "    Ollama indiriliyor..."
    TMPZ="$(mktemp -d)"
    curl -fL --progress-bar -o "$TMPZ/Ollama.zip" https://ollama.com/download/Ollama-darwin.zip
    HEDEF_APP="/Applications"
    [ -w "$HEDEF_APP" ] || { HEDEF_APP="$HOME/Applications"; mkdir -p "$HEDEF_APP"; }
    ditto -x -k "$TMPZ/Ollama.zip" "$HEDEF_APP"
    rm -rf "$TMPZ"
    open -a "$HEDEF_APP/Ollama.app" || true
  else
    echo "    Ollama kuruluyor (resmi kurulum betigi, sifreniz istenebilir)..."
    curl -fsSL https://ollama.com/install.sh | sh
  fi
  OLLAMA="$(ollama_yolu)"
  [ -n "$OLLAMA" ] || hata "Ollama kurulamadi. https://ollama.com/download adresinden elle kurup tekrar deneyin."
fi
if ! hazir; then
  nohup "$OLLAMA" serve >/dev/null 2>&1 &
  for _ in $(seq 1 40); do hazir && break; sleep 0.5; done
  hazir || hata "Ollama baslatilamadi."
fi
yesil "Tamam ($OLLAMA)"

# ------------------------------------------------------------ 4. model
if [ "$OS" = "Darwin" ]; then
  RAM_GB=$(( $(sysctl -n hw.memsize) / 1073741824 ))
else
  RAM_GB=$(( $(awk '/MemTotal/ {print $2}' /proc/meminfo) / 1048576 ))
fi
if [ "$RAM_GB" -lt 12 ]; then MODEL="qwen2.5-coder:3b"; CTX=8192; BOYUT="1.9 GB"
elif [ "$RAM_GB" -lt 28 ]; then MODEL="qwen2.5-coder:7b"; CTX=16384; BOYUT="4.7 GB"
else MODEL="qwen2.5-coder:14b"; CTX=16384; BOYUT="9 GB"; fi
mavi "4/5  Yapay zeka modeli: $MODEL  (bilgisayarinda $RAM_GB GB RAM var)"
if "$OLLAMA" list 2>/dev/null | grep -q "$MODEL"; then
  yesil "Model zaten yuklu"
else
  echo "    Indiriliyor (~$BOYUT). Internet hizina gore 5-30 dakika surebilir..."
  "$OLLAMA" pull "$MODEL" || hata "Model indirilemedi. Internet baglantinizi kontrol edip tekrar deneyin."
  yesil "Tamam"
fi

# ------------------------------------------------------------ 5. kisayollar
mavi "5/5  Kisayollar olusturuluyor"
BASLAT=("$PY" "$UYGULAMA/bulut.py" --ac --model "$MODEL" --ctx "$CTX")

if [ "$OS" = "Darwin" ]; then
  APP="$HOME/Applications/Bulut.app"
  rm -rf "$APP"
  mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
  cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleName</key><string>Bulut</string>
  <key>CFBundleIdentifier</key><string>local.bulut</string>
  <key>CFBundleExecutable</key><string>Bulut</string>
  <key>CFBundleIconFile</key><string>bulut.icns</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>LSUIElement</key><true/>
</dict></plist>
PLIST
  printf '#!/bin/bash\nexec "%s" "%s" --ac --model "%s" --ctx "%s" >/dev/null 2>&1\n' \
    "$PY" "$UYGULAMA/bulut.py" "$MODEL" "$CTX" > "$APP/Contents/MacOS/Bulut"
  chmod +x "$APP/Contents/MacOS/Bulut"
  # PNG'den macOS simgesi
  if command -v sips >/dev/null && command -v iconutil >/dev/null; then
    SET="$(mktemp -d)/bulut.iconset"; mkdir -p "$SET"
    for s in 16 32 128 256; do sips -z $s $s "$UYGULAMA/static/bulut.png" --out "$SET/icon_${s}x${s}.png" >/dev/null 2>&1 || true; done
    iconutil -c icns "$SET" -o "$APP/Contents/Resources/bulut.icns" 2>/dev/null || true
  fi
  ln -sf "$APP" "$HOME/Desktop/Bulut.app" 2>/dev/null || true
  yesil "Uygulamalar klasorune ve masaustune 'Bulut' eklendi"
else
  DESKTOP_DOSYA="[Desktop Entry]
Type=Application
Name=Bulut
Comment=PHP / Java / Python kod asistani
Exec=\"$PY\" \"$UYGULAMA/bulut.py\" --ac --model $MODEL --ctx $CTX
Icon=$UYGULAMA/static/bulut.png
Terminal=false
Categories=Development;"
  mkdir -p "$HOME/.local/share/applications"
  echo "$DESKTOP_DOSYA" > "$HOME/.local/share/applications/bulut.desktop"
  MASAUSTU="$(command -v xdg-user-dir >/dev/null && xdg-user-dir DESKTOP || echo "$HOME/Desktop")"
  if [ -d "$MASAUSTU" ]; then
    echo "$DESKTOP_DOSYA" > "$MASAUSTU/bulut.desktop"
    chmod +x "$MASAUSTU/bulut.desktop"
    command -v gio >/dev/null && gio set "$MASAUSTU/bulut.desktop" metadata::trusted true 2>/dev/null || true
  fi
  yesil "Uygulama menusune ve masaustune 'Bulut' eklendi"
fi

# Kaldirma araci
cat > "$HEDEF/kaldir.sh" <<KALDIR
#!/usr/bin/env bash
curl -fsS -m 2 -X POST http://127.0.0.1:8765/api/kapat >/dev/null 2>&1 || true
rm -rf "$HOME/Applications/Bulut.app" "$HOME/Desktop/Bulut.app" "$HOME/.local/share/applications/bulut.desktop"
rm -f "\$(command -v xdg-user-dir >/dev/null && xdg-user-dir DESKTOP || echo "$HOME/Desktop")/bulut.desktop"
rm -rf "$HEDEF"
echo "Bulut kaldirildi. Ollama ve modeller duruyor (https://ollama.com uzerinden kaldirabilirsiniz)."
KALDIR
chmod +x "$HEDEF/kaldir.sh"

echo
printf '  \033[32mKurulum tamamlandi! Bulut aciliyor...\033[0m\n'
echo "  Sonra acmak icin masaustundeki / uygulamalardaki 'Bulut' simgesine tikla."
echo "  Kaldirmak icin: bash \"$HEDEF/kaldir.sh\""
nohup "${BASLAT[@]}" >/dev/null 2>&1 &
sleep 2
exit 0
__PAYLOAD_BASLA__
