#!/usr/bin/env python3
"""Alan adı için DNS / OSINT tabanlı e-posta ve alt alan kaynakları.

email_spider.py'nin web taramasına ek olarak, adres içermesi muhtemel
meşru kaynakları tarar:

  * DNS TXT / SPF / DMARC kayıtları  (DNS-over-HTTPS ile, ek paket gerekmez)
  * /.well-known/security.txt ve /security.txt
  * RDAP/WHOIS kayıt sahibi + abuse iletişim adresleri
  * crt.sh sertifika şeffaflık kayıtlarından alt alan keşfi (taramaya tohum)

Hiçbiri posta sunucusunu "yoklamaz" (SMTP VRFY/RCPT yok); yalnızca herkese
açık DNS ve HTTPS kaynaklarını okur.

Sadece Python 3 standart kütüphanesini kullanır.
"""

from __future__ import annotations

import json
import ssl
import urllib.error
import urllib.parse
import urllib.request

try:  # modül olarak da, tek başına da çalışsın
    from email_spider import USER_AGENT, extract_emails, normalize_email
except ImportError:  # pragma: no cover
    from .email_spider import USER_AGENT, extract_emails, normalize_email  # type: ignore

DOH_ENDPOINT = "https://dns.google/resolve"
RDAP_ENDPOINT = "https://rdap.org/domain/"
CRTSH_ENDPOINT = "https://crt.sh/"

_SSL_CTX = ssl.create_default_context()  # SSL_CERT_FILE / proxy CA'yı ortamdan okur


def _http_json(url: str, timeout: float, accept: str = "application/json"):
    """HTTPS üzerinden JSON getirir; hata olursa None döner."""
    req = urllib.request.Request(
        url, headers={"User-Agent": USER_AGENT, "Accept": accept}
    )
    try:
        with urllib.request.urlopen(req, timeout=timeout, context=_SSL_CTX) as resp:
            raw = resp.read(4 * 1024 * 1024)
        return json.loads(raw.decode("utf-8", errors="replace"))
    except (urllib.error.URLError, OSError, ValueError, json.JSONDecodeError):
        return None


# --- DNS-over-HTTPS -------------------------------------------------------

_DNS_TYPES = {"TXT": 16, "MX": 15, "A": 1}


def doh_records(name: str, rtype: str, timeout: float) -> list[str]:
    """Bir DNS kaydının değerlerini döner (TXT için tırnaklar temizlenir)."""
    q = urllib.parse.urlencode({"name": name, "type": rtype})
    data = _http_json(f"{DOH_ENDPOINT}?{q}", timeout, accept="application/dns-json")
    out: list[str] = []
    if not data or data.get("Status") != 0:
        return out
    want = _DNS_TYPES.get(rtype)
    for ans in data.get("Answer", []):
        if want is not None and ans.get("type") != want:
            continue
        val = (ans.get("data") or "").strip()
        if rtype == "TXT":
            # TXT verisi tırnaklı ve parçalı olabilir: "v=spf1 ..." "...devam"
            val = "".join(seg.strip('"') for seg in _split_txt(val))
        out.append(val)
    return out


def _split_txt(data: str) -> list[str]:
    parts, buf, in_q = [], [], False
    for ch in data:
        if ch == '"':
            in_q = not in_q
            buf.append(ch)
        elif ch == " " and not in_q:
            if buf:
                parts.append("".join(buf))
                buf = []
        else:
            buf.append(ch)
    if buf:
        parts.append("".join(buf))
    return parts or [data]


def collect_dns_txt(domain: str, timeout: float) -> dict[str, set[str]]:
    """TXT, SPF ve DMARC kayıtlarından e-posta çıkarır."""
    found: dict[str, set[str]] = {}

    def add(emails: set[str], label: str) -> None:
        for e in emails:
            found.setdefault(e, set()).add(label)

    for rec in doh_records(domain, "TXT", timeout):
        add(extract_emails(rec), f"DNS:TXT({domain})")
    for rec in doh_records(f"_dmarc.{domain}", "TXT", timeout):
        # rua=mailto:dmarc@..., ruf=mailto:...
        add(extract_emails(rec.replace("mailto:", " ")), f"DNS:DMARC({domain})")
    return found


# --- security.txt ---------------------------------------------------------

def collect_security_txt(fetch, domain: str) -> dict[str, set[str]]:
    """RFC 9116 security.txt dosyalarındaki Contact adreslerini toplar.

    `fetch` spider'ın fetch metodu (robots + throttle'a uyar).
    """
    found: dict[str, set[str]] = {}
    for base in (f"https://{domain}", f"https://www.{domain}"):
        for path in ("/.well-known/security.txt", "/security.txt"):
            try:
                body, _, _ = fetch(base + path)
            except Exception:
                continue
            if not body:
                continue
            for e in extract_emails(body.replace("mailto:", " ")):
                found.setdefault(e, set()).add("security.txt")
    return found


# --- RDAP / WHOIS ---------------------------------------------------------

def _walk_vcard(entity, out: set[str]) -> None:
    """RDAP entity ağacındaki vcard e-postalarını toplar."""
    if isinstance(entity, dict):
        vcard = entity.get("vcardArray")
        if isinstance(vcard, list) and len(vcard) == 2:
            for field in vcard[1]:
                if isinstance(field, list) and len(field) >= 4 and field[0] == "email":
                    val = field[3]
                    if isinstance(val, str):
                        n = normalize_email(val)
                        if n:
                            out.add(n)
        for sub in entity.get("entities", []) or []:
            _walk_vcard(sub, out)


def collect_rdap(domain: str, timeout: float) -> dict[str, set[str]]:
    """RDAP (modern WHOIS) üzerinden kayıt sahibi / abuse adreslerini toplar."""
    data = _http_json(RDAP_ENDPOINT + urllib.parse.quote(domain), timeout)
    if not data:
        return {}
    emails: set[str] = set()
    for ent in data.get("entities", []) or []:
        _walk_vcard(ent, emails)
    return {e: {"RDAP/WHOIS"} for e in emails}


# --- crt.sh alt alan keşfi ------------------------------------------------

def discover_subdomains(domain: str, timeout: float, limit: int = 200) -> set[str]:
    """crt.sh sertifika kayıtlarından alt alan adlarını bulur (taramaya tohum)."""
    q = urllib.parse.urlencode({"q": f"%.{domain}", "output": "json"})
    data = _http_json(f"{CRTSH_ENDPOINT}?{q}", timeout)
    subs: set[str] = set()
    if not isinstance(data, list):
        return subs
    for row in data:
        for name in (row.get("name_value") or "").splitlines():
            name = name.strip().lstrip("*.").lower()
            if name and (name == domain or name.endswith("." + domain)) and "@" not in name:
                subs.add(name)
            if len(subs) >= limit:
                return subs
    return subs


# --- hepsini bir arada ----------------------------------------------------

def collect_all(fetch, domain: str, timeout: float, want_subdomains: bool):
    """Tüm DNS/OSINT kaynaklarını çalıştırır.

    Döner: (emails: dict[email -> set[label]], seed_hosts: set[str])
    """
    emails: dict[str, set[str]] = {}

    def merge(part: dict[str, set[str]]) -> None:
        for e, labels in part.items():
            emails.setdefault(e, set()).update(labels)

    merge(collect_dns_txt(domain, timeout))
    merge(collect_security_txt(fetch, domain))
    merge(collect_rdap(domain, timeout))

    seed_hosts: set[str] = set()
    if want_subdomains:
        seed_hosts = discover_subdomains(domain, timeout)
    return emails, seed_hosts
