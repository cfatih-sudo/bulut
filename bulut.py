#!/usr/bin/env python3
"""Bulut - yerel bilgisayarda calisan PHP / Java / Python kod asistani.

Ollama (https://ollama.com) uzerinde calisan bir dil modelini kullanir.
Sadece Python standart kutuphanesi gerekir.

Kullanim:
    python bulut.py            # web arayuzu: http://127.0.0.1:8765
    python bulut.py cli        # terminalde sohbet
    python bulut.py --model qwen2.5-coder:14b
    python bulut.py --proje C:\\projelerim\\site   # proje klasoru ile ac
"""

import argparse
import json
import os
import re
import shutil
import socket
import subprocess
import sys
import tempfile
import threading
import urllib.error
import urllib.request
import webbrowser
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

from proje import Project
from uygula import Applier, parse_blocks

ROOT = Path(__file__).resolve().parent
def _ollama_url():
    """OLLAMA_URL, yoksa Ollama'nin kendi OLLAMA_HOST ayari, yoksa varsayilan adres."""
    if os.environ.get("OLLAMA_URL"):
        return os.environ["OLLAMA_URL"].rstrip("/")
    host = os.environ.get("OLLAMA_HOST", "").strip()
    if not host:
        return "http://127.0.0.1:11434"
    if not re.match(r"https?://", host):
        host = "http://" + host
    host = host.replace("://0.0.0.0", "://127.0.0.1").rstrip("/")
    if not re.search(r":\d+$", host):
        host += ":11434"
    return host


OLLAMA_URL = _ollama_url()
DEFAULT_MODEL = os.environ.get("BULUT_MODEL", "qwen2.5-coder:7b")
RUN_TIMEOUT = 20  # saniye
NUM_CTX = int(os.environ.get("BULUT_CTX", "16384"))  # modelin baglam penceresi (token)

PROJECT = None
APPLIER = None
PROJECT_LOCK = threading.Lock()

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

PROJECT_PROMPT = """

Kullanici bir proje klasoru acti. Asagida projenin yapisi ve soruyla ilgili dosyalar var.
- Cevaplarini bu gercek koda dayandir; dosya yollarini ve satir numaralarini belirt.
- Degisiklik onerirken hangi dosyanin neresinin degisecegini acikca yaz.
- Projedeki mevcut stil, framework ve isimlendirmeye uy.
- Ihtiyacin olan dosya asagida yoksa tahmin etme; kullanicidan @dosya/yolu ile eklemesini iste.

Dosya degistirme bicimi (kullanici "Uygula" dugmesiyle dosyaya yazar, bu yuzden bicime kesinlikle uy):
- Kod blogunun dil etiketinden sonra iki nokta ve proje icindeki yolu yaz: ```php:app/Http/Controllers/UserController.php
- YENI dosya veya tamamini gordugun kucuk dosya: blokta dosyanin TAM ve EKSIKSIZ yeni icerigini ver.
  Asla "// ... mevcut kod ..." gibi kisaltma yazma; yazarsan o kod silinir.
- BUYUK dosya veya sadece bir kismini gordugun dosya: sadece degisen kismi su bicimde ver
  (ARA kismi dosyadaki mevcut kodla birebir ayni olmali, birkac satir cevre kod ekle):
```java:src/main/java/com/ornek/UserService.java
<<<<<<< ARA
    public User find(int id) {
        return repo.get(id);
    }
=======
    public User find(int id) {
        return repo.findById(id).orElseThrow();
    }
>>>>>>> DEGISTIR
```
- Ornek/aciklama amacli, dosyaya yazilmayacak kodlarda yol yazma.

"""


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


def trim_history(messages, max_chars):
    """Baglama sigmayacak kadar eski mesajlari atar (son mesaj hep kalir)."""
    out, total = [], 0
    for m in reversed(messages):
        total += len(m.get("content", ""))
        if out and total > max_chars:
            break
        out.append({"role": m["role"], "content": m["content"]})
    return list(reversed(out))


