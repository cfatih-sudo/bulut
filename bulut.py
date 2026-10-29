#!/usr/bin/env python3
"""Bulut - yerel bilgisayarda calisan PHP / Java / Python kod asistani.

Ollama (https://ollama.com) uzerinde calisan bir dil modelini kullanir.
Sadece Python standart kutuphanesi gerekir.

Kullanim:
    python bulut.py            # web arayuzu: http://127.0.0.1:8765
    python bulut.py cli        # terminalde sohbet
    python bulut.py --model qwen2.5-coder:14b
"""

import argparse
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
import urllib.error
import urllib.request
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

ROOT = Path(__file__).resolve().parent
OLLAMA_URL = os.environ.get("OLLAMA_URL", "http://127.0.0.1:11434")
DEFAULT_MODEL = os.environ.get("BULUT_MODEL", "qwen2.5-coder:7b")
RUN_TIMEOUT = 20  # saniye

SYSTEM_PROMPT = """Sen "Bulut" adinda, kullanicinin kendi bilgisayarinda calisan uzman bir yazilim asistanisin.
Uzmanlik alanlarin: PHP (8.x, Laravel, Symfony, Composer, PDO), Java (17+, Spring Boot, Maven, Gradle, JUnit)
ve Python (3.x, Django, Flask, FastAPI, pandas, pytest).

Kurallar:
- Kullanici hangi dilde yazarsa o dilde cevap ver (Turkce soruya Turkce cevap).
- Kod orneklerini her zaman dil etiketiyle ver: ```php, ```java, ```python.
- Calisabilir, eksiksiz ve guvenli kod yaz; SQL icin hazirlanmis ifadeler (prepared statements) kullan.
- Java orneklerinde tek dosyada calisabilen `public class Main` ve `main` metodu tercih et.
- PHP orneklerini `<?php` ile baslat.
- Hata ayiklarken once hatanin nedenini kisaca acikla, sonra duzeltilmis kodu ver.
- Emin olmadigin konularda bunu acikca soyle; uydurma API veya kutuphane onerme.
- Gereksiz uzun yazma; once cozum, sonra kisa aciklama."""


# --------------------------------------------------------------------------- #
# Ollama
# --------------------------------------------------------------------------- #

def ollama_request(path, payload=None, timeout=600):
    data = json.dumps(payload).encode() if payload is not None else None
    req = urllib.request.Request(
        OLLAMA_URL + path,
        data=data,
        headers={"Content-Type": "application/json"},
        method="POST" if data else "GET",
    )
    return urllib.request.urlopen(req, timeout=timeout)


def list_models():
    with ollama_request("/api/tags", timeout=5) as r:
        return [m["name"] for m in json.load(r).get("models", [])]


def chat_stream(model, messages):
    """Ollama'dan gelen cevabi parca parca (str) dondurur."""
    payload = {
        "model": model,
        "messages": [{"role": "system", "content": SYSTEM_PROMPT}] + messages,
        "stream": True,
        "options": {"temperature": 0.2, "num_ctx": 8192},
    }
    with ollama_request("/api/chat", payload) as r:
        for line in r:
            if not line.strip():
                continue
            chunk = json.loads(line)
            if "error" in chunk:
                raise RuntimeError(chunk["error"])
            text = chunk.get("message", {}).get("content", "")
            if text:
                yield text
            if chunk.get("done"):
                break


# --------------------------------------------------------------------------- #
# Kodu yerelde calistirma
# --------------------------------------------------------------------------- #

def run_code(language, code):
    language = (language or "").lower()
    with tempfile.TemporaryDirectory(prefix="bulut_") as tmp:
        tmp = Path(tmp)
        if language in ("python", "py"):
            f = tmp / "main.py"
            cmd = [sys.executable, str(f)]
        elif language == "php":
            if not shutil.which("php"):
                return {"ok": False, "output": "PHP bulunamadi. PHP'yi kurup PATH'e ekleyin."}
            if not code.lstrip().startswith("<?"):
                code = "<?php\n" + code
            f = tmp / "main.php"
            cmd = ["php", str(f)]
        elif language == "java":
            if not shutil.which("java"):
                return {"ok": False, "output": "Java bulunamadi. JDK 17+ kurup PATH'e ekleyin."}
            m = re.search(r"public\s+(?:final\s+)?class\s+(\w+)", code)
            f = tmp / f"{m.group(1) if m else 'Main'}.java"
            cmd = ["java", str(f)]  # Java 11+ tek dosya calistirma
        else:
            return {"ok": False, "output": f"Desteklenmeyen dil: {language}"}

        f.write_text(code, encoding="utf-8")
        try:
            p = subprocess.run(
                cmd, cwd=tmp, capture_output=True, text=True,
                timeout=RUN_TIMEOUT, encoding="utf-8", errors="replace",
            )
        except subprocess.TimeoutExpired:
            return {"ok": False, "output": f"Zaman asimi ({RUN_TIMEOUT} sn)."}
        out = (p.stdout or "") + (p.stderr or "")
        return {"ok": p.returncode == 0, "output": out or "(cikti yok)", "code": p.returncode}


# --------------------------------------------------------------------------- #
# Web sunucusu
# --------------------------------------------------------------------------- #

