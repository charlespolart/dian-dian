"""The Soft palette: little bubbles, synthesised.

Every cue is a bloop — a sine whose pitch glides up or down in a few
milliseconds and dies in a few tens — short and clean like a satisfying
click; the bigger moments are two or three bloops in a row. The button is
a dry low tap. A touch of room for body. render() returns {cue: float32
mono array at 44.1 kHz}. Tune here and run `python3 tools/sounds/build.py soft`."""
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


def bubble(f0, f1, dur=0.14, tau=0.05, gain=0.7):
    """A sine whose pitch glides f0 → f1 in a few ms: a bloop."""
    t = _t(dur)
    f = f1 + (f0 - f1) * np.exp(-t / 0.018)
    phase = 2 * np.pi * np.cumsum(f) / SR
    x = np.sin(phase) * np.exp(-t / tau) * _attack(t, 1.5)
    return (x * gain).astype(np.float32)


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


def render():
    up, down = bubble, bubble
    return {
        "dot_fill": room(up(620, 1040, dur=0.10, tau=0.04, gain=0.75)),
        "dot_erase": room(down(760, 430, dur=0.11, tau=0.045, gain=0.6)),
        "tracker_open": room(mix([(0.0, up(420, 760, dur=0.14, tau=0.06)), (0.09, up(640, 1150, dur=0.14, tau=0.07, gain=0.6))])),
        "tracker_close": room(mix([(0.0, down(1150, 640, dur=0.14, tau=0.06, gain=0.6)), (0.09, down(760, 420, dur=0.14, tau=0.07))])),
        "dialog_open": room(up(520, 940, tau=0.06)),
        "dialog_close": room(down(940, 520, tau=0.05, gain=0.55)),
        "tracker_create": room(mix([(0.0, up(480, 820, dur=0.12, tau=0.05)), (0.08, up(640, 1100, dur=0.12, tau=0.05)), (0.16, up(820, 1480, dur=0.16, tau=0.08))])),
        "legend_add": room(up(900, 1500, dur=0.10, tau=0.045, gain=0.65)),
        "year_change": room(mix([(0.0, down(700, 520, dur=0.07, tau=0.03, gain=0.6)), (0.06, up(560, 760, dur=0.09, tau=0.04, gain=0.7))])),
        "press": thump(),
    }