def search_terms(model, question):
    """Turkce soruyu koddaki Ingilizce adlarla eslestirmek icin modelden anahtar kelime ister."""
    payload = {
        "model": model,
        "stream": False,
        "messages": [{"role": "user", "content":
                      "Asagidaki soru icin bir kod tabaninda aranacak anahtar kelimeleri yaz. "
                      "Ingilizce karsiliklari, olasi sinif/fonksiyon/degisken/tablo adlarini dahil et. "
                      "Sadece bosluklarla ayrilmis en fazla 15 kelime yaz, baska hicbir sey yazma.\n\n"
                      "Soru: " + question[:1500]}],
        "options": {"temperature": 0, "num_predict": 60},
    }
    try:
        with ollama_request("/api/chat", payload, timeout=60) as r:
            return json.load(r).get("message", {}).get("content", "")[:400]
    except Exception:  # noqa: BLE001 - arama terimleri istege bagli
        return ""


def project_context(model, messages):
    """Acik proje varsa son soruya gore (sistem metni, kullanilan dosyalar) dondurur."""
    with PROJECT_LOCK:
        proj = PROJECT
    if not proj or not messages:
        return "", []
    proj.refresh()
    question = messages[-1]["content"]
    prev = " ".join(m["content"] for m in messages[-3:-1] if m["role"] == "user")
    budget = int(NUM_CTX * 3 * 0.55)  # ~3 karakter/token, baglamin ~%55'i proje icin
    ctx, used, whole = proj.build_context(question, budget, "")
    if not whole:
        extra = search_terms(model, question) + " " + prev
        ctx, used, _ = proj.build_context(question, budget, extra)
    return PROJECT_PROMPT + ctx, used


def chat_stream(model, messages, extra_system=""):
    """Ollama'dan gelen cevabi parca parca (str) dondurur."""
    history_budget = int(NUM_CTX * 3 * (0.3 if extra_system else 0.75))
    payload = {
        "model": model,
        "messages": [{"role": "system", "content": SYSTEM_PROMPT + extra_system}]
        + trim_history(messages, history_budget),
        "stream": True,
        "options": {"temperature": 0.2, "num_ctx": NUM_CTX},
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

def system_python():
    """Kullanicinin kendi Python'u (paketleri orada kurulu). Yoksa Bulut'un Python'u."""
    if os.name == "nt" and shutil.which("py"):
        return ["py", "-3"]
    for name in ("python3", "python"):
        p = shutil.which(name)
        if p and "WindowsApps" not in p:  # Windows Store kisayolu gercek Python degil
            return [p]
    exe = sys.executable
    if exe.lower().endswith("pythonw.exe"):
        exe = exe[:-11] + "python.exe"
    return [exe]


def run_code(language, code):
    language = (language or "").lower()
    with tempfile.TemporaryDirectory(prefix="bulut_") as tmp:
        tmp = Path(tmp)
        if language in ("python", "py"):
            f = tmp / "main.py"
            cmd = system_python() + [str(f)]
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
                creationflags=0x08000000 if os.name == "nt" else 0,  # Windows'ta konsol penceresi acma
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
        elif self.path in ("/favicon.ico", "/bulut.png"):
            body = (ROOT / "static" / ("bulut.ico" if self.path.endswith("ico") else "bulut.png")).read_bytes()
            self.send_response(200)
            self.send_header("Content-Type", "image/x-icon" if self.path.endswith("ico") else "image/png")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)
        elif self.path == "/api/project":
            with PROJECT_LOCK:
                proj = PROJECT
            self._json({"project": proj.info() if proj else None})
        elif self.path == "/api/project/files":
            with PROJECT_LOCK:
                proj = PROJECT
            self._json({"files": sorted(proj.files) if proj else []})
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
        if self.path == "/api/project":
            return self._json(open_project(data.get("path")))
        if self.path in ("/api/project/preview", "/api/project/apply", "/api/project/undo"):
            with PROJECT_LOCK:
                applier = APPLIER
            if not applier:
                return self._json({"ok": False, "error": "Once bir proje klasoru acin."})
            try:
                if self.path.endswith("undo"):
                    return self._json(applier.undo())
                fn = applier.preview if self.path.endswith("preview") else applier.apply
                r = fn(data.get("path", ""), data.get("content", ""))
                return self._json({"ok": True, **r})
            except (ValueError, OSError) as e:
                return self._json({"ok": False, "error": str(e)})
        if self.path == "/api/chat":
            self.send_response(200)
            self.send_header("Content-Type", "application/x-ndjson; charset=utf-8")
            self.end_headers()
            model = data.get("model") or self.model
            messages = data.get("messages", [])
            try:
                extra, used = project_context(model, messages)
                if used:
                    self.wfile.write((json.dumps({"files": used}) + "\n").encode())
                    self.wfile.flush()
                for piece in chat_stream(model, messages, extra):
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
        elif self.path == "/api/kapat":
            self._json({"ok": True})
            threading.Thread(target=self.server.shutdown, daemon=True).start()
        elif self.path == "/api/run":
            self._json(run_code(data.get("language"), data.get("code", "")))
        else:
            self._json({"error": "bulunamadi"}, 404)


