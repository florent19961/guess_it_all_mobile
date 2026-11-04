#!/usr/bin/env python3
"""Génère le logo « Bulle chrono » et ses déclinaisons (icône, splash).

Géométrie = le SVG validé par Florent le 2026-11-04 (canevas 1024×1024),
rendue en 4× puis réduite en LANCZOS pour l'anticrénelage.

Usage : python3 scripts/render_logo.py   (depuis la racine du repo)
Sorties dans visuals/ :
  logo_bulle_chrono.png             1024 opaque (icône iOS / launcher, sans alpha)
  logo_bulle_chrono_foreground.png  1024 transparent, dans la zone sûre 66/108 (adaptive icon Android)
  logo_bulle_chrono_splash.png      768 transparent (splash 4x : iOS + Android < 12)
  logo_bulle_chrono_android12.png   1152 transparent, dans le cercle de 768 (splash Android 12+)
"""

import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "visuals"
FONT = ROOT / "assets" / "fonts" / "Bangers-Regular.ttf"

NAVY = (0x2B, 0x38, 0x48)
TEAL = (0x7D, 0xD3, 0xC0)
PINK = (0xF1, 0x9B, 0x9B)
WHITE = (255, 255, 255)

SS = 4  # suréchantillonnage
N = 1024 * SS


def p(v):
    return v * SS


def layer():
    return Image.new("RGBA", (N, N), (0, 0, 0, 0))


def circle(draw, cx, cy, r, fill):
    draw.ellipse((p(cx - r), p(cy - r), p(cx + r), p(cy + r)), fill=fill)


def artwork():
    """Le logo sans fond, transparent, en 4096×4096."""
    img = layer()
    cx = cy = 512
    r, w = 345, 58
    box = (p(cx - r - w / 2), p(cy - r - w / 2), p(cx + r + w / 2), p(cy + r + w / 2))

    # Piste de l'anneau : teal à 22 %.
    track = layer()
    ImageDraw.Draw(track).ellipse(box, outline=TEAL + (round(255 * 0.22),), width=p(w))
    img.alpha_composite(track)

    # Arc 270° horaire, du haut (512,167) jusqu'à la gauche (167,512), bouts ronds.
    d = ImageDraw.Draw(img)
    d.arc(box, start=-90, end=180, fill=TEAL + (255,), width=p(w))
    circle(d, 512, 167, w / 2, TEAL)
    circle(d, 167, 512, w / 2, TEAL)

    # Point en haut.
    circle(d, 512, 167, 44, TEAL)

    # Bulle rose + queue (triangle avec contour arrondi de 18 px).
    circle(d, 512, 490, 215, PINK)
    tail = [(475, 632), (368, 748), (377, 615)]
    pts = [(p(x), p(y)) for x, y in tail]
    d.polygon(pts, fill=PINK)
    d.line(pts + [pts[0]], fill=PINK, width=p(18), joint="curve")
    for x, y in tail:
        circle(d, x, y, 9, PINK)

    # « ? » Bangers 300 px, centré sur x=512, ligne de base y=600, tourné de -6° autour de (512,600).
    q = layer()
    font = ImageFont.truetype(str(FONT), p(300))
    ImageDraw.Draw(q).text((p(512), p(600)), "?", font=font, fill=WHITE + (255,), anchor="ms")
    # SVG rotate(-6) = anti-horaire à l'écran ; PIL rotate(+angle) = anti-horaire.
    q = q.rotate(6, resample=Image.BICUBIC, center=(p(512), p(600)))
    img.alpha_composite(q)
    return img


def radius(img):
    """Rayon (en unités du canevas 1024) du plus petit cercle centré contenant le dessin."""
    small = img.getchannel("A").resize((1024, 1024), Image.BOX)
    px = small.load()
    rmax = 0.0
    for y in range(1024):
        for x in range(1024):
            if px[x, y] > 8:
                rmax = max(rmax, math.hypot(x + 0.5 - 512, y + 0.5 - 512))
    return rmax


def place(art, size, scale, bg=None):
    """Pose `art` (canevas 1024 en 4x) réduit de `scale`, centré sur un canevas `size`."""
    canvas = Image.new("RGBA", (size * SS, size * SS), (bg + (255,)) if bg else (0, 0, 0, 0))
    side = round(N * scale)
    a = art.resize((side, side), Image.LANCZOS)
    off = (size * SS - side) // 2
    canvas.alpha_composite(a, (off, off))
    return canvas.resize((size, size), Image.LANCZOS)


def main():
    art = artwork()
    r = radius(art)
    print(f"rayon du dessin : {r:.1f} px (canevas 1024)")

    # Icône iOS / launcher : opaque, sans canal alpha (exigence App Store).
    place(art, 1024, 1.0, NAVY).convert("RGB").save(OUT / "logo_bulle_chrono.png")

    # Adaptive icon Android : canevas 108 dp, zone sûre = cercle de 66 dp.
    safe = 1024 * 66 / 108 / 2
    place(art, 1024, 0.97 * safe / r).save(OUT / "logo_bulle_chrono_foreground.png")

    # Splash iOS + Android < 12 : image 4x (768 px ≈ 192 pt), fond = couleur du splash.
    place(art, 768, 0.75).save(OUT / "logo_bulle_chrono_splash.png")

    # Splash Android 12+ sans fond d'icône : 1152×1152, dessin dans un cercle de 768 de diamètre.
    place(art, 1152, 0.97 * 384 / r).save(OUT / "logo_bulle_chrono_android12.png")


if __name__ == "__main__":
    main()
