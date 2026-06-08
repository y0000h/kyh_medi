"""Generate v4 launcher icon — minimal single capsule on solid background.

Output: assets/icon/icon.png at 1024×1024.
"""
from PIL import Image, ImageDraw, ImageFilter
from pathlib import Path

SIZE = 1024
BG = (236, 232, 225)          # 베이지 #ECE8E1 (앱 surface와 동일 톤)
CAP_LEFT = (184, 111, 64)     # 주황/테라코타 #B86F40
CAP_RIGHT = (245, 240, 230)   # 따뜻한 아이보리
CAP_OUTLINE = (110, 60, 28)   # 어두운 갈색 외곽
SHEEN = (255, 255, 255, 70)   # 광택 반투명

OUT = Path(__file__).resolve().parents[1] / "assets" / "icon" / "icon.png"


def main() -> None:
    img = Image.new("RGB", (SIZE, SIZE), BG)
    d = ImageDraw.Draw(img, "RGBA")

    # 캡슐 좌표: 중앙, 가로로 누움
    cw = int(SIZE * 0.74)           # 캡슐 폭
    ch = int(SIZE * 0.32)           # 캡슐 높이
    cx = SIZE // 2
    cy = SIZE // 2
    x0 = cx - cw // 2
    y0 = cy - ch // 2
    x1 = cx + cw // 2
    y1 = cy + ch // 2

    # 그림자 (아래쪽 살짝)
    shadow = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    sd.rounded_rectangle(
        (x0 + 10, y0 + 32, x1 + 10, y1 + 32),
        radius=ch // 2,
        fill=(0, 0, 0, 55),
    )
    shadow = shadow.filter(ImageFilter.GaussianBlur(18))
    img.paste(shadow, (0, 0), shadow)

    d = ImageDraw.Draw(img, "RGBA")

    # 캡슐 전체 (왼쪽 색으로 깔고, 오른쪽 반만 다른 색으로 덮음)
    radius = ch // 2
    d.rounded_rectangle((x0, y0, x1, y1), radius=radius, fill=CAP_LEFT)
    # 오른쪽 반: 가운데 사각 + 우측 반원
    d.rectangle((cx, y0, x1 - radius, y1), fill=CAP_RIGHT)
    d.pieslice((x1 - 2 * radius, y0, x1, y1), start=-90, end=90, fill=CAP_RIGHT)

    # 외곽 라인 (얇게)
    d.rounded_rectangle((x0, y0, x1, y1), radius=radius,
                        outline=CAP_OUTLINE, width=4)
    # 중앙 분할선
    d.line((cx, y0 + 4, cx, y1 - 4), fill=CAP_OUTLINE, width=4)

    # 광택(sheen) — 왼쪽 위 1/3 영역에 얇은 타원
    sheen_w = int(cw * 0.42)
    sheen_h = int(ch * 0.22)
    sx = x0 + int(cw * 0.12)
    sy = y0 + int(ch * 0.18)
    d.ellipse((sx, sy, sx + sheen_w, sy + sheen_h), fill=SHEEN)

    OUT.parent.mkdir(parents=True, exist_ok=True)
    img.save(OUT, "PNG", optimize=True)
    print(f"wrote {OUT} ({OUT.stat().st_size:,} bytes, {SIZE}×{SIZE})")


if __name__ == "__main__":
    main()
