# Bulut - Windows kurulum betigi.
# paket/olustur.py bu dosyayi uygulama dosyalariyla birlikte tek bir .bat dosyasina gomer.
# Asagidaki yer tutucuya uygulama dosyalarinin base64 zip hali konur.

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'   # Invoke-WebRequest'i cok hizlandirir
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
try { $Host.UI.RawUI.WindowTitle = 'Bulut Kurulumu' } catch {}

$PythonSurum = '3.12.7'
$Hedef = Join-Path $env:LOCALAPPDATA 'Bulut'
$Uygulama = Join-Path $Hedef 'uygulama'
$PyKlasor = Join-Path $Hedef 'python'

function Adim($m) { Write-Host ''; Write-Host "==> $m" -ForegroundColor Cyan }
function Tamam($m) { Write-Host "    $m" -ForegroundColor Green }

function OllamaYolu {
    $c = Get-Command ollama -ErrorAction SilentlyContinue
    if ($c) { return $c.Source }
    $p = Join-Path $env:LOCALAPPDATA 'Programs\Ollama\ollama.exe'
    if (Test-Path $p) { return $p }
    return $null
}

function OllamaHazir {
    try { Invoke-WebRequest 'http://127.0.0.1:11434/api/tags' -UseBasicParsing -TimeoutSec 3 | Out-Null; return $true }
    catch { return $false }
}

