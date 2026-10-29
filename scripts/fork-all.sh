#!/usr/bin/env bash
# repos.txt'teki tüm depoları GitHub hesabınıza fork eder.
# Gerekli: GitHub CLI (https://cli.github.com) ve bir kez "gh auth login".
# Kullanım: ./scripts/fork-all.sh
set -u
cd "$(dirname "$0")/.."

if ! command -v gh >/dev/null 2>&1; then
  echo "GitHub CLI (gh) bulunamadı. Kurun: https://cli.github.com" >&2; exit 1
fi
gh auth status >/dev/null 2>&1 || { echo "Önce 'gh auth login' çalıştırın." >&2; exit 1; }

me=$(gh api user --jq .login)
grep -vE '^\s*(#|$)' repos.txt | while read -r upstream name _rest; do
  if gh repo view "$me/$name" >/dev/null 2>&1; then
    echo "✓ zaten var: $me/$name"
  elif gh repo fork "$upstream" --clone=false --default-branch-only --fork-name "$name" >/dev/null 2>&1; then
    echo "+ fork edildi: $upstream -> $me/$name"
  else
    echo "✗ başarısız: $upstream" >&2
  fi
done
