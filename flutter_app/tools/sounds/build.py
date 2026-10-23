#!/usr/bin/env python3
"""Builds assets/sounds/<palette>/<cue>.wav for the palettes under trial.

  python3 tools/sounds/build.py paper|pop|soft|all

paper and pop: Mixkit (Sound Effects Free License), by id; soft:
soft_palette.py. Every source is trimmed of its leading silence, cut to
its length with a fade-out, peak-normalised and written as 16-bit mono
44.1 kHz wav. Needs ffmpeg and numpy. Downloads land in
tools/sounds/cache/ (git-ignored)."""
import subprocess
import sys
import urllib.request
import wave
from pathlib import Path

import numpy as np

HERE = Path(__file__).resolve().parent
APP = HERE.parent.parent
CACHE = HERE / "cache"
OUT = APP / "assets" / "sounds"
SR = 44100
CUES = ["dot_fill", "dot_erase", "tracker_open", "tracker_close", "dialog_open",
        "dialog_close", "tracker_create", "legend_add", "year_change", "press",
        "panel_open", "panel_close", "drag_pick", "drag_hover", "drag_drop", "select"]
MAX_MS = {"tracker_open": 700, "tracker_close": 700, "tracker_create": 700}
PEAK_DB = {"press": -10.0, "drag_hover": -10.0, "select": -6.0}

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
    "panel_open": (1530, 220, False),      # Paper slide, short
    "panel_close": (1530, 220, True),      # … back
    "drag_pick": (2380, 180, False),       # Paper quick movement
    "drag_hover": (1125, 50, False),       # Typewriter soft click, quieter
    "drag_drop": (2386, 220, False),       # Pages of paper moving
    "select": (1125, 70, False),           # Typewriter soft click
}

# cue: (mixkit id, max ms, reverse) — bubbles, pops and little tones
POP = {
    "dot_fill": (731, 160, False),          # Cartoon bubble pop
    "dot_erase": (2925, 220, False),        # Soap bubble sound
    "tracker_open": (2820, 600, False),     # Magic marimba
    "tracker_close": (2575, 500, False),    # Software interface back
    "dialog_open": (2357, 260, False),      # Bubble pop up alert notification
    "dialog_close": (2356, 260, False),     # Dry pop up notification alert
    "tracker_create": (3193, 700, False),   # Bubbly achievement tone
    "legend_add": (960, 350, False),        # Tile game reveal
    "year_change": (3005, 300, False),      # Explainer video pops whoosh light pop
    "press": (1124, 60, False),             # Plastic bubble click
    "panel_open": (731, 140, False),        # Cartoon bubble pop
    "panel_close": (2925, 160, False),      # Soap bubble sound
    "drag_pick": (3069, 200, False),        # Game balloon or bubble pop
    "drag_hover": (1124, 50, False),        # Plastic bubble click, quieter
    "drag_drop": (2356, 220, False),        # Dry pop up notification alert
    "select": (1124, 70, False),            # Plastic bubble click
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


def build_mixkit(palette, table):
    for cue, (sid, max_ms, rev) in table.items():
        data = fetch(MIXKIT.format(id=sid), f"mixkit-{sid}.mp3").read_bytes()
        write(palette, cue, shape(decode(data), cue, max_ms, rev))


def build_soft():
    sys.path.insert(0, str(HERE))
    from soft_palette import render
    for cue, x in render().items():
        write("soft", cue, shape(x.astype(np.float32), cue, 700))


if __name__ == "__main__":
    which = sys.argv[1] if len(sys.argv) > 1 else "all"
    assert set(PAPER) == set(CUES) == set(POP)
    if which in ("paper", "all"):
        build_mixkit("paper", PAPER)
    if which in ("pop", "all"):
        build_mixkit("pop", POP)
    if which in ("soft", "all"):
        build_soft()
