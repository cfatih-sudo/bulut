"""Basit Flask web arayüzü. İndirmeler arka planda iş parçacığında çalışır."""

from __future__ import annotations

import os
import threading
import uuid

from flask import Flask, abort, jsonify, render_template, request, send_file

from .core import (
    KALITELER,
    SES_FORMATLARI,
    VARSAYILAN_KLASOR,
    IndirmeAyarlari,
    IndirmeHatasi,
    bilgi_al,
    ffmpeg_var_mi,
    indir,
)


def uygulama_olustur(klasor: str = VARSAYILAN_KLASOR) -> Flask:
    app = Flask(__name__)
    klasor = os.path.abspath(klasor)
    isler: dict[str, dict] = {}
    kilit = threading.Lock()

    def _guncelle(is_id: str, **alanlar) -> None:
        with kilit:
            isler[is_id].update(alanlar)

    def _calistir(is_id: str, ayar: IndirmeAyarlari) -> None:
        def ilerleme(d: dict) -> None:
            if d["status"] == "downloading":
                toplam = d.get("total_bytes") or d.get("total_bytes_estimate")
                inen = d.get("downloaded_bytes") or 0
                _guncelle(
                    is_id,
                    durum="indiriliyor",
                    yuzde=round(inen / toplam * 100, 1) if toplam else None,
                    baslik=d.get("info_dict", {}).get("title"),
                    hiz=d.get("speed"),
                )
            elif d["status"] == "finished":
                _guncelle(is_id, durum="isleniyor", yuzde=100)

        try:
            dosyalar = indir(ayar, ilerleme)
            _guncelle(is_id, durum="bitti", yuzde=100, dosyalar=dosyalar)
        except IndirmeHatasi as e:
            _guncelle(is_id, durum="hata", hata=str(e))
        except Exception as e:  # beklenmeyen hatalar da kullanıcıya görünsün
            _guncelle(is_id, durum="hata", hata=f"Beklenmeyen hata: {e}")

    @app.get("/")
    def ana_sayfa():
        return render_template(
            "index.html",
            kaliteler=KALITELER,
            ses_formatlari=SES_FORMATLARI,
            ffmpeg=ffmpeg_var_mi(),
        )

    @app.post("/api/bilgi")
    def api_bilgi():
        url = (request.get_json(silent=True) or {}).get("url", "").strip()
        if not url:
            return jsonify(hata="URL gerekli"), 400
        try:
            return jsonify(bilgi_al(url))
        except IndirmeHatasi as e:
            return jsonify(hata=str(e)), 400

    @app.post("/api/indir")
    def api_indir():
        veri = request.get_json(silent=True) or {}
        url = str(veri.get("url", "")).strip()
        if not url:
            return jsonify(hata="URL gerekli"), 400
        kalite = veri.get("kalite", "en-iyi")
        ses_formati = veri.get("ses_formati", "mp3")
        if kalite not in KALITELER or ses_formati not in SES_FORMATLARI:
            return jsonify(hata="Geçersiz seçenek"), 400

        ayar = IndirmeAyarlari(
            url=url,
            klasor=klasor,
            sadece_ses=bool(veri.get("sadece_ses")),
            ses_formati=ses_formati,
            kalite=kalite,
            oynatma_listesi=bool(veri.get("oynatma_listesi")),
            altyazi=bool(veri.get("altyazi")),
        )
        is_id = uuid.uuid4().hex
        with kilit:
            isler[is_id] = {"id": is_id, "url": url, "durum": "bekliyor", "yuzde": 0, "dosyalar": []}
        threading.Thread(target=_calistir, args=(is_id, ayar), daemon=True).start()
        return jsonify(id=is_id), 202

    @app.get("/api/durum/<is_id>")
    def api_durum(is_id: str):
        with kilit:
            is_ = isler.get(is_id)
            if not is_:
                return jsonify(hata="İş bulunamadı"), 404
            yanit = dict(is_)
        yanit["dosyalar"] = [os.path.basename(p) for p in yanit.get("dosyalar", [])]
        return jsonify(yanit)

    @app.get("/dosya/<is_id>/<int:sira>")
    def dosya(is_id: str, sira: int):
        with kilit:
            is_ = isler.get(is_id)
            dosyalar = list(is_["dosyalar"]) if is_ else []
        if sira >= len(dosyalar):
            abort(404)
        yol = os.path.abspath(dosyalar[sira])
        # Yalnızca indirme klasörü içindeki dosyalar sunulur.
        if os.path.commonpath([yol, klasor]) != klasor or not os.path.isfile(yol):
            abort(404)
        return send_file(yol, as_attachment=True)

    return app


def calistir(port: int = 5000, klasor: str = VARSAYILAN_KLASOR) -> None:
    app = uygulama_olustur(klasor)
    print(f"Web arayüzü: http://127.0.0.1:{port}")
    app.run(host="127.0.0.1", port=port, debug=False, threaded=True)
