"""The Cute palette: a chill little game, synthesised.

Every cue is a pling — a triangle wave (hollow, mellow) with a quick bend
of pitch at its onset, a short decay and a low-pass — on a major
pentatonic; the bigger moments are motifs of two to four plings, picking
something up goes boing, dropping it goes plop. render() returns {cue:
float32 mono array at 44.1 kHz}. Tune here and run
`python3 tools/sounds/build.py cute`."""
import numpy as np

SR = 44100
rng = np.random.default_rng(11)


def _t(dur):
    return np.arange(int(SR * dur)) / SR


def _attack(t, ms):
    return 1 - np.exp(-t / (ms / 1000))


def _lowpass(x, cutoff):
    rc = 1.0 / (2 * np.pi * cutoff)
    alpha = (1.0 / SR) / (rc + 1.0 / SR)
    y = np.empty_like(x)
    acc = 0.0
    for i, v in enumerate(x):
        acc += alpha * (v - acc)
        y[i] = acc
    return y


def pling(freq, dur=0.18, tau=0.07, bend=0.06, bend_ms=15.0, vib=0.0, gain=0.7):
    """A triangle-wave note that bends up into its pitch (bend < 0: down)."""
    t = _t(dur)
    f = freq * (1 - bend * np.exp(-t / (bend_ms / 1000)))
    if vib:
        f = f * (1 + vib * np.sin(2 * np.pi * 5.5 * t))
    phase = np.cumsum(f) / SR
    tri = 2 * np.abs(2 * (phase % 1.0) - 1) - 1
    x = tri * np.exp(-t / tau) * _attack(t, 2.0)
    return (_lowpass(x.astype(np.float32), 3500) * gain).astype(np.float32)


def thump(freq=240.0, dur=0.05, tau=0.010, gain=0.9):
    t = _t(dur)
    x = np.sin(2 * np.pi * freq * t) * np.exp(-t / tau) * _attack(t, 0.8)
    click = rng.standard_normal(int(SR * 0.0012)).astype(np.float32) * 0.2
    x[: len(click)] += _lowpass(click, 4000)
    return (x * gain).astype(np.float32)


def mix(parts, tail=0.05):
    end = max(int(SR * st) + len(a) for st, a in parts) + int(SR * tail)
    out = np.zeros(end, dtype=np.float32)
    for st, a in parts:
        i = int(SR * st)
        out[i:i + len(a)] += a
    return out


def room(x, amount=0.6):
    out = np.zeros(len(x) + int(SR * 0.045), dtype=np.float32)
    out[: len(x)] += x
    for delay, amp in ((0.023, 0.18), (0.041, 0.08)):
        i = int(SR * delay)
        out[i:i + len(x)] += x * amp * amount
    return out


C5, D5, E5, G5, A5, B5 = 523.25, 587.33, 659.25, 783.99, 880.0, 987.77
C6, D6, E6, G6, A6, C7 = 1046.5, 1174.7, 1318.5, 1568.0, 1760.0, 2093.0


def render():
    return {
        "dot_fill": room(pling(E6, tau=0.06, bend=0.08)),
        "dot_erase": room(pling(A5, tau=0.07, bend=-0.08, gain=0.6)),
        "tracker_open": room(mix([(0.0, pling(C5)), (0.07, pling(E5)), (0.14, pling(G5, tau=0.12))])),
        "tracker_close": room(mix([(0.0, pling(G5)), (0.07, pling(E5)), (0.14, pling(C5, tau=0.12))])),
        "dialog_open": room(mix([(0.0, pling(E5)), (0.07, pling(G5))])),
        "dialog_close": room(mix([(0.0, pling(G5)), (0.07, pling(E5, gain=0.55))])),
        "tracker_create": room(mix([(0.0, pling(C5)), (0.08, pling(E5)), (0.16, pling(G5)), (0.26, pling(C6, tau=0.22, vib=0.012))])),
        "legend_add": room(mix([(0.0, pling(D6, tau=0.05)), (0.06, pling(A6, tau=0.09))])),
        "step_next": pling(G5, dur=0.09, tau=0.04, gain=0.6),
        "step_prev": pling(E5, dur=0.09, tau=0.04, gain=0.6),
        "press": thump(),
        "panel_open": room(pling(G5, dur=0.14, tau=0.08, bend=0.3, bend_ms=40.0, gain=0.6)),
        "panel_close": room(pling(G5, dur=0.14, tau=0.08, bend=-0.3, bend_ms=40.0, gain=0.55)),
        "drag_pick": room(pling(A5, dur=0.14, tau=0.06, bend=0.35, bend_ms=30.0, vib=0.02, gain=0.65)),
        "drag_hover": pling(C7, dur=0.04, tau=0.015, bend=0.0, gain=0.5),
        "drag_drop": room(mix([(0.0, pling(E5, tau=0.06, bend=-0.3, bend_ms=30.0, gain=0.6)), (0.02, thump(freq=160.0, gain=0.6))])),
        "select": pling(B5, dur=0.09, tau=0.04, gain=0.65),
    }
