"""Modelin onerdigi degisiklikleri proje dosyalarina guvenli sekilde uygular.

Iki bicim desteklenir (kod blogunun ilk satiri ```php:app/Foo.php gibi dosya yolunu tasir):

1) Tam dosya: blok, dosyanin yeni tam icerigidir (yeni dosyalar ve kucuk dosyalar icin).

2) Ara / degistir: buyuk dosyalarda sadece degisen kisim verilir.
       <<<<<<< ARA
       eski kod
       =======
       yeni kod
       >>>>>>> DEGISTIR
   Bir blokta birden fazla ARA/DEGISTIR cifti olabilir.

Her yazmadan once eski hali ~/.bulut/yedekler altina kopyalanir ve geri alinabilir.
"""

import difflib
import fnmatch
import hashlib
import re
import time
from pathlib import Path

from proje import IGNORE_DIRS, SECRET_PATTERNS

BACKUP_ROOT = Path.home() / ".bulut" / "yedekler"

EDIT_RE = re.compile(
    r"^<{5,9} ?ARA[^\n]*\n(.*?)^={5,9}[^\n]*\n(.*?)^>{5,9} ?DE[GĞ][Iİ][SŞ]T[Iİ]R[^\n]*$",
    re.S | re.M,
)
# Modelin "kodun geri kalani ayni" diye kisalttigi yerler: tam dosya yazilirsa kod kaybolur.
PLACEHOLDER_RE = re.compile(
    r"^\s*(//|#|/\*|\*|<!--)\s*\.{3}|"
    r"(mevcut kod|geri kalan|diger metodlar|diğer metodlar|existing code|rest of (the )?(code|file|class)|"
    r"unchanged|ayni kalacak|aynı kalacak)",
    re.I | re.M,
)

# Modelin ```php:yol/dosya.php veya ```php yol/dosya.php bicimindeki bloklari
BLOCK_RE = re.compile(r"```([\w+#-]*)[ :]([^\s`]+\.[\w]+|[^\s`]*Dockerfile|[^\s`]*Makefile)[ \t]*\n(.*?)```", re.S)


def parse_blocks(answer):
    """Cevaptaki dosya yollu kod bloklarini [(yol, icerik), ...] olarak dondurur."""
    return [(m.group(2).strip().lstrip("./"), m.group(3)) for m in BLOCK_RE.finditer(answer)]


def safe_path(project, rel):
    """Yolu proje icinde tutar; .git, gizli dosya ve atlanan klasorlere yazmayi reddeder."""
    rel = (rel or "").replace("\\", "/").strip()
    if not rel or rel.startswith("~"):
        raise ValueError("Gecersiz dosya yolu.")
    if rel.startswith("/") or re.match(r"^[A-Za-z]:", rel):
        # Mutlak yol: sadece proje klasorunun icini gosteriyorsa kabul et.
        target = Path(rel).resolve()
    else:
        target = (project.root / rel).resolve()
    try:
        rel_norm = target.relative_to(project.root).as_posix()
    except ValueError:
        raise ValueError("Proje klasoru disina yazilamaz.") from None
    parts = rel_norm.split("/")
    if any(p in IGNORE_DIRS or p == ".git" for p in parts[:-1]):
        raise ValueError(f"Bu klasore yazilmaz: {rel_norm}")
    name = parts[-1]
    if name != ".env.example" and any(fnmatch.fnmatch(name, p) for p in SECRET_PATTERNS):
        raise ValueError(f"Gizli bilgi dosyasina yazilmaz: {name}")
    return target, rel_norm


def _find(old, search):
    """Aranan metni once birebir, sonra satir basi/sonu bosluklarini yok sayarak bulur."""
    i = old.find(search)
    if i != -1:
        return i, i + len(search)
    old_lines = old.splitlines(keepends=True)
    want = [l.strip() for l in search.strip("\n").splitlines()]
    if not want:
        return None
    for s in range(len(old_lines) - len(want) + 1):
        if [l.strip() for l in old_lines[s:s + len(want)]] == want:
            start = sum(len(l) for l in old_lines[:s])
            end = start + sum(len(l) for l in old_lines[s:s + len(want)])
            if old_lines[s + len(want) - 1].endswith("\n") and not search.endswith("\n"):
                end -= 1
            return start, end
    return None


