"""Frame raw app screenshots with a caption for the Play Store listing.

    cd app && flutter test test_screenshots/play_screenshots_test.dart
    python pipeline/frame_screenshots.py

Reads app/build/play_screenshots/*.png (1080x1920) and writes captioned
1080x1920 images, in listing order, into docs/store/screenshots/.
"""

import shutil
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

from cseasy_pipeline.paths import REPO

BLUE = (31, 95, 191)
WHITE = (255, 255, 255)
GOLD = (255, 196, 61)
RAW = REPO / "app" / "build" / "play_screenshots"
OUT = REPO / "docs" / "store" / "screenshots"
W, H = 1080, 1920

# (raw name, caption, highlighted words), in listing order.
SHOTS = [
    ("02-explanation", "Every answer explained, with the law it comes from", "explained"),
    ("04-mock", "Timed mock exams as long as the real CSE", "Timed mock exams"),
    ("05-results", "See your score in every section", "every section"),
    ("03-data-interpretation", "All the exam question types, tables included", "question types"),
    ("06-filipino", "May Filipino rin: sawikain, talasalitaan, at iba pa", "Filipino"),
    ("01-home", "Daily streaks and review keep you on track", "Daily streaks"),
]


def font(size: int) -> ImageFont.FreeTypeFont:
    flutter = Path(shutil.which("flutter")).resolve().parent
    return ImageFont.truetype(str(flutter / "cache" / "artifacts" / "material_fonts" / "roboto-bold.ttf"), size)


def wrap(draw: ImageDraw.ImageDraw, text: str, f: ImageFont.FreeTypeFont, width: int) -> list[str]:
    lines, line = [], ""
    for word in text.split():
        trial = f"{line} {word}".strip()
        if draw.textlength(trial, font=f) <= width:
            line = trial
        else:
            lines.append(line)
            line = word
    return lines + [line]


def draw_caption(draw: ImageDraw.ImageDraw, text: str, highlight: str) -> None:
    f = font(72)
    lines = wrap(draw, text, f, W - 160)
    marked = set(highlight.split())
    y = 110
    for line in lines:
        x = (W - draw.textlength(line, font=f)) / 2
        for i, word in enumerate(line.split()):
            piece = word if i == 0 else f" {word}"
            colour = GOLD if word.strip(",.:") in marked else WHITE
            draw.text((x, y), piece, font=f, fill=colour)
            x += draw.textlength(piece, font=f)
        y += 90


def frame(raw: Path, caption: str, highlight: str) -> Image.Image:
    canvas = Image.new("RGB", (W, H), BLUE)
    draw_caption(ImageDraw.Draw(canvas), caption, highlight)

    scale = 0.74
    shot = Image.open(raw).convert("RGB").resize((int(W * scale), int(H * scale)), Image.LANCZOS)
    sw, sh = shot.size
    x, y = (W - sw) // 2, 360
    radius = 44

    shadow = Image.new("L", (W, H), 0)
    ImageDraw.Draw(shadow).rounded_rectangle([x, y + 16, x + sw, y + sh + 16], radius=radius, fill=110)
    canvas.paste((10, 40, 90), mask=shadow.filter(ImageFilter.GaussianBlur(28)))

    mask = Image.new("L", shot.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, sw - 1, sh - 1], radius=radius, fill=255)
    canvas.paste(shot, (x, y), mask)
    return canvas


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    for old in OUT.glob("*.png"):
        old.unlink()
    for i, (name, caption, highlight) in enumerate(SHOTS, start=1):
        frame(RAW / f"{name}.png", caption, highlight).save(OUT / f"play-{i}.png")
        print(f"play-{i}.png  <- {name}")


if __name__ == "__main__":
    main()
