# Windows (PowerShell) için: repos.txt'teki tüm depoları hesabınıza fork eder.
# Gerekli: GitHub CLI (winget install GitHub.cli) ve bir kez "gh auth login".
# Kullanım: powershell -ExecutionPolicy Bypass -File scripts\fork-all.ps1
Set-Location (Join-Path $PSScriptRoot "..")
$me = gh api user --jq .login
if (-not $me) { Write-Error "Önce 'gh auth login' çalıştırın."; exit 1 }
Get-Content repos.txt | Where-Object { $_ -notmatch '^\s*(#|$)' } | ForEach-Object {
  $p = $_ -split '\s+'; $upstream = $p[0]; $name = $p[1]
  gh repo view "$me/$name" *> $null
  if ($LASTEXITCODE -eq 0) { Write-Host "✓ zaten var: $me/$name"; return }
  gh repo fork $upstream --clone=false --default-branch-only --fork-name $name *> $null
  if ($LASTEXITCODE -eq 0) { Write-Host "+ fork edildi: $upstream -> $me/$name" } else { Write-Warning "✗ başarısız: $upstream" }
}
