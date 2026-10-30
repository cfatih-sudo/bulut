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
    $adaylar = @(
        (Join-Path $env:LOCALAPPDATA 'Programs\Ollama\ollama.exe'),
        (Join-Path $env:ProgramFiles 'Ollama\ollama.exe'),
        (Join-Path $env:USERPROFILE 'scoop\shims\ollama.exe'),
        (Join-Path $env:ProgramData 'chocolatey\bin\ollama.exe')
    )
    foreach ($p in $adaylar) { if (Test-Path $p) { return $p } }
    return $null
}

function OllamaAdresi {
    if ($env:OLLAMA_URL) { return $env:OLLAMA_URL.TrimEnd('/') }
    $h = $env:OLLAMA_HOST
    if (-not $h) { return 'http://127.0.0.1:11434' }
    if ($h -notmatch '^https?://') { $h = "http://$h" }
    $h = ($h -replace '://0\.0\.0\.0', '://127.0.0.1').TrimEnd('/')
    if ($h -notmatch ':\d+$') { $h = "${h}:11434" }
    return $h
}
$OllamaUrl = OllamaAdresi

function OllamaHazir {
    try { Invoke-RestMethod "$OllamaUrl/api/tags" -TimeoutSec 3 | Out-Null; return $true }
    catch { return $false }
}

function Modeller {
    try { return @((Invoke-RestMethod "$OllamaUrl/api/tags" -TimeoutSec 10).models | ForEach-Object { $_.name }) }
    catch { return @() }
}

function ModelIndir($ad) {
    if ($ollama) {
        & $ollama pull $ad | Out-Host   # cikti ekrana; donus degerine karismasin
        return ($LASTEXITCODE -eq 0)
    }
    # ollama.exe bulunamadi ama sunucu calisiyor: API uzerinden indir.
    $req = [Net.HttpWebRequest]::Create("$OllamaUrl/api/pull")
    $req.Method = 'POST'; $req.ContentType = 'application/json'
    $req.Timeout = [Threading.Timeout]::Infinite; $req.ReadWriteTimeout = [Threading.Timeout]::Infinite
    $b = [Text.Encoding]::UTF8.GetBytes("{`"model`":`"$ad`"}")
    $st = $req.GetRequestStream(); $st.Write($b, 0, $b.Length); $st.Close()
    $r = New-Object IO.StreamReader($req.GetResponse().GetResponseStream())
    $son = ''
    while ($null -ne ($satir = $r.ReadLine())) {
        if (-not $satir.Trim()) { continue }
        $j = $satir | ConvertFrom-Json
        if ($j.error) { Write-Host ''; Write-Host "    $($j.error)" -ForegroundColor Red; return $false }
        $m = "    $($j.status)"
        if ($j.total -and $j.completed) { $m += ' %' + [math]::Floor(100 * $j.completed / $j.total) }
        if ($m -ne $son) { Write-Host ("`r" + $m.PadRight(70)) -NoNewline; $son = $m }
    }
    Write-Host ''
    return $true
}

