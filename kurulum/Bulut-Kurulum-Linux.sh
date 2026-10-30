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
  for p in "/Applications/Ollama.app/Contents/Resources/ollama" "$HOME/Applications/Ollama.app/Contents/Resources/ollama" \
           /usr/local/bin/ollama /opt/homebrew/bin/ollama /snap/bin/ollama "$HOME/.local/bin/ollama"; do
    [ -x "$p" ] && { echo "$p"; return; }
  done
  return 0
}
OLLAMA_URL="$(cd "$UYGULAMA" && "$PY" -B -c 'import bulut; print(bulut.OLLAMA_URL)')"
hazir() { curl -fsS -m 3 "$OLLAMA_URL/api/tags" >/dev/null 2>&1; }

OLLAMA="$(ollama_yolu)"
if hazir; then
  yesil "Ollama zaten calisiyor ($OLLAMA_URL), indirme yok"
else
  if [ -z "$OLLAMA" ]; then
    echo "    Ollama bulunamadi, indiriliyor..."
    if [ "$OS" = "Darwin" ]; then
      TMPZ="$(mktemp -d)"
      curl -fL --progress-bar -o "$TMPZ/Ollama.zip" https://ollama.com/download/Ollama-darwin.zip
      HEDEF_APP="/Applications"
      [ -w "$HEDEF_APP" ] || { HEDEF_APP="$HOME/Applications"; mkdir -p "$HEDEF_APP"; }
      ditto -x -k "$TMPZ/Ollama.zip" "$HEDEF_APP"
      rm -rf "$TMPZ"
      open -a "$HEDEF_APP/Ollama.app" || true
    else
      echo "    (resmi kurulum betigi, sifreniz istenebilir)"
      curl -fsSL https://ollama.com/install.sh | sh
    fi
    OLLAMA="$(ollama_yolu)"
    [ -n "$OLLAMA" ] || hata "Ollama kurulamadi. https://ollama.com/download adresinden elle kurup tekrar deneyin."
  else
    echo "    Kurulu Ollama bulundu, baslatiliyor: $OLLAMA"
  fi
  hazir || { nohup "$OLLAMA" serve >/dev/null 2>&1 & }
  for _ in $(seq 1 40); do hazir && break; sleep 0.5; done
  hazir || hata "Ollama baslatilamadi. Ollama uygulamasini acip tekrar deneyin."
  yesil "Tamam"
fi

# ------------------------------------------------------------ 4. model
if [ "$OS" = "Darwin" ]; then
  RAM_GB=$(( $(sysctl -n hw.memsize) / 1073741824 ))
else
  RAM_GB=$(( $(awk '/MemTotal/ {print $2}' /proc/meminfo) / 1048576 ))
fi
if [ "$RAM_GB" -lt 12 ]; then ONERILEN="qwen2.5-coder:3b"; CTX=8192; BOYUT="1.9 GB"
elif [ "$RAM_GB" -lt 28 ]; then ONERILEN="qwen2.5-coder:7b"; CTX=16384; BOYUT="4.7 GB"
else ONERILEN="qwen2.5-coder:14b"; CTX=16384; BOYUT="9 GB"; fi
mavi "4/5  Yapay zeka modeli kontrol ediliyor (bilgisayarinda $RAM_GB GB RAM var)"

# Kurulu modeller (gomme / embedding modelleri haric)
MEVCUT=()
while IFS= read -r m; do [ -n "$m" ] && MEVCUT+=("$m"); done < <(
  curl -fsS -m 10 "$OLLAMA_URL/api/tags" 2>/dev/null | "$PY" -c '
import json, sys
try:
    for m in json.load(sys.stdin).get("models", []):
        if "embed" not in m["name"]:
            print(m["name"])
except Exception:
    pass')

MODEL=""
ESLER=("$ONERILEN")
[ "$ONERILEN" = "qwen2.5-coder:7b" ] && ESLER+=("qwen2.5-coder:latest" "qwen2.5-coder")
for m in "${MEVCUT[@]+"${MEVCUT[@]}"}"; do
  for e in "${ESLER[@]}"; do [ "$m" = "$e" ] && { MODEL="$m"; break 2; }; done
done
if [ -z "$MODEL" ]; then
  for aile in qwen3-coder qwen2.5-coder devstral codestral deepseek-coder yi-coder codegemma codellama starcoder granite-code opencoder; do
    for m in "${MEVCUT[@]+"${MEVCUT[@]}"}"; do
      case "$m" in "$aile"*) MODEL="$m"; break 2;; esac
    done
  done
fi

if [ -n "$MODEL" ]; then
  yesil "Bilgisayardaki $MODEL modeli kullanilacak, indirme yok"
elif [ "${#MEVCUT[@]}" -gt 0 ]; then
  echo "    Bilgisayarindaki modeller:"
  i=1; for m in "${MEVCUT[@]}"; do echo "      [$i] $m"; i=$((i + 1)); done
  echo "      [i] Kod icin onerilen modeli indir: $ONERILEN (~$BOYUT)"
  SEC=""
  read -r -p "    Secimin (Enter = ${MEVCUT[0]}): " SEC < /dev/tty || true
  if [ "$SEC" = "i" ] || [ "$SEC" = "I" ]; then
    MODEL=""
  elif [[ "$SEC" =~ ^[0-9]+$ ]] && [ "$SEC" -ge 1 ] && [ "$SEC" -le "${#MEVCUT[@]}" ]; then
    MODEL="${MEVCUT[$((SEC - 1))]}"
  else
    MODEL="${MEVCUT[0]}"
  fi
fi

if [ -z "$MODEL" ]; then
  MODEL="$ONERILEN"
  echo "    $MODEL indiriliyor (~$BOYUT). Internet hizina gore 5-30 dakika surebilir..."
  if [ -n "$OLLAMA" ]; then
    "$OLLAMA" pull "$MODEL" || hata "Model indirilemedi. Internet baglantinizi kontrol edip tekrar deneyin."
  else
    # ollama komutu yok ama sunucu calisiyor: API uzerinden indir
    curl -fsSN -X POST "$OLLAMA_URL/api/pull" -d "{\"model\":\"$MODEL\"}" | "$PY" -c '
