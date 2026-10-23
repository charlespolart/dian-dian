#!/usr/bin/env python3
"""Builds assets/sounds/<cue>.wav from cute_palette.py.

  python3 tools/sounds/build.py

Each cue is trimmed of its leading silence, cut to its length with a
fade-out, peak-normalised and written as 16-bit mono 44.1 kHz wav. Needs
numpy only."""
import sys
import wave
from pathlib import Path

import numpy as np

HERE = Path(__file__).resolve().parent
APP = HERE.parent.parent
OUT = APP / "assets" / "sounds"
SR = 44100
MAX_MS = {"tracker_open": 700, "tracker_close": 700, "tracker_create": 700}
PEAK_DB = {"press": -10.0, "drag_hover": -10.0, "select": -6.0, "step_next": -6.0, "step_prev": -6.0}
LEVEL_DB = -2.0  # the whole set, under the per-cue peaks

sys.path.insert(0, str(HERE))
import cute_palette  # noqa: E402


def shape(x: np.ndarray, cue: str) -> np.ndarray:
    # Leading silence off (−50 dBFS), 2 ms of grace before the first sound.
    peak = float(np.max(np.abs(x))) or 1.0
    loud = np.flatnonzero(np.abs(x) > peak * 10 ** (-50 / 20))
    start = max(0, loud[0] - int(SR * 0.002)) if len(loud) else 0
    x = x[start:]
    n = min(len(x), int(SR * MAX_MS.get(cue, 400) / 1000))
    x = x[:n].copy()
    fade = min(n, int(SR * 0.02))
    x[n - fade:] *= np.linspace(1, 0, fade, dtype=np.float32)
    x *= 10 ** ((PEAK_DB.get(cue, -3.0) + LEVEL_DB) / 20) / (float(np.max(np.abs(x))) or 1.0)
    return x


def write(cue: str, x: np.ndarray):
    OUT.mkdir(parents=True, exist_ok=True)
    pcm = np.round(np.clip(x, -1, 1) * 32767).astype("<i2").tobytes()
    with wave.open(str(OUT / f"{cue}.wav"), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(pcm)
    print(f"{cue}.wav  {len(x) * 1000 // SR} ms")


if __name__ == "__main__":
    for cue, x in cute_palette.render().items():
        write(cue, shape(x.astype(np.float32), cue))
