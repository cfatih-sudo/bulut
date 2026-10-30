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
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
8fFT8QCQAQA=
