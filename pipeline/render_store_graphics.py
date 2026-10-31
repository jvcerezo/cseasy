"""Render the launcher icon and Play Store graphics from design/store/*.html.

    cd app && flutter test test_screenshots/play_screenshots_test.dart
    python pipeline/render_store_graphics.py
    cd app && dart run flutter_launcher_icons

Needs Google Chrome (or Edge) and network access for the web font. Writes:
  app/assets/icon/icon.png, icon_foreground.png, icon_background.png
  docs/store/play-icon-512.png, feature-graphic-1024x500.png
  docs/store/screenshots/play-1.png .. play-6.png (from app/build/play_screenshots)
"""

import html
import re
import subprocess
import tempfile
from pathlib import Path

from PIL import Image

from cseasy_pipeline.paths import REPO

DESIGN = REPO / "design" / "store"
RAW = REPO / "app" / "build" / "play_screenshots"
ICONS = REPO / "app" / "assets" / "icon"
STORE = REPO / "docs" / "store"
SHOTS = STORE / "screenshots"

BROWSERS = [
    Path(r"C:\Program Files\Google\Chrome\Application\chrome.exe"),
    Path(r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"),
    Path("/usr/bin/google-chrome"),
    Path("/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"),
]

# (raw screenshot, eyebrow, headline with *gold* words), in listing order.
SCREENSHOTS = [
    ("02-explanation", "Every answer explained", "Learn the *why*, straight from the law"),
    ("04-mock", "Timed mock exams", "Practice under *real exam* conditions"),
    ("05-results", "Score by section", "Know exactly *where to improve*"),
    ("03-data-interpretation", "All question types", "Data tables, logic, analogies, *and more*"),
    ("06-filipino", "May Filipino rin", "*Sawikain*, talasalitaan, at wastong gamit"),
    ("01-home", "Study every day", "Streaks and *smart review* keep you on track"),
]


def browser() -> Path:
    for b in BROWSERS:
        if b.exists():
            return b
    raise SystemExit("Chrome or Edge not found; add its path to BROWSERS.")


def render(page: Path, out: Path, size: tuple[int, int], fragment: str = "", transparent: bool = False) -> None:
    args = [
        str(browser()), "--headless=new", "--disable-gpu", "--hide-scrollbars",
        "--force-device-scale-factor=1", f"--window-size={size[0]},{size[1]}",
        "--virtual-time-budget=8000", "--allow-file-access-from-files", f"--screenshot={out}",
    ]
    if transparent:
        args.append("--default-background-color=00000000")
    args.append(page.as_uri() + (f"#{fragment}" if fragment else ""))
    subprocess.run(args, check=True, capture_output=True)
    with Image.open(out) as im:
        assert im.size == size, f"{out.name}: rendered {im.size}, expected {size}"


def fill(template: Path, dest: Path, **values: str) -> Path:
    text = template.read_text(encoding="utf-8")
    for key, value in values.items():
        text = text.replace("{{" + key + "}}", value)
    assert "{{" not in text, f"unfilled placeholder in {template.name}"
    dest.write_text(text, encoding="utf-8")
    return dest


def headline(text: str) -> str:
    return re.sub(r"\*(.+?)\*", r"<em>\1</em>", html.escape(text))


def icons(tmp: Path) -> Path:
    ICONS.mkdir(parents=True, exist_ok=True)
    page = DESIGN / "icon.html"
    render(page, ICONS / "icon.png", (1024, 1024), "full")
    render(page, ICONS / "icon_foreground.png", (1024, 1024), "fg", transparent=True)
    render(page, ICONS / "icon_background.png", (1024, 1024), "bg")
    with Image.open(ICONS / "icon.png") as im:
        im.convert("RGB").resize((512, 512), Image.LANCZOS).save(STORE / "play-icon-512.png")
    # A rounded copy for the feature graphic's brand mark.
    return ICONS / "icon.png"


def screenshots(tmp: Path) -> None:
    SHOTS.mkdir(parents=True, exist_ok=True)
    for old in SHOTS.glob("*.png"):
        old.unlink()
    for i, (name, eyebrow, text) in enumerate(SCREENSHOTS, start=1):
        raw = RAW / f"{name}.png"
        with Image.open(raw) as im:
            r, g, b = im.convert("RGB").getpixel((4, 4))
        page = fill(
            DESIGN / "screenshot.html", tmp / f"shot-{i}.html",
            shot=raw.as_uri(), eyebrow=html.escape(eyebrow), headline=headline(text),
            status_bg=f"rgb({r},{g},{b})",
        )
        render(page, SHOTS / f"play-{i}.png", (1080, 1920))
        print(f"play-{i}.png  <- {name}")


def feature(tmp: Path, icon: Path) -> None:
    page = fill(
        DESIGN / "feature.html", tmp / "feature.html",
        icon=icon.as_uri(),
        shot_a=(RAW / "02-explanation.png").as_uri(),
        shot_b=(RAW / "05-results.png").as_uri(),
    )
    out = STORE / "feature-graphic-1024x500.png"
    render(page, out, (1024, 500))
    with Image.open(out) as im:
        im.convert("RGB").save(out)  # Play rejects alpha in the feature graphic


def main() -> None:
    with tempfile.TemporaryDirectory() as d:
        tmp = Path(d)
        icon = icons(tmp)
        feature(tmp, icon)
        screenshots(tmp)
    print("done")


if __name__ == "__main__":
    main()
