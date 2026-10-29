"""Proje klasorunu tarar, indeksler ve sorulara gore ilgili kodu bulur.

Yerel modellerin baglam penceresi sinirli oldugu icin tum proje her seferinde
modele verilemez. Bunun yerine:
  1. Klasor taranir (vendor, node_modules, target, .git vb. atlanir).
  2. Dosyalar parcalara bolunur ve BM25 ile anahtar kelime indeksi kurulur.
  3. Her soruda: proje ozeti + klasor agaci + en ilgili kod parcalari
     (kucuk projelerde tum dosyalar) modele verilir.
  4. Mesajda @yol/dosya.php yazilan dosyalar her zaman tam olarak eklenir.
"""

import fnmatch
import json
import math
import os
import re
import threading
from collections import Counter, defaultdict
from pathlib import Path

IGNORE_DIRS = {
    ".git", ".svn", ".hg", ".idea", ".vscode", ".gradle", ".mvn", "node_modules", "vendor",
    "target", "build", "dist", "out", "bin", "obj", "__pycache__", ".venv", "venv", "env",
    ".tox", ".mypy_cache", ".pytest_cache", ".ruff_cache", ".next", ".nuxt", "coverage",
    "htmlcov", "site-packages", ".cache", ".terraform", "logs",
}
IGNORE_PATHS = {"storage/framework", "storage/logs", "bootstrap/cache", "public/build", "var/cache", "var/log"}
CODE_EXT = {
    ".php", ".java", ".py", ".kt", ".kts", ".groovy", ".js", ".mjs", ".ts", ".jsx", ".tsx", ".vue",
    ".html", ".htm", ".twig", ".jsp", ".css", ".scss", ".sql", ".xml", ".yml", ".yaml", ".json",
    ".toml", ".ini", ".cfg", ".properties", ".gradle", ".md", ".rst", ".txt", ".sh", ".bat", ".ps1",
}
SPECIAL_NAMES = {
    "Dockerfile", "Makefile", "artisan", "composer.json", "pom.xml", "build.gradle",
    "requirements.txt", "pyproject.toml", "setup.py", "setup.cfg", "Pipfile", "manage.py",
    ".env.example", "docker-compose.yml", "package.json",
}
# Gizli bilgi icerebilecek dosyalar modele hic verilmez.
SECRET_PATTERNS = [".env", ".env.*", "*.pem", "*.key", "*.p12", "*.jks", "id_rsa*", "*.keystore",
                   "credentials*", "secrets.*", "auth.json"]
SKIP_FILES = {"composer.lock", "package-lock.json", "yarn.lock", "pnpm-lock.yaml", "poetry.lock", "Pipfile.lock"}
KEY_FILES = ["README.md", "README.rst", "README.txt", "composer.json", "pom.xml", "build.gradle",
             "build.gradle.kts", "requirements.txt", "pyproject.toml", "package.json"]

MAX_FILE_BYTES = 300_000
MAX_FILES = 6000
CHUNK_LINES = 40

STOPWORDS = {
    # Turkce
    "bir", "bu", "su", "ve", "ile", "icin", "için", "ne", "nasil", "nasıl", "neden", "mi", "mı", "mu",
    "mü", "da", "de", "ki", "var", "yok", "olan", "gibi", "daha", "kod", "kodu", "dosya", "dosyada",
    "hata", "bana", "beni", "benim", "yap", "yaz", "ekle", "nerede", "hangi", "projede", "proje",
    # Ingilizce / kod
    "the", "a", "an", "and", "or", "to", "of", "in", "is", "it", "for", "on", "this", "that", "with",
    "public", "private", "protected", "static", "return", "new", "void", "class", "function", "def",
    "import", "self", "this", "true", "false", "null", "none", "var", "let", "const", "if", "else",
    "php", "java", "py", "js", "ts", "json", "xml", "yml",
}