function SistemPython {
    # Bilgisayarda zaten Python 3.9+ varsa onu kullan (Windows Store kisayolu haric).
    foreach ($aday in 'py', 'python') {
        $c = Get-Command $aday -ErrorAction SilentlyContinue
        if (-not $c -or $c.Source -like '*WindowsApps*') { continue }
        $ek = if ($aday -eq 'py') { @('-3') } else { @() }
        try {
            $exe = & $c.Source @ek -c "import sys; print(sys.executable if sys.version_info >= (3, 9) else '')" 2>$null
            if ($LASTEXITCODE -eq 0 -and $exe) {
                $w = Join-Path (Split-Path ($exe | Select-Object -Last 1).Trim()) 'pythonw.exe'
                if (Test-Path $w) { return $w }
            }
        } catch {}
    }
    return $null
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
    Adim '2/5  Python kontrol ediliyor'
    $pyw = Join-Path $PyKlasor 'pythonw.exe'
    if (Test-Path $pyw) {
        Tamam "Bulut'un Python'u zaten kurulu"
    } elseif ($sistem = SistemPython) {
        $pyw = $sistem
        Tamam "Bilgisayardaki Python kullanilacak, indirme yok ($pyw)"
    } else {
        $mimari = if ($env:PROCESSOR_ARCHITECTURE -eq 'ARM64') { 'arm64' } else { 'amd64' }
        $url = "https://www.python.org/ftp/python/$PythonSurum/python-$PythonSurum-embed-$mimari.zip"
        Write-Host "    Python bulunamadi, sadece Bulut icin indiriliyor (~10 MB, sistemine dokunmaz)"
        $pz = Join-Path $env:TEMP 'bulut_python.zip'
        Invoke-WebRequest $url -OutFile $pz -UseBasicParsing
        Expand-Archive -Force -Path $pz -DestinationPath $PyKlasor
        Remove-Item $pz
        # Gomulu Python sadece ._pth dosyasindaki klasorleri gorur: uygulama klasorunu ekle.
        $pth = Get-ChildItem (Join-Path $PyKlasor 'python*._pth') | Select-Object -First 1
        Add-Content -Path $pth.FullName -Value '..\uygulama'
        Tamam 'Tamam'
    }

    # ------------------------------------------------------------ 3. ollama
    Adim '3/5  Ollama (yapay zeka motoru) kontrol ediliyor'
    $ollama = OllamaYolu
    if (OllamaHazir) {
        Tamam "Ollama zaten calisiyor ($OllamaUrl), indirme yok"
    } else {
        if (-not $ollama) {
            Write-Host '    Ollama bulunamadi, indiriliyor (yaklasik 1 GB)...'
            $setup = Join-Path $env:TEMP 'OllamaSetup.exe'
            Invoke-WebRequest 'https://ollama.com/download/OllamaSetup.exe' -OutFile $setup -UseBasicParsing
            Write-Host '    Kuruluyor...'
            Start-Process -FilePath $setup -ArgumentList '/VERYSILENT', '/SUPPRESSMSGBOXES', '/NORESTART' -Wait
            Remove-Item $setup -ErrorAction SilentlyContinue
            $ollama = OllamaYolu
            if (-not $ollama) { throw 'Ollama kurulamadi. https://ollama.com/download adresinden elle kurup bu dosyayi tekrar calistirin.' }
        } else {
            Write-Host "    Kurulu Ollama bulundu, baslatiliyor: $ollama"
        }
        Start-Process -FilePath $ollama -ArgumentList 'serve' -WindowStyle Hidden
        for ($i = 0; $i -lt 40 -and -not (OllamaHazir); $i++) { Start-Sleep -Milliseconds 500 }
        if (-not (OllamaHazir)) { throw 'Ollama baslatilamadi. Ollama uygulamasini acip bu dosyayi tekrar calistirin.' }
        Tamam 'Tamam'
    }

    # ------------------------------------------------------------ 4. model
    $ramGB = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB)
    if ($ramGB -lt 12) { $onerilen = 'qwen2.5-coder:3b'; $ctx = 8192; $boyut = '1.9 GB' }
    elseif ($ramGB -lt 28) { $onerilen = 'qwen2.5-coder:7b'; $ctx = 16384; $boyut = '4.7 GB' }
    else { $onerilen = 'qwen2.5-coder:14b'; $ctx = 16384; $boyut = '9 GB' }
    Adim "4/5  Yapay zeka modeli kontrol ediliyor (bilgisayarinda $ramGB GB RAM var)"

    $mevcut = @(Modeller | Where-Object { $_ -notmatch 'embed' })
    $esler = @($onerilen)
    if ($onerilen -eq 'qwen2.5-coder:7b') { $esler += 'qwen2.5-coder:latest', 'qwen2.5-coder' }
    $kodAileleri = 'qwen3-coder', 'qwen2.5-coder', 'devstral', 'codestral', 'deepseek-coder', 'yi-coder',
                   'codegemma', 'codellama', 'starcoder', 'granite-code', 'opencoder'
    $model = $mevcut | Where-Object { $esler -contains $_ } | Select-Object -First 1
    if (-not $model) {
        foreach ($aile in $kodAileleri) {
            $model = $mevcut | Where-Object { $_ -like "$aile*" } | Select-Object -First 1
            if ($model) { break }
        }
    }
    if ($model) {
        Tamam "Bilgisayardaki $model modeli kullanilacak, indirme yok"
    } elseif ($mevcut.Count -gt 0) {
        Write-Host '    Bilgisayarindaki modeller:'
        for ($i = 0; $i -lt $mevcut.Count; $i++) { Write-Host "      [$($i + 1)] $($mevcut[$i])" }
        Write-Host "      [i] Kod icin onerilen modeli indir: $onerilen (~$boyut)"
        $sec = Read-Host "    Secimin (Enter = $($mevcut[0]))"
        if ($sec -eq 'i' -or $sec -eq 'I') {
            $model = $null
        } elseif ($sec -match '^\d+$' -and [int]$sec -ge 1 -and [int]$sec -le $mevcut.Count) {
            $model = $mevcut[[int]$sec - 1]
        } else {
            $model = $mevcut[0]
        }
    }
    if (-not $model) {
        $model = $onerilen
        Write-Host "    $model indiriliyor (~$boyut). Internet hizina gore 5-30 dakika surebilir..."
        if (-not (ModelIndir $model)) { throw 'Model indirilemedi. Internet baglantinizi kontrol edip tekrar deneyin.' }
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