try {
    Write-Host ''
    Write-Host '  ===========================================' -ForegroundColor Blue
    Write-Host '     Bulut - PHP / Java / Python Kod Asistani' -ForegroundColor Blue
    Write-Host '  ===========================================' -ForegroundColor Blue
    Write-Host "  Kurulum klasoru: $Hedef"

    # ------------------------------------------------------------ 1. dosyalar
    Adim '1/5  Bulut dosyalari kopyalaniyor'
    New-Item -ItemType Directory -Force -Path $Hedef | Out-Null
    if (Test-Path $Uygulama) { Remove-Item -Recurse -Force $Uygulama }
    $zip = Join-Path $env:TEMP 'bulut_paket.zip'
    $b64 = @'
__PAYLOAD__
'@
    [IO.File]::WriteAllBytes($zip, [Convert]::FromBase64String(($b64 -replace '\s', '')))
    Expand-Archive -Force -Path $zip -DestinationPath $Uygulama
    Remove-Item $zip
    Tamam 'Tamam'

    # ------------------------------------------------------------ 2. python
    Adim '2/5  Python hazirlaniyor (sadece Bulut icin, sistemine dokunmaz)'
    $pyw = Join-Path $PyKlasor 'pythonw.exe'
    if (-not (Test-Path $pyw)) {
        $mimari = if ($env:PROCESSOR_ARCHITECTURE -eq 'ARM64') { 'arm64' } else { 'amd64' }
        $url = "https://www.python.org/ftp/python/$PythonSurum/python-$PythonSurum-embed-$mimari.zip"
        Write-Host "    Indiriliyor: $url"
        $pz = Join-Path $env:TEMP 'bulut_python.zip'
        Invoke-WebRequest $url -OutFile $pz -UseBasicParsing
        Expand-Archive -Force -Path $pz -DestinationPath $PyKlasor
        Remove-Item $pz
        # Gomulu Python sadece ._pth dosyasindaki klasorleri gorur: uygulama klasorunu ekle.
        $pth = Get-ChildItem (Join-Path $PyKlasor 'python*._pth') | Select-Object -First 1
        Add-Content -Path $pth.FullName -Value '..\uygulama'
    }
    Tamam 'Tamam'

    # ------------------------------------------------------------ 3. ollama
    Adim '3/5  Ollama (yapay zeka motoru) kontrol ediliyor'
    $ollama = OllamaYolu
    if (-not $ollama) {
        Write-Host '    Ollama indiriliyor (yaklasik 1 GB, internet hizina gore birkac dakika surebilir)...'
        $setup = Join-Path $env:TEMP 'OllamaSetup.exe'
        Invoke-WebRequest 'https://ollama.com/download/OllamaSetup.exe' -OutFile $setup -UseBasicParsing
        Write-Host '    Kuruluyor...'
        Start-Process -FilePath $setup -ArgumentList '/VERYSILENT', '/SUPPRESSMSGBOXES', '/NORESTART' -Wait
        Remove-Item $setup -ErrorAction SilentlyContinue
        $ollama = OllamaYolu
        if (-not $ollama) { throw 'Ollama kurulamadi. https://ollama.com/download adresinden elle kurup bu dosyayi tekrar calistirin.' }
    }
    if (-not (OllamaHazir)) {
        Start-Process -FilePath $ollama -ArgumentList 'serve' -WindowStyle Hidden
        for ($i = 0; $i -lt 40 -and -not (OllamaHazir); $i++) { Start-Sleep -Milliseconds 500 }
        if (-not (OllamaHazir)) { throw 'Ollama baslatilamadi. Bilgisayari yeniden baslatip tekrar deneyin.' }
    }
    Tamam "Tamam ($ollama)"

    # ------------------------------------------------------------ 4. model
    $ramGB = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB)
    if ($ramGB -lt 12) { $model = 'qwen2.5-coder:3b'; $ctx = 8192; $boyut = '1.9 GB' }
    elseif ($ramGB -lt 28) { $model = 'qwen2.5-coder:7b'; $ctx = 16384; $boyut = '4.7 GB' }
    else { $model = 'qwen2.5-coder:14b'; $ctx = 16384; $boyut = '9 GB' }
    Adim "4/5  Yapay zeka modeli: $model  (bilgisayarinda $ramGB GB RAM var)"
    $liste = (& $ollama list) -join "`n"
    if ($liste -match [regex]::Escape($model)) {
        Tamam 'Model zaten yuklu'
    } else {
        Write-Host "    Indiriliyor (~$boyut). Bu adim internet hizina gore 5-30 dakika surebilir..."
        & $ollama pull $model
        if ($LASTEXITCODE -ne 0) { throw "Model indirilemedi. Internet baglantinizi kontrol edip tekrar deneyin." }
        Tamam 'Tamam'
    }

    # ------------------------------------------------------------ 5. kisayollar
    Adim '5/5  Kisayollar olusturuluyor'
    $arguman = "`"$Uygulama\bulut.py`" --ac --model $model --ctx $ctx"
    $ikon = Join-Path $Uygulama 'static\bulut.ico'
    $ws = New-Object -ComObject WScript.Shell
    $yerler = @([Environment]::GetFolderPath('Desktop'), [Environment]::GetFolderPath('Programs'))
    foreach ($yer in $yerler) {
        $k = $ws.CreateShortcut((Join-Path $yer 'Bulut.lnk'))
        $k.TargetPath = $pyw
        $k.Arguments = $arguman
        $k.WorkingDirectory = $Uygulama
        $k.IconLocation = $ikon
        $k.Description = 'Bulut - PHP / Java / Python kod asistani'
        $k.Save()
    }

    # Kaldirma araci
    $kaldir = @"
@echo off
echo Bulut kaldiriliyor...
powershell -NoProfile -Command "try { Invoke-WebRequest -Method Post -UseBasicParsing -TimeoutSec 2 http://127.0.0.1:8765/api/kapat | Out-Null } catch {}; Remove-Item -ErrorAction SilentlyContinue (Join-Path ([Environment]::GetFolderPath('Desktop')) 'Bulut.lnk'), (Join-Path ([Environment]::GetFolderPath('Programs')) 'Bulut.lnk')"
echo.
echo Bulut kaldirildi. Ollama ve indirilen modeller duruyor;
echo onlari Ayarlar ^> Uygulamalar ^> Ollama ile kaldirabilirsiniz.
pause
cd /d "%TEMP%"
rmdir /s /q "$Hedef"
"@
    [IO.File]::WriteAllText((Join-Path $Hedef 'Kaldir.bat'), ($kaldir -replace "`r?`n", "`r`n"))
    Tamam 'Masaustu ve Baslat menusune "Bulut" eklendi'

    Write-Host ''
    Write-Host '  Kurulum tamamlandi! Bulut aciliyor...' -ForegroundColor Green
    Write-Host '  Sonra acmak icin masaustundeki "Bulut" simgesine cift tikla.'
    Write-Host "  Kaldirmak icin: $Hedef\Kaldir.bat"
    Write-Host ''
    Write-Host '  Not: Yazdigi PHP/Java kodlarini "Calistir" ile denemek istersen' -ForegroundColor DarkGray
    Write-Host '  PHP 8 ve Java JDK 17+ ayrica kurulu olmali (istege bagli).' -ForegroundColor DarkGray
    Start-Process -FilePath $pyw -ArgumentList $arguman -WorkingDirectory $Uygulama
    Start-Sleep -Seconds 6
}
catch {
    Write-Host ''
    Write-Host "  HATA: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host '  Sorun devam ederse bu pencerenin ekran goruntusunu paylasin.'
    Write-Host ''
    Read-Host '  Kapatmak icin Enter'
}