def tokenize(text):
    """camelCase / snake_case / kebab-case adlari da parcalar."""
    out = []
    for word in re.findall(r"[A-Za-z_À-ɏ][A-Za-z0-9_À-ɏ]*", text):
        parts = [word]
        for piece in re.split(r"_+", word):
            parts += re.findall(r"[A-Z]+(?=[A-Z][a-z])|[A-Z]?[a-zÀ-ɏ]+|[A-Z]+|\d+", piece)
        for p in parts:
            p = p.lower()
            if len(p) > 1 and p not in STOPWORDS:
                out.append(p)
    return out


class Project:
    def __init__(self, root):
        root = Path(root).expanduser().resolve()
        if not root.is_dir():
            raise ValueError(f"Klasor bulunamadi: {root}")
        self.root = root
        self.lock = threading.Lock()
        self.files = {}     # rel_path -> {"text", "mtime", "lines"}
        self.chunks = []    # (rel_path, start_line, end_line, Counter)
        self.df = Counter()
        self.avg_len = 1.0
        self.gitignore = self._read_gitignore()
        self.truncated = False
        self.refresh()

    # ------------------------------------------------------------------ tarama

    def _read_gitignore(self):
        pats = []
        try:
            for line in (self.root / ".gitignore").read_text(encoding="utf-8", errors="ignore").splitlines():
                line = line.strip()
                if line and not line.startswith(("#", "!")):
                    pats.append(line.strip("/"))
        except OSError:
            pass
        return pats

    def _ignored(self, rel, name):
        if any(fnmatch.fnmatch(name, p) for p in SECRET_PATTERNS) and name != ".env.example":
            return True
        for p in self.gitignore:
            if fnmatch.fnmatch(rel, p) or fnmatch.fnmatch(name, p) or rel.startswith(p + "/"):
                return True
        return False

    def _walk(self):
        found = {}
        for dirpath, dirnames, filenames in os.walk(self.root):
            rel_dir = Path(dirpath).relative_to(self.root).as_posix()
            rel_dir = "" if rel_dir == "." else rel_dir
            keep = []
            for d in dirnames:
                rd = f"{rel_dir}/{d}" if rel_dir else d
                if d in IGNORE_DIRS or rd in IGNORE_PATHS or (d.startswith(".") and d != ".github"):
                    continue
                if self._ignored(rd, d):
                    continue
                keep.append(d)
            dirnames[:] = sorted(keep)
            for name in sorted(filenames):
                rel = f"{rel_dir}/{name}" if rel_dir else name
                ext = os.path.splitext(name)[1].lower()
                if name in SKIP_FILES or not (ext in CODE_EXT or name in SPECIAL_NAMES):
                    continue
                if self._ignored(rel, name):
                    continue
                try:
                    st = os.stat(os.path.join(dirpath, name))
                except OSError:
                    continue
                if st.st_size > MAX_FILE_BYTES:
                    continue
                found[rel] = st.st_mtime
                if len(found) >= MAX_FILES:
                    self.truncated = True
                    return found
        return found

    def refresh(self):
        """Yeni / degisen / silinen dosyalari indekse yansitir. Degisiklik varsa True."""
        with self.lock:
            found = self._walk()
            changed = False
            for rel in list(self.files):
                if rel not in found:
                    del self.files[rel]
                    changed = True
            for rel, mtime in found.items():
                old = self.files.get(rel)
                if old and old["mtime"] == mtime:
                    continue
                try:
                    raw = (self.root / rel).read_bytes()
                except OSError:
                    continue
                if b"\x00" in raw[:4096]:
                    continue  # ikili dosya
                text = raw.decode("utf-8", errors="replace")
                self.files[rel] = {"text": text, "mtime": mtime, "lines": text.splitlines()}
                changed = True
            if changed:
                self._index()
            return changed

    def _index(self):
        self.chunks = []
        self.df = Counter()
        total = 0
        for rel, f in self.files.items():
            lines = f["lines"] or [""]
            path_tokens = tokenize(rel.replace("/", " ").replace(".", " "))
            for start in range(0, len(lines), CHUNK_LINES):
                end = min(start + CHUNK_LINES, len(lines))
                # Dosya adi her parcaya eklenir: "UserController" sorusu o dosyayi bulsun.
                tf = Counter(tokenize("\n".join(lines[start:end])) + path_tokens * 3)
                self.chunks.append((rel, start, end, tf))
                self.df.update(tf.keys())
                total += sum(tf.values())
        self.avg_len = total / max(len(self.chunks), 1)

    # ------------------------------------------------------------------ bilgi

    def stack(self):
        """Projede kullanilan dil / framework'leri tahmin eder."""
        f = self.files
        found = []

        def has(name):
            return name in f

        def text(name):
            return f.get(name, {}).get("text", "").lower()

        if has("composer.json"):
            try:
                req = json.loads(f["composer.json"]["text"]).get("require", {})
            except ValueError:
                req = {}
            php = req.get("php")
            found.append("PHP" + (f" {php}" if php else ""))
            if "laravel/framework" in req or has("artisan"):
                found.append("Laravel " + req.get("laravel/framework", "").lstrip("^~"))
            if any(k.startswith("symfony/") for k in req):
                found.append("Symfony")
        elif any(r.endswith(".php") for r in f):
            found.append("PHP")
        if has("pom.xml"):
            found.append("Java (Maven)")
            if "spring-boot" in text("pom.xml"):
                found.append("Spring Boot")
        if has("build.gradle") or has("build.gradle.kts"):
            found.append("Java/Kotlin (Gradle)")
            if "spring" in text("build.gradle") + text("build.gradle.kts"):
                found.append("Spring Boot")
        if not any("Java" in s for s in found) and any(r.endswith(".java") for r in f):
            found.append("Java")
        py_deps = text("requirements.txt") + text("pyproject.toml") + text("setup.py") + text("pipfile")
        if py_deps or any(r.endswith(".py") for r in f):
            found.append("Python")
            for lib, label in (("django", "Django"), ("flask", "Flask"), ("fastapi", "FastAPI"),
                               ("pandas", "pandas"), ("sqlalchemy", "SQLAlchemy"), ("pytest", "pytest")):
                if lib in py_deps or (lib == "django" and has("manage.py")):
                    found.append(label)
        if has("package.json"):
            found.append("JavaScript/Node")
        return [s.strip() for s in found]

    def tree(self, max_lines=250):
        lines, seen = [], set()
        for rel in sorted(self.files):
            parts = rel.split("/")
            for i in range(len(parts) - 1):
                d = "/".join(parts[: i + 1])
                if d not in seen:
                    seen.add(d)
                    lines.append("  " * i + parts[i] + "/")
            lines.append("  " * (len(parts) - 1) + parts[-1])
        if len(lines) > max_lines:
            lines = lines[:max_lines] + [f"... ({len(lines) - max_lines} satir daha)"]
        return "\n".join(lines)

    def info(self):
        return {
            "root": str(self.root),
            "name": self.root.name,
            "files": len(self.files),
            "chars": sum(len(f["text"]) for f in self.files.values()),
            "stack": self.stack(),
            "truncated": self.truncated,
        }

    # ------------------------------------------------------------------ arama

    def search(self, query, k1=1.4, b=0.75):
        terms = set(tokenize(query))
        if not terms:
            return []
        n = len(self.chunks)
        scores = []
        for i, (rel, s, e, tf) in enumerate(self.chunks):
            length = sum(tf.values()) or 1
            score = 0.0
            for t in terms:
                c = tf.get(t)
                if not c:
                    continue
                idf = math.log(1 + (n - self.df[t] + 0.5) / (self.df[t] + 0.5))
                score += idf * c * (k1 + 1) / (c + k1 * (1 - b + b * length / self.avg_len))
            if score > 0:
                scores.append((score, i))
        scores.sort(reverse=True)
        if not scores:
            return []
        floor = scores[0][0] * 0.2  # en iyi sonuca gore cok zayif eslesmeleri at
        return [(sc, self.chunks[i]) for sc, i in scores if sc >= floor]

    def mentioned_files(self, text):
        """Mesajdaki @yol veya tam dosya adlarini (UserController.php) bulur."""
        out = []
        for m in re.findall(r"@([\w./\\-]+)", text):
            m = m.replace("\\", "/").strip("./")
            hit = m if m in self.files else next((r for r in self.files if r.endswith("/" + m)), None)
            if hit and hit not in out:
                out.append(hit)
        for name in re.findall(r"\b[\w-]+\.(?:php|java|py|kt|js|ts|xml|yml|yaml|json|sql|twig|vue)\b", text):
            hits = [r for r in self.files if r.split("/")[-1] == name]
            if len(hits) == 1 and hits[0] not in out:
                out.append(hits[0])
        return out

    def build_context(self, query, budget_chars, extra_terms=""):
        """Modele verilecek proje baglamini ve kullanilan dosya listesini dondurur."""
        with self.lock:
            info = self.info()
            head = [f"# Acik proje: {info['name']}  ({info['root']})",
                    f"Teknolojiler: {', '.join(info['stack']) or 'bilinmiyor'}",
                    f"Dosya sayisi: {info['files']}", "", "## Klasor yapisi", "```", self.tree(), "```"]
            head = "\n".join(head)
            budget = budget_chars - len(head)
            sections, used = [], []

            def add(rel, body, start=None, end=None):
                nonlocal budget
                ext = rel.rsplit(".", 1)[-1] if "." in rel else ""
                label = rel if start is None else f"{rel} (satir {start + 1}-{end})"
                block = f"### {label}\n```{ext}\n{body}\n```"
                if len(block) > budget:
                    return False
                sections.append(block)
                budget -= len(block)
                if rel not in used:
                    used.append(rel)
                return True

            # 1) Kucuk proje: hepsi sigiyorsa tum dosyalar.
            if info["chars"] + 200 * len(self.files) < budget:
                for rel in sorted(self.files):
                    add(rel, self.files[rel]["text"])
                return head + "\n\n## Projedeki tum dosyalar\n" + "\n\n".join(sections), used, True

            # 2) Kullanicinin adini verdigi dosyalar (tam hali, cok buyukse ilk kismi).
            for rel in self.mentioned_files(query):
                text = self.files[rel]["text"]
                limit = int(budget * 0.6)
                add(rel, text if len(text) <= limit else text[:limit] + "\n... (kesildi)")

            # 3) Ozet sorulari icin anahtar dosyalar.
            if re.search(r"\b(ozet|özet|yapı|yapi|mimari|ne yapıyor|ne yapiyor|açıkla|acikla|overview|structure)", query, re.I):
                for name in KEY_FILES:
                    if name in self.files and name not in used:
                        add(name, self.files[name]["text"][:2500])

            # 4) Arama sonuclari: dosya bazinda grupla, kucuk dosyalari tam ver.
            picked = defaultdict(list)
            for score, (rel, s, e, _) in self.search(query + " " + extra_terms)[:40]:
                if rel in used and not picked.get(rel):
                    continue
                picked[rel].append((s, e))
            for rel, ranges in picked.items():
                if budget < 500:
                    break
                lines = self.files[rel]["lines"]
                text = self.files[rel]["text"]
                if len(text) <= 5000:
                    add(rel, text)
                    continue
                for s, e in sorted(ranges):
                    s2, e2 = max(0, s - 5), min(len(lines), e + 5)
                    add(rel, "\n".join(lines[s2:e2]), s2, e2)

        body = "\n\n".join(sections) if sections else "(Soruyla eslesen kod bulunamadi.)"
        return head + "\n\n## Soruyla ilgili kod\n" + body, used, False