def open_project(path):
    """path bos/None ise projeyi kapatir."""
    global PROJECT, APPLIER
    if not path:
        with PROJECT_LOCK:
            PROJECT = APPLIER = None
        return {"project": None}
    try:
        proj = Project(path)
    except (ValueError, OSError) as e:
        return {"error": str(e)}
    with PROJECT_LOCK:
        PROJECT = proj
        APPLIER = Applier(proj)
    return {"project": proj.info()}


def describe(info):
    return (f"Proje acildi: {info['name']} - {info['files']} dosya"
            + (f" - {', '.join(info['stack'])}" if info["stack"] else "")
            + (" (cok buyuk, bir kismi atlandi)" if info["truncated"] else ""))


def find_ollama():
    found = shutil.which("ollama")
    if found:
        return found
    for p in (Path(os.environ.get("LOCALAPPDATA", "")) / "Programs" / "Ollama" / "ollama.exe",
              Path(os.environ.get("ProgramFiles", "")) / "Ollama" / "ollama.exe",
              Path.home() / "scoop" / "shims" / "ollama.exe",
              Path(os.environ.get("ProgramData", "")) / "chocolatey" / "bin" / "ollama.exe",
              Path("/opt/homebrew/bin/ollama"),
              Path("/snap/bin/ollama"),
              Path("/Applications/Ollama.app/Contents/Resources/ollama"),
              Path.home() / "Applications" / "Ollama.app" / "Contents" / "Resources" / "ollama",
              Path("/usr/local/bin/ollama")):
        if p.is_file():
            return str(p)
    return None


