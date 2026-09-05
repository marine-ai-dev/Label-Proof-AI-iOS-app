#!/usr/bin/env python3
"""Generates the LabelProof placeholder app icon (1024x1024 PNG).

Requires Pillow: pip install pillow

Run from the repo root:
    python3 scripts/generate_app_icon.py

Writes directly into the AppIcon.appiconset used by the app target.
This is a simple placeholder concept (checkmark-seal + barcode motif on a
teal-to-indigo gradient) — replace with real design artwork before shipping
if desired.
"""
import os
from PIL import Image, ImageDraw

SIZE = 1024
OUTPUT_PATH = os.path.join(
    os.path.dirname(__file__),
    "..",
    "App", "LabelProof", "Resources", "Assets.xcassets",
    "AppIcon.appiconset", "AppIcon-1024.png",
)
img = Image.new("RGB", (SIZE, SIZE), (16, 24, 26))
draw = ImageDraw.Draw(img)

# Gradient background (teal -> deep indigo)
top = (17, 130, 122)
bottom = (25, 33, 60)
for y in range(SIZE):
    t = y / SIZE
    r = int(top[0] * (1 - t) + bottom[0] * t)
    g = int(top[1] * (1 - t) + bottom[1] * t)
    b = int(top[2] * (1 - t) + bottom[2] * t)
    draw.line([(0, y), (SIZE, y)], fill=(r, g, b))

# Rounded "label" card
margin = 200
card_box = [margin, margin + 40, SIZE - margin, SIZE - margin - 40]
draw.rounded_rectangle(card_box, radius=90, fill=(245, 247, 244))

# Checkmark-seal glyph
cx, cy = SIZE // 2, SIZE // 2
r = 210
draw.ellipse([cx - r, cy - r, cx + r, cy + r], outline=(17, 130, 122), width=28)

# Checkmark
draw.line([(cx - 100, cy + 10), (cx - 30, cy + 90), (cx + 120, cy - 100)],
          fill=(17, 130, 122), width=48, joint="curve")

# Small "barcode" strokes under the seal to reference scanning
bar_y0 = cy + r + 60
bar_y1 = bar_y0 + 70
x = cx - 160
widths = [10, 6, 14, 6, 10, 20, 6, 14, 10, 6, 18, 10]
for w in widths:
    draw.rectangle([x, bar_y0, x + w, bar_y1], fill=(30, 40, 38))
    x += w + 14

img.save(OUTPUT_PATH)
print(f"saved {OUTPUT_PATH}")
