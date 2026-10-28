"""The app's sounds, all bubbles: a panel in the spirit of chill, cute games.

One family only — the water bubble: a sine that bends up in a few
milliseconds with a soft attack and a round octave under it. Bending down it
is a "blub" (an erase, a drop, a close); ringing a little longer and higher
it is a "droplet" (a creation, a legend); the side panel is one low, round
bubble unfolding and a low blub folding. Three bubbles rising open a tracker, three falling
close it. No knock, no marimba, no breath of air. render() returns
{cue: float32 mono array at 44.1 kHz}; the noise generator is reseeded from
each cue's name so editing one never changes another's file. Tune here and
run `python3 tools/sounds/build.py bubble_palette`."""
import numpy as np

SR = 44100
rng = np.random.default_rng(11)


def _t(dur):
    return np.arange(int(SR * dur)) / SR


def _attack(t, ms):
    return 1 - np.exp(-t / (ms / 1000))


def bubble(f0=520.0, f1=1040.0, dur=0.09, tau=0.035, gain=0.75, bend=0.008, attack_ms=1.5):
    """A water bubble: the pitch bends up fast, a round octave underneath."""
    t = _t(dur)
    f = f1 + (f0 - f1) * np.exp(-t / bend)
    phase = 2 * np.pi * np.cumsum(f) / SR
    x = np.sin(phase) * np.exp(-t / tau)
    x += 0.22 * np.sin(2 * phase) * np.exp(-t / (tau * 0.45))
    x *= _attack(t, attack_ms)
    return (x * gain).astype(np.float32)


def blub(f0=420.0, f1=190.0, dur=0.11, tau=0.045, gain=0.75):
    """A bubble bending down, with a little low body: a drop, an erase."""
    t = _t(dur)
    f = f1 + (f0 - f1) * np.exp(-t / 0.012)
    phase = 2 * np.pi * np.cumsum(f) / SR
    x = np.sin(phase) * np.exp(-t / tau)
    x += 0.3 * np.sin(0.5 * phase) * np.exp(-t / (tau * 1.2))
    x *= _attack(t, 1.5)
    return (x * gain).astype(np.float32)


def droplet(freq=1318.5, dur=0.28, tau=0.09, gain=0.5):
    """A high bubble that rings on, with a faint shimmer: a reward."""
    t = _t(dur)
    f = freq + (freq * 0.8 - freq) * np.exp(-t / 0.006)
    phase = 2 * np.pi * np.cumsum(f) / SR
    x = np.sin(phase + 0.08 * np.sin(2 * np.pi * 9 * t)) * np.exp(-t / tau)
    x += 0.18 * np.sin(2 * phase) * np.exp(-t / (tau * 0.5))
    x *= _attack(t, 2.0)
    return (x * gain).astype(np.float32)


def fizz(n=6, dur=0.14, low=700.0, high=1500.0, rising=True, gain=0.55):
    """A handful of tiny bubbles over a tenth of a second, pitched up or down."""
    out = np.zeros(int(SR * (dur + 0.05)), dtype=np.float32)
    times = np.sort(rng.uniform(0, dur, n))
    pitches = np.linspace(low, high, n) if rising else np.linspace(high, low, n)
    for st, f in zip(times, pitches):
        b = bubble(f0=f, f1=f * 1.5, dur=0.035, tau=0.011, gain=0.6 + 0.2 * rng.random(), attack_ms=1.0)
        i = int(SR * st)
        out[i:i + len(b)] += b
    return (out / (np.max(np.abs(out)) or 1.0) * gain).astype(np.float32)


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


def render():
    out = {}
    for name, make in _voices().items():
        global rng
        rng = np.random.default_rng(sum(ord(ch) for ch in name) * 7919 + 11)
        out[name] = make()
    return out


def _voices():
    up3 = lambda: mix([(0.0, bubble(400.0, 800.0, dur=0.12, tau=0.05)), (0.07, bubble(500.0, 1000.0, dur=0.12, tau=0.05)), (0.14, bubble(650.0, 1300.0, dur=0.16, tau=0.07))])
    return {
        "dot_fill": lambda: room(bubble()),
        "dot_erase": lambda: room(blub()),
        # Three bubbles rising open a tracker; falling, the last one a blub, close it.
        "tracker_open": lambda: room(up3()),
        "tracker_close": lambda: room(mix([(0.0, bubble(650.0, 1300.0, dur=0.12, tau=0.05)), (0.07, bubble(500.0, 1000.0, dur=0.12, tau=0.05)), (0.14, blub(520.0, 260.0, dur=0.14, tau=0.06))])),
        "dialog_open": lambda: room(bubble(600.0, 1200.0, dur=0.1, tau=0.04, gain=0.6)),
        "dialog_close": lambda: room(blub(480.0, 240.0, dur=0.1, tau=0.04, gain=0.5)),
        "tracker_create": lambda: room(mix([(0.0, up3()), (0.24, droplet(1318.5))])),
        "legend_add": lambda: room(mix([(0.0, droplet(1318.5, dur=0.22, tau=0.07)), (0.07, droplet(1975.5, dur=0.26, tau=0.08, gain=0.45))])),
        # Steps are bubbles bending up for next and down for back.
        "step_next": lambda: bubble(650.0, 1150.0, dur=0.06, tau=0.02, gain=0.65),
        "step_prev": lambda: bubble(1150.0, 650.0, dur=0.06, tau=0.02, gain=0.65),
        # The plain button: the tiniest bubble.
        "press": lambda: bubble(700.0, 1150.0, dur=0.05, tau=0.018, gain=0.6),
        # The side panel: one low, round bubble as it unfolds, a low blub as it folds
        # (the fizz of tiny bubbles was tried and disliked).
        "panel_open": lambda: room(bubble(300.0, 620.0, dur=0.11, tau=0.045, gain=0.6, attack_ms=2.5)),
        "panel_close": lambda: room(blub(420.0, 200.0, dur=0.11, tau=0.045, gain=0.55)),
        "drag_pick": lambda: room(bubble(380.0, 760.0, dur=0.12, tau=0.045)),
        "drag_hover": lambda: bubble(900.0, 1400.0, dur=0.035, tau=0.012, gain=0.5),
        "drag_drop": lambda: room(blub(380.0, 160.0)),
        # A choice (colour, theme, cursor, language): a rounder bubble than the button.
        "select": lambda: bubble(560.0, 980.0, dur=0.065, tau=0.024, gain=0.65),
        # A whole tracker goes: the erase's blub, lower and heavier.
        "tracker_delete": lambda: room(blub(330.0, 120.0, dur=0.15, tau=0.06, gain=0.85)),
    }
