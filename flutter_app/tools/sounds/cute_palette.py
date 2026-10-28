"""The app's sounds: a cozy little game, synthesised.

In the spirit of Minecraft, Tiny Wings and Stardew Valley — organic, warm,
a bit wooden: bubbles (a sine that bends in a few ms, a grain of noise) for
the button, a choice, a step (up for next, down for back) and the hover of a
drag, the bigger pickup "pop" of the same voice for a dot filled or a drag
picked up; a dull "plop" for an erase or a drop, lower and heavier for a
deletion; a breath of air, brighter or darker, for the side panel; little
marimba notes alone for opening and closing and the dialogs; a bell "ding",
like an experience orb, for a creation or a legend. The wooden knock of the
first cut is gone: the user found it ugly wherever it played. render() returns {cue: float32 mono array
at 44.1 kHz}. Tune here and run `python3 tools/sounds/build.py`."""
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


def _noise(dur):
    return rng.standard_normal(int(SR * dur)).astype(np.float32)



def pop(f0=520.0, f1=1040.0, dur=0.09, tau=0.035, gain=0.75):
    """The pickup pop: a sine that bends up in a few ms, a grain of noise on top."""
    t = _t(dur)
    f = f1 + (f0 - f1) * np.exp(-t / 0.008)
    x = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-t / tau) * _attack(t, 1.0)
    grain = _lowpass(_noise(0.004), 5000) * 0.15
    x[: len(grain)] += grain
    return (x * gain).astype(np.float32)


def plop(f0=420.0, f1=190.0, dur=0.11, tau=0.04, gain=0.75):
    """A dull drop: a sine that bends down into a low thud, a puff of noise."""
    t = _t(dur)
    f = f1 + (f0 - f1) * np.exp(-t / 0.012)
    x = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-t / tau) * _attack(t, 1.0)
    puff = _lowpass(_noise(0.015), 1500) * np.exp(-_t(0.015) / 0.005) * 0.4
    x[: len(puff)] += puff
    return (x * gain).astype(np.float32)


def marimba(freq, dur=0.3, tau=0.12, gain=0.7):
    """A warm bar: the fundamental, the bar's fourth-harmonic ring, a mallet tap."""
    t = _t(dur)
    x = np.sin(2 * np.pi * freq * t) * np.exp(-t / tau)
    x += 0.35 * np.sin(2 * np.pi * freq * 4 * t) * np.exp(-t / (tau * 0.3))
    x += 0.10 * np.sin(2 * np.pi * freq * 10 * t) * np.exp(-t / (tau * 0.12))
    x *= _attack(t, 2.5)
    tap = _lowpass(_noise(0.003), 3000) * 0.12
    x[: len(tap)] += tap
    return (x * gain).astype(np.float32)


def ding(freq, dur=0.5, tau=0.22, gain=0.6):
    """A small bell, like an experience orb: a sine with two inharmonic partials."""
    t = _t(dur)
    x = np.sin(2 * np.pi * freq * t) * np.exp(-t / tau)
    x += 0.45 * np.sin(2 * np.pi * freq * 2.76 * t) * np.exp(-t / (tau * 0.5))
    x += 0.15 * np.sin(2 * np.pi * freq * 5.4 * t) * np.exp(-t / (tau * 0.25))
    x *= _attack(t, 1.5)
    return (x * gain).astype(np.float32)


def whoosh(dur=0.14, low=350.0, high=1800.0, gain=0.35):
    """A breath of air under a soft hump; lower bounds make it darker."""
    t = _t(dur)
    n = _noise(dur)
    x = _lowpass(n, high) - _lowpass(n, low)
    return (x * np.sin(np.pi * t / dur) ** 2 * gain).astype(np.float32)


def mix(parts, tail=0.05):
    end = max(int(SR * st) + len(a) for st, a in parts) + int(SR * tail)
    out = np.zeros(end, dtype=np.float32)
    for st, a in parts:
        i = int(SR * st)
        out[i:i + len(a)] += a
    return out


def room(x, amount=0.5):
    out = np.zeros(len(x) + int(SR * 0.045), dtype=np.float32)
    out[: len(x)] += x
    for delay, amp in ((0.023, 0.18), (0.041, 0.08)):
        i = int(SR * delay)
        out[i:i + len(x)] += x * amp * amount
    return out


C5, E5, G5, C6, E6, B6 = 523.25, 659.25, 783.99, 1046.5, 1318.5, 1975.5


def render():
    """One array per cue. The noise generator is reseeded from each cue's name
    first, so editing or adding a cue never changes another cue's file."""
    out = {}
    for name, make in _voices().items():
        global rng
        rng = np.random.default_rng(sum(ord(ch) for ch in name) * 7919 + 11)
        out[name] = make()
    return out


def _voices():
    return {
        "dot_fill": lambda: room(pop()),
        "dot_erase": lambda: room(plop()),
        "tracker_open": lambda: room(mix([(0.0, marimba(C5, tau=0.10)), (0.07, marimba(E5, tau=0.10)), (0.14, marimba(G5, tau=0.13))])),
        "tracker_close": lambda: room(mix([(0.0, marimba(G5, tau=0.10)), (0.07, marimba(E5, tau=0.10)), (0.14, marimba(C5, tau=0.13))])),
        "dialog_open": lambda: room(marimba(G5, tau=0.09, gain=0.5)),
        "dialog_close": lambda: room(marimba(E5, tau=0.08, gain=0.4)),
        "tracker_create": lambda: room(mix([(0.0, marimba(C5, tau=0.10)), (0.07, marimba(E5, tau=0.10)), (0.14, marimba(G5, tau=0.10)), (0.24, ding(C6))])),
        "legend_add": lambda: room(mix([(0.0, ding(E6, dur=0.3, tau=0.12, gain=0.5)), (0.07, ding(B6, dur=0.35, tau=0.14, gain=0.45))])),
        # Steps are bubbles too, bending up for next and down for back.
        "step_next": lambda: pop(f0=650.0, f1=1150.0, dur=0.06, tau=0.02, gain=0.65),
        "step_prev": lambda: pop(f0=1150.0, f1=650.0, dur=0.06, tau=0.02, gain=0.65),
        # The plain button: a tiny bubble.
        "press": lambda: pop(f0=700.0, f1=1150.0, dur=0.05, tau=0.018, gain=0.6),
        "panel_open": lambda: room(whoosh()),
        "panel_close": lambda: room(whoosh(low=250.0, high=1100.0)),
        "drag_pick": lambda: room(pop(380.0, 760.0, dur=0.12, tau=0.045)),
        # The hover during a drag: the smallest bubble, high and very short.
        "drag_hover": lambda: pop(f0=900.0, f1=1400.0, dur=0.035, tau=0.012, gain=0.5),
        "drag_drop": lambda: room(plop(380.0, 160.0)),
        # A choice (colour, theme, cursor, language): a rounder bubble than the button.
        "select": lambda: pop(f0=560.0, f1=980.0, dur=0.065, tau=0.024, gain=0.65),
        # The erase's plop, lower and heavier: a whole tracker goes, in the
        # same family as a dot (erase 420→190, drop 380→160, this 330→120).
        "tracker_delete": lambda: room(plop(f0=330.0, f1=120.0, dur=0.15, tau=0.06, gain=0.85)),
    }
