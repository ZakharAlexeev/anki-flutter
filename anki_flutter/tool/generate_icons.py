"""Draws the Anki app icon ("deck": two fanned cards) and writes every
platform asset from it.

    python tool/generate_icons.py

Outputs:
  ios/Runner/Assets.xcassets/AppIcon.appiconset/  light, dark and tinted
      1024x1024 icons (iOS 18 home-screen appearances) + Contents.json
  windows/runner/resources/app_icon.ico           16-256 px, rounded corners

Geometry is written in a 100x100 design space (the same one the SVG
mock-ups used) and drawn at 2x the output size, then downsampled, so edges
come out anti-aliased.
"""

import json
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parent.parent
IOS_DIR = ROOT / "ios" / "Runner" / "Assets.xcassets" / "AppIcon.appiconset"
ICO_PATH = ROOT / "windows" / "runner" / "resources" / "app_icon.ico"

SIZE = 1024
SS = 2  # supersampling factor
W = SIZE * SS
U = W / 100  # one design unit in pixels

# Colours per appearance. "tinted" is a greyscale master: iOS takes its
# luminance and recolours it with the tint the user picked.
THEMES = {
    "light": dict(
        bg=("#3C9478", "#1D5847"),
        back=("#FFFFFF", 0.35),
        shadow=0.20,
        front=("#FFFFFF", "#EEF3EF"),
        line1="#256653",
        line2="#BFD3C9",
    ),
    "dark": dict(
        bg=("#2C2F2D", "#121413"),
        back=("#6FC2A2", 0.35),
        shadow=0.0,
        front=("#8ED7B9", "#5DB592"),
        line1="#123B2F",
        line2="#2E7A60",
    ),
    "tinted": dict(
        bg=("#3A3A3C", "#151516"),
        back=("#FFFFFF", 0.30),
        shadow=0.0,
        front=("#FFFFFF", "#C9C9CC"),
        line1="#2A2A2C",
        line2="#8E8E93",
    ),
}

# Cards, in design units: (x, y, w, h, corner radius, rotation° clockwise
# about (cx, cy)). The pair is shifted right a little so the fan, which
# leans left, sits optically centred.
SHIFT = 2
BACK = (25 + SHIFT, 25, 38, 50, 8, -12, 44 + SHIFT, 50)
FRONT = (33 + SHIFT, 25, 38, 50, 8, 8, 52 + SHIFT, 50)


def rgb(hex_color):
    h = hex_color.lstrip("#")
    return tuple(int(h[i : i + 2], 16) for i in (0, 2, 4))


def vertical_gradient(size, top, bottom):
    w, h = size
    t, b = rgb(top), rgb(bottom)
    col = Image.new("RGB", (1, h))
    for y in range(h):
        f = y / max(1, h - 1)
        col.putpixel((0, y), tuple(round(t[i] + (b[i] - t[i]) * f) for i in range(3)))
    return col.resize((w, h))


# The whole glyph is scaled about the icon centre so it fills ~60% of the
# canvas, like Apple's own icons.
K = 1.12


def px(v):
    """Design coordinate -> pixels, with the glyph scale applied."""
    return (50 + (v - 50) * K) * U


def box(x, y, w, h):
    return [px(x), px(y), px(x + w), px(y + h)]


def rounded_mask(x, y, w, h, r):
    mask = Image.new("L", (W, W), 0)
    ImageDraw.Draw(mask).rounded_rectangle(box(x, y, w, h), radius=r * K * U, fill=255)
    return mask


def rotate(layer, angle, cx, cy):
    # PIL rotates counter-clockwise; the design angles are clockwise (SVG).
    return layer.rotate(-angle, resample=Image.BICUBIC, center=(px(cx), px(cy)))


def draw_icon(theme):
    t = THEMES[theme]
    canvas = vertical_gradient((W, W), *t["bg"]).convert("RGBA")

    # Back card: a translucent silhouette.
    x, y, w, h, r, a, cx, cy = BACK
    color, alpha = t["back"]
    back = Image.new("RGBA", (W, W), rgb(color) + (0,))
    back.putalpha(rounded_mask(x, y, w, h, r).point(lambda v: round(v * alpha)))
    canvas.alpha_composite(rotate(back, a, cx, cy))

    x, y, w, h, r, a, cx, cy = FRONT

    # Soft drop shadow under the front card (light icon only).
    if t["shadow"]:
        shadow = Image.new("RGBA", (W, W), (0, 0, 0, 0))
        m = rounded_mask(x + 1.2, y + 2.5, w, h, r).point(lambda v: round(v * t["shadow"]))
        shadow.putalpha(m)
        shadow = rotate(shadow, a, cx, cy).filter(ImageFilter.GaussianBlur(2.2 * K * U))
        canvas.alpha_composite(shadow)

    # Front card: gradient face with two bars standing for word + translation.
    # The gradient spans the card itself, not the whole canvas.
    x0, y0, x1, y1 = box(x, y, w, h)
    face = vertical_gradient((round(x1 - x0), round(y1 - y0)), *t["front"]).convert("RGBA")
    front = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    front.paste(face, (round(x0), round(y0)))
    front.putalpha(rounded_mask(x, y, w, h, r))
    d = ImageDraw.Draw(front)
    d.rounded_rectangle(box(x + 7, y + 15, 22, 5), radius=2.5 * K * U, fill=rgb(t["line1"]))
    d.rounded_rectangle(box(x + 7, y + 26, 15, 4), radius=2 * K * U, fill=rgb(t["line2"]))
    canvas.alpha_composite(rotate(front, a, cx, cy))

    return canvas.resize((SIZE, SIZE), Image.LANCZOS).convert("RGB")


def with_rounded_corners(img):
    """For platforms that don't mask the icon themselves (Windows)."""
    s = img.size[0]
    mask = Image.new("L", (s * 4, s * 4), 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, s * 4 - 1, s * 4 - 1], radius=s * 4 * 0.224, fill=255)
    out = img.convert("RGBA")
    out.putalpha(mask.resize((s, s), Image.LANCZOS))
    return out


def main():
    icons = {name: draw_icon(name) for name in THEMES}

    # iOS: full-bleed opaque squares - the system applies the corner mask.
    for old in IOS_DIR.glob("*.png"):
        old.unlink()
    files = {
        "light": "AppIcon-1024.png",
        "dark": "AppIcon-1024-dark.png",
        "tinted": "AppIcon-1024-tinted.png",
    }
    for name, filename in files.items():
        icons[name].save(IOS_DIR / filename, optimize=True)

    images = [{"filename": files["light"], "idiom": "universal", "platform": "ios", "size": "1024x1024"}]
    for name in ("dark", "tinted"):
        images.append({
            "appearances": [{"appearance": "luminosity", "value": name}],
            "filename": files[name],
            "idiom": "universal",
            "platform": "ios",
            "size": "1024x1024",
        })
    (IOS_DIR / "Contents.json").write_text(
        json.dumps({"images": images, "info": {"author": "xcode", "version": 1}}, indent=2) + "\n",
        encoding="utf-8",
    )

    # Windows: one .ico holding every common size.
    rounded = with_rounded_corners(icons["light"])
    rounded.save(ICO_PATH, sizes=[(s, s) for s in (16, 24, 32, 48, 64, 128, 256)])

    print("iOS icons ->", IOS_DIR)
    print("Windows icon ->", ICO_PATH)


if __name__ == "__main__":
    main()
