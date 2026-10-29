#!/usr/bin/env bash
# repos.txt'teki depoları vendor/<kategori>/<ad> altına indirir (sığ klon, hızlı).
# Önce sizin fork'unuzu dener, yoksa asıl depoyu indirir.
# Kullanım:
#   ./scripts/clone-all.sh              # hepsi
#   ./scripts/clone-all.sh stil         # sadece bir kategori (araclar | algoritma | stil)
#   ./scripts/clone-all.sh prettier     # sadece adı eşleşenler
# Zaten inmiş depolar güncellenir (git pull).
set -u
cd "$(dirname "$0")/.."
owner="${GITHUB_OWNER:-cfatih-sudo}"
filter="${1:-}"
export GIT_TERMINAL_PROMPT=0  # fork yoksa şifre sormadan asıl depoya geç

grep -vE '^\s*(#|$)' repos.txt | while read -r upstream name category _rest; do
  if [ -n "$filter" ] && [ "$filter" != "$category" ] && [ "$filter" != "$name" ]; then continue; fi
  dest="vendor/$category/$name"
  if [ -d "$dest/.git" ]; then
    echo "↻ güncelleniyor: $dest"; git -C "$dest" pull --ff-only -q || echo "  (güncellenemedi)"
    continue
  fi
  mkdir -p "vendor/$category"
  echo "↓ indiriliyor: $dest"
  git clone -q --depth 1 "https://github.com/$owner/$name.git" "$dest" </dev/null 2>/dev/null \
    || git clone -q --depth 1 "https://github.com/$upstream.git" "$dest" </dev/null \
    || echo "  ✗ indirilemedi: $upstream" >&2
done
