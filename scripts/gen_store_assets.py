"""Generate Play Store assets from the v4 icon:
- 512×512 app icon (Play Store listing requires exactly 512)
- 1024×500 feature graphic (Play Store header banner)

Output to docs/store-assets/.
"""
from PIL import Image, ImageDraw, ImageFilter, ImageFont
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "assets" / "icon" / "icon.png"
OUT = ROOT / "docs" / "store-assets"
OUT.mkdir(parents=True, exist_ok=True)

BG = (236, 232, 225)          # #ECE8E1
CAP_LEFT = (184, 111, 64)     # #B86F40
CAP_RIGHT = (245, 240, 230)   # #F5F0E6
CAP_OUTLINE = (110, 60, 28)   # #6E3C1C
TEXT_DARK = (66, 42, 22)
TEXT_MED = (110, 84, 60)


def gen_icon_512() -> None:
    src = Image.open(SRC).convert("RGB")
    icon = src.resize((512, 512), Image.LANCZOS)
    icon.save(OUT / "icon_512.png", "PNG", optimize=True)
    print(f"wrote {OUT / 'icon_512.png'}")


def _try_font(size: int) -> ImageFont.FreeTypeFont:
    candidates = [
        "C:/Windows/Fonts/malgunbd.ttf",
        "C:/Windows/Fonts/malgun.ttf",
        "C:/Windows/Fonts/NanumGothicBold.ttf",
        "C:/Windows/Fonts/NotoSansKR-Bold.otf",
        "C:/Windows/Fonts/arial.ttf",
    ]
    for p in candidates:
        try:
            return ImageFont.truetype(p, size)
        except OSError:
            continue
    return ImageFont.load_default()


def gen_feature_graphic() -> None:
    W, H = 1024, 500
    img = Image.new("RGB", (W, H), BG)
    d = ImageDraw.Draw(img, "RGBA")

    # 좌측 1/3 영역에 캡슐 — 미니멀 통일감
    cap_w, cap_h = 360, 150
    cx = 220
    cy = H // 2 + 10
    x0, y0 = cx - cap_w // 2, cy - cap_h // 2
    x1, y1 = cx + cap_w // 2, cy + cap_h // 2
    radius = cap_h // 2

    # 그림자
    shadow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    sd.rounded_rectangle((x0 + 6, y0 + 16, x1 + 6, y1 + 16),
                         radius=radius, fill=(0, 0, 0, 50))
    shadow = shadow.filter(ImageFilter.GaussianBlur(10))
    img.paste(shadow, (0, 0), shadow)

    d = ImageDraw.Draw(img, "RGBA")
    # 캡슐
    d.rounded_rectangle((x0, y0, x1, y1), radius=radius, fill=CAP_LEFT)
    d.rectangle((cx, y0, x1 - radius, y1), fill=CAP_RIGHT)
    d.pieslice((x1 - 2 * radius, y0, x1, y1), start=-90, end=90, fill=CAP_RIGHT)
    d.rounded_rectangle((x0, y0, x1, y1), radius=radius,
                        outline=CAP_OUTLINE, width=3)

    # 우측 텍스트
    title_font = _try_font(64)
    sub_font = _try_font(32)
    tagline = "KYH 약 알림"
    sub = "한 알도, 잊지 않게."
    sub2 = "어르신 약 알림 + 자녀 모니터링"

    tx = 460
    ty = 130
    d.text((tx, ty), tagline, font=title_font, fill=TEXT_DARK)
    d.text((tx, ty + 90), sub, font=sub_font, fill=TEXT_DARK)
    d.text((tx, ty + 140), sub2, font=sub_font, fill=TEXT_MED)

    img.save(OUT / "feature_graphic_1024x500.jpg", "JPEG",
             quality=92, optimize=True)
    print(f"wrote {OUT / 'feature_graphic_1024x500.jpg'}")


if __name__ == "__main__":
    gen_icon_512()
    gen_feature_graphic()
