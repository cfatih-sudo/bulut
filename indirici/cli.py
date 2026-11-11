"""Komut satırı arayüzü.

Örnekler:
    python -m indirici https://youtu.be/XXXX
    python -m indirici https://youtu.be/XXXX --ses --format mp3
    python -m indirici https://youtube.com/playlist?list=XXX --liste -k 720
    python -m indirici --web
"""

from __future__ import annotations

import argparse
import sys

from .core import (
    KALITELER,
    SES_FORMATLARI,
    VARSAYILAN_KLASOR,
    IndirmeAyarlari,
    IndirmeHatasi,
    bicimli_boyut,
    ffmpeg_var_mi,
    indir,
)


def _ilerleme_yaz(d: dict) -> None:
    if d["status"] == "downloading":
        toplam = d.get("total_bytes") or d.get("total_bytes_estimate")
        inen = d.get("downloaded_bytes") or 0
        yuzde = f"{inen / toplam * 100:5.1f}%" if toplam else "  ?  "
        hiz = bicimli_boyut(d.get("speed")) + "/s"
        ad = (d.get("info_dict", {}).get("title") or "")[:40]
        sys.stdout.write(f"\r{yuzde}  {bicimli_boyut(inen):>10} / {bicimli_boyut(toplam):<10} {hiz:>12}  {ad}")
        sys.stdout.flush()
    elif d["status"] == "finished":
        sys.stdout.write("\n✓ İndirildi, işleniyor...\n")


def arguman_ayristirici() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(prog="indirici", description="YouTube video/ses indirici")
    p.add_argument("url", nargs="*", help="İndirilecek video veya oynatma listesi URL'leri")
    p.add_argument("-o", "--klasor", default=VARSAYILAN_KLASOR, help="Kayıt klasörü (varsayılan: %(default)s)")
    p.add_argument("-s", "--ses", action="store_true", help="Sadece sesi indir")
    p.add_argument("-f", "--format", choices=SES_FORMATLARI, default="mp3", help="Ses formatı (varsayılan: %(default)s)")
    p.add_argument("-k", "--kalite", choices=KALITELER, default="en-iyi", help="Azami video yüksekliği")
    p.add_argument("-l", "--liste", action="store_true", help="Oynatma listesinin tamamını indir")
    p.add_argument("-a", "--altyazi", action="store_true", help="Altyazıları da indir (tr, en)")
    p.add_argument("--web", action="store_true", help="Web arayüzünü başlat")
    p.add_argument("--port", type=int, default=5000, help="Web arayüzü portu (varsayılan: %(default)s)")
    return p


def main(argv: list[str] | None = None) -> int:
    args = arguman_ayristirici().parse_args(argv)

    if args.web:
        from .web import calistir

        calistir(port=args.port, klasor=args.klasor)
        return 0

    if not args.url:
        arguman_ayristirici().print_help()
        return 2

    if not ffmpeg_var_mi():
        print("Uyarı: ffmpeg bulunamadı; video+ses birleştirme ve ses dönüştürme yapılamaz.", file=sys.stderr)

    hata = 0
    for url in args.url:
        ayar = IndirmeAyarlari(
            url=url,
            klasor=args.klasor,
            sadece_ses=args.ses,
            ses_formati=args.format,
            kalite=args.kalite,
            oynatma_listesi=args.liste,
            altyazi=args.altyazi,
        )
        print(f"→ {url}")
        try:
            for yol in indir(ayar, _ilerleme_yaz):
                print(f"  Kaydedildi: {yol}")
        except IndirmeHatasi as e:
            print(f"\n✗ Hata: {e}", file=sys.stderr)
            hata = 1
        except KeyboardInterrupt:
            print("\nİptal edildi.", file=sys.stderr)
            return 130
    return hata


if __name__ == "__main__":
    raise SystemExit(main())
