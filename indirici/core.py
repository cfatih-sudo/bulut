"""İndirme mantığı: yt-dlp seçeneklerini kurar ve indirmeyi çalıştırır."""

from __future__ import annotations

import os
import shutil
from dataclasses import dataclass
from typing import Callable

import yt_dlp

KALITELER = ("en-iyi", "2160", "1440", "1080", "720", "480", "360")
SES_FORMATLARI = ("mp3", "m4a", "opus", "wav", "flac")
VARSAYILAN_KLASOR = "indirilenler"


class IndirmeHatasi(Exception):
    """İndirme sırasında oluşan, kullanıcıya gösterilebilir hata."""


class _SessizLogger:
    """yt-dlp mesajlarını yutar; hatalar zaten IndirmeHatasi olarak raporlanır."""

    def debug(self, msg: str) -> None: ...
    def info(self, msg: str) -> None: ...
    def warning(self, msg: str) -> None: ...
    def error(self, msg: str) -> None: ...


@dataclass
class IndirmeAyarlari:
    url: str
    klasor: str = VARSAYILAN_KLASOR
    sadece_ses: bool = False
    ses_formati: str = "mp3"
    kalite: str = "en-iyi"
    oynatma_listesi: bool = False
    altyazi: bool = False


def ffmpeg_var_mi() -> bool:
    return shutil.which("ffmpeg") is not None


def _format_secici(ayar: IndirmeAyarlari) -> str:
    if ayar.sadece_ses:
        return "bestaudio/best"
    if ayar.kalite == "en-iyi":
        return "bestvideo+bestaudio/best"
    h = int(ayar.kalite)
    return f"bestvideo[height<={h}]+bestaudio/best[height<={h}]/best"


def ytdlp_secenekleri(
    ayar: IndirmeAyarlari,
    ilerleme: Callable[[dict], None] | None = None,
) -> dict:
    """Ayarlardan yt-dlp seçenek sözlüğü üretir."""
    if ayar.kalite not in KALITELER:
        raise IndirmeHatasi(f"Geçersiz kalite: {ayar.kalite}")
    if ayar.ses_formati not in SES_FORMATLARI:
        raise IndirmeHatasi(f"Geçersiz ses formatı: {ayar.ses_formati}")

    ffmpeg = ffmpeg_var_mi()
    if ayar.sadece_ses and not ffmpeg:
        raise IndirmeHatasi("Ses dönüştürmek için ffmpeg kurulu olmalı.")

    sablon = (
        "%(playlist_title)s/%(playlist_index)03d - %(title)s.%(ext)s"
        if ayar.oynatma_listesi
        else "%(title)s.%(ext)s"
    )

    secenekler: dict = {
        "format": _format_secici(ayar),
        "outtmpl": os.path.join(ayar.klasor, sablon),
        "noplaylist": not ayar.oynatma_listesi,
        "restrictfilenames": False,
        "windowsfilenames": True,
        "quiet": True,
        "no_warnings": True,
        "noprogress": True,
        "logger": _SessizLogger(),
        "postprocessors": [],
    }

    if not ffmpeg and not ayar.sadece_ses:
        # ffmpeg yoksa birleştirme yapılamaz; tek dosyalık en iyi formatı al.
        secenekler["format"] = "best"
    elif not ayar.sadece_ses:
        secenekler["merge_output_format"] = "mp4"

    if ayar.sadece_ses:
        secenekler["postprocessors"].append(
            {
                "key": "FFmpegExtractAudio",
                "preferredcodec": ayar.ses_formati,
                "preferredquality": "192",
            }
        )

    if ayar.altyazi:
        secenekler.update(
            {
                "writesubtitles": True,
                "writeautomaticsub": True,
                "subtitleslangs": ["tr", "en"],
            }
        )

    if ilerleme:
        secenekler["progress_hooks"] = [ilerleme]

    return secenekler


def bilgi_al(url: str) -> dict:
    """Videoyu indirmeden başlık, süre vb. bilgileri döndürür."""
    try:
        with yt_dlp.YoutubeDL(
            {"quiet": True, "no_warnings": True, "noplaylist": True, "logger": _SessizLogger()}
        ) as ydl:
            bilgi = ydl.extract_info(url, download=False)
    except yt_dlp.utils.DownloadError as e:
        raise IndirmeHatasi(_temiz_hata(e)) from e
    return {
        "baslik": bilgi.get("title"),
        "kanal": bilgi.get("uploader"),
        "sure": bilgi.get("duration"),
        "kucuk_resim": bilgi.get("thumbnail"),
    }


def indir(
    ayar: IndirmeAyarlari,
    ilerleme: Callable[[dict], None] | None = None,
) -> list[str]:
    """İndirmeyi yapar, oluşan dosyaların yollarını döndürür."""
    if not ayar.url.strip():
        raise IndirmeHatasi("URL boş olamaz.")
    os.makedirs(ayar.klasor, exist_ok=True)

    dosyalar: list[str] = []

    def _son_isleme(d: dict) -> None:
        if d.get("status") == "finished":
            yol = d.get("info_dict", {}).get("filepath")
            if yol and yol not in dosyalar:
                dosyalar.append(yol)

    secenekler = ytdlp_secenekleri(ayar, ilerleme)
    secenekler["postprocessor_hooks"] = [_son_isleme]

    try:
        with yt_dlp.YoutubeDL(secenekler) as ydl:
            ydl.download([ayar.url])
    except yt_dlp.utils.DownloadError as e:
        raise IndirmeHatasi(_temiz_hata(e)) from e
    return dosyalar


def _temiz_hata(e: Exception) -> str:
    mesaj = str(e)
    return mesaj.removeprefix("ERROR: ").strip() or "Bilinmeyen hata"


def bicimli_boyut(bayt: float | None) -> str:
    if not bayt:
        return "?"
    for birim in ("B", "KB", "MB", "GB"):
        if bayt < 1024:
            return f"{bayt:.1f} {birim}"
        bayt /= 1024
    return f"{bayt:.1f} TB"