def ensure_ollama():
    """Ollama calismiyorsa arka planda baslatir."""
    try:
        list_models()
        return
    except (urllib.error.URLError, OSError):
        pass
    exe = find_ollama()
    if not exe:
        print("Ollama bulunamadi. https://ollama.com adresinden kurun.")
        return
    flags = 0x08000000 if os.name == "nt" else 0  # CREATE_NO_WINDOW
    subprocess.Popen([exe, "serve"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
                     stdin=subprocess.DEVNULL, creationflags=flags, start_new_session=os.name != "nt")
    for _ in range(30):
        try:
            list_models()
            return
        except (urllib.error.URLError, OSError):
            threading.Event().wait(0.5)


def serve(model, port, open_browser=False):
    Handler.model = model
    url = f"http://127.0.0.1:{port}"
    try:
        # Windows'ta SO_REUSEADDR dolu portu da kapabildigi icin once elle kontrol et.
        socket.create_connection(("127.0.0.1", port), timeout=0.5).close()
        in_use = True
    except OSError:
        in_use = False
    try:
        if in_use:
            raise OSError("port dolu")
        ThreadingHTTPServer.allow_reuse_address = os.name != "nt"
        srv = ThreadingHTTPServer(("127.0.0.1", port), Handler)
    except OSError:
        # Bulut zaten calisiyor olabilir: sadece tarayiciyi ac.
        if open_browser:
            webbrowser.open(url)
            return
        sys.exit(f"{port} portu kullanimda (Bulut zaten acik olabilir: {url}). "
                 "Baska port icin: python bulut.py --port 8766")
    if open_browser:
        ensure_ollama()
        threading.Timer(0.5, webbrowser.open, [url]).start()
    print(f"Bulut hazir -> {url}   (model: {model}, durdurmak icin Ctrl+C)")
    try:
        srv.serve_forever()
    except KeyboardInterrupt:
        print("\nKapatildi.")


# --------------------------------------------------------------------------- #
# Terminal modu
# --------------------------------------------------------------------------- #

def cli(model):
    print(f"Bulut terminal modu (model: {model})")
    print("Komutlar: /proje <klasor>  /projekapat  /geri  /temizle  /dosya <yol>  /cik")
    print("Cok satirli giris icin satiri \\ ile bitirin. Projede dosya secmek icin: @yol/dosya.php\n")
    if PROJECT:
        print(describe(PROJECT.info()) + "\n")
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
        if text.startswith("/proje "):
            r = open_project(text[7:].strip().strip('"'))
            print((r.get("error") or describe(r["project"])) + "\n")
            continue
        if text == "/projekapat":
            open_project(None)
            print("Proje kapatildi.\n")
            continue
        if text == "/geri":
            if not APPLIER:
                print("Acik proje yok.\n")
            else:
                r = APPLIER.undo()
                print((r.get("message") or r.get("error")) + "\n")
            continue
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
        answer = ""
        try:
            extra, used = project_context(model, history)
            if used:
                shown = ", ".join(used[:8]) + (f" (+{len(used) - 8})" if len(used) > 8 else "")
                print(f"  [incelenen dosyalar: {shown}]")
            print("Bulut> ", end="", flush=True)
            for piece in chat_stream(model, history, extra):
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
        if APPLIER:
            cli_apply(answer)


def color_diff(diff):
    if not sys.stdout.isatty():
        return diff
    out = []
    for line in diff.splitlines():
        if line.startswith("+") and not line.startswith("+++"):
            line = f"\033[32m{line}\033[0m"
        elif line.startswith("-") and not line.startswith("---"):
            line = f"\033[31m{line}\033[0m"
        elif line.startswith("@@"):
            line = f"\033[36m{line}\033[0m"
        out.append(line)
    return "\n".join(out)


def cli_apply(answer):
    """Cevaptaki dosya bloklarini farkiyla gosterip onay ister."""
    for path, content in parse_blocks(answer):
        try:
            r = APPLIER.preview(path, content)
        except (ValueError, OSError) as e:
            print(f"[{path}] uygulanamaz: {e}\n")
            continue
        if not r["changed"]:
            continue
        print(f"--- Onerilen degisiklik: {r['path']}" + (" (YENI DOSYA)" if r["new_file"] else ""))
        print(color_diff(r["diff"]))
        for w in r["warnings"]:
            print(f"!! UYARI: {w}")
        try:
            ok = input(f"{r['path']} dosyasina yazilsin mi? (e/h) ").strip().lower()
        except (EOFError, KeyboardInterrupt):
            print()
            return
        if ok in ("e", "evet", "y", "yes"):
            res = APPLIER.apply(path, content)
            print(f"Yazildi: {res['path']}  (geri almak icin /geri)\n")
        else:
            print("Atlandi.\n")


def main():
    global NUM_CTX
    ap = argparse.ArgumentParser(description="Bulut - yerel PHP/Java/Python kod asistani")
    ap.add_argument("mode", nargs="?", default="web", choices=["web", "cli"])
    ap.add_argument("--model", default=DEFAULT_MODEL, help=f"Ollama modeli (varsayilan: {DEFAULT_MODEL})")
    ap.add_argument("--port", type=int, default=8765)
    ap.add_argument("--proje", help="Acilista yuklenecek proje klasoru")
    ap.add_argument("--ctx", type=int, default=NUM_CTX, help=f"Baglam penceresi, token (varsayilan: {NUM_CTX})")
    ap.add_argument("--ac", action="store_true", help="Tarayiciyi ac ve gerekirse Ollama'yi baslat")
    args = ap.parse_args()
    NUM_CTX = args.ctx
    if args.proje:
        r = open_project(args.proje)
        print(r.get("error") or describe(r["project"]))
    if args.mode == "cli":
        cli(args.model)
    else:
        serve(args.model, args.port, args.ac)


if __name__ == "__main__":
    main()
