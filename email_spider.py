#!/usr/bin/env python3
"""Alan adı e-posta toplayıcı spider.

Verilen alan adının sayfalarını gezer (BFS), sayfalarda geçen e-posta
adreslerini toplar ve hangi sayfada bulunduklarını raporlar.

Sadece Python standart kütüphanesini kullanır.

Örnek:
    python3 email_spider.py ornek.com
    python3 email_spider.py ornek.com --max-pages 500 --depth 4 --subdomains
    python3 email_spider.py ornek.com --only-domain -o sonuc.csv
"""

from __future__ import annotations

import argparse
import csv
import gzip
import html
import json
import re
import sys
import threading
import time
import urllib.error
import urllib.parse
import urllib.request
import urllib.robotparser
import zlib
from collections import deque
from concurrent.futures import ThreadPoolExecutor
from html.parser import HTMLParser

USER_AGENT = "bulut-email-spider/1.0 (+https://github.com/cfatih-sudo/bulut)"

EMAIL_RE = re.compile(
    r"(?<![\w.+-])([a-zA-Z0-9._%+-]{1,64}@(?:[a-zA-Z0-9-]{1,63}\.)+[a-zA-Z]{2,24})(?![\w-])"
)

# "ali [at] ornek [dot] com", "ali(at)ornek.com", "ali at ornek dot com" gibi gizlemeler
_AT = r"\s*(?:\[\s*at\s*\]|\(\s*at\s*\)|\{\s*at\s*\}|\s+at\s+)\s*"
_DOT = r"\s*(?:\[\s*dot\s*\]|\(\s*dot\s*\)|\{\s*dot\s*\}|\s+dot\s+)\s*"
OBFUSCATED_RE = re.compile(
    rf"([a-zA-Z0-9._%+-]{{1,64}}){_AT}([a-zA-Z0-9-]{{1,63}}(?:(?:{_DOT}|\.)[a-zA-Z0-9-]{{1,63}})+)",
    re.IGNORECASE,
)
_DOT_SPLIT_RE = re.compile(_DOT, re.IGNORECASE)

# E-posta gibi görünen ama olmayan şeyler (ör. logo@2x.png)
FILE_EXT_RE = re.compile(
    r"\.(png|jpe?g|gif|svg|webp|bmp|ico|css|js|mjs|map|woff2?|ttf|eot|mp4|webm|pdf)$",
    re.IGNORECASE,
)

SKIP_EXT_RE = re.compile(
    r"\.(png|jpe?g|gif|svg|webp|bmp|ico|css|js|mjs|map|woff2?|ttf|eot|otf|"
    r"mp3|mp4|avi|mov|webm|wav|ogg|zip|rar|7z|gz|tar|exe|dmg|iso|apk|"
    r"pdf|docx?|xlsx?|pptx?)$",
    re.IGNORECASE,
)


class PageParser(HTMLParser):
    """Bağlantıları, mailto adreslerini ve Cloudflare korumalı e-postaları toplar."""

    def __init__(self) -> None:
        super().__init__(convert_charrefs=True)
        self.links: list[str] = []
        self.mailtos: list[str] = []
        self.cf_emails: list[str] = []

    def handle_starttag(self, tag, attrs):
        a = dict(attrs)
        href = a.get("href")
        if href:
            if href.lower().startswith("mailto:"):
                addr = urllib.parse.unquote(href[7:].split("?", 1)[0])
                self.mailtos.extend(x.strip() for x in addr.split(","))
            elif tag in ("a", "area", "link") and not href.startswith(("javascript:", "#", "tel:")):
                self.links.append(href)
        if tag in ("frame", "iframe") and a.get("src"):
            self.links.append(a["src"])
        cf = a.get("data-cfemail")
        if cf:
            decoded = decode_cfemail(cf)
            if decoded:
                self.cf_emails.append(decoded)
        # /cdn-cgi/l/email-protection#<hex>
        if href and "/cdn-cgi/l/email-protection#" in href:
            decoded = decode_cfemail(href.rsplit("#", 1)[1])
            if decoded:
                self.cf_emails.append(decoded)


def decode_cfemail(hexstr: str) -> str | None:
    try:
        data = bytes.fromhex(hexstr)
        key = data[0]
        return "".join(chr(b ^ key) for b in data[1:])
    except (ValueError, IndexError):
        return None


def normalize_email(email: str) -> str | None:
    email = email.strip().strip(".").lower()
    if not EMAIL_RE.fullmatch(email):
        return None
    if FILE_EXT_RE.search(email):
        return None
    local, _, dom = email.partition("@")
    if local.startswith(".") or ".." in email:
        return None
    if dom in ("example.com", "example.org", "domain.com", "email.com", "sentry.io"):
        return None
    return email


def extract_emails(text: str) -> set[str]:
    found: set[str] = set()
    for m in EMAIL_RE.finditer(text):
        e = normalize_email(m.group(1))
        if e:
            found.add(e)
    for m in OBFUSCATED_RE.finditer(text):
        local, dom = m.group(1), _DOT_SPLIT_RE.sub(".", m.group(2))
        e = normalize_email(f"{local}@{dom}")
        if e:
            found.add(e)
    return found


