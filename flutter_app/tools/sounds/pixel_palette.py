"""The Pixel palette: soft 8-bit-ish cues synthesised with numpy.

render() returns {cue: float32 mono array at 44.1 kHz, peak ≤ 1}. The notes
live here: change them and run `python3 tools/sounds/build.py pixel`."""
import numpy as np

SR = 44100


def _wave(freq, dur, kind="square", duty=0.25):
    t = np.arange(int(SR * dur)) / SR
    ph = (t * freq) % 1.0
    if kind == "square":
        w = np.where(ph < duty, 1.0, -1.0)
    elif kind == "tri":
        w = 4 * np.abs(ph - 0.5) - 1
    else:
        w = np.sin(2 * np.pi * ph)
    return w.astype(np.float32)


def _env(n, attack=0.004, release=0.06):
    a, r = int(SR * attack), int(SR * release)
    s = max(0, n - a - r)
    env = np.concatenate([np.linspace(0, 1, a, endpoint=False), np.ones(s), np.linspace(1, 0, r)])
    return env[:n].astype(np.float32)


def _lowpass(x, cutoff=3200.0):
    rc = 1.0 / (2 * np.pi * cutoff)
    alpha = (1.0 / SR) / (rc + 1.0 / SR)
    y = np.empty_like(x)
    acc = 0.0
    for i, v in enumerate(x):
        acc += alpha * (v - acc)
        y[i] = acc
    return y


def note(freq, dur, kind="square", release=0.06, gain=0.8):
    w = _wave(freq, dur, kind)
    return _lowpass(w * _env(len(w), release=release)) * gain


def seq(notes, gap=0.012):
    """notes: [(freq, dur)] played one after another with a short gap."""
    parts = []
    for f, d in notes:
        parts.append(note(f, d))
        parts.append(np.zeros(int(SR * gap), dtype=np.float32))
    return np.concatenate(parts[:-1])


def sweep(f0, f1, dur, gain=0.6):
    t = np.arange(int(SR * dur)) / SR
    f = f0 + (f1 - f0) * t / dur
    ph = np.cumsum(f) / SR
    w = np.where((ph % 1.0) < 0.5, 1.0, -1.0).astype(np.float32)
    return _lowpass(w * _env(len(w), release=0.05)) * gain


C5, D5, E5, F5, G5, A5, C6 = 523.25, 587.33, 659.25, 698.46, 783.99, 880.0, 1046.5


def render():
    return {
        "dot_fill": note(A5, 0.07),
        "dot_erase": sweep(E5, 330.0, 0.09, gain=0.5),
        "tracker_open": seq([(C5, 0.07), (E5, 0.07), (G5, 0.12)]),
        "tracker_close": seq([(G5, 0.07), (E5, 0.07), (C5, 0.12)]),
        "dialog_open": seq([(E5, 0.05), (G5, 0.08)]),
        "dialog_close": seq([(G5, 0.05), (E5, 0.08)]),
        "tracker_create": seq([(C5, 0.06), (E5, 0.06), (G5, 0.06), (C6, 0.16)]),
        "legend_add": seq([(F5, 0.05), (A5, 0.09)]),
        "year_change": sweep(D5, A5, 0.14),
        "press": note(1200.0, 0.025, kind="tri", release=0.015, gain=0.5),
    }
