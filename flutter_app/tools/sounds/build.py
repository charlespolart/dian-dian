#!/usr/bin/env python3
"""Builds assets/sounds/<palette>/<cue>.wav for the three palettes.

  python3 tools/sounds/build.py paper|interface|pixel|all

paper: Mixkit (Sound Effects Free License), by id; interface: Kenney CC0
packs, by file; pixel: pixel_palette.py. Every source is trimmed of its
leading silence, cut to its length with a fade-out, peak-normalised and
written as 16-bit mono 44.1 kHz wav. Needs ffmpeg and numpy.
Downloads land in tools/sounds/cache/ (git-ignored)."""
import subprocess
import sys
import urllib.request
import wave
import zipfile
from pathlib import Path

import numpy as np

HERE = Path(__file__).resolve().parent
APP = HERE.parent.parent
CACHE = HERE / "cache"
OUT = APP / "assets" / "sounds"
SR = 44100
CUES = ["dot_fill", "dot_erase", "tracker_open", "tracker_close", "dialog_open",
        "dialog_close", "tracker_create", "legend_add", "year_change", "press"]
MAX_MS = {"tracker_open": 700, "tracker_close": 700, "tracker_create": 700}
PEAK_DB = {"press": -10.0}

MIXKIT = "https://assets.mixkit.co/active_storage/sfx/{id}/{id}-preview.mp3"
# cue: (mixkit id, max ms, reverse)
PAPER = {
    "dot_fill": (2376, 160, False),        # Short pencil writing
    "dot_erase": (2380, 220, False),       # Paper quick movement
    "tracker_open": (1104, 600, False),    # Page turn single
    "tracker_close": (1104, 600, True),    # the same page, turned back
    "dialog_open": (1530, 260, False),     # Paper slide
    "dialog_close": (1530, 260, True),
    "tracker_create": (2995, 400, False),  # Stapling paper
    "legend_add": (3102, 300, False),      # Duct tape bandage
    "year_change": (1097, 380, False),     # Turning the newspaper big page
    "press": (1125, 70, False),            # Typewriter soft click
}

KENNEY = {
    "interface-sounds": "https://kenney.nl/media/pages/assets/interface-sounds/fa43c1dd4d-1677589452/kenney_interface-sounds.zip",
    "ui-audio": "https://kenney.nl/media/pages/assets/ui-audio/490d233f68-1677590494/kenney_ui-audio.zip",
}
# cue: (pack, file inside Audio/, max ms)
INTERFACE = {
    "dot_fill": ("interface-sounds", "pluck_001.ogg", 200),
    "dot_erase": ("interface-sounds", "drop_001.ogg", 220),
    "tracker_open": ("interface-sounds", "open_001.ogg", 600),
    "tracker_close": ("interface-sounds", "close_001.ogg", 600),
    "dialog_open": ("interface-sounds", "open_002.ogg", 350),
    "dialog_close": ("interface-sounds", "close_002.ogg", 350),
    "tracker_create": ("interface-sounds", "confirmation_001.ogg", 600),
    "legend_add": ("interface-sounds", "glass_001.ogg", 300),
    "year_change": ("interface-sounds", "scroll_001.ogg", 300),
    "press": ("ui-audio", "click1.ogg", 70),
}


def fetch(url, name):
    CACHE.mkdir(exist_ok=True)
    path = CACHE / name
    if not path.exists():
        req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
        path.write_bytes(urllib.request.urlopen(req, timeout=60).read())
    return path


def decode(data: bytes) -> np.ndarray:
    """Any format ffmpeg reads → float32 mono 44.1 kHz."""
    out = subprocess.run(
        ["ffmpeg", "-v", "error", "-i", "pipe:0", "-f", "f32le", "-ac", "1", "-ar", str(SR), "pipe:1"],
        input=data, stdout=subprocess.PIPE, check=True).stdout
    return np.frombuffer(out, dtype=np.float32).copy()


def shape(x: np.ndarray, cue: str, max_ms: int, reverse=False) -> np.ndarray:
    if reverse:
        x = x[::-1]
    # Leading silence off (−50 dBFS), 2 ms of grace before the first sound.
    peak = float(np.max(np.abs(x))) or 1.0
    loud = np.flatnonzero(np.abs(x) > peak * 10 ** (-50 / 20))
    start = max(0, loud[0] - int(SR * 0.002)) if len(loud) else 0
    x = x[start:]
    cap = min(max_ms, MAX_MS.get(cue, 400))
    n = min(len(x), int(SR * cap / 1000))
    x = x[:n].copy()
    fade = min(n, int(SR * 0.02))
    x[n - fade:] *= np.linspace(1, 0, fade, dtype=np.float32)
    x *= 10 ** (PEAK_DB.get(cue, -3.0) / 20) / (float(np.max(np.abs(x))) or 1.0)
    return x


def write(palette: str, cue: str, x: np.ndarray):
    folder = OUT / palette
    folder.mkdir(parents=True, exist_ok=True)
    pcm = (np.clip(x, -1, 1) * 32767).astype("<i2").tobytes()
    with wave.open(str(folder / f"{cue}.wav"), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(pcm)
    print(f"{palette}/{cue}.wav  {len(x) * 1000 // SR} ms")


def build_paper():
    for cue, (sid, max_ms, rev) in PAPER.items():
        data = fetch(MIXKIT.format(id=sid), f"mixkit-{sid}.mp3").read_bytes()
        write("paper", cue, shape(decode(data), cue, max_ms, rev))


def build_interface():
    zips = {pack: zipfile.ZipFile(fetch(url, f"{pack}.zip")) for pack, url in KENNEY.items()}
    for cue, (pack, name, max_ms) in INTERFACE.items():
        z = zips[pack]
        member = next(m for m in z.namelist() if m.endswith("/" + name) or m == name)
        write("interface", cue, shape(decode(z.read(member)), cue, max_ms))


def build_pixel():
    sys.path.insert(0, str(HERE))
    from pixel_palette import render
    for cue, x in render().items():
        write("pixel", cue, shape(x.astype(np.float32), cue, 700))


if __name__ == "__main__":
    which = sys.argv[1] if len(sys.argv) > 1 else "all"
    assert set(PAPER) == set(CUES) == set(INTERFACE)
    if which in ("paper", "all"):
        build_paper()
    if which in ("interface", "all"):
        build_interface()
    if which in ("pixel", "all"):
        build_pixel()