import json, sys
for line in sys.stdin:
    j = json.loads(line)
    if "error" in j:
        print("\n    " + j["error"]); sys.exit(1)
    msg = "    " + j.get("status", "")
    if j.get("total") and j.get("completed"):
        msg += " %%%d" % (100 * j["completed"] // j["total"])
    print("\r" + msg.ljust(70), end="", flush=True)
print()' || hata "Model indirilemedi."
  fi
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
H4sIAAAAAAAC/+y93XLcSJYm2NfxFEgoqwmQQQR/9JMZFJVJSayUWlJKLVJdnU2ygmAEgkRGBBAJ
IEiFKJbVmK3N3E2bTa21rY2Ndc7uRdfNXlTe1KzZpO3FSH0xr5EvsPsIe75z3AEHAkFSmVk1u7bF
rFJEAP5z/Pjx8+fHjx9NhpPMG0//6k/4t0J/t2/e5E/6q3zeur1+a00/U8/v3Lx966+slb/6M/xN
0sxPqMu/+v/n342PWpM0aR2FUSuITq3xNDuJo/WGbdv3QRnWsjUNkmBoHYXD4zD1p37S862uP6Tv
kfXi0QurZf2Nf+rTxwuuag3inuWnIWE1Cr1G4/lw6I98yznJsnHabrVi/u1145FrTd4ESRj1gry9
ozCxeuHQGsW9YBhGoTWYUPEoTLzGjt8LuoHuBK33/CSjAtlkfOJHQRpaxwToAGUbT6TaqN2w6E/G
ZB0pSreMvxvWWXBk+Yk/nbyZtC0ASTCurt3xVui/1fYnd27fqm2jOwyLNrIgGYWRP6SRpPHJUZDV
Vlle5mFZ35wF0Zp3a7lLv5L26s2jOaXHSfx1YD1o7+/ztyHharS/n4ZZwJ3K68HQT+NkYoXDwPK7
mLZGIxyNY0KNnxyP/SQN9O+v0zjS3+NUf0vy9+nJJAuH+a+4O6CB6F+TI+qvG6R5vXSaf82C0bhP
AOS/T5LA74XRsX4wSYbD8MgLkiROKs+S4JtJkOb90GwcJfFZGiSNfhKPeEI8+nUaJJYqct9Pg0e7
uy9eSs1HRAiEmqa1q3vFyx2uIm2M/eyEutL1X9DPhnrDKNTP8aObyZvJ9Hgy9PWrrfF4GKIPxmfn
aEi4SRuNl8+f71qb3KDT6QADnY5LI0rj4WnguB6VDqKs0Qv6VkfIvkOjdlyhSpqq50+fbj3b6rx6
+bRpTeNB6luyWhaikNZREPVCSxV59Hxn18LiC3XJUwLFn4ZE5pbfoz49TD3aDfs0ux6t5TCJI+84
yByjH1t1jr8kyCZJZBTeMwseeEmaJeHYsVu2y3VO4jSj4c5pHBDaTRqV60k9V0MTxRnXnenZnllu
q6s312/aZsUk8EZ+1j1xEi6dfkblqRu0ZwxFgaYbtK0lfmSCjQ+am/HQ7waOTYVWuM8VwGzCQPBX
B16AkgZ+wrC093tLH8+BY4kAMUeiRssAET/MUUxAlcii8XD7l1uvnu52nj1/uP20BtP3Xz19pd4C
6jIfuXNE0L589WVn9/Gz7eevQJhrK+ATxFfDadD48tWzzoPdv6fHYZQ59U3TezS8env9k5u266K2
4sTWkX9MkFrjIOoSlyVm62QxUajbaLx4+fxvth+gvy/jKGhsvXjx9PH2S/1Tve08ff7gCT3LWYP3
lNYQjbmx89XO7vazDpV79gKNEBnvBEQbLH1sC4V7flMLgm5YLI1CIqFILkMmb0ZKkkz9N+EwHOXS
KA0jr/EKr4fhwPKpvSHqtlmMOZ94r5vWUxIFp8Gwae1MR/04mjatBzHxgBSL/8XD525ThJ2zemeJ
yoyp9rF1P46zpvWM6kVN64vEJ3ZExV5FYeY2TnOJ5ayj/Ydf+9Fx3LR+SWx7QB9+mm29eAzGQkNI
m5ACxNNcFmGJT0NO2o1l64kevEWS7jiEiCRRQ8MDD7Bi9bsbnPpjC5zS2Z0kgy6EUTKZ+pb6xe+p
aWqPRHScRMEAMoWk7AnVeeMDbRC+QRYS5w+nJFGosbZ1eHg4Phk38fk1DZ6/iLRCWw8Y7TQXIaEo
GKQh/e8NVbSOJ4QQkpLQBwjUDWvnb59amEAaxJswoQGNwpTWFsn1IWAe0+IkhtmDbCeJQpwzddW0
ox/GewE0jTcLBlYvTqd+PvkEBZHO4XhyNAy7JKL9NKV5CaNDwHM44m+jIIt7E4jsbnhCY0XbmH8T
H4d3P6MRH7JQPfLToc+lHvmZTzw4JJGbEAVaMS0FGgsoK7KioBdErLEQHF0q10W5Jk1BlPhWjzSd
IQlXjHiA7gmxaHKb1AYrHo6Iyo9B13FEUgcK1tEkmnAb1FQa01RskEjqTRLSpIheqDpNa676ECSk
gARo8AuoQJgAUmcioH3kbwig3fjNZKThAZAKRNLFWGnQC9VciLki1Q15QZVVDr+bhZ61lfrHIUHM
74CJqT+mlQaMM/lBitI6JULguaLhQXQx5YAeeQVS6xNob12aUUIP4YtWNS3xZEMqkcgbqoJo1s8I
lmgyorWqqxOPSniSHgbEE2hctMCBlZBnSq0aNCVzBQ6Gbz2UJrXyGI0odBPSmCYwnh7pk0Qxp11S
hFOav6bVT/xRcBYnA0BCPY2G4EWE/WlAM4SKj09o7fhdnlisKB6Ar7AksjvzTzDxQTaiec05W49K
f87FWzReUelAkiMGljrLaIobD7k9BjxDvzQx3XBE/Dhvx7JfsfZiE9kdozJWMrc79YVpNIFv0niJ
ZKU6TSo6IawNMQy3rZgEaTrHRIklvhChlpBRSNiJ4gEtC0KGUqa6KEDPeQjUm+YfbX88bj0i+dx6
EEdZQhMaJGnrFXHW4rdH5ajnr7a/fKzwxoSeEZGOgILjOKEhETiDSXeiFn8bQAKEfHp3t54Bnu0n
O4/pf/9A9guwR2IrPBYKIuqziG6JMu1Wy/I8T08xWBX9tK3j8EhW8jAb+XoZKX5L88oF0xAWClPy
/VdfvXpiQpyKsYI1Q62UYVdQqyJCgZEUIzVb5qPHrJegdLZebql3itUVBElA0BCojwD9+FPqBKxk
SCoiPRj4XbVSiO8nAYMMaqK5VYy8nSbdFphiC79aZJG1mAnypECBJpx5eNW4K38WASO2ijBYlLP6
NN8OqRRW2HOt86qKRzw9Zg2D3m7wy4vGpvz9mJZQ5P70cQ/NeXGyPUwDUvvjMydv/J78WQ+3v3i8
s/v4JQZLM/ScB6Y5nkX/7wJPxqog5kzfuv5A8JrwYh3K3NOyY27YuEFm2c/2Z92g9kTh/9kbZqND
KZfKxHJgB0HTmA5jv7cJ7axpZbT240m2eXtlRamxPUi5TTYWvd5kNE4dVcMljRGqpuNCIVYPiSux
bozWrICmQ7Q+mbdvqJ2ymecpo83JZ9dQh5fYUmvmrwDJJv4pHp2Q8khsY/PcBtMgFWF5dzoO7LZl
+zDRukTvMZEzwW5fFLVI5J/EvU37BUwUAM9jZGjtL7bJauGSrqmsV8CmnzGpvg79LnCmPkmHZWyT
ApJ1WF1OtYl3FmYn1VmwWyQfW5l/nNpFU7dckhBWMmMh7Y327IgEjn1g9ePEGpHuLjMD3DuJK8q7
dErN7R24BwoasmBGnRMCKU6mDgkBkj8B6Zcj/3Wne0JsrDBC77NmTzwrPM5XAPGZxApS5jWp/zWk
rEU4Iy2NOpdnNBdjKkhy181NTxoKjSnO/CHN/N5B01rhxznoSUBcLQ16OUCG6STVyHYigeqMZGBd
mWQxK928KCxc4n+kIaha94pxFQ3i74isjUH+hCp5RCcksJ1zmyQOCIcQzN8I2Lw7fqp/HFyUCAOz
7OTjwPTr+RfbsANfUOrwlDQtnnIiyQLbpmY+Aathjv44gob0hl744D3E1oN0GIiAH4jSzC1C9PqR
f4KpGJDOMwpYLUjyGdDLctNgoEIfGBUDVTwnMzfwR/Tilz6tBeOFnh56tZdjyp4Qk7ZNNJVQXfzZ
SiWkcYlrCuCzKCQRlPlHENLEXUl7i5jaygOCCs46mGXPa7/A1oBmPByyRk7cnPQtUjyhLPVbZLyR
HjwlbsASlrRAWnOkKQiCIZB7/gkrNZd0pHyOR3E6nAxkXvxpImo8zUTff0NPVm/pqSCom7AXBr51
EnYx4jSYKgmyH+1H8/shNBGCiQNqgtlrr95aWTm4ODBmJR7jDSbl3IbLLUh8IklMzQrNCunDHTKh
emEXBHx7RfG/C/43S6bFbM3nSrSCsNgUEZnSocqfjBVRw4+EfKil8wu3ZiXvtW/S2Lit4HU3GGfW
Nn/Q6NrwOUTxN6Qg3X+6vbKyai2DUIg9ZXB/MnGA4o8D9kiEMy4lW63GsXjzOtzx60wvyArjoWWz
RTqB0l3ZpQbVVhvOpLMFxPLQ4QhSJApzR0Su2hNZuPQtIuNsUqxDxrHp+yhQh77gNZSXpoOJ3xCv
xHcN6KzTjPl8Q7dEIqpP1syJcrdp+qEOdAt7y6sHBjtTNYNTmHiW7X0dh8RvjQIFuy5aWG9TIwAz
Z5fW5qbiCNLx0aRHE628S9rXtGit0/9XvFu32Jf0m3UsWH9AU9li71FTuZWor9/84tathdAwIrjV
bva6aVEvRItnJ9Qvtc+DPpqEw14+t3rQTQUFE5mJWK5bYJLqJNBxLuXYtBhtXpLAVV7VAKhzXWC4
u5IQqdjaS0WzinqxEDvCnquUq9rrpFNQ5aZtG+5kcR7DjjwO4AmBx4cMmTEN01f/OtRqDb0qTaFz
yTQ6K946EGp2L0rUinfnlhLPHyR/6sWMtFwSNFbZSbhUguHiIG9xaZ7aUx6eWycDd5NJcD1m660p
dkuzRr8Vlkr89rostspWsfTIqgxYWSpzW0XKeKsd7LMCGBgLo0lQetE9mUQDrdKj19RBK261eZv3
Z2z0zVVmm098slWtl5MIgmEbpR0uuaeqHpTbxHqgfrnI9SRDFSS0MAvGNCRNiN9VyxtdEYkHdg2K
RCX8U5hyT+DY481SvaMJ/e1PZNsJ7XfED2tsKT2Z9ZOLA3phYpElNwgylqFxAq/pgHjAcOJ61lfs
lmKX+8IkymtU9pRgiTDfj+CYJ+1bdgy9M9J2Thx7PK3ZXdrDY5rb5XUlekDi3BDBhzq83YwS8tVs
YgwebXaBeiUzYMxg2L8ihTI+S7fG49TmVUJtj1mVUG+snQyiHB4d9kspX6NyzUNDHNapNntjraVA
8hDKPfrWnUCRDDRe6AktqrMgcWAg91IsfT2uM5Q3RyQN0b97JFBJoi7pYXNBU0Ts0QNtyyWTqMOW
N83s8YTWT9PCT9WufkgN5wWgRWAnTgFW8CS9VevtBtja9JPpwzAhPQnskgRdP3y9afMWdMdm3pSN
xoaJNhrr7U76WpqIvGNjVmVSq2uwj10gaqhF/N8PI49KlLnVqCe4NsmbELVHTM/puwWzJ53b6Bdk
OT4Z27VMs0KnVKyGMSjEn9vxIDeJSA5MsvEEIsjGJgFQQ0To90IPmwYL05DX0Nh6sbX7aEHctVMa
lH1RBwYmzRsq5u0h7CRT5HL3M7uWm/cwqzbvRpD5AEWBHl2OThpcDT73eNRN62okwuF3HSxyuR+B
Rt7HMfH4Nw+fWKt3lq6FyBENxdyGFffhfrrkfNbuIwKDvrqf8cYPHu6fLbm2WixzsNa3z0fecRJP
xs4qO7aUTrOAfaOFC/Z/1iOU3+QYBbPhoa2uLhU7U6YYKFCeBrWG1DyU9e2HpD8AIxG2GdgZT2qJ
nrULwlGhQHhnSZgFHVZFMW5SF+G1C6PjTXuS9Zc/MYRsySrMGW4e6eER33FmiXJEum/3rLdJ+KMv
/hhqUUeA3WQliiXzZlmfyrtUFqWxUT0LIT2BOpFu2mq/3p5tqEtiHBpaf+gfp5srr1c+kdixOlEl
SmrTkAcLmY/NtjQeGjvafteYpcIjaJipBm52ZSDbr8fEP3sfOJ//wHutfsr7NucGLi6sNHJNooef
i/j6mLhFD9+FrxMjkEeEJ/WoUd/52JPfwko22VOQA6IbdMgEzrBjM3BF7e4FlaoXfxKF6VfBEaE0
mnQn6eTn15Jk+1eFBzn1UUOKf0lc1qZVCsCQRcWe3fi4ozRXJw2G/aa16CfHpvNyTF0V5TvQtFXJ
+OjrJu9oT9LNtdzJzopo3JuWHe1UtnCy5+XQDnG8qEeWRDomoiUguL26IuIgd8ru8ease3zDYm9p
kG1WmcL8tp4G0XF2olgevLQYgetWqhY10+ogzljzYAYldQ2U4TejzMBQpOxQrqzaFOV+BqQVd2YF
GOYON5Bw7wg/cci6J7o/ss8vbBOGlJhGJ+ZtwiooNxB2NoCTPGMPZWRlCBrEbqsOYowsNvCIaRJX
PAbL521bgjAYUsfFkuYO2P1QHdZzfjW7mFWVMJV9ljjJG9kkbqKCns5n2lt4FKfZgnthF2PsxZ0v
tnerowv7Agz2X0SDQ4yV3cKwXnsn2WhYlfSKeB0OgWvBjCba6tr4alZidHeOENTilCVwDVVjecwp
M4+sIWla6Go+Pf9Emr6Cri+h7ZKKVUVv3z8NyfL16B/GtAr7jI6vj2hHFHVuojSDhhmCd67a6TK6
+JPPSzgiXtl6vYwxXgs4qcDA/b925qBO8BJXvuWKlnyJy/cS128JFBEc53begTgYw6gfq11XNJBv
s15cG9QWxpj+6QBWzcNvngU9h6HmZxWo9w6uAbPazixDM6OrzsCgq5U3YokYie/5kyGwyeX5zUWZ
EJR+55iByt6rl0/Zx9W0nu/wF/cKCMQJRjaOcsSS/s/+bewWiK2zID5BiyOaF8Q6CKfwt08+q1Fy
S5tE+fiwsXrVoGaNjHpIC0PMvmhaN1duuiVZgR3zGmHB1iC3Z4pMt1YLru83fINIMVJRudd1t7Tp
r2WjKAVuvZi6YjXO9o4N/I4q7KAbkblozHZd9zJhaK4kbAeEwRlzbfM5NKzpzNMJmRtVln6NdedL
wDkhQoXT1tnjqtBcE7yE+ZIpUhBqpKKUqpF9bHq7V6/AOay9btjzoVMD8VDLqXBwNmqhLelCCv/z
etbTowSLrsWzM4soarcfVYmBPdFNq3g6JwzhSnSLNby4mMzhNn/nDydBhcXA6Rb8hCmFNAzci6sW
DW9DtP8Ekt80NF4vR73LjY1ryGhtmxXTIdtJrMIXvK9cR238lKvp3SaOk7matHmPSXbl1E7fZfvJ
dSsDVevXwIzi4RhmYCFO0cAF70Tuk1WQm4buVW32h5N8R7i0kAhl4xAhDbzHc9Ueo/ujgGe1BZ38
XJDr5XI/wZ7xi3Cs1wzRXkRzQqT2MiDqmiejZe3UNZmHHciqq8YezLQ0So8hm3iJ1U04ThjgpEE3
cGhN1ioTc3AqLf9IxeEDQYEbRDObqGcFnnYOkfi/FLpnvBRN3y3kR1ttdFrjyXDIO+bOFWvVbXwg
SWnmRnBcSlTzNMqBP65ndzPsuirz8uMqcrrMIaufxrWp+CDOmHlwi/fiswgSIxjFEXs+lXvfuRq2
ZBLNhyzf+Skwqt2+VRHVC5R8+nmUQAkgNVUmgF3sM/IgjuK0xR4JbAtzOWyIANlhEVpwPIyP/KFW
eJoljUYHvlBjlfik+fpRcd6octRoxgNamFFsLc1GQmnzxhxh4wMldN5bRQJfFQZUDANQ5I+LMalD
h2xMlaJH5tiHF2rSekHaTcKjwMFjNWGqptO3eaxQ8Ia9sG2do8zeArzlCwcX1rJ+wAIIT3gXo8xg
ltAMii40rQUJH5JKRPHdwcKBe8EWPz+z+Zl9oKz8iuSnlmzL6cYD4inTyaBZxMtbfjbEARDXaCqj
xUCKRdAzmtOEirhwdZZOmyH9mNTJ6gayLWWK6CAuNTOZ/DTfrR6zFcDbntVjczSlW09pyh5u7W6p
5QcnDSH5OPFHKfvDhKfzV3X2GXu9VWOvtnnVzi9ZHSiav36L3kk8QsA2HEfdOB5znfQkVKD9SHge
EtsxwOmexN14SDMz5UaPwuhajduteJy1AOBREpzxAXQ9O3PKp5E/vk65rUIHTVuCLBgALaWrpi1S
F+JJ0g3SS1sykGe2aEwqWuWfumX+kbduoGEeCnD0fhiTOC+Nq2xtj70w5dPF8yxsYjjjEodgdigr
I4hS3p8rrY08VkwUiRE0CRwISwYkxbHwfHXszWDjJcZZcrE0ahStD3ao8A5KESJRWtCmqKDXJv/G
9oAei6mYzGYbkFPS4qjHVjMZuLWQ84YiQXCdLUUojA9ebm/tbne+fN751eMvHz7/FTdibBS+4IMD
COegFcMqA2LNZTtv0yj3cPvvvnz19Cm/InTVvar3D1H5MKptqbxHyv/yXlSSdaLgrJNSYXq7qcf2
kYzNzRlfh8PQSN8InHVz52rGXKonhxrd+0f52QolbPuUFpnjemd+mDkr3q0i9J7Qqo0YnNhviuqi
UglsspGsWlU7f562KwvrkYCyjP2U4lT6OZq8qFkGpf3kneedl9uvdra3Hj58SXJzOGFIJhbirEgl
OoLEPQ4lGp5PZGJbCLvQOPzGB1HzGeXUCx5PXwCLU1k5jmMXx9RloG4RpA18eN1hnJqbh2HUISOS
hgWl1FyZCtXt2ZKMrNmxshxGkQoP4pBA1Zpjc7oEDN5YXDWJGTx/OIzPOklA7XX8HlZmKgfeTUos
EJIgWrmmnXqM6M3dS8d7Q8LdrDeE48gwqEiS8WHm/ISe3uibIkLAKx1CMWis4uLL01h4vPyJtC5d
FxJaRkTdt4XYFO2oYPMR0ZBjgouDbAak59T+hVt7kMGWfUueF5Beuy7RCF5+cuf27UIvqh9aRZg0
aswkIsYES7NZxUHT2iMoD8qGkTDwvko1w+fCreV7Mh56LUuaxifubTJ4JgkfglZnYh5kyXDpgavA
LpErkYwYaB3iZDiu45TI4UkwPYr9pPeY5HaSTMbZjFDZj56wIUOrFpLiTxH/sKvSxoAHTf40YaLd
YShIVNyvjPDMBKCKbY1WhY8n8WiSIR+BJc5t6654i+9Z6gHbffTjGPGlVisLRuEbYnBWSyKh7k7j
IcoS5ZYbfkD6Px9UHYbWcZggJwDmlh+F1v6+nMIP8Svy9LFsFV6VBl19QKptfU49SGeexMvl1Kxs
reoc55aSeq8MqdzDYEbG84E2selOABD46aUSMWL3414YjSc0yJ0gumfZRuBd0RIXxSENw4u9v1/n
Pc9LUsP5d0SSHtQX1YfdFAw46GyZDmwtjbef/1IJ4JllUYFC8OZecsZOxXwDf2IbMiTlnDCGOjcb
4D0Twq7CwNVWDMgHmyzglvzlmwl9cS879qcaKAVcKhquVsSGQMnpgYp7d9oHXhG1ic8Fe6HiyxTM
OIkYSuILYLdXTmTJXm63H1Ro7Mqxs7eoWGUVh1EJYuj+daApy3+QM7UP7B3Luj4uVLks6naPuWPj
hNU0Hsz2O+um0lOhWlYbQ3Pa1zjXZwsY6+V5+DHYVvyrMmTFDUjPCvzEqcXzDmcAs1T96EMwXSZR
YXFVEhXvoYrCrlCnS0oEMsngXJZzjS0OtbEFHxTsXQ4K4d2NqyMya130Ssmas4elZY9ksIgHylgj
gRNczKBo7mkW3qBEXBjztPsTJQlO/MGAj5XifTR5A26r0cJBjvcnknklJNWbM9tYpNHpM7acK8Sz
606vKHgJSsYR9FOC9vDwcD86V/jTv+kJetfxVia9VI8dzx6m5f4M97MfpWe8A2zb88XMtfaoFAwz
h2vqt6fSk/gM+60ATjg4yu21PzlwlevPWTpHvA0eu9ay9cmFeOmKZ/esT+odfiYVWJCNmIooKE5S
Epa5/4sDu3ZtsdpyD7ARNjdxFJI3jMTl3viQrS6FlPk7XQr/S5vSzJxx8LvLoVFro34LpmapaATt
R3vIOHRgVbddcsXfsx4S9qbQfcwtGKW/WQ6tK7eCR02P43jsXMGTfpStnivPCvYft6H1U2G+RLsv
Ayn2xGTYm5gEl783ns1dyH4q2cWy8moW8invw9cKStLQOxyd4EgV7dPoxsM46fTCft/BPwrPOviG
7EVxIXkhKcrZ1Jk9eYVajSKGfK84fqVPGKKEl46HYcZKmlN2O6qThoVAWrJlw9A4hmi8XFqqSiru
Bgx0f2V9fW99bXSOJxf8a2VkV86gVBtcvqw3snCu6G31w3r7/PMr2rs9rz0jqURxqlKf1c61YCNP
yMyE5z5ZToiVIW+CyDQkNlLJCvp+MgiRS+s4Rr6HcEwSy59Wkj8wz+MkL1qw4xyckbKy3GOtRDHV
LhVL45TanDUfrhnGovnaHgvSiwOVYxM87U29DlCnJnEixj27i5Re2Aq6wnjQncIkfo58YDgW3ctz
hFG/yd4C4Fk4uLDVhhSnn3r4fOerLRFs1B3cpfDAl7aeyn0Y65Uq4BNqfulk7xn7U/fsMz+JSLlK
q9BrYD/6yHr11dbLxwTd2cVl53XiQa4J9W1jJEI/KZn2ktkoxWH+8DPLCVonrqEYlc4H/nwWYcW5
BXfSQMw33qMOTgNmlhwtNw3SGSOMLWdNhLJU5pCgibWvMFJWJ6mBAhWWww4Jf5h7jdiUcUvUNmuC
aNtF9iFFhZf1i2N2mlWqvW11BLwhoXsIVlOpd72t5HiCVIYv8CtRHgcOOdms5Fd+8ehFCwfIWjVp
lBWk/tjze72Or9qU6ApCYoTTKJv2Z/RVhYVu2mfBEU6+ncRhN0g399Rvm5iPPqU905rKT2y0UjoP
QzpTMBxv9vV2i2QGtZwiES2hvlQj1z5quoLPEQmQpuNgkzBd9ImMy/NrQcO1FSQwLLHzQEQ+weG4
AEd6S4GM87vH0f263tVM5mO9X0l7ivRGyChYHrVOAXDJeP0u9ed3ZeahSgSdjNTEfCy7ppeZ02dK
Mms415UOFapNOd1JwvtU1JewePxWC7HI9YqHHg1WKw/8m3Fk6AtVp0dRqMrkru3eKPU3UvFFTH1F
v/BN5u+Vf7y8EGVfpyjTVPDzDg9/9btYltRRpwPLrNPhfjodLNJOR3UmK7bxV3/5q/njSfsfmv9/
/fat9Zsz+f9vrf4l//+f44+Uxxcmz4wmvONFop8TeabIzatyuZIuqnIiqYyu7FCBYYqc+1+xGON1
KifkZlJG4zwcvPzxEJkwRRhnE52GHUmI06Avh+ka3A5nwQyRAfWNZ93nRKRTvGcWsepZTxhkhpda
JqZMWjiUlogqYz96MkQsq8TsNS3vOMys0yNPgouQt45aWSMjWuel5Qw5PMijmIztCQ/8/rO1W5Jd
v5J3jbETqhwanFJ03bMeYRCEqp7fVsOK3wRZSJqloNfyj/0ufpIMKZCY96zyWTmS31Sn/UeuY0JT
kW7KRE7IXd/0rGfIytfzK9sgogAayaqMZM8ZzU6M8Q74vD0nMzUvEOhHnHq97v6AEZLoX3KXQHEF
AKfT7yK9Kwu/VOfUfxBPoFLmoheJyy7J1//4iy+fv9zuPHz8cidPLmRjRtlPlZ5ytgnv5Jg/wl7A
AUreaaoDI71jTszNX0dS2qQS/BbqUZE6tlANnnN+J3zpkbJhywFqfh5yM/HR1/jodMbTrt89IRkk
XQfRqWqVP/lDgZ3FrwWQ6Xja4Ur8U5J/Gw+SSb9v/IyC1zLcaPJauRuIBDifjjSMk5D0DK9wUHV5
7HcHKuTd9op2oMn7ZJBwkqVhjEyUjQuNYSRgYBSzloJTeXnKY25XPZRqhIQ4zsia8MetvH1JytDK
0UaqUvESP6iufdF4QCpiZ/vvd43plBwVtqdSKwAj/DHI1EeqpjKOT+XN1/JkpD5Vga/T1+qnfJ5O
chTJwdSmfJFCZ+GxqiW9d1NpJc2/fCM1XquaU/3pqy+ccLSYXPWUuJ2015f2aTmPgyQLg3SGIHsy
3UJeXqamOeWzKN6RLz/H6SpP1M6L7QePt552vtx6tm0shoeIGuFDzij9zB8E+rtPnaZ+JBQj2ewV
yDRZ8UiPiycsB0saRfKqMJFs7Bqu8VQpevlQUzL4xmqy5Lsa84twrIEghkN0w4UUomhFeMFrfzSW
Aj2Gf1lBqJGsSFij+KJxw/oifDNU2f85rXOAtO9dnXIDLE7xx5OwKzwS8qOxs/3g5fYu6Ht3++WX
O5zDw1OLk2FZxLdFbyzJxxa9QTBVT1bX5MvXA566sNch5X8xL8XqfP3xPbubIDF8FvrDdFHQQ08I
l/zDn2QnMrKDxs6Txy86v3z8VKa0mCg4bgxELON3PntTP4mKEtF4JK81YY7jIEumeQE1G/L7ovFk
+6u8wz375fbWw2fbihTVD0WQ6lemmc4HkVCBCvOlXsvXo68SERw0Gs+2/p4h79z/apfBX19Z6ZDi
mL/As9t48ODRqy+fdJ4+/pIf3VxpNHZ2n7/41fOXD4uVc0NdkCBkeRQmMhKerYmwcJ51IVNoLfz5
7vfyJeLHEdnqQ/Xl/XfyDTPPpM98YPT+O/6Y6AUwevc90z2zOpFSg1DxSJ7cmGcNWeTxiZzkUv6E
a5DeoD4msnwQqa2/9PxcJqhg3SNaf/wZCFvC50hoaCwfb1hMDWSYyJEvMHHyfJ4FCb3Iv6oebhjZ
a1vQZpT8FH7PfcoA/IgBjnlwGZ97j/uMSkGorC0mgb4UEvrKTuRVJqnzbHhs9ehE1ghI4amfaegy
Ip+gJwKLD8wzrcEtJYPj85uncdgTp4gvnL4/iVhJkQnp605EEZHVO+yXQBIT3u4jZo5bngxl7uMo
MKZyGOjtAVlRIbcScCU1EBF9WvIJLxWpJitFrza10pg9NnTMPzslwjcB7wgXDuUuCe7hAz/FxKQR
SQRSJvjHIDjyj5b5h+TDRZSiVkLNdM7ljQNSAnqSx5kzsfvDoZPYe1vL/+Avv+m8++3yf//HA/Vr
ZflT9QCMzoBKtrCTjINj0N5Bo3bLDlmesDNBHXSWqAkUndkJRzNLm7PgHCw5n23ylz2C5cB9y98/
ww8BakmeLL3d76Fx7rXsqx0r33mWzqZIGs/4TfWWSRA5Y+x/rvLWxVjnost5zuw2o7F9UI7hphcN
ncRGHVBpF6lKOqRcZJ2OSjJD+pCJX/zUIQL8qhQWUFxQNeNXp7KINe+FyUyoOYd5Fp5+p28r46vY
l4TnlVq4qCaTUeDgo/wCcqjuTqBSIT6KAl59ocI2ycrscBAEAgU5AwizVYTB8lLDVpaRQYkb4byQ
THIH0oijW9EB0ajG+7jqmzJPKsD0kDhMvaoC6p8ed7C7sEmW6Ur5FZkp4XEEw1mfbOdQi/xxtan8
qEspHLdAaJ7yVzHgnyFeMOMsy0YynAqElSQAhLq04A21mxPmTqNTEEJLzDZpVmeIuSLoJC9cv1lZ
2bIzU6TWHY3kYvO2Fh37Bqjoo9IhjEr8TWpu+HnFZWEz+ygzQcelkw7GYkejBu5lvD29uuH45NSX
pf1ZP5o6ykL31CcnyCR25hYsrKL1qj1VHWRd0sFrD5fkceMlxlim6pmosCpYPIIx+4vnQoygrWBo
TsUYUVutS3IMlmBTz2S5FKg884eDKvHqo2HnF6WREdsTjkBfAFbatMB8+CsGHade3ppXYbkCwRCs
U3Ne1RwoHCdpToNOFht1PT/tkB4dvp7ZPNOt2LL7qH9jutTBE/WsVG8QBOPyiszHJXv9MqYaZPZ4
m/tcNXrROu9dlHrmLnt1K4lbNj0zmETzoTgT6KnTK223e2pzvydUSJR0MjmalzCiNgzMTG2Qr5ek
R5P3oa0AcXpB98pzoZG210bIrUpug/KzsUY6pa0qlBNOLfUOqxjnqLJZpONxXV4COSrB8WjMEcE9
mUHsrR7U6iZayCsgDVtTpZt3VIRt7pQxhlTyN/z0OarhZtdqqTaCUQ5ACT6g6TsaLxx1ka9o7s+t
QeV8Nn2tkSFis5OS4k06X9ko/cDGmCXtEW6Y0LhZ1mhq5RdpmVyeNM3NvNudS5I1mPpEiWnWMNXi
7OvMw5yragWkwlfJbvgKd2218lutWnJLlhHhFyrHOW7LiFJE9XvmnW1yBQNgzK2Q/Bx1rjNW9Qx1
0JfJjDl0JYxEYkVmdCm9dLEeQ3WzS6FyurXJblBWKfWVo8MlvkGlipZ4WuvJIYdsZlYUYE2LySDv
z6PFPqpVfuJhjgTulXdqk7pkC4jHoMLgv/S5p1RnvtGBv/5c6zLxz5C5zlT9AM/83HM/x5I8svdf
r6zYcnLxDDeNfHr74PJmoEGHg/yGwtkBCsel5rxewNkYrhkVXbZh9OpWNosE/OaWS1twnxswbRUQ
bii8F40PoB9Ohs9v5yUt4zyNtZE7uqapkXLhynqvmlbXspX09VArjRlS7+eqpVBwLa3rkzX9PYWp
A8iqPds+mAmT77BbBIVz/whUzPwSYE5yabENop546smsfGftpTgPu9JkNiyHW8haLNyMNUszYP40
QlZRbmXJLG82NEs+N2R3Etfg8sYd+2jot9qva1t2+QZFm3cf0wkuheW77XC15jCdRN4sWZvzkyOo
cnBnjyFu0wjkzIqJ1kVrfQ69C01opUpEPjfEFnaTunbn1Oz1vcm4R6LKyfrsWq/LGZRfFZZORih3
CrdEqWTFIJcKLdwSxqkiDSBp8lZ/TjuatyWKhcP5L2rkpD7GZt4mFALEfLNtge9p0DeF9owwT53A
vFgpM5YNrcUiox6BceKnTo3OpZa7VvT65UqFWllbq88SRuy3/DYP7Y4x7h4wbVbAUdlAcK+R51Gu
EjQS+vb3Kq0c7EnXBwoOta8gF43UHVUpXFnzujsv81vspcPV+I3KFIdLBGb1EE3zuC3AVuclzqms
KPdoYzZ+VOHGHsrd08Z+qzhCvwGDY8zpjbwaHlPuXV1jzdmYcpBn21cTpTwYv/5NDVTwMgxKtlsq
N2OTYc6McaCAvBImdaO2XUmJhA4S4+gjbwJL0wkTpdu+As3uDIXpHalLq8pF3nxttzt784yd8uXe
y9jf5nng1TCv5ZrRFneD1wBY2idz8/md2SG7cgCtJzHUA8uRe8fnD8QYQ6XzpZrHdZ1/wBg5OyXN
K4PIPaciRHM9Vsz/mbmXSyWuO/ncuhGiOO30gjGLex7QzN5iMdbKFmPxIt/JNsqqPezyxTOqL0T0
zBDw9APoV116U+M5PSLNwD8S28Rx7B7fHI8lK3fII/+XY/dxjzwe8oXy6plPy3XMW3bqfvnZ/DYz
f8h9iSvoZbuVv3Fj6TdDf9g9CUa8IbXzt0+31C9+KxEr6vYefHPrzSYO54lMrDl4BJ+WGhfTAy+C
IlBgngu2hELGUQ0LMLeMr6SiHY7Kbn2JYKGZ7Ot7aX6QsEzEB4Wcz5JA3w2Aq0hZd9pcu2VmTeFn
pAcFrJIgiS8Rm+M2akxR5USaa4zqDTR2mPIuGfykMzQUFvoq70yhFk7srdbgFVoDNSKqH5fca1sI
VFs9cOtdf8oMxnjmuR6CCHHQVa9a7Rl1m9Qi0ihD1jHRe3ig3L+Nq+pUB5c3sWzCrhwnomirG2P5
R715IdpvOy8FaPb6fIbeOTcaWi4aulD3bWOD3jXMkZnDQFK1IB5OO1DREXWutxJwNsxolWKu8CSX
17bcF9wutt74yGqljE4wmivDQmWVUpy1FU2Rms1Op1zJYvKqmmu5Gl5pRnLAKYhEIa4WKXK7tSse
q6Lgxc+opVc2u9R9QrJ+v5kEOBc6WN1c9W42raNNvt7QODKF6yJZ/c4Ks4kruTXpDahsrfZsWMtg
B1WrpLBkurGch9krb5SHTUvZVWRTsUWF2QiiyQg3FQalxioUzonzrVnrCWy5nPOUO4etbmxoagAy
UShmxsd+CchgsQ+yekc0bsP6UOcOOxQQeEpGwLGzCu06ovWn7Ma9DEsUSZBwN8LMwxp7kwdHViQa
XiSYiZMM0Ooqt9BFzO4qHuIO2iP6dUQ/FPJaJQtzVmuWtu9ZK+36bgvbmH82rdCtTrkHIaBvmq4c
KdanQLngVeTVH8YxtpOk9N7KAf2Pb2Vdw2JCHPIUFzVHk64K7kZCxjf+FHfb4RJqdSWzn83IRQK+
aRr8xLOViKTnLHwU9TJG4KxmWAyxCd0sjKOgx6frUrUCK+EiZPeq2OZByNHN1mkw9Tl6uaecI+qU
pFN2hsCUcFV8umk8l+JaND2PZgJbPnf29s+81v7+8gFfI1YBi0+WgCIL99H+PqckyQ/Y2V5r5iwz
uh7JRWMl9ql2fKByOkmhPhoF4H429MwWjLsRcVtrNuUHtKBQbkjHpxLVNO5LA1CoaFkd0Y6BElr2
jwgthJJ9z/msTRh+C6X97Xj6dpC9/Tp9m6VvyUB6O8X/ffoHCthb0iLfIs727SmR8f5RPTKpe2Z0
l4y+UHYkDc4mg3hQF4eD1lyUWNVoAO1/ACpQfPYmHkTlaOotX/xbkh5y0axcSa9v7GVmWVzYq0nb
POhQnGDTFyOHOINQvXOa9yoCvl5o5ibfq7ZLoGxo55HkOypPQsC395Kqc8MqErfMZIolJUgeQMOg
B+6c2yv69m4wiOJh/DWNDukd5iWNhfBZQFaDiLNRLlzMbVAcojh8lxYZbHXCWnZp0P9v3NCHQ6Zk
CqVsDB0eHtpNrV6Quu6qZwd1CCi0NTyoZDzSlySbs0xCgslupnSqDj7kaTqg+psOOk1OUJVZpOPa
C+Uw3cTalvwSvMpniTaKI04gqoCZs13Mfm+1euDkXpUFBP+Ap9xMQ+2amo2rYTN0U6yTvnaFq8uo
uJJsZl+Q3GUN+Fz7uVcvls8JdiKP2Xt4VfQXERpN1jn3IYlUzpEIZT86BxrkiT1vG5QbgTYvg7/0
wonZzT9zdvTClxZnoZUpX940ur1if3B+9n+80f3V7tCZ8S2N8nYAKSdPisNBbSLXMZ+sOlY5XM2D
Ql6VL0oiZVHroRitrayITmMaAdbdudj8ABM1T6OiibqyEZabEvMGz+uQ0zbtR0QgymFOGoA5QrkU
lcuo1arn09XXtNchcQ1INO5JRvQhGG3CGTrzYwQOVIwTfxg2rTxJdYrDbwPJUu168/aSJdd9RbkR
G6E9b39xDoJqotxGob6hXZEltLnbs5jMcS/502TJsOC17m6qdnj5ch6pNj84EHyynTsgETNEEm63
isB113r+hjpWpwJVVlN9Qm4u/ZlXt+4fOTga9/bdH/Evcen33+Hf8O0oHFGLbyNECNBDImv1HRT+
1n/3+/ffDYb+W6TApA+cgEKSirekcU26uIsUqpqSwtTfY7eejLVqkx+CqCdfI2jG0EXyGLorl7qe
BtkmMaaY9RY9x3vttVsr0DYqaL7pWlsJZ8mBeg5Et3VqEP8NZ7s6Tiake5K1yjyhCLIA5SLPatlt
FHYHLIGMI3cOVIma7U4xS0wTs+PmWFCTyFgGvfA+g6HkuNh3P5gbQKEwlsdgClx5wMIH2oVSm9dM
YVURxDWbuDwadoixE0/1OzekAuEEssDuWjQ/9XCVcw1W3Ugzi1rtWf9UJlBdzATeyhUMmMt+aFRS
wpNvMHzB3rybYdao8Bpb6a+xRQ6l6BZxYmx9m9vlZHZbt9zLwZ3ZiF5rB2sHVFk6MdaKuiKxVgpI
/Jk6eSr6jbNDTAupdNi6DSTThpE73NBV6kWRrl+c3xUxJGqbSB1RNv6/cP5bsvD8aRMAXH7+f/X2
+vrt6vn/2/ToL+f//zzn/9kE5azkWgPKA/LY9SMWaS5cIhI7k9MgItpPSSEb9gKVyglZAB4PcDSz
G46QGSRTYSqkSmCNDeNjPsMPBUql9yXlfnwybuN2hl/GMR9Yxzk3JeWmfAyfhFkaImlVg5TfXe31
aXN6rKb8gBI3Regh5B7OhNIoEEXr8MNcoWNT2hSUrLeQGtdYY0mrIxczRNawupeXRGZJyQeuYxtJ
BQxH5hl8/rsrf9bWyy39KEgHYX4ujv425U//ZBCN1/fkz3q4/cXjnd3HfFHOfRoLhpv5uCMFVxj0
/TfEgqiXli5ndcN+ZiQHbDSQjGDqvyGu5uuU8wAFGq31m5bHGcBbU2jVSPLgDzNM7SAeY8CYNclC
g9xJ9EI1auYHQJKrYXg0J13AiZ+eGG+N3ACIa51/0l/eMMmp50aEebN6oKHRuL/14MmrFx2+IHez
enGHDJIv4tADJfi3Hz7e7bzcZpMWd0OMcbmGHL6yf333/Fbz0wvrM8Lt3q/3o4PF/cjxFj9zf73J
L8rP7qnCD7f3vnj/zwd7j9//4WBv51//+WCXv76U0h8rZwb1tmO9xcezZsNt3LD0yuNTnJFge8DY
t/xpFNqE4mkASqPJybAyp0HCfpTC+cn5HUKYflhjA3+K3BU0US+ebj3YfvT86cPtl3OHup8uOq3W
2xtvW/uLb+l/dz9aXnbp4b53vn7x1lbFnFFw2p1kaP9tAeFb4hRENaMgi+F+pZ/vvzV/B6+xjqJj
CxGTbxNiBlbcJ5PqJLDczxx+CD3nLZ9wc/POJpEKPnwLBHBXXX+AH++/07/cAp2PDXQa+FRspZwJ
g73G8sYqv2GGxXHJYZ50r3Ef9zXNoC6BywiO4aUbyweL7p7VPnBoktNDOETpMY4W8s/F4jy+fqLP
5FOt/SynIXFLgTR0hrH5KftqkgTSSIYTS/FXnS5wz6HHTeGEA9KZyJw70Kk+ZjyGuTt/hMwKk7Gz
ZiSIMxzZpMepAuuuW/jMNZ7YRRwimFCBfKBv5/D7AZ+1c1TQBR9pKkb0Fd+VIQu+i1kgE59E8gYn
bGmSPHijQ3PBkTh5C/EzyadCiyEQHjcNqdVerxQpJyctoE9yCmAz0rPqqi9dMqMqVM4j2b8xXbcz
JyLtL0g6JGn4xhBeXpGDvtpYSyWqDjx1Rsr+tTo7e9C2TQyJKfgMyfcHaDS/mGJcTtsTMfZCnSFS
3EEDnxhg6XIRyWuSHw+VgGzzQGg5BVdeXE9eJZTbrFmK3cNBlihOsEMibZTOQZmNzRyFuiREbxbr
peRFxC+LrIdILImDRixQ8hvijNgJhq8aQKFC0sY1R5vGcggLSWcqZ4Q5Cf9lxNHn/NMMZCDQSdZL
DYU+NCuXDBXxCw3TCTFzYi8Povrwc4CXwmpm2KikkhSw5bxS6byyzrKkR6QWfwdcwYmHvabaZS/W
PSlcWMgkMYhqY3UTcUD/b8LfkfgqnOKIem/BAYLrBocTzeKmfG3ElFlaeYsvxHGgYY/5kaM61XgM
gcTl1Zk4i7DJoSfiCi1qUDMdbcqjSSMcH8fAsBlnbM2e+ZxLfW9YihdSDkE0qrcF+fpKM7T/wOQ+
aGYGwJx+8xCkIrAnh9JVmxBoweWd7NKJ0TrA8rp7aTtVGODqB7y9VoZFTlvBtb+ZB4UMaxtrpxXP
rsTA632ByytXIZnZ2zSKmgUR/VO6RSMycgirGSi/rY/VX96sxEHkF63pEPY5l61BSZhkQUnOFVlL
C4GXGyXaVpFtvglRc8juu5Mg9ccwqCT8X9Q8Zmf6NrZitQGt9RJWMVPSw9KCC+d3yTWKU0M5gy4O
5lx91AUToRo3N466ybDP3hh2zsu85mspUuuoEMMo1TQuZyiuJFDfLimr8+gaAe9BTzaRlYafb1uX
MscCcJSbudNehnNl5gPZ6ypcRhtlO0yJ51OfL5NSW7a4BUzv4oopZUQGRMGZIKYTlfffm5ZiR5hQ
RkMlzIfH0ZyJ6CNpSg0K76XGc95bXUgopzbyasLga0YeXXiGdyALEEnF2hjpn4IWpcKZl/HZVwWf
Wupu4Z4+KAh7/niC6wHYWoUhwMgb+bzpjd3vaVi6wU8WpIToM6KQvChntrMbEWNmDNdkCii+JHvC
pXcyb/TvXpswubdycMDx9ji4jod4tnrQPqhRq6Rmnqa7n1N7hXvxytLFlsoQFOsPQynbe9pFT/0U
LLC+CJNdZdB6ZeWRlnIHgVip+S2tNBMLZFkskDa4UNiIC+LBCfs+AhuSobZfR0Roxc0Fl9OE/Uoc
SilRwhsrFl8L/DV8nDRMPipHYxto0PIwwq7wzZWV/CFj4q75Hrtmty4fd194tdhR7D1JecMQjBp3
SfrsBvJVSCi6uCBknBedXJAGThoKMolcOeYddVQWa0kjqsmZ361ggAyXkBrhYEAWUKCuMVGLQHM1
8N4qjdG/BgsVBprkawIuHE41oA9Ms0fHm0RhPwx6ks68YRwx7UTzdaBmpS+DXV9SqWB4pKZDMm32
bb/FvMSeETGtXnDaUjmWsliVPlKlqf/NdWnPrV6YTLLRbos4LpK5tw2mz+kd+316hg9kmdJJ2ts5
VcyGx3IO+jZj+iNm4EgEqTJHtnMhbeO6TSl2kef0Udc7F0oBBLzhcqMfDmm9On8nSI3TP7PG67Ii
MC8dkFICqic11ePiophGkQIBGyjKYeelJ/6qw5fKloy0/Lp17yR4DedPmjnuXnt1pXLu88jvDiZj
lcPCdM61ECZitimX6SyfU/cXdrkR89Y1mL97jqHxNC325XVgYYtXh2NjjLhCfXOBkUClrIXpvNda
YzMRVKkwE5I9aFuncvSpSV+giestRK1HlA9MdWz3ogBN8tn/rIBdeS1Cvg7ye+75lIesiT35doCj
yOoKrbZlG2fyp7mbXd8+OY1Cz0ixlPsIqC1N/QVRCD1UL2nHjVeidcr6q+6/5rWqNNVi/zEMmT6+
OPYvvvrF6Be95V88+sWzX+zYrpBZHtOiLz+66Jg3PdR0hSzqEMCjAdJfyQ/hUU1hEZ14UHPPkKp8
lhAJKN25Rpt2K7j6EZ2pimZHQDc4y4Fem0pZrx6ErdxdUyylYuplGNWK+WLNE059KEUZvLZ0jcZs
cJ8tIKjTDQoe3oIXSmABINFwNu6D63RxdNk8w5BPdbHY+OK4yskKHTxtVLlstfBOLpL1cc57Whlf
5FsiXXhTS+tkdlWoNVsm5/objfKxVk7Ezk68Irp6CuO45PQ4TzFzUez6RIF4fz37kpsvVH+TiMoP
HNLaSNE5rid+3Q0rScSM0wzJsElSSb+srOH61J+Fqlh2FxyK+r4GJfwlv/9Vf3ne1/9h+/9rq2t3
Zvb/19Zv/mX//8/xd8P64X/5N//X//GP6jrsH377P1tf6QtpSJbyKemWpS6leUKmyZZcSvP+u0aD
qzStxcWMLP0RTBfcdymOY/bNvv8OQWrvfu8P33/3r9/60eJi03ow9CdwEATRG3BStiaLu27ef9d7
/13iNd7/AXkpoiCT0Hjr+N0fo16QjII3G4gF9KfWm2Dw7n/Tt9DsySUpBw4ub0/brZZcL4dtO5ez
96cB7LaRP4CJRd1rmLizxrL1f3/7H/53iy9hef9dl4BAzB3f44lH775/8+57XC8gnocgCspXJ7vc
wO//M+PMUYfvm5Y68d60Xjx8TtaRHDg3Dk03LTl9Dq1fIdiRw70IIOKTu6TM82FcGgTyDVtAKvwg
AJ049TAcYT8sof5/+Kc/YhaL7cG6+WMDfkLAD6yMwyhp7i6fMyqWjPzFRR7h7/4NlS82XN79MXn3
fUSY4aDMsZW9+17t3OMWmwgTsLjYRubiJCRwOR9y3vCIQzs/U1vcKa5tUAFVOuQCG76ALQ3FwS+z
9H8SCO/+qbjK6/231HYRq4Jr0WgENDLdjPKdLi5aDtFQN2CLmtomiuKNsqRp4kNZX9QEDVzm9Xf/
3tpFAZ1hnJOvTMOxssGzETLqIs2yha6pkWzkU8Xtgcb62B/gDgi+0YcIGFHy7CEEvffgEB+8+55w
NyblPcA2Ni3J//i/Sp8ClNwxMeIByMCp2KF62jo0JgMYJnwQVOHIwooKRpD6iM9RrjUCESm4QrI8
G2+tHS5ivVVpZt5aX3L66tL002/613rbeLu8vJz/nyovLv6KWorPUmt1pbW6Shh+a+0dMlNYfiLA
LasSSGJ/eOBokOeWcamJd/8u7Gd66NLPyO8+36lt/5nfxSIfESbntm+UQfv62vWFXtC2DsmoPrF+
03oYn0WcW2R+3UMFzNMwmryuBYbfkP08FxJdYC4YxPZoajDDRM1zKgOOhnqotudoTpEd6F+/xcrT
iwZskoN4FheL1d3TRhxc01Qtg2spEYog2qT12lj1RBYsTEB4iINXE0Rg/uLp8wdbT7devHi4tbv1
i30ud4gz7zQ/9Po3rafhEVWZtti90fUReGntTMaI42np0jwQLu3x0ZVWekIWUItDdQ7dxpoHLsNL
p01oLsGuVtS69+mSyhWHjUFxDoOVW1/FA/jj1ApTgC9kvqvGRJztj284qDlfHD1cRTyiDiIsxHe/
f/f9gKWS6otRg9CndcAlcgZwFRJEttp78ftvcfELQq0QoP3+W4FpQy3fKeBCQswmDjMcJ/7I+mXI
F9Sk3Tge82VtXeL8j+JRcJQEZz/89l9caoYWs5/x0HZkTCckCWBrUHMaNOvw+dOnW8+2Oo+e7+we
WoqL+7yh5DVuAm524AJsASYXuyMVMSPIdA6/OQuiNe/WMuzJhOaKH6wXP3tBME6DYFA86fKNP4QU
eX2K20CG+sVxQEvnkIdSmSg1mmMSpqVbgxQgxM5oWNzu+qFrcRL6tNgIINvr/bfMpInMkby8GIum
5YHaJhjz5yhAgBIaIFGDjbVHQCPXUMh8ufVsIYBUSKAtkLQda/xazuqa9cV9RMhRfz/82/9gHa4f
0QjXPqk8vYOn775PiZnLg9WbR4eu17jlkaRPfXkT8eXT92VicQKWHvPTliVe7xGk1gJEM5MszVka
jo5xgdIgnsqK1uuTBC9HXe7wfnnpBiVak3mPHNg00xy0GGayuAtoSppWMgw3OBF0rgMxKxky4iBZ
WM4PWWV6gnvk+UpF1ktSmg4eeSZd/fCP/5U66r37/v23ZLKFBKLsIAhGh3hm3HAXKl3POnn/3Rum
XJmGWz/89nfrKxYO/g5IIXv3Pd/1gQn5zRq9+pTQ73pWlRUabK2sxQxyvB0TUrpMcRsWThySdiKk
kLNDvjKkUUi4Ca8pah1rKFdOwUhDzbGNqFLGia3rlnQrHiHNJLGKiW3xaRZx9TPFLC5uD6Q8dSMP
vmIeFZTGsrjIwD3xhz0eGYC6nEnvoyyxCshh67/9F+HYLcWJtX5h6hE0jYcDqUMix2uoWx+J+PRi
JT5DA+oiyIjBUHpCIS22WFmVgRmkzb+lOYTekrqzPcQukQDRgPzRfHYB2gq9wPhmNftWTwntvE/O
8UYDo08emhImTwpGp9gDtMHf3PTugILY/XF4yCK4wdscxV3aJXbYvnOkioosMIRRwVhjzrYHS0lU
2CoJIiqSBUaEFkhH/4TqspD+m4dPrNU7aIpmG4JigYwfbs5ywMLefxuIWHn/ncLbu39ntt1oFCQg
N0XKbOfrAlp9oVpREyVctRsaB15LVafvGGxDWCwmvSg0lsGz0PbGUy4obKjEQRYXMW80bWTkeyv0
32obN3zSIP1eIkeYiasQLLumQTW3G1wayV3p4oSqw1YecFfEdB6y1ScvSL5nejvtsAWp/2YYSAEx
8kgovP+uT0jE9kpesBsOpJCxSAlgQX3FCpoOiwXKMxEcFZYjuHGVQbIxxY2YfDLCDJNGUCxEjvRV
cfBkx7BgJPI6fNDeRxDYeP8k68XddB/3fY0OXaGkrXe/X1wkCaIn+iueP829iV6wjpP5SFYXrVrU
ib6DLhxJFyXk81xFuOvusDW3BonEQVlYqML8lDiLuBEsuTgHkzVFxN8yH+BmJMiFhBvWodzQBt3C
vLsNv8VpiW8Iz9OfknP6cIEzRyBQVqTnIYLoUIZvbzqU/erFRSPQFAU50FTx2mVLZ9Rraase3wpT
nn6xLU+fkomNvogpT184Nxc+xaaX/vhwo7CIOIvJjA/J3BPdiLojnqVV0eIWQKIUNrENA/kkv2/Q
vBRQNXGf6HKmBV1DzYWYxJwPR91syGa0kHzC/HyX5O7g3e8DXHOTkUFgi24TRqe4XPjQ1eF6xZWG
ebBuyqqrgArqGuvgmDiShwItX5vYDU79I+JSVq60WDatkv8J0hZ2tplF2tYZEFhRYCcEj1nfgbi4
ePj5IQ2WVgy12FXOAEubz8UAiag+x+GTR8SkWkXmkLT1ND4Oo3IqEUUorBvm4r7uEkXLYE7gT59z
yUNAY3CR5fziScJDWvgysjDphYxvyZRtznFOKbkCw5c2Nt7/YTzpTtrW7IzrmqIX9ZsW0e4gJQkU
yc6pzqAChwgGlkAhI4FziFQqOzhbS1NMSyWJJ4Tv1llwxKhwCYHxgFNdkUTziYfStGMGx+w8SdCd
MMqHVQ9N4ZeZKJ2g0RBuKmd7cb2ycATYKDp4ynT0yDz2lFqqY9/ff8tB0AX1FGHYwhXZeSR6iMlz
NSl4SvMoFVvgs7YpUzzbICZJRyocZSwzT3QtFobyLAGNA0hmVvla04DAH7o8KnUnqqlQs6LyPPJx
svBUAS9xf6wQ8KzIiMy5txwxXmiQRDlyFSmpxNKOHPyBvYg+4RyQBYEgXjZn70OngKqLxk3t/d/+
0VLbXNS5yMmyrw2Kr9imEoGbu830zC/ntGicoBIdOz9Hxc3Ba0yKNSGJiG7r5RYY5/b7f37/h3/9
5933f3h5qKbW1R7gkNasIg/IRE0fwl3kdlixk9iLgRjwVEdP6hhLxWOLmCaSSC2ckbCKKCb8VAse
4CF+CZIz9WXZ8KEtQqwZFyTeTVoVXAHmvprmHqjvh//4n+Gflf7ZfcBUxw539MekxDqAeETzSJ8j
f5AzC6HmeCjeCnXgg/kdU60RLEomt5o6rsKGXMS8KzBZkCy8nvgxIt+Qn3NkrYiNoBCjgqOy7ARA
0CALchMhCjZfpSIRQBL1hyVVHFE7nDmjVnJ1BvlRNZZSzPLg41cAkvD841iflqcS/oDAcAGFthVk
JYO0hQc7D14+/aXLplnENxpX1RxhcHL2pszVLFrs9JVdy0M/dy0P5RAdGLgK9xX9xwlaJ+5h7vnm
6HW94Ew1CasKCtI9SxuBMkoLNxljbgHLGMGsQ7EpmtaRXnVlAHs5puHMRGoo0sdgKItIJGVNuPUj
5nHKkQJqIX0gnIajz+Asvm/asXDU5m54WdhvyeoZ0fKZ9RSzo+Tl1rOmRLIhKA5OE8Twv7XKPqf2
+tEhHs63wrgANbp6W7UqS/L2D7/9Hffzd3g00+wdquWwc2kKvStyL+/kjupkfa3Uyera0vwu4O25
vFUpQc3evllqdu3mJc2urwF0SdSWhlfAzYXfQiOAmSsyUrTGwmzP7ZLCKtEmP6tVvcBUq6y/K5BG
c1ZoKexiA6VeZkgIZcxggc0IOZB3/9XTV7udZ88fbj89tOKETzZKH8ityCch4UYQ+lQuBVDj82pR
QowBKv3aUrlCRn4NSZb7rSWXtypLDNpDrIdygajVwY0ov+url9LGjK27unpz/SZeqbpi9FoOZOeA
D/OqPUnGvuH0yOPFc43RtQywH+z+PXe4env9E25fn3wUv7N567okqSSlQAQyTbXoElDdRInTRjKR
xsg3XhA1tpgkDbft4fJyN3tNy+LO7U+Uja2Tl6nIXiK+fIsY4bHQesT12pqQFI5ISdCu2xpasg41
8ShRI56ona92drefdV68fP7sxe6hnBlCOCzRMbZKhDi+ePc9H0sfIMBn0mjYpn/ENjQ+lvmLi7In
XNn5bKqtYj3mLvhUkA3YbKCuDM+/bI6R7FlbsdJIXaouijbkCU56eg09MSQKezJy6b7sF4KiJvyZ
Vt4b4s6etUNSqDvR2tJhTlOHFgYtPt4eIEqaFk0627iKrLrhCY6HJ1aAjddAfJkqcwWEB2+kN9hG
tDXNGVsWrDm+/85WLkhFulpbVx5WUl1VHkbDE6P4EpkOp8FhaYhikao48vxwQNHJ5ayYK/PW9pC9
ukScU/+UBqtqPwTN5ps3Ss0k6UUqJUkLVx39FdL9ZPXTNaFctVYwI1J1mAmYohWp5EayHz5lwv3X
bw0dhxQz3vtRMOyIocXvW8rcYsMqym0rtVeRG4QAAoqN9Mpb9baJNFu2lU/lOKfqh92Eq0vafb4B
ckKjchWuJdHFz/wwOmQlbcTf+Fi2aI7UulouRJe8+MJuqFbMExQq2aFQ0cS8H5hu9qHyZbMizMrF
9wkyhlUEAe98t1RkWO4lxPbDNKxf/VIjHMQRswC9wGFkze5Je3+J7/rJf3I/cosv+PFOstHwzx7/
dXvlztqdcvzX6urazVt/if/6c/zd/agXd7PpmMwUmvx7jbv4sEgOHG/aWWLjQeD36INYiG9x7sAg
01e06scI5N+0EXLPN2XrEPVN+yzsZSebvQBupGX+0bRwViH0h8tp1x8Gm6toJAvJ0r2nI9B+V44z
u9uS1427iEhFIOimHVIPxB2ToL9pt5TGEB2jqTSboqxltfmguiRQX14+Om5bN/p36L9bG/Bv+1Ew
xBP+wxOkx6IHqz367wgPyJIJevTk9hH9d3tDtxMnkEnWjWA9WOt1UdDvdmms9Gitf7vfC/AINy2j
TNBf7/fwAJIM3a32VwKuFCQo0F1Z/3TtCG0jbvhzbFL7MGWxiZtSpWGcEJpOSIK3SXAkA1eNxxxb
PrrVO/Sfb45ulfpbWzdGF3xC/902R/epT//d2iha0uNbX6H/bpfGd/vo064gS41v7eb6yk3fGN/q
Gv13qxhfv3/76FYgrV+oUS5a59ZR/Ho5Dd+EEcEtPVLHrzf4PafzOie1ODkm08Ja2eCoaCSeiAhg
suAcjNfdsBg9+glnN9toGKnLAPLqrfHr1qp365aVThEEsDwJm9YyjmAEy/IEl1oEx3FgvXqM5LB+
lC7T2MK+0VQvTEntmLat/jAgGPHvMtlWklWsDTAmo2iDrPzw+AR9rqycnshQsHLI4DqvNnHsj6nc
2pi++sPwOFrm8yPUVIB95Q0Sm70e42Z1Zfya7FwqaMZd5xjLsnhEhahMGg/DnkYOv3br8MaE4aox
nCUAA/+WoD1ZJYCBPswQTerqHcBpTId8XU5kuP4ki6V+Ggz5kMrRhOCKVCNtWu4nhNCsdr7mg1h3
VE7T5vwBC2ISvxdOCJ2fAPAcl7eByhU86k6SFJCM41DwzWTHULdPkFCSKZSbKsEsC8GV8jcgOCdp
BVfr3L5ZiRca1WHmx9Txi1IDHq0UaqRUhx6pXqC9oQuaL6q7YQG6/jA+W55qzBe0AjLhSh7mlJfQ
62XV7Se3V0qzaEybhyj+c6OdNSDqJopX8CkUq9tg2ly51hReOXH5sIQm/Wh6RkQTFAB64DiYlpnO
8ALoPaE1tJyO/S5NAzHQ5YKueYBjk6V4N4MRQM/fgn3Vto4XrolkGsGtGtTcrCzRggMRRViTcHkU
RzFDRwzngU+iD5z+Ae6bwV3zEWEF+755KQWbJEk+n8X5j1kJGslt6yTskc5e6sM78ucxqttX8yka
Pvcxmzd5Hkavy8PMxbU2d3FVB0I4jHK0zXIqs2jOrfLBrKnBzPZt1CUSKwupEs82KPq17nguKiqt
1tBiFEeB0YOmXNxjUA/DJzmvU1RI1vQMHdaRXTGBcxaUmrcsHsuk9cjaC2ZmTYNHGO7NZ25eMBpn
0+p7PaeQEMtMdgXBqQmV3te0mFXtHFVbUjKGi3RPwnE6h8Blsqsi8WsyDML+dFnpsnOAKJiu9FAS
fiWpgEJ9UttM8ZKj8QPld4VZ3y7aT0bXYvxz0VBa54yTIOpJ40CnnwS+KY/gYcQQhUJHhBatBt28
Kf2+zp+s3VwpCWRRbtZm2MaPUhugETZ+krYg68UcaLsfd1nCEyXj8JywBrOtXCNQJZbjfp/Mo7a1
vKobu5EipUydbMkrqxHeYEtEg11Z84KsT/JWcYzSJGcpzq+wR3Q/izwmw0v1mEu0GzTyAtQ220kd
8f10lbTcqxePg8jsmvnjDGxeEp/9NHqfWfa1gs7oNjsx6R8Ur3peWyuT950KD76MoBtXSU02eH6U
1M9Bf4yLPy7DFYQGsAVJcj2dlvmepEQ/v6akVsxTE0rBPqUZJfzMtla9WxX2hlxxYnvplHJqmCrj
fqmIf0Soos6BHUWcrIIPgz64FONIKQifGugoQ1heAY0rJkuT9I+ZryoPIzv5xO9BaVthLQvLzUqO
j3xnpYn/vNU1t5bNzloKJRT1wlNT57ldVRjWr6Uu1JtSZideisMW5pPCxJqny1dVNG8sq65OEjCl
9P1ROKRxXgPgevXP46wMP55d1rTYw+Uo1QZvrAWfBreOCpavf3MjaUZCZ4SQwr2en/nURbbJgB00
L3nppwdzBAEOR5MgmPN2FPf8YWmp9MPXQQ8B8SzCKqadSXM3b7nVNVHLN01inqtOVQzYN8vsisYy
NQGdEQjCyI2ReLRYaqnqxy5H4WKm3T5j3hjM9FPNTIuV+Ck7gq7pPqq3ztTYTtYqTPFWxSfzU2Sy
iUOkuqnam8xy6q2LOoFTFR2znpwZslr9dK15607z5jqxs+o6K8wFDSPnLKqB0cShcLxcTF9lhs7n
wIYlzzZUa5Wo/zqMpoStlVkHRc2YKjx5xVBJS+VwqWqF0hmNN283V2990vx0ldD4SR3SvB7rc5fi
/3ZtRdzvV+XAZYVRFffVXQuXWFoznKAwMy4h48tNpToQvHGCq2SmP1r55kaz2E+zOjap15VoDaJO
3IJmkSV+lEJVactXUlGCv3eW6V2tAjyrAZawzJpfeendvO7Sq/LogreuYnR3W2qz5G5L7fHA9652
fIIEmyh3T1bvmfkBqOQqP1d2btjbtJW9YVvYRdq05Q39wqbNpl05KIG4AftecfrhbkvKc6PiQeZG
eQ8/b4TDBux7BDCXqEKgBN0cCHZiHTlrBMWpSF2JubPvGRGvJYiMTpBpp9zBPc57IkdI5tX6ZoJs
wbVw5YdscQ6CQPjH/1pqBNwALYibGIOnJ3quMDuNvEhuENl5TQ4D2LTJPuJn9DSMxpPMKJ6d2Ban
ajuJh9TezExF5umTpiXnTmqPnUh4RQtZ91tHQSSnO0a63wqlPCc5XsXj1rvfm0OfrfRgGKdBtRYf
QSyhTDBk4E7bPfY93KCghiZR1zgVIBuORnz9bAYCiStGcBTCpYdhMgyLuHQEaiF+o4hfGKkDCHch
X+59frfFnwj+8fL544/GXXbtA8juCabfnDVYoja/G8bHeubvtlADNcWLxANliwgF8UVjXI9eKd05
6ZiYLVNkHHWHYXewadOkTlANlzFtY2BRdn/6uOfwBYsLrsfFHDen4Yd5QgRe1P++Mo1Cc9IXJ34S
WPnbaDLMwrHs1VLR3LuEElzPtoh6CRurVTp99EIl02C6U6fwTvzBQEJ1aC5/+O2/WM429EsdNt60
dk7CfrYkDzl8W+J/XaBHdz5LffDeaMJLJ0cjWs33vpAmy6SHCcDs6skpVieLpfIEk6oqS5UUOy6y
C3QCkpO1EgGPfkUKmTGBZiOcr1BKPcTX+lJKGtqXTT+38cDHqQL73vs/jLMyF5xXTfWgxKxq5vnA
vld7jKFmpWrClh96zCxx89E07qbdJBwTzyd9gSTxx8hFH/Zca/OeNY9a6fWGKk4LiCp87PBKchF8
MObbf+mJEBmuNYB02eFMyvRYJI/LF3AS491WjxUbzht++erLL7fuP8X1EKQcSLYCy5YvdpOelH6d
jPHzZEzfcV0u/cCHbV1sNIYBToFzWivJZCyPjiYp0h/2kX5MnvhZ5ndP1BWi8qhI6YikmHnmR84r
oIo1MtaAjB7+Zuf5lx7fMeFw+oWdLE7oFZD4mLi5Y3M8RUfXsF3r7VvL3juwoWdZXSSYt5zAtc4v
FCpS/xRJ6x2ek3NLOiw1nc5puinAIFNvdEw6oaPfuDN9AVWqvyDFBeNOyv2lecbR1t5f371nLxy0
jpuW0+WXzrll/zWStv01Ca0NZCO9y7+GGf+4xz+O+ceCvYAf30xiebfA726sf7pBs7TXPSCIGo3+
JOLlRGQEdy9AQBCGyltGcDnq6vYCqENn79eHB0vuIcCyRS58vKoEg10tvb+4v0gVFqkCvkqdI65w
dA/Ed9FotFpWfjiQFt4Ap6Ctd78PTjmSr23eBfL+u6Yc0+E4aGKCHN/NIaNEAP5x4vf52qZ8XAmS
IyXOqCcDE3zrKxNGKgE+DerwsMU6K4iQA4aQQxYPuKxHzHCbaNVBasMMt5szZeg0tU5o/cJawz1I
uM5UR7FIX9FQXX/gsar6vC+JkDdKhdQdxg4KbyKfv/UZdW+1pWJKMirA9XPR0HU9Iq2RU6k/4usz
+7G6eqP168qFLvs7S+7HrUolhESh0xF1NtpbPbDa3Ab1ED+Nz4LkgU8LqlKHHVe47xtV1g6Kef71
vvfZfquF24pdakhwV9RjN+imZY4PQyuPkN4ixX8FNel2j68HbZkXGbVGXoZ8rWL1liokkwg+os2c
oe1hoAfWX/+19ZFq7DPrUAuA3PVkUz1bfkqs2Mfn5QYuSKP9pz+WjqjnEuCwZsjsyxJIPtJsLZ/V
7CS3jwxgtIRDTdsAzXyAugAOaxPf3QsoKvkJvwKkvIO25fBUEwL48yNc+oGgVrv8aOYBX9VYjyzl
qFNdl49pVbAyQ3Vy9zJTEtrmrW0teaHE3zMHRxYSveempKh6y1CCjRNzsItiui9ewkubVMdUUuDT
rOgtfoL+5LLmj8/1nNFXIaOLQ2up4j+pwUY3Hk9JfZfTW/nwlTIwToJ7iksy5Phq8MfoY1k0GAOX
utviGlxZjedCkoVqxiJLRhjXfnS+1rxouSUO5RvsSbOoj/BcMQ9XMfjCSFdzo24G4aLqGhmTWUlL
XMoLToNk6uDCC+qqxTdv7S0vHrzd7y3te+5+2pIFOmRh+9FQ9+waYBXTZN+dDO/hyklpm/RpXLuk
Gs/rliaCWN1Yl7DvDkOurqTY0ORLM4AJupF8/m4L9VxJFQ7Gxc8ASjFihXsMvPXrG+erzdsX+eAY
1fNGNL5Hcs4AipFawHVjqQLKEWa+pud5rRfoAiakEz2Uu0fJPT2ccpvq24VrxDDyd301KPXAQjmX
oLyP9YgeO+o6bQDEFCU7XJhe/uYNg+iY1qxuShii0qhOINM3pbFCoK2uuTKPfZ7HQ3Od9PMVcaiH
ZdkmqKW1zQ2zyVZ7vr5tfXzOMNDKNoG17hEMYEPWUuXFMr24EA52kS9GEy9+r/csPXaSeBjIXbRN
y0CQUuzA6XKlvksGWRYovd4hc+dUxhMMPR7Fl3JXko0ALswumt5QyMZ3lp029pT4IgUPnT7IrxfB
rw0hGXoXRlGQPNp99lQj3ZzBJa0W5a46MiZUNuUHJ+Gw56hwN7JU4uHQMbEeVMhDFyENmYwKNv1d
Tx7uxmMxNUpPH/FmAtx1RiM0NduIeXEEewDHHEFpqjk4htg4L7BnQXLiH+GcqD5l7/FSogVwf27W
Tk4l+d/+i9jc9Kks7jxjJ/1v5GHlFO4H1TfHxCjTs7AiWRJ8w4b8AlLdPHzOJ2GO1fEtyU1mHL9S
+SPJWjnGMTh4ouDIY6+KfQ/AoQl+WzZbZ7vEEBZ6cvBuKPnBLNlZs5CZA2CAmyaBZHiU67WnfDiL
Oh2oLhkRO3m1qzoVfKFbnQFETh+loeQ4eLm9s8vdOw9evnro6nEJlnUVvLqqo/sTC4aB1eNLWZ3c
UdJUU+aWXVf6ALR8IPGK3OQCl2SCA+FDXx3esu+to9Hq84qTgJf9x+eF9nZ4d2yxi3nTNoKmECeh
XMByQlPM1rYFQ0d0GZUhGscKwNaE11+fsO6r+wTlqo4x5+2Sw85vgmyIcKXicvmmyuuQBYMoHsZf
45wfXO9NXGevXYZ4RnVwmM7iBcKpS++9ULlOVbvXmB4Gi480YsMICVzonU6Fkq+AgaWvuVenrJyd
v31KgvFr2TRsWn+/s9NUCQf5VhxM3DHOa1mnR54LpyVN2SOcHWsZjWac5iXFiYrrAcrnIPlWUdJt
JFkTXOi41AWniwGynCsPRrRsb+GA8jBQJ7oYLREuY7z3/g/GcyMJSx35XCZCkqCX+GdzeJ6ITxa0
2olQlbAG20TZvFiuC45YrCpJNfJEVo08tVGFryIRxA7302nUtXLokIiM9ylSBSH7QRqGpUVQ+mc+
LXpHPvoBrE+75Y/DFnudUtJuvK/TONJ2pNYzU75dwZNCWuR+lj8hnO0lXi/o+5NhdiBVtVOrhCS0
JBrESGkQ8RjAq3U3wmJTTw4LPc+EBb4eeKAu9RyJB60CxykuktIwhFF3OOkFqcPtuTQWaRjGV+l9
PiyXx6t+UDkU21s5UL2wzPc4R79rpUG2w946/YgUDuSu38gvYhI6yRGa91YG1jWbOpSjq0iuMHz3
vWwlDUupfszzie1SFjkyjzTkF4cGMCUPl9GXLWd/a87kerauTgpBSSXIK2d8Vxs3qByYVc2HDUF7
o3hvqlM4jvAZX3dgi5VuzZI6nOKiDOXaLbsrodvicY3dVL8w6xcxnErdsqKmWtAu0LyB88qlcXkB
U01+KPeFk8YqN87sR/uH/F+ER2g/f5RTPT2IxCTgb/RFw2FVHLHmvAnRX5jMZTxJT5xzVk7bShvN
r3BRtoRiOJWX/Ip91PnSwWxIxK0wCOUjBkFssI8amxVuZbrtH377L4ZpwTq27pGmnXW4zG5q14PW
rp9iGVI5eL5V5JGdu/zkhl+GqGkR2NonLbOk7x+qKtYLpA7M2B9qH5iFU8SClX0i43sLG3U8lA3u
WfbJKnMzN/5GAak7PcL3i+c7u/RctkzTNi0KW2FmeXc65ptu/CJTcQu817Yu9O0k2A5vV13U58LS
2hXO1synvF1MPlOhTL456co1XX3s0v+l64sSz03kYBautks9wASG+5IfOi7pAUFX7vkiZvQ6e8j3
NiZagshWQj9fW3KxoLOxUXW8nltqGBy4dpFjWTrnu0YK7yZmGeVI1aAXA/0YHZG5TQDp6yNVm+dK
yW4zrebDqzpSqH7Jj6IgF7OdL0vR9XgQRWVcLa5uQK24cfA0Z0dAdRhNgqoj5+vKrghcA2Unztda
tmQnCDkGsuVORP2iWlzbtnp1qCcb841NFOR4FAWjVVwlo5bbEprJrmqiMFfVPdwbJbu0cGvIv3MY
lckZ8kAdaVAZ7m0Zmp5LyG9nVqpV+ijmsDIIw1SQ8Jci+ks0WfBv6CiBp1qDrjIWl98FQUQyeKh5
RWnvbD5jVPu49oZisxzub8BX8MEkGMU0vCorZBHMvoBeb5uU7AyFAxoU2fDYKCfcieQEKpSLUSju
G0haT121A7WbhIj3jWag3xQqKyTtN27Bvn3e7ZupSo9zKeuD9RaSV+pJgKpRs4uQipRWmsSu2kYf
aveBn3vfTIJkusNhN7hue5wEhEieuV1TMAMsuFuU7500gfIjH/uI5zlLUhsjM+PA80Kjm9uEpRsg
UUMKvb4FXCWMURadsfdM+hNMwM90+lSkfBRdvYU8h0hp6Nol7vYR+9NLjt8L805BdcPcFt/mhrJN
RlszH1KuCZQGwq5vPQphsJF/Gh77hFwEV4yPYj/pyWVPwK+5Y5Mjq0LGypEeIYfjD//pdzZrJLvh
KIgnmSObss4VdbHdvXprZUWt31xFzuHGbo85fzFvotdSCM592YZa/hH9duUQzSXePaYrPkdTdu6h
sQ3VkelxQ6OaRc6phMeV4erdKK1nKJFYaBnXstWAjKYhaH4mbWOuvoHNmwlxvPbsesErobxcd4D2
ULYirRpUJJgmhELQSlVW0oa2iuKBW4tTskZ6tt5i0TxeTI1LcK3StYj90mZPLVXSXHzjkp5UygBI
mAYxcQ4bcut4Ld96WMdsDTWhDx0hx5/hehYqJcWD1GrrnrXGKUjK9thhbjpI7iGdZM+hwtaT+0XO
J9fLzbsZQZ6bJkrQor22Je2KR7ytFVtGpeMq2YrqOeCGKTDPJjLske1B1a8P9NcZSQKHtn7IGmAn
RynmQVsehBqRlyyvPYl2B0gIus6FaeXlM2KRHklOR701fNtNHFlhU2v8middiszOswTsNBUgBNu8
goNgiqAIKmrQAnAVeHzVKTgaB4LxDu5HgZciNuxJMMXYAg+8ndp7KBa7AwUKYtiwxcT8JghAloi8
qyNLFS5WAHHtpqVhBJy6l6gWOt6mHDykFbHcWybt5cbKJcvnAwJ42MPTrJhANTE7IKBWy1r+iX/i
jixvgLwQK9MZyzI2brfFyvjYyeOSXUORy+Lj4yEpchyV9dFHY3embJmLjeELYSsVC2fMiwRukcJw
zdfhWLMT1RxH2Lr5gh3zlbcbZgmOTHUranDuAze838odzLliPz4fC/e6sFQWMb3jTlVIYyc5mfsH
+aYH3Zy8M9a32q5zzQaId0U0g6TX07hRW+INRDNfqGrmC/dMdtiUjRuVzJfTp/fga+ZQA7vS16GX
J+uejZXllMISsl3OWKs2+E1hrOa9JR4Fmr+TIHKchEk5UWKw/NSpRMklhVe3sotcE053+fTZP0OY
sa15Pq25V7i/dEXtJ6rlXON6xtmofDn42i9WBrNC1xJOYu+aXhc7D8u5hhKkcJMrQj9VCZqn/DCk
otuU9ZqSy/f80jVl0HCNdSkLRDdVxMZo5V8mw+A4ib7C1M1dVJdyywJVPBj2vs7GUuoR5d6znI8g
sN+tsUYx7SomsMTCrhYZc5vO+aM0XeFl2kDWEiqP57+6T5NEaxhkHu+St6veXke414t297p9loYj
Jw0+CIclNg8XrdmvzDTEYGXNIguaLvQj9os0TVVU/QoJGRtf9cRbhJnxFtNluzp5j0VPqOXORQXe
lpHB5ZVaXyb+i59HTdAmf36zAPsaOPf5sQqSNjVajjR3RumxGYSiosMlCh15SCqsk4rjoei36oAV
Jl7cKMw9h4GfaAOc2/FO0JB840ugq/Z5TXs4sgW7fF3s8lmuP44J+EkyFNZZikQuEQwXOf/5rNTa
v1ruzanciN2dX7gl5l0zljp3itp1Pcoic36KZcEIKGsBqh1IJavUjLKlDAtXocofBgm1IuGgkS/X
krZlyycxnLuqpijLvby6kNAhdvjQ34W6XdGfRoi9Lt1agfvBD7mtgiIrUPJgEenO0ludCqnKblrC
+iJ1iHA+hKZyOOe3QCBfNYw9+r95AQf9ZP9w7mdDL3zEpCwyEz4ITCCqLYwztVtsnlHigynqVgMR
oWeu3rcv7x2jEz6hUu0EJ1hMh78ZpGhyQuxvDKHAJln6qzAjHri0tCTnEsqPiQfYrg4bHu6tHIhA
WEJYrk0svfx4mR/zOcN2paHPP5d2cO7VNqKV62LpPj7vXmgtQuI3bcuIYIDeMoMOPhLkVnfatECX
Ms8Hhsgtbfay7/YZ2tCBZLMNVpSEKhckJoxq6tDPZfKu6EykpO7qEglZlsvKcxH2BOuqfmkQIiJz
3+CPEvpp1yfmBYNeDbWui0aO2Ctd9iXHwUd5m1XHev0KhootNTaux7jEbz6PbZUGchkb+4p93crX
NsvECLaZ3eH/9DsVCw9rDb5WKlOhyx6Log3DJkk8nLntdOOJ2qie4YP4ZrKpgjfh3kPcCp1fY9ML
7QvFGa+27F7zvLyuWHavay2710a8TsmVpYcRqeWjDxC7M2I4AuwSLbwsEh6ws2xWa6ioe32SugZB
oFnbQG3uMTU8tpdNyc/mevncvDsrDdUZLJ3QRY7MqYOmrjrNBrVRDOamNZKDdSsm+lX5v8XGgWPK
9qOgHycBn87JHWJF+LNyHfJOA1XfAb82tq1wqkca0Od6Pse5Hq+1v4+TPepAj1ovxike0QpN/joZ
90iKPxMoSwB+I3tOOZEVvpbKmHSzakOPeRSeuKyJcdE5Kt+Gib+yEapgAD6/mT12lFcrAagPB2g3
b6laEfn0zVAdGPD+n/auOqyqZuvvc+CIhIA00kh3g3RJdyOKdEh3wwFFEQFpQbpFQSlp4SDdJSiN
IN0NgvAd4DXve9/73H/uPx+/5zlnn9lzZvbEmrXWzKw9y8kOzkjoTk2Ez63hvgtoVjiFn+3f/pHF
L2ITngm8JZjZ4bU3+q+TnaYy/GlObvR9PfuvUv2wgT9fDvlJVuQ/2vNX5eK8Mf5a4f7+Btq52D6z
crQ8lduWPpQ/hbjlWR+xnY53p3OVgJLyh1w3+zeqzb/ryr8e/4M6KP/kHb/Rmz2cS3ynNsvf3ryz
c/oxGH6ne6b/MFbgKX8ZGmeN/XN4nM7DZL+/XidK+TeWRn+b51kuZwv1oqeC5byOepZ3Tu+Qn7+6
8Weq34txqsedF+WX1N8biZGc42c5TvcwvtdX7VTjpjOGy8R/bPK/Gz0/8vuxcvHTfAreAf9po+E3
PvAP+w3f2fyf//9e1H9NYWN3ajzxh0bzd9sDv6lQ33f94DTyK8kw/s0fztWd/3qDhOJ3woWLmn/T
3EI/Zqh/GPn9opKJwWWUm+Tpc04z+jNC0/7HjvLfVPx8TfF8kNOdXRn/Xd7nrOP3gjOTs9PTk1P/
fvc8Uz0WFpbvlTI+3Ut2NLW989MG2OQ7szD5m2Uxp7Ndj3NOcVoo+j83zP91g+n3mmsYGv1TreH3
nJzt7GVtzk6CdzZVcbSzNzQ3PBdDAr91+tnj/+Hp5+rwfy1ufFB8fhionmo3Z+eX/NfaMny4m1k6
2tCdn3FyfsLJXzYY5PAZtgg5nca5o23D+pyfDs/+9Fh+nvhPb+Us9JS/WZaer7/+ix51fqrK3y2z
/phmnJnS/Wmg+Nv7CvwcbK4W54dJ/XIc7V8nl/26knx+vCGl8O/1PTXYhdcCrqJZnRnEn93/6QL0
LyvHM03t5/L+r3bkpyP4l2XC7wP6x6RQkPX74QiCrH+d3cN67sbhv/X/8cOHAvA/9//BxsXGzvGn
/w82Xo4L/x//CzxWUZK+gnLtlGCuyMpIqsGv0NPP5Uvw73phw3YAQOqVlRTTcB9eSbJ0itIkeNit
kFMb+HSVcbUBkhvElLQYgsp/nURVLFCNXDwXIlcXGhYAe2FhyqURIUadGkRH6SzrH8uiW5lJrTiP
LpvQE9k89wE/h82/ZCbRTaBbyCnpRkqc44S2WqQruMpSFYpMieBArtQQ6B7OhiUdeRkTmzLXBX+w
0tlyjL/kdeAyzRRGq1TbW9bYh/2Pygc9SlXBJpQHMuFNbImppTdnMxHLCZ8iRz55gEmucFNmxEzc
qygBH6mpHachFDC8NzqsNT3sUj09R67K8JFD8m1nH6p9u5Ef/yYmOZOsfqVPf+hdUepbyQGtKKJP
vSHJyJ+Y7Q7UI+4DhoyOajadto3TDNnkqoiX9a4OlL4zWtMAl+cyjUwp0YqyxJh4Ob7BnCwt83nW
Kil+GbOUJtNGqPJQB7SZS2zaokwtGh6s+nDyBDwahhQZCqTheDvhTJKQ5RCDxOn3ZzPAJuQODJI3
9mcJl8PcqtERL1M72IMSNR4U8Q2RyFeznIYLBZ65C13GlJv6DH6Qe9kU2Qk0BY9vqABkGcR1I5df
ZymKvkBFFgWrIMuh2vOSPqgsqNpaF4d9MFVkqyon1Ke3uc9b+rZ+imSlYL3Y1X1hWiuugsdgpLas
CCxYlQvh+Ubgj8CN0HNNVrSS6mFUzwd2RC/l7XqvCZf3HZReMnWrrVaImnFvWQC9sTuTqI1ikoL+
BNFHmA8fJem3u6Y/AFi9P6CIaO/cz0OjYREbIhMK1/xSlgq0rxupm+F8NejeEO5hrL8u+8m3oF2N
pNBro+D6kqvb+4O6q2yU/l18TMNXSySVS3EM7t4UiaM4GoIi9kTcaPR9YUOCyBlY28b2FlDfIoKh
C54Ycjo708JCbnwOfX+9i0Z91wwVlOwlAiT54Nd15G7f/Hw8E0oFtch+sxF2nNGOcuO2VzIiZmfv
V1SDrGX+PmMW0Gp9/UvvYz18HfZXri5x2RKuE47VOuGBKW8DNPudfAmSmbafp0u3o9i/pL6k1fWU
1rOTAvatfanunvU+BaJrS4CyHtpaXyQYsQqrFHPSfgWKjKjjj49a6LqnW6A+a2fLU6K8C5BqTZk4
dWiBo8mW2EuU5ZHXp5pBBXpfjeupYO5Dvmxg146iJLFpRHf7GcIClBw941KcSa8jHgONnNirkxsB
lwqsjpIkqGBv40pfkiYfwpDsbO1AAuaehvfZwYIPHsW7O7sI5R2Ukvi+XAyMlSHWaLXSS7iykCD0
peEJsnvWBwwvRk8K3w2sF3GU2o8o3hGxwJanaD5pD6G+NH8lkJcMLLULTAaI1VZYlUaTLHBIQR8l
uRggvs4YK/kat3xcNRJOgnZ10kCRjNlXcx/hPQFovPFJ2PJez34uByaRv93JYsByqGLlah1pnQRr
Db93WKxSlHwrlbcDXfoITSVyQVFe6GCS6OKw0bpjbjcpWEFPE2llzOGWS8Bj9FDR8S68itNbqEUH
m3uX82+0Um3ogZ+JDvL0QVoY+BHuO3jm+13/vBbTwbpzSx3KfChRkgpNtA1tuwrzf6TwvAu9zzNg
88DO8PMhW/O9ahmjYzPWfBo2fOlItjeZYvNSapB9i7tI+TR8VceCtFpQae2US7rLb1bTGhFz5t7f
TCOSxU1lIchqpDK5qfuEGzFom9aCGZleZJBaBQqulqGUenNC/U6RGLf0qhcahi4aNUvvLSx4jfFK
IzRAXzPqS2IzTXAHnt+FDrZgMlPTb8l1BcG7ijtHFO+EC71HLZLDXCIpPDQTZb0zgo2ZmuKI9kE6
TyQDrK3I7Ja8OL8X9hSiOxjDEic5XRuM5ZhXePeTVMhTqigE7m3XgnlrEQKs0qfOoFjfhZxGRPO6
WCkHsAKrIHJR7mZKzgBiVulKQI+N81WDBSVPPMyYSCGbAIg7Bit/QVn6k8GqOi7nhgdr75MbJFiP
kraXDHkjcU1BnxPmGWDvbUIxs1IwlRgmSK7ID0lqg/gY248yTqrwTI9uDPfQ2mCMQSaZToZFvh64
R2/nbl+BhVB66BUQ3uQ2QHzje0vka+RDxxVi/rHrPkj1iOUdvNL8lgsaa7vfhtPkTx6iwnQLskjR
P/TQPlw/0h8RGH6kP1bMJNjx/kjtmBBMsR5oJBfqa0sO8gqTntyxuVLp1lU0ONX4oLq8An0whne6
LAjzyLOIKIx3R+KtH2xTg8JvYK9uPNhpvZVVTKcko7cnWZERSIsClPN3gDQWKugmOK8eNY3JmgbO
0cIBKiAmtQRQfvNGiVKUTjYSFTOHMpq6C3JZ/Wob1izY/cVl040C3aVXd075pFFx8Kuk0x9fwHzw
CIcC8+BXHOF84Adq652c5UCi4xnDDREqTguOOufITWbTaVcloSoBkzNjzSjhyo10Er4MII4IzBhj
L/HhwRNktpxMR6aKU+butjyrjQpzUJctbfTZGc9FjAuQhEuCU6mgBq1wzyRHAr3X+pI5/LxzTMeD
GS5crMXG37rWJAOJYIbuTZzbdtPO4B5Of0WygxNUNjvjRvcWsfTLmLHkL21iXUc2UGDxAeW5t/un
B0uNprEN1BslW2/CRUo2ZaYNZ5qQLg9pFDl2q3TAZcyHWB9KWxI7YqNwDZiGZG5g5bA7X3/tkuyT
cfgYc5KDMAjBgZKl4f6Dt6w8shmKcZmDd3SW+rJclnoq8YpGasGVUvd4YKkVpxqA7E0lydfiBgEX
vvD+H/v/O9f/LY3t/vf6Pzsn57/6/2PjZb/Q//83AAGIACbm6ZUcUAQBgBT8Hjn5eVgDDABRIOCs
ec7CCAAwh/A9HTmQiAEAAkh/O4vAPP2czSLItk4M4X/HOZ9FZHV0MkqqEjdtzClHwoG1EBtNg4q6
pCsbScVqLjOuZsaNaqWHqo7HUxRpqDCtwGlsFpcdgl1JVPZgm69sdp7DqeKOso/W3J6QRcILUezn
fQTh97hED010LdBkU40Xb1miyaY5VbZMSA7aWTYy1KzNP6cviGl8JzA+Yscl0CrUf4uFeyzNi6c7
Jf0xg95K9TLXWLo5i/Sb3k6sKPoE3yc0tjVjGW76fUG0S0dWAkgunkTbzLd7ucmp7k6IEJhUSQdn
S5yoxb4uXBG8z6LnYsGP1sTBZdKJvF13vFCvjWA1E9nkfntTZzhPqGafX0Gkd8TAgrvzBLY+HNhH
EPm+RUoOXkryIpdZrPNy7yOqjc3IPAQIkH5lxH/TmOSnn7PGdPL03AYAMNF5YzZ2tSpjOxA0beyJ
9JU3UL9wuHn/mmFDxoaoUXoTpGQS5XJMOuk2VEycK0mGSkyoQ3Y7VdFYgUGtAPVOdhrei0iOfIEm
GuHj52yy/Uo5nC7DEwner7v3sjTNjaKlDaikDA3YTU31Wuz6FovZY1pSpSTfylt1td6gvH+tnfvx
YKkU5FLi5ZLXzAzsk5LpO3PXURCUcIbtKdCSLTKYQ+QGXCTtj/TBK12QxGvPJXyeWXve5xkSZ3uV
Jt1UXEZ41Hp88/O7TZ/6wiqHer2SCiFETiU0X8lFK7yZLuFYrhJpFxJOtkX72pCOp5sOO8OkNG22
fbFPxAi4V7+BOfEVWZ6NZeY/C2BLb70qRm3uROPsZjkyA2wvr6Klr7WCpcbkcYXYpuQWVvt3GX2j
+4T4H23vMR3PNb0jnOe2aNYUKfmU6KDj8nSMPnqxp8tK2AKZyvd9W5RgsNkjV5evKvPzSWwvHWjX
2m8yD/fvgAJvkTW83ISttyvfZH65liyVFuuvoklK4ODDcq93fKm/h6Oq3PoAYbfQXfXR7o6C2JNp
y9G+/eUp1k507m1P1bbJLQ/5qdZtu0RSdCsei9oxVCFmBJCgZ9IDgbi6BEKn28dcD/U7MnrZNR1T
0D/R1mGTVLMjJ8+rTHgFgmhRuPlpqC4lynz4IELBNilJ/nm2ijhCLHTmuWRnmSAD/FfQvWdho7tf
sAkeqxLoKOgO4W0mnABsbdE19e4j1v+Bpk45HtsZTWmDDx4BAMJfNDUw2KqsrorTvLFFtk+2fdc+
ee6quUpEoPydCgdRxN45QOaJaMhjmnshQWLYXEwfEK+0ygcNPKCLFntZ8raDWSIcidL4weGW6PCV
vo/CXycdlDcrKqoOhRJq+ja3OrmQiNTjoiwV2Jg4rnqOEN4r7ByQY9yPa+wqkBwy3+trQz0uMFUw
1Zn6oLKkwJtfPY+hTkiV9rDKEpeso4s8fsEsfSBXxAYtsqj3ubwI7iVZ+pLdyO5WcnrafPktS7TI
vmx8TCxWcotvpqxUNBYSlfioMwalZAuNoFGvj08ekX1V2c/Gn0t2NjrkTtG1uzwct+o/1JcMUZkh
lMqMf461P/k1tH9vZMpHvicbDaOjaO4hBq5LraGJHINf41Z2aqf2c4OHVI/IxicJZjljQiW2fD5W
Q66NSF/tjv6I1mXnzxyvGKS9kOMbxx5WxJJhhzr8/ABhg8/lI0ZxtnwC29eaVBttP3JSVuHduo4K
zWtsmzWpKx9rrpMyCxlns6ioClh88RET2DeK3ixCWLO61INDEDjUPyxgmxmIr7KPlVH89NbkKkGd
eNf6Jyo0LuRhj7FQHRNBu3oqPzF8T6km2gP58WCCKsSVKXmu1gNSNLSTRqMur2cPCYYRV2p6gyzG
fRce4W71ChHkK/aQ1szLtjgaT63h5D0/nBF7JyzmZed7P/lDupnOjSSfaU+fahhzzbx9tAts8cYW
jChXuUe4Zr7VY8z2ABxPzRzxFZHahFu0e0hauB1fhnFXehG7RKQK1It42Mx8hzwLRpKr2OO/7Cm5
VU5poesd46byRrGnLtGz4f0MWZGJ/wfKFH3tZdRMHG8JiaWUm8eXnCWXsJznXUlC3BeWkw9qi8Kn
10jrOvtmdTwRSbry76s+DvM89rBp2moj1/dZZe9U54YyUgtfZw4I+zIobhQQNmxFwS72GP2ZQfiH
DvDzBlSL6Og5Rw6ZNtnmzXs4cPJwPlIKDRVT4+GPuCvUeU5AJsLiGpdkX3y2lWN5ga7XpPGQWunK
2y7n/tb3b4qHCGPpDpf15T4bo/Nks9H2xxUE4d1TEVc8eXuMQMN8JQD30SPEfx5ToDOxeDambju+
MAMADOO/ls7GRtyiP3o0bxxc13lCNFFYbtsfKZ5QqYprHxXXQFtQ6POZwVZGru9TYahRSEFDq3gs
JihE/f7NQAjB9S/DTTrI2YmjOixB97nm+TK2yA2TwsMf9Bi6V04stOBygEnG44cOxyYmbqXoOs3M
vJ2YO0iLGI/f+NaI6iKM0KEaGaMp91otM5pOLEudUON9MOCAGdZ129z5knw6ZzxRUu+X+Y57tXqV
x087tbUYIHJQ//tp4F5CfcIkS5RJUjyG+OCUOn/pgwzOmnDwvohTjEZWyGeoaVt6scjHJrBO6hd2
RFFJfWdawbvAk2hxFj577cBeksd3QUdZnkH3PeRqKIFVRpFKTvaJTncmv2v4OHERXFGo5LL0M5Tg
YrVrY1kEuLAnLoXhaZeBjyYNRtpjxxjCqThOhdA4urDVuFhIgQ6yQwQ0DuWmm+IrsMzn94BDzJQc
yHuucdI6XwtRdDQ/eeW4y/Wgv+KyqHgW7UtAxxe2jjXZ7AubeoZQs3bEw3eHPhjoUWpz3vOobK+N
k7hUUup+C7KuvWgYTKoiDo/Soqt8pT68tIAjyv4IlSDt0wq4ZVIFlGFSrgnIEtMYZFLxoqRG30cM
0eAfActMY4IysjpLgFkHdyhtR0IJcPw1C2ayiQsyqD5q3fUumrnbkAZKLrLgh6i0+IOS1fgGwDow
Q1ByiQEDJLxZDJQc7VYLjmunACXz7IXBG4+0SVYTEWqeFTZx8Bii0gQCJWu5moOqiQmKVa4CyWX2
1mvN+KI0SAg6FFu2kMk5A4BxnxYP5o0OKWg7kgF5783capa7CejUDx3YoaRCEUB5amw1AJj4skEM
TAfU8ZkNYOx0QCGPvw/kRS8frjK+fYUDMkjSVAJ9ccSExjj6+G3J2URQAnnqX3BEkZFAOrkN9FD4
5FWHfh5HlPY03E8PFUMHF/SlqgOG8KvapzJ7l1CgABsCqAAAHQDgAACc+CEArBhSICN0FqFzB8hd
RAYYVYH9WDK7y3JtYTSynRiysxFWm4OFrkNe6eq7KauRe92u7WIz79TvFB0qkxStRL2hnlZ5dWSm
/CSvxTJ87U3+DBo9EEdpKp1hcjLHfbDv59kw4az+1Taszbp/UIjprtaetJzRyvGrzXkil0RuCEAi
mH8cc/yt981Mt6YPhz0j04acU3O49/bAjgwF1ZvpHEQblEk79VeQ8d2OwUsee1tKyCXjWHccS9OV
ebx78DxaYdxyxCiweh780tbGSlDvDYn6zy3tT+9WjzVwZwBsehh2aFK+hm7v/CQV2rO+gnTdUmOW
ZEAGlbEvG0Xcs+Xfl9k9WXDQf2m9D6UMUgYdKQn5F9bs3Qv19JmgqM+YZT1u0OCaCDmij1wiFsCB
1g2S3YsZfG244akUOxGOO7Rze0sHBzaRixRnqquVlLg7gTlStFTs+rq2nQ6ot6a/F6VXb1jIPYfw
bdPaVqhYFPSJ2tIm1Ftr+Lqkicl2qQmppTELHSAgWFusGmBT9ukI+camKe+WGMh9ZAnpTZvFPs+I
sGzXwG57XyjILBC8npzUXGNWnxOevUvhYeuFwCkBcm+uiUqy3uXqE2BjqPXNeTwUbwvyXhtg8NdH
9+ltlOomr79eNlPm0dnRw6UCMNXmTB3VfGl0owehwESPPq0pXXr0fvNJGVE8PQqMWEBkBt/XNjvD
TVLrywd2PRzocaLIztU9dZJr0V9cuDsIIKlv5tx4JFetrxd6XldldXJ9A9732oE2yNzSY/YfFCvl
amoV6K2rVgwAy6QaZ30c6uKj5q4NjK+yAuWpKmO66QXfGmrjy175WnBk73OlmBcECQfaiwIcneg6
tJpuNMt5xYmgkG8k3lWIaDAZ88fklAFRKTUdUpSy+VsuEEci3TVGp4ciOlwKp+I5oBWIaywEu9sr
ZpEL7xLbmR9ytaoPiZmppQFTJgvZz1uEFiWfEgu5JVVkAlPmJ5bj8xl6ySP60qCCxMK99abnLV4D
j/UPtgVFIPuk3opCYgozPl1Wfne2TFxhi0PwJKkZbnGK/Vxd8pyvUCfJPiAYmfcbji++ckq0Uy31
EKaHEjjVtD6cTwp9JIEDjO4p2IavcJBTD/jAA2WHfGRbpnKk7XlZwOTrl7EJ1rEUrd/KQ8FQr+Tx
awav3AlT/UDefjaBMJ+uWrqGxAd2E7HUC5qDnfQQzOvmr9eT/fo3q3wU4Tn1crK9lyKMvW/OTwd0
6LeF8Ze2wqK50VSAuHd5GBWH3Q1ooQ/oAYWJorxbBwMCVza/1uG1HrzQDJbbD1BW3ypOcsEBaMqO
Om8NOfNRkb2kru3jIkcokxq6htFYwfzpJVhGDaO8LGXtZZRPznDWLsPE1PTOssCQ7YC1OhDlTpeh
VkpmM20r3O445fjUFBKenTxJ9NQuNwLBnH+/d7xvnwgp77kbCnnbAf6J0I6x8MQHK7dbVY/ogBET
3Dsz6l4yVF3apapArE6EOqM5Y7nps9F46oWYXRyYSPadq0Q2gqOUPveru2gnuq7baegVI2nhweqK
SRRuxHO1T+SlAdXzSEsMX6JrHyHT7nUEwwe2k29lhRzLwBYo6cuxB8NINlgnJ9l9NCNeU22IA2YS
RT/zOO9eoSErcTIrlMzmBY4fdrtydvKbe7YyTWlmKDDUxCeyLQp96zupX7ydB0Yg4Xmk1YvzN8Zj
5c1SRJcUdd0KWqMEpobA7kucwtFR5QnYpkJFR533UETdTkpzki2p2WXXYEHW/KPioPm8WQa7z9SF
nWms8E4hWREZ63KOLG/wIGuVIMTFgbJo1XQ+c4jcz64uFHFMeVwIWb//8dsU7smdVoFDmaPpUZPZ
aOhjgel4sPvOOymaCCom0yvfiqimUSDhdPiLX+PEI3sSK/okQFTv20/qUr4Fkd5wL00CB/GOT8k7
t32VUMQRrc5ryTWbCtJaWCSKbS6L25AXmzDaMSgaa66YeTb/TER/mcfIL4QVuohpt0PtaaYohgDB
lO+2eWPYFlSaa0HKlgr0DWBLrAg2fbTHfhflkam7RMJRCdS8+FJ2IrnGx6oKp+uFVSLD90G7HjZ+
CJBJHv0TbPWpUYoXNiAmWVZ87Bu8ephGcrGmmvcqpJvwYOPYH+MYjBR8T2SDwPbqGzeF16PioiIX
9VFgilliwqsJcVFpEQVMrT2FQOIJPcINsgGFIFkPS7skVy8Ta1CJCwa7asOL6q0crW8okxQ7Bumr
NYY0wQQx3axuVmXw7EWVRXhBV4unRnFlQOWZT1KAIMMFQoI0YLSvbQ0I8vdwj0oB2yP4QchpzBoH
5VBgV+YQRpFEO+Tbwu7BA4345djhcc/8hjQztEFH/V852HvHsb3xyNlZRUZ08wdICfWAJZHJBGiQ
h4erHjVk8qHfuGoj19XpzRYiXxQY8x3ecnxoXNSxXsbwSngvxL40oBuRajbzeFgRXjmBp4Gn9e7S
uv3xDeD7glShcQ0UJDvk9lKx6rQ9iWOYvyngsVNaIi1yM0GvLD6ucyWbaxcLIvSwfnK36ht7DZDc
mm9QFLRLb7fc7wjvL6C5ddOWJsQiqRo7H0c0rzqSzOR90KDHcT6DEOqkNBHLE/z1VdF0K5aBPcsq
3mR6KDfEReFaL8cQGbcqsDE5aiEWpFTh6iOzlLShATraxBhQIO5l6ErJpYfyMfB1ziFiHu+keIKs
NZQFs4OrEB5fGnIt0T28s2ECql63Ze6Xxnr+xIU35BPuxNOB+/jvdnRR1WWwYu+uvWY3UhbUA8Ke
druwPaZaHXI6eskuMLUAtj+qCMa4QrHRTu9Xpnr4+QC83zrb7liR9rSVil3ZZgkqGKkrBZqffZzn
uMGrCqZyXZgniYRzGQ5b3jw6oNlYry2T61N7JtbHfi8nSf2OV+yOrN4YdpVwjv7GsUY1qPwZnArg
NJJfeGhwB8SHnvjZVozjkKsUo622Rt10m0VHFwhTDNyJ2KUxoTl4mS2d3EbP64uRxww0F48cOX5F
SaGRzH62113qYYaUxwJl1yXjkbP6yEyTMMrZhe+VJ4S5/WFZHZiudnupeck2lGPhS1jIQzv5ugUt
5S5BCFtd1NBM0YlCwu21uT0EyS9RTiubo7uMyUluE2o70KqRY0tsXkzduC6iesf5J6UtU14+TfRQ
+v2ZWu22mijtrPT4bsL1e4nPfLt8jhJQl/Kf20z0dS4iZy8vjG62hBMfbD6//bK2LgXryrH2sXeq
9rtRqxhuCMhqLh5sXxecP7OZ4PaK+puKSqnvKF1VcILp3kb4sj/e8Xoz3tCubJT1fqqSfsursNus
s7FguOKGDiooB3yLDtJ/0eVicWFE54obtBOyrr4DwJRwAFEQkAr8VPa68WDX4/HhU4gCpU8/VcMk
YkSDLKUcIOD0Cg9Tn16xcoBgvsswuZs10pysXxjAMP4KJVDeFDnAmL8pVDkjXgTXO6OWcWDEp5kQ
5wDEIHSEguDirZpCMN2kKPAKB86IYk412ZgIsLu1fK4xfCaR93n5iBcyue5EB8U9MvYSqQE4bhDA
UOLdGKGBxGgGgYEndwHdrOkYejCsuK1p7agBLDMDBZTl32UApNoY0x2nunYnSe0WNiosohmuhEfz
OkysaQGofHSwKDyFLIA4kBhvkj7QbWSnFcXgKtIl97b0BRzo9RQJBEEKvyKhPaGN2YPWDnVE6Mas
YuncHgMgfe0REgHzir6Aby3YPtoxCBoht1Y2oU4PpULHYlOLJIJMtkyywScTCqZlObeAMCN0XDbx
DY09T37IOhRryh6UH5hexf8WrJNNmm1YSAmUvHXnFxAaA9tn2rdAY9Wyq7prTIfmzI3ewqMKPWmq
BPvhUU7zULw+88rmYnpADmBzPxijA/TRgYffPvlJg5i6hece4twEGhSDiaqWtEB8eIwULGiY6mnz
rw+cGYFmBDl2fOSgx1PzYQfOzFB2wttMME3Cwk+aE5uJToWRmdEMYIMmuYwqnCihUFNQiOw0JZgz
Em/pW4g0iG+W/uC2ioHcZoYA9tbYtlAu6ZRFhNqLy1A7+pBVmVFXjnEIm5l/ZDMEiXIzXeDq3h0F
DVBI/KtMBlM0EJM6XtK3isejdZL4MHfUGIXGbntYxlEv4d0X7eMLGsD0X/POOv/v884VV8WP4DiL
sMi8PDXHGMosSWSGpLZULLNJTNrP8x0uUuYFVPxRFb2EimFdebtVO7UUbcQ1i1U9VBebWRe4wAUu
cIELXOACF7jABS5wgQtc4AIXuMAFLnCBC1zgAhe4wAUucIELXOD/Jf4PzQBlnQCQAQA=
