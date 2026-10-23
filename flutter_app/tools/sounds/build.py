#!/usr/bin/env python3
"""Builds assets/sounds/<palette>/<cue>.wav for the palettes under trial.

  python3 tools/sounds/build.py [soft|softer|lighter|all]

Every palette is synthesised by soft_palette.py with its own Style. Each
cue is trimmed of its leading silence, cut to its length with a fade-out,
peak-normalised (per cue, with a per-palette offset) and written as 16-bit
mono 44.1 kHz wav. Needs numpy only."""
import sys
import wave
from pathlib import Path

import numpy as np

HERE = Path(__file__).resolve().parent
APP = HERE.parent.parent
OUT = APP / "assets" / "sounds"
SR = 44100
MAX_MS = {"tracker_open": 700, "tracker_close": 700, "tracker_create": 700}
PEAK_DB = {"press": -10.0, "drag_hover": -10.0, "select": -6.0, "day_next": -6.0, "day_prev": -6.0}

sys.path.insert(0, str(HERE))
from soft_palette import LIGHTER, SOFT, SOFTER, render  # noqa: E402

# palette: (style, level offset in dB — softer palettes are also quieter)
PALETTES = {
    "soft": (SOFT, 0.0),
    "softer": (SOFTER, -4.0),
    "lighter": (LIGHTER, -6.0),
}


def shape(x: np.ndarray, cue: str, level_db: float) -> np.ndarray:
    # Leading silence off (−50 dBFS), 2 ms of grace before the first sound.
    peak = float(np.max(np.abs(x))) or 1.0
    loud = np.flatnonzero(np.abs(x) > peak * 10 ** (-50 / 20))
    start = max(0, loud[0] - int(SR * 0.002)) if len(loud) else 0
    x = x[start:]
    n = min(len(x), int(SR * MAX_MS.get(cue, 400) / 1000))
    x = x[:n].copy()
    fade = min(n, int(SR * 0.02))
    x[n - fade:] *= np.linspace(1, 0, fade, dtype=np.float32)
    x *= 10 ** ((PEAK_DB.get(cue, -3.0) + level_db) / 20) / (float(np.max(np.abs(x))) or 1.0)
    return x


def write(palette: str, cue: str, x: np.ndarray):
    folder = OUT / palette
    folder.mkdir(parents=True, exist_ok=True)
    pcm = np.round(np.clip(x, -1, 1) * 32767).astype("<i2").tobytes()
    with wave.open(str(folder / f"{cue}.wav"), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(pcm)
    print(f"{palette}/{cue}.wav  {len(x) * 1000 // SR} ms")


if __name__ == "__main__":
    which = sys.argv[1] if len(sys.argv) > 1 else "all"
    for name, (style, level_db) in PALETTES.items():
        if which not in (name, "all"):
            continue
        for cue, x in render(style).items():
            write(name, cue, shape(x.astype(np.float32), cue, level_db))