def compute(project, rel, content):
    """Yeni dosya icerigini ve uyarilari hesaplar. Dosyaya yazmaz."""
    target, rel = safe_path(project, rel)
    exists = target.is_file()
    old = target.read_bytes().decode("utf-8", errors="replace") if exists else ""
    crlf = "\r\n" in old
    old_n = old.replace("\r\n", "\n")
    content = content.replace("\r\n", "\n")
    warnings = []

    edits = EDIT_RE.findall(content)
    if edits:
        if not exists:
            raise ValueError(f"{rel} bulunamadi; ARA/DEGISTIR sadece var olan dosyada kullanilabilir.")
        new = old_n
        for n, (search, replace) in enumerate(edits, 1):
            pos = _find(new, search)
            if pos is None:
                raise ValueError(f"{n}. degisiklikte aranan kod {rel} icinde bulunamadi. "
                                 "Modelden dosyanin guncel halini kullanmasini isteyin.")
            rep = replace.rstrip("\n")
            if rep and search.endswith("\n"):
                rep += "\n"
            new = new[:pos[0]] + rep + new[pos[1]:]
    else:
        new = content if content.endswith("\n") else content + "\n"
        if exists and PLACEHOLDER_RE.search(new) and not PLACEHOLDER_RE.search(old_n):
            warnings.append("Model kodun bir kismini '...' / 'mevcut kod' gibi ifadelerle kisaltmis olabilir. "
                            "Uygularsaniz o kisimlar silinir!")
        if exists and len(old_n) > 400 and len(new) < len(old_n) * 0.5:
            warnings.append(f"Yeni icerik eskisinin yarisindan kisa ({len(new)} / {len(old_n)} karakter). "
                            "Silinen kod olabilir, fark ekranini dikkatle inceleyin.")

    if crlf:
        new = new.replace("\n", "\r\n")
    diff = "".join(difflib.unified_diff(
        old_n.splitlines(keepends=True), new.replace("\r\n", "\n").splitlines(keepends=True),
        fromfile=f"a/{rel}" if exists else "/dev/null", tofile=f"b/{rel}", n=3,
    ))
    return {"path": rel, "new_file": not exists, "diff": diff, "warnings": warnings,
            "changed": new != old, "_target": target, "_new": new}


class Applier:
    """Yazma ve geri alma (son yazilandan baslayarak)."""

    def __init__(self, project):
        self.project = project
        key = hashlib.sha1(str(project.root).encode()).hexdigest()[:10]
        self.backup_dir = BACKUP_ROOT / f"{project.root.name}-{key}"
        self.history = []  # [(target, rel, yedek_yolu veya None)]

    def preview(self, rel, content):
        r = compute(self.project, rel, content)
        return {k: v for k, v in r.items() if not k.startswith("_")}

    def apply(self, rel, content):
        r = compute(self.project, rel, content)
        if not r["changed"]:
            return {"ok": True, "path": r["path"], "message": "Degisiklik yok, dosya zaten ayni."}
        target = r["_target"]
        backup = None
        if target.exists():
            backup = self.backup_dir / time.strftime("%Y%m%d-%H%M%S") / f"{len(self.history)}_{r['path']}"
            backup.parent.mkdir(parents=True, exist_ok=True)
            backup.write_bytes(target.read_bytes())
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(r["_new"].encode("utf-8"))
        self.history.append((target, r["path"], backup))
        self.project.refresh()
        return {"ok": True, "path": r["path"], "new_file": r["new_file"],
                "backup": str(backup) if backup else None, "undo_count": len(self.history)}

    def undo(self):
        if not self.history:
            return {"ok": False, "error": "Geri alinacak degisiklik yok."}
        target, rel, backup = self.history.pop()
        if backup:
            target.write_bytes(backup.read_bytes())
            msg = f"{rel} eski haline dondu."
        else:
            target.unlink(missing_ok=True)
            msg = f"Yeni olusturulan {rel} silindi."
        self.project.refresh()
        return {"ok": True, "path": rel, "message": msg, "undo_count": len(self.history)}
