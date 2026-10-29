# Windows (PowerShell) için: repos.txt'teki depoları vendor\<kategori>\<ad> altına indirir.
# Kullanım: powershell -ExecutionPolicy Bypass -File scripts\clone-all.ps1 [kategori|ad]
param([string]$Filter = "")
Set-Location (Join-Path $PSScriptRoot "..")
$owner = if ($env:GITHUB_OWNER) { $env:GITHUB_OWNER } else { "cfatih-sudo" }
$env:GIT_TERMINAL_PROMPT = "0"
Get-Content repos.txt | Where-Object { $_ -notmatch '^\s*(#|$)' } | ForEach-Object {
  $p = $_ -split '\s+'; $upstream = $p[0]; $name = $p[1]; $category = $p[2]
  if ($Filter -and $Filter -ne $category -and $Filter -ne $name) { return }
  $dest = "vendor/$category/$name"
  if (Test-Path "$dest/.git") { Write-Host "↻ güncelleniyor: $dest"; git -C $dest pull --ff-only -q; return }
  New-Item -ItemType Directory -Force "vendor/$category" | Out-Null
  Write-Host "↓ indiriliyor: $dest"
  git clone -q --depth 1 "https://github.com/$owner/$name.git" $dest 2>$null
  if ($LASTEXITCODE -ne 0) { git clone -q --depth 1 "https://github.com/$upstream.git" $dest }
  if ($LASTEXITCODE -ne 0) { Write-Warning "✗ indirilemedi: $upstream" }
}
