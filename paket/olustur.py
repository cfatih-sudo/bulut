"""Tek tikla kurulum dosyalarini uretir:

    kurulum/Bulut-Kurulum-Windows.bat   (cift tikla)
    kurulum/Bulut-Kurulum-Mac.command
    kurulum/Bulut-Kurulum-Linux.sh

Her dosya uygulama dosyalarini icinde tasir, ek indirme gerektirmez
(Python / Ollama / model kurulum sirasinda internetten indirilir).

Kullanim:  python paket/olustur.py
"""

import base64
import io
import tarfile
import textwrap
import zipfile
from pathlib import Path

KOK = Path(__file__).resolve().parent.parent
PAKET = KOK / "paket"
CIKTI = KOK / "kurulum"
DOSYALAR = ["bulut.py", "proje.py", "uygula.py", "README.md",
            "static/index.html", "static/bulut.png", "static/bulut.ico"]
SABIT_TARIH = (2024, 1, 1, 0, 0, 0)  # ayni kaynak -> ayni cikti

BAT_BASLIK = """@echo off
chcp 65001 >nul
title Bulut Kurulumu
set "BULUT_KURULUM=%~f0"
powershell -NoProfile -ExecutionPolicy Bypass -Command "$s=[IO.File]::ReadAllText($env:BULUT_KURULUM); $i=$s.IndexOf('#'+'PS_BASLA'); Invoke-Expression $s.Substring($i)"
exit /b
#PS_BASLA
"""


def zip_b64():
    buf = io.BytesIO()
    with zipfile.ZipFile(buf, "w", zipfile.ZIP_DEFLATED, compresslevel=9) as z:
        for d in DOSYALAR:
            info = zipfile.ZipInfo(d, SABIT_TARIH)
            info.compress_type = zipfile.ZIP_DEFLATED
            z.writestr(info, (KOK / d).read_bytes())
    return base64.b64encode(buf.getvalue()).decode()


def tar_b64():
    buf = io.BytesIO()
    with tarfile.open(fileobj=buf, mode="w:gz", compresslevel=9) as t:
        for d in DOSYALAR:
            data = (KOK / d).read_bytes()
            info = tarfile.TarInfo(d)
            info.size, info.mtime, info.mode = len(data), 0, 0o644
            t.addfile(info, io.BytesIO(data))
    raw = buf.getvalue()
    raw = raw[:4] + b"\0\0\0\0" + raw[8:]  # gzip zaman damgasini sifirla
    return base64.b64encode(raw).decode()


def satirla(b64):
    return "\n".join(textwrap.wrap(b64, 76))


def main():
    CIKTI.mkdir(exist_ok=True)

    ps = (PAKET / "windows.ps1").read_text(encoding="utf-8")
    ps = ps.replace("__PAYLOAD__", satirla(zip_b64()))
    bat = BAT_BASLIK + ps
    win = CIKTI / "Bulut-Kurulum-Windows.bat"
    win.write_bytes(bat.replace("\r\n", "\n").replace("\n", "\r\n").encode("utf-8"))

    sh = (PAKET / "unix.sh").read_text(encoding="utf-8") + satirla(tar_b64()) + "\n"
    for ad in ("Bulut-Kurulum-Mac.command", "Bulut-Kurulum-Linux.sh"):
        f = CIKTI / ad
        f.write_bytes(sh.encode("utf-8"))
        f.chmod(0o755)

    for f in sorted(CIKTI.iterdir()):
        print(f"{f.relative_to(KOK)}  ({f.stat().st_size // 1024} KB)")


if __name__ == "__main__":
    main()