def host_of(url: str) -> str:
    h = (urllib.parse.urlsplit(url).hostname or "").lower()
    return h[4:] if h.startswith("www.") else h


class EmailSpider:
    def __init__(
        self,
        domain: str,
        max_pages: int = 200,
        max_depth: int = 3,
        delay: float = 0.5,
        workers: int = 4,
        timeout: float = 15.0,
        subdomains: bool = False,
        only_domain: bool = False,
        respect_robots: bool = True,
        verbose: bool = False,
    ) -> None:
        domain = domain.strip()
        if "://" not in domain:
            domain = "https://" + domain
        self.start_url = domain.rstrip("/") + "/"
        self.domain = host_of(self.start_url)
        self.max_pages = max_pages
        self.max_depth = max_depth
        self.delay = delay
        self.workers = max(1, workers)
        self.timeout = timeout
        self.subdomains = subdomains
        self.only_domain = only_domain
        self.respect_robots = respect_robots
        self.verbose = verbose

        self.emails: dict[str, set[str]] = {}
        self.seen: set[str] = set()
        self.pages_crawled = 0
        self._lock = threading.Lock()
        self._rate_lock = threading.Lock()
        self._last_request = 0.0
        self._robots: dict[str, urllib.robotparser.RobotFileParser | None] = {}

    # --- yardımcılar -------------------------------------------------------

    def log(self, msg: str) -> None:
        if self.verbose:
            print(msg, file=sys.stderr)

    def in_scope(self, url: str) -> bool:
        h = host_of(url)
        if h == self.domain:
            return True
        return self.subdomains and h.endswith("." + self.domain)

    def email_in_scope(self, email: str) -> bool:
        if not self.only_domain:
            return True
        dom = email.rsplit("@", 1)[1]
        return dom == self.domain or dom.endswith("." + self.domain)

    @staticmethod
    def canonical(url: str) -> str:
        parts = urllib.parse.urlsplit(url)
        path = parts.path or "/"
        return urllib.parse.urlunsplit(
            (parts.scheme.lower(), (parts.netloc or "").lower(), path, parts.query, "")
        )

    def allowed(self, url: str) -> bool:
        if not self.respect_robots:
            return True
        parts = urllib.parse.urlsplit(url)
        base = f"{parts.scheme}://{parts.netloc}"
        if base not in self._robots:
            rp = urllib.robotparser.RobotFileParser()
            try:
                body, _, _ = self.fetch(base + "/robots.txt", check_robots=False)
                rp.parse((body or "").splitlines())
            except Exception:
                rp = None  # robots.txt yoksa her şeye izin ver
            self._robots[base] = rp
        rp = self._robots[base]
        return rp is None or rp.can_fetch(USER_AGENT, url)

    def _throttle(self) -> None:
        with self._rate_lock:
            wait = self._last_request + self.delay - time.monotonic()
            if wait > 0:
                time.sleep(wait)
            self._last_request = time.monotonic()

    def fetch(self, url: str, check_robots: bool = True) -> tuple[str | None, str, str]:
        """(gövde, son_url, content_type) döner. HTML/metin değilse gövde None."""
        if check_robots and not self.allowed(url):
            self.log(f"[robots] atlandı: {url}")
            return None, url, ""
        self._throttle()
        req = urllib.request.Request(
            url,
            headers={
                "User-Agent": USER_AGENT,
                "Accept": "text/html,application/xhtml+xml,text/plain;q=0.9,*/*;q=0.5",
                "Accept-Encoding": "gzip, deflate",
            },
        )
        with urllib.request.urlopen(req, timeout=self.timeout) as resp:
            ctype = resp.headers.get("Content-Type", "")
            final_url = resp.geturl()
            if not any(t in ctype for t in ("text/", "xml", "json")) and ctype:
                return None, final_url, ctype
            raw = resp.read(5 * 1024 * 1024)  # en fazla 5 MB
            enc = resp.headers.get("Content-Encoding", "").lower()
            if enc == "gzip":
                raw = gzip.decompress(raw)
            elif enc == "deflate":
                raw = zlib.decompress(raw)
            charset = resp.headers.get_content_charset() or "utf-8"
            try:
                return raw.decode(charset, errors="replace"), final_url, ctype
            except LookupError:
                return raw.decode("utf-8", errors="replace"), final_url, ctype

    # --- tarama ------------------------------------------------------------

    def process(self, url: str) -> list[str]:
        try:
            body, final_url, ctype = self.fetch(url)
        except (urllib.error.URLError, OSError, ValueError, zlib.error) as exc:
            self.log(f"[hata] {url}: {exc}")
            return []
        if body is None:
            return []
        if not self.in_scope(final_url):  # alan dışına yönlendirme
            return []

        parser = PageParser()
        if "html" in ctype or "<html" in body[:2000].lower():
            try:
                parser.feed(body)
            except Exception:
                pass

        found = extract_emails(html.unescape(body))
        for e in parser.mailtos + parser.cf_emails:
            n = normalize_email(e)
            if n:
                found.add(n)

        with self._lock:
            self.pages_crawled += 1
            for e in found:
                if self.email_in_scope(e):
                    if e not in self.emails:
                        print(f"  + {e}  ({final_url})", file=sys.stderr)
                    self.emails.setdefault(e, set()).add(final_url)

        links = []
        for href in parser.links:
            link = urllib.parse.urljoin(final_url, html.unescape(href))
            if not link.startswith(("http://", "https://")):
                continue
            link = self.canonical(link)
            if self.in_scope(link) and not SKIP_EXT_RE.search(urllib.parse.urlsplit(link).path):
                links.append(link)
        self.log(f"[{self.pages_crawled}] {final_url} -> {len(found)} e-posta, {len(links)} link")
        return links

    def seed_urls(self) -> list[str]:
        """Başlangıç sayfası + iletişim sayfası gibi sık e-posta içeren yollar."""
        base = self.start_url
        paths = ["", "iletisim", "contact", "contact-us", "about", "hakkimizda", "impressum", "kunye"]
        return [self.canonical(urllib.parse.urljoin(base, p)) for p in paths]

    def run(self) -> dict[str, set[str]]:
        queue: deque[tuple[str, int]] = deque()
        for u in self.seed_urls():
            if u not in self.seen:
                self.seen.add(u)
                queue.append((u, 0))

        print(f"Taranıyor: {self.start_url} (en fazla {self.max_pages} sayfa, derinlik {self.max_depth})",
              file=sys.stderr)
        with ThreadPoolExecutor(max_workers=self.workers) as pool:
            while queue and self.pages_crawled < self.max_pages:
                batch = []
                while queue and len(batch) < self.workers * 2:
                    batch.append(queue.popleft())
                results = pool.map(lambda item: (item[1], self.process(item[0])), batch)
                for depth, links in results:
                    if depth >= self.max_depth:
                        continue
                    for link in links:
                        if link not in self.seen and len(self.seen) < self.max_pages * 20:
                            self.seen.add(link)
                            queue.append((link, depth + 1))
        return self.emails


