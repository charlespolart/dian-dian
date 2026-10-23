"""The Soft palette: kalimba notes and little bubbles, synthesised.

Sines with gentle decays, a pentatonic scale, a touch of room — the sounds
of a chill game, never a square wave. render() returns {cue: float32 mono
array at 44.1 kHz}. Tune here and run `python3 tools/sounds/build.py soft`."""
import numpy as np

SR = 44100
rng = np.random.default_rng(7)


def _t(dur):
    return np.arange(int(SR * dur)) / SR


def _attack(t, ms=2.0):
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


def kalimba(freq, dur=0.45, tau=0.12, gain=0.8):
    """A plucked tine: a few decaying partials, a 2 ms attack, a tiny mallet tick."""
    t = _t(dur)
    partials = [(1.0, 1.0, tau), (2.0, 0.30, tau * 0.5), (3.0, 0.10, tau * 0.35), (5.4, 0.04, tau * 0.2)]
    x = np.zeros_like(t)
    for ratio, amp, decay in partials:
        x += amp * np.sin(2 * np.pi * freq * ratio * t) * np.exp(-t / decay)
    x *= _attack(t)
    tick = rng.standard_normal(int(SR * 0.003)).astype(np.float32) * 0.06
    x[: len(tick)] += _lowpass(tick, 4000)
    return (x * gain).astype(np.float32)


def bubble(f0, f1, dur=0.14, tau=0.05, gain=0.7):
    """A sine whose pitch glides f0 → f1 in a few ms: a bloop."""
    t = _t(dur)
    f = f1 + (f0 - f1) * np.exp(-t / 0.018)
    phase = 2 * np.pi * np.cumsum(f) / SR
    x = np.sin(phase) * np.exp(-t / tau) * _attack(t, 1.5)
    return (x * gain).astype(np.float32)


def whoosh(dur=0.16, gain=0.35):
    """Filtered noise under a soft hump: a page-sized breath of air."""
    t = _t(dur)
    n = rng.standard_normal(len(t)).astype(np.float32)
    x = _lowpass(n, 1800) - _lowpass(n, 350)
    hump = np.sin(np.pi * t / dur) ** 2
    return (x * hump * gain).astype(np.float32)


def thump(freq=220.0, dur=0.05, tau=0.012, gain=0.9):
    """A low, dry tap for a button under the finger."""
    t = _t(dur)
    x = np.sin(2 * np.pi * freq * t) * np.exp(-t / tau) * _attack(t, 0.8)
    click = rng.standard_normal(int(SR * 0.0015)).astype(np.float32) * 0.25
    x[: len(click)] += _lowpass(click, 5000)
    return (x * gain).astype(np.float32)


def mix(parts, tail=0.05):
    """parts: [(start_seconds, array)] summed in time."""
    end = max(int(SR * s) + len(a) for s, a in parts) + int(SR * tail)
    out = np.zeros(end, dtype=np.float32)
    for s, a in parts:
        i = int(SR * s)
        out[i:i + len(a)] += a
    return out


def room(x):
    """A touch of body: two short, quiet echoes."""
    out = np.zeros(len(x) + int(SR * 0.045), dtype=np.float32)
    out[: len(x)] += x
    for delay, amp in ((0.023, 0.18), (0.041, 0.08)):
        i = int(SR * delay)
        out[i:i + len(x)] += x * amp
    return out


C5, D5, E5, G5, A5 = 523.25, 587.33, 659.25, 783.99, 880.0
C6, D6, E6, G6, A6 = 1046.5, 1174.7, 1318.5, 1568.0, 1760.0


def render():
    return {
        "dot_fill": room(kalimba(C6, tau=0.11)),
        "dot_erase": room(bubble(700, 420, tau=0.06, gain=0.6)),
        "tracker_open": room(mix([(0.0, kalimba(G5)), (0.1, kalimba(C6, tau=0.16))])),
        "tracker_close": room(mix([(0.0, kalimba(C6)), (0.1, kalimba(G5, tau=0.16))])),
        "dialog_open": room(bubble(520, 940, tau=0.06)),
        "dialog_close": room(bubble(940, 520, tau=0.05, gain=0.55)),
        "tracker_create": room(mix([(0.0, kalimba(C5)), (0.08, kalimba(E5)), (0.16, kalimba(G5)), (0.26, kalimba(C6, tau=0.25))])),
        "legend_add": room(mix([(0.0, kalimba(D6, tau=0.08)), (0.07, kalimba(G6, tau=0.1))])),
        "year_change": room(mix([(0.0, whoosh()), (0.06, kalimba(G5, tau=0.1, gain=0.3))])),
        "press": thump(),
    }