class Handler(BaseHTTPRequestHandler):
    model = DEFAULT_MODEL

    def log_message(self, *args):
        pass

    def _json(self, obj, status=200):
        body = json.dumps(obj).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def _body(self):
        n = int(self.headers.get("Content-Length", 0))
        return json.loads(self.rfile.read(n) or b"{}")

    def _same_origin(self):
        # Baska sitelerin tarayici uzerinden /api/run cagirmasini engelle.
        origin = self.headers.get("Origin")
        return origin is None or origin == f"http://{self.headers.get('Host')}"

    def do_GET(self):
        if self.path in ("/", "/index.html"):
            body = (ROOT / "static" / "index.html").read_bytes()
            self.send_response(200)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)
        elif self.path == "/api/models":
            try:
                self._json({"models": list_models(), "default": self.model})
            except (urllib.error.URLError, OSError):
                self._json({"error": "Ollama'ya baglanilamadi. 'ollama serve' calisiyor mu?",
                            "models": [], "default": self.model})
        else:
            self._json({"error": "bulunamadi"}, 404)

    def do_POST(self):
        if not self._same_origin():
            return self._json({"error": "izin yok"}, 403)
        data = self._body()
        if self.path == "/api/chat":
            self.send_response(200)
            self.send_header("Content-Type", "application/x-ndjson; charset=utf-8")
            self.end_headers()
            try:
                for piece in chat_stream(data.get("model") or self.model, data.get("messages", [])):
                    self.wfile.write((json.dumps({"t": piece}) + "\n").encode())
                    self.wfile.flush()
            except (BrokenPipeError, ConnectionResetError):
                return
            except Exception as e:  # noqa: BLE001
                msg = str(e)
                if isinstance(e, urllib.error.URLError):
                    msg = "Ollama'ya baglanilamadi. 'ollama serve' calisiyor mu?"
                if isinstance(e, urllib.error.HTTPError) and e.code == 404:
                    msg = "Model bulunamadi. Once: ollama pull " + (data.get("model") or self.model)
                self.wfile.write((json.dumps({"error": msg}) + "\n").encode())
        elif self.path == "/api/run":
            self._json(run_code(data.get("language"), data.get("code", "")))
        else:
            self._json({"error": "bulunamadi"}, 404)


def serve(model, port):
    Handler.model = model
    srv = ThreadingHTTPServer(("127.0.0.1", port), Handler)
    print(f"Bulut hazir -> http://127.0.0.1:{port}   (model: {model}, durdurmak icin Ctrl+C)")
    try:
        srv.serve_forever()
    except KeyboardInterrupt:
        print("\nKapatildi.")


# --------------------------------------------------------------------------- #
# Terminal modu
# --------------------------------------------------------------------------- #

def cli(model):
    print(f"Bulut terminal modu (model: {model})")
    print("Komutlar: /temizle  /dosya <yol>  /cik   | Cok satirli giris icin satiri \\ ile bitirin.\n")
    history = []
    while True:
        try:
            lines = [input("Sen> ")]
            while lines[-1].endswith("\\"):
                lines[-1] = lines[-1][:-1]
                lines.append(input("...  "))
        except (EOFError, KeyboardInterrupt):
            print()
            break
        text = "\n".join(lines).strip()
        if not text:
            continue
        if text in ("/cik", "/exit", "/quit"):
            break
        if text == "/temizle":
            history.clear()
            print("Sohbet temizlendi.\n")
            continue
        if text.startswith("/dosya "):
            path = Path(text[7:].strip()).expanduser()
            try:
                content = path.read_text(encoding="utf-8", errors="replace")
            except OSError as e:
                print(f"Dosya okunamadi: {e}\n")
                continue
            soru = input("Bu dosya hakkinda sorunuz> ").strip() or "Bu kodu incele ve iyilestirme oner."
            text = f"Dosya: {path.name}\n```\n{content}\n```\n\n{soru}"

        history.append({"role": "user", "content": text})
        print("Bulut> ", end="", flush=True)
        answer = ""
        try:
            for piece in chat_stream(model, history):
                answer += piece
                print(piece, end="", flush=True)
        except urllib.error.HTTPError as e:
            print(f"\n[Hata] Model bulunamadi olabilir. Deneyin: ollama pull {model} ({e})")
            history.pop()
            continue
        except (urllib.error.URLError, OSError):
            print("\n[Hata] Ollama'ya baglanilamadi. 'ollama serve' calisiyor mu?")
            history.pop()
            continue
        except KeyboardInterrupt:
            print("\n[durduruldu]")
        print("\n")
        history.append({"role": "assistant", "content": answer})


def main():
    ap = argparse.ArgumentParser(description="Bulut - yerel PHP/Java/Python kod asistani")
    ap.add_argument("mode", nargs="?", default="web", choices=["web", "cli"])
    ap.add_argument("--model", default=DEFAULT_MODEL, help=f"Ollama modeli (varsayilan: {DEFAULT_MODEL})")
    ap.add_argument("--port", type=int, default=8765)
    args = ap.parse_args()
    if args.mode == "cli":
        cli(args.model)
    else:
        serve(args.model, args.port)


if __name__ == "__main__":
    main()