def write_output(emails: dict[str, set[str]], path: str | None) -> None:
    rows = sorted(emails.items())
    if not path:
        for email, _ in rows:
            print(email)
        return
    if path.endswith(".json"):
        with open(path, "w", encoding="utf-8") as f:
            json.dump({e: sorted(s) for e, s in rows}, f, ensure_ascii=False, indent=2)
    elif path.endswith(".csv"):
        with open(path, "w", newline="", encoding="utf-8") as f:
            w = csv.writer(f)
            w.writerow(["email", "sayfa_sayisi", "kaynak_sayfalar"])
            for e, s in rows:
                w.writerow([e, len(s), " ".join(sorted(s))])
    else:
        with open(path, "w", encoding="utf-8") as f:
            f.write("\n".join(e for e, _ in rows) + "\n")
    print(f"Sonuçlar yazıldı: {path}", file=sys.stderr)


def main(argv: list[str] | None = None) -> int:
    p = argparse.ArgumentParser(description="Alan adından e-posta adresi toplayan spider")
    p.add_argument("domain", help="Hedef alan adı veya URL (ör. ornek.com)")
    p.add_argument("--max-pages", type=int, default=200, help="Taranacak en fazla sayfa (varsayılan 200)")
    p.add_argument("--depth", type=int, default=3, help="En fazla link derinliği (varsayılan 3)")
    p.add_argument("--delay", type=float, default=0.5, help="İstekler arası saniye (varsayılan 0.5)")
    p.add_argument("--workers", type=int, default=4, help="Eşzamanlı istek sayısı (varsayılan 4)")
    p.add_argument("--timeout", type=float, default=15.0, help="İstek zaman aşımı, saniye")
    p.add_argument("--subdomains", action="store_true", help="Alt alan adlarını da tara")
    p.add_argument("--only-domain", action="store_true",
                   help="Sadece hedef alan adına ait e-postaları raporla")
    p.add_argument("--ignore-robots", action="store_true", help="robots.txt kurallarını yok say")
    p.add_argument("-o", "--output", help="Çıktı dosyası (.csv, .json veya .txt)")
    p.add_argument("-v", "--verbose", action="store_true", help="Ayrıntılı günlük")
    args = p.parse_args(argv)

    spider = EmailSpider(
        args.domain,
        max_pages=args.max_pages,
        max_depth=args.depth,
        delay=args.delay,
        workers=args.workers,
        timeout=args.timeout,
        subdomains=args.subdomains,
        only_domain=args.only_domain,
        respect_robots=not args.ignore_robots,
        verbose=args.verbose,
    )
    try:
        emails = spider.run()
    except KeyboardInterrupt:
        print("\nDurduruldu, o ana kadar bulunanlar yazılıyor...", file=sys.stderr)
        emails = spider.emails

    print(f"\n{spider.pages_crawled} sayfa tarandı, {len(emails)} benzersiz e-posta bulundu.",
          file=sys.stderr)
    write_output(emails, args.output)
    return 0


if __name__ == "__main__":
    sys.exit(main())
