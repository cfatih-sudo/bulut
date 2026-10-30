"""Bulut simgesini (static/bulut.png ve static/bulut.ico) ek kutuphane olmadan uretir."""
import math
import struct
import zlib
from pathlib import Path

STATIC = Path(__file__).resolve().parent.parent / "static"


def cloud_alpha(x, y):
    """(0..1, 0..1) koordinatinda bulut sekli icin isaretli mesafe (<0 icerde)."""
    circles = [(0.34, 0.58, 0.16), (0.55, 0.46, 0.22), (0.72, 0.60, 0.14)]
    d = min(math.hypot(x - cx, y - cy) - r for cx, cy, r in circles)
    # alt duz kisim
    if 0.34 <= x <= 0.72:
        d = min(d, max(y - 0.74, 0.50 - y))
    return d


def rounded_box(x, y, r=0.2):
    qx, qy = abs(x - 0.5) - (0.5 - r), abs(y - 0.5) - (0.5 - r)
    return math.hypot(max(qx, 0), max(qy, 0)) + min(max(qx, qy), 0) - r


def render(size):
    rows = []
    aa = 1.0 / size
    for j in range(size):
        row = bytearray([0])
        for i in range(size):
            x, y = (i + 0.5) / size, (j + 0.5) / size
            bg = min(max(0.5 - rounded_box(x, y) / aa, 0), 1)
            cl = min(max(0.5 - cloud_alpha(x, y) / aa, 0), 1)
            # mavi gradyan arka plan
            r0, g0, b0 = 47 + 40 * y, 111 + 30 * y, 222 - 20 * y
            r = r0 * (1 - cl) + 255 * cl
            g = g0 * (1 - cl) + 255 * cl
            b = b0 * (1 - cl) + 255 * cl
            row += bytes([int(r), int(g), int(b), int(255 * bg)])
        rows.append(bytes(row))
    raw = b"".join(rows)

    def chunk(tag, data):
        c = struct.pack(">I", len(data)) + tag + data
        return c + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)

    return (b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", size, size, 8, 6, 0, 0, 0))
            + chunk(b"IDAT", zlib.compress(raw, 9)) + chunk(b"IEND", b""))


def main():
    sizes = [16, 32, 48, 256]
    pngs = {s: render(s) for s in sizes}
    (STATIC / "bulut.png").write_bytes(render(128))
    header = struct.pack("<HHH", 0, 1, len(sizes))
    offset = 6 + 16 * len(sizes)
    entries, data = b"", b""
    for s in sizes:
        png = pngs[s]
        entries += struct.pack("<BBBBHHII", s % 256, s % 256, 0, 0, 1, 32, len(png), offset + len(data))
        data += png
    (STATIC / "bulut.ico").write_bytes(header + entries + data)
    print("static/bulut.png ve static/bulut.ico olusturuldu")


if __name__ == "__main__":
    main()
