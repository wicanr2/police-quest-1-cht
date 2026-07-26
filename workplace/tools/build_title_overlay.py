#!/usr/bin/env python3
"""Render the PQ1 Traditional Chinese title into AGI or SCI overlay format."""
from pathlib import Path
import argparse, struct
from PIL import Image, ImageDraw, ImageFont

EGA = [(0,0,0),(0,0,170),(0,170,0),(0,170,170),(170,0,0),(170,0,170),(170,85,0),(170,170,170),
       (85,85,85),(85,85,255),(85,255,85),(85,255,255),(255,85,85),(255,85,255),(255,255,85),(255,255,255)]

def nearest(rgb):
    return min(range(16), key=lambda i: sum((rgb[j] - EGA[i][j]) ** 2 for j in range(3)))

ap = argparse.ArgumentParser()
ap.add_argument("format", choices=("agi", "sci"))
ap.add_argument("output", type=Path)
ap.add_argument("--text", default="警察故事 1  追捕死亡天使")
ap.add_argument("--font", default="/usr/share/fonts/truetype/arphic/uming.ttc")
ap.add_argument("--face", type=int, default=2)
ap.add_argument("--size", type=int, default=30)
ap.add_argument("--y", type=int, default=320)
a = ap.parse_args()

font = ImageFont.truetype(a.font, a.size, index=a.face)
tmp = Image.new("RGB", (10, 10)); d = ImageDraw.Draw(tmp)
b = d.textbbox((0, 0), a.text, font=font)
pad = 8
w, h = b[2] - b[0] + pad * 2, b[3] - b[1] + pad * 2
img = Image.new("RGB", (w, h), (0, 0, 0)); mask = Image.new("1", (w, h), 0)
d = ImageDraw.Draw(img); m = ImageDraw.Draw(mask)
x, y = pad - b[0], pad - b[1]
d.rounded_rectangle((0, 0, w - 1, h - 1), radius=5, fill=(0, 0, 0))
m.rounded_rectangle((0, 0, w - 1, h - 1), radius=5, fill=1)
d.text((x + 1, y + 1), a.text, font=font, fill=(170, 85, 0))
d.text((x, y), a.text, font=font, fill=(255, 255, 85))
data = bytearray(0xFF if not mask.getpixel((xx, yy)) else nearest(img.getpixel((xx, yy)))
                   for yy in range(h) for xx in range(w))
ox = (640 - w) // 2; oy = a.y
if a.format == "agi":
    a.output.write_bytes(b"CHTO" + bytes((1, 0)) + struct.pack(">HHHH", ox, oy, w, h) + data)
else:
    a.output.write_bytes(struct.pack("<HHHH", w, h, ox, oy) + data)
print(f"{a.format} title overlay: {w}x{h} @ {ox},{oy} -> {a.output}")
