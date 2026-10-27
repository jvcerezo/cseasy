"""Draw the CSEasy launcher icon (shapes only, no fonts) into app/assets/icon/.

    python pipeline/make_icon.py

icon.png is the full legacy icon; icon_foreground.png is the adaptive-icon
foreground, kept inside the central safe zone on a transparent background.
Also writes the Play Store graphics into docs/store/.
"""

from PIL import Image, ImageDraw

from cseasy_pipeline.paths import REPO

BLUE = (31, 95, 191, 255)
WHITE = (255, 255, 255, 255)
GOLD = (255, 196, 61, 255)
OUT = REPO / "app" / "assets" / "icon"
STORE = REPO / "docs" / "store"
S = 1024


def draw_mark(draw: ImageDraw.ImageDraw, scale: float, cx: float, cy: float) -> None:
    """An answer sheet with three lines and a check mark badge."""
    w, h = 520 * scale, 640 * scale
    left, top = cx - w / 2, cy - h / 2
    draw.rounded_rectangle([left, top, left + w, top + h], radius=56 * scale, fill=WHITE)
    for i in range(3):
        y = top + (150 + i * 120) * scale
        draw.rounded_rectangle(
            [left + 80 * scale, y, left + (80 + 300 - i * 60) * scale, y + 44 * scale],
            radius=22 * scale,
            fill=BLUE,
        )
    # Check badge, overlapping the sheet's lower-right corner.
    r = 170 * scale
    bx, by = left + w - 40 * scale, top + h - 60 * scale
    draw.ellipse([bx - r, by - r, bx + r, by + r], fill=GOLD, outline=WHITE, width=int(28 * scale))
    draw.line(
        [(bx - 80 * scale, by + 5 * scale), (bx - 20 * scale, by + 65 * scale), (bx + 90 * scale, by - 60 * scale)],
        fill=BLUE,
        width=int(48 * scale),
        joint="curve",
    )


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)

    icon = Image.new("RGBA", (S, S), BLUE)
    draw_mark(ImageDraw.Draw(icon), 1.0, S * 0.46, S * 0.48)
    icon.save(OUT / "icon.png")

    # Adaptive icons crop to a circle/squircle: keep the mark within ~60%.
    fg = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    draw_mark(ImageDraw.Draw(fg), 0.62, S * 0.475, S * 0.49)
    fg.save(OUT / "icon_foreground.png")
    # Play Store listing: 512x512 icon and a 1024x500 feature graphic.
    STORE.mkdir(parents=True, exist_ok=True)
    icon.convert("RGB").resize((512, 512), Image.LANCZOS).save(STORE / "play-icon-512.png")
    banner = Image.new("RGBA", (1024, 500), BLUE)
    draw_mark(ImageDraw.Draw(banner), 0.62, 300, 250)
    banner.convert("RGB").save(STORE / "feature-graphic-1024x500.png")

    print(f"wrote {OUT} icons and {STORE} store graphics")


if __name__ == "__main__":
    main()
