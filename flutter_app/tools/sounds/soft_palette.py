"""The bubble palette, synthesised: gentle (SOFT is the base it is bent from).

Every cue is a bloop — a sine whose pitch glides up or down in a few
milliseconds and dies in a few tens — short and clean like a satisfying
click; the bigger moments are two or three bloops in a row. The button is
a dry low tap. A Style bends the whole set: pitch, length, decay, glide
width, attack, room. render(style) returns {cue: float32 mono array at
44.1 kHz}. Tune here and run `python3 tools/sounds/build.py`."""
from dataclasses import dataclass

import numpy as np

SR = 44100
rng = np.random.default_rng(7)


@dataclass(frozen=True)
class Style:
    pitch: float = 1.0      # every frequency × this
    length: float = 1.0     # every duration × this
    decay: float = 1.0      # every decay time × this
    glide: float = 1.0      # pitch glide width × this (1 = full, 0 = a plain tone)
    attack_ms: float = 1.5  # how fast a bubble comes in
    room: float = 1.0       # the two short echoes × this (0 = dry)
    lowpass: float = 0.0    # a cutoff in Hz that rounds every bubble (0 = none)


SOFT = Style()
# Softer still, but not the way `softer` was (lower and narrower, rejected):
# the same pitches as soft, a slow attack that erases the onset click, a
# low-pass that rounds the tone, a little less glide and echo.
GENTLE = Style(pitch=0.95, decay=0.9, glide=0.6, attack_ms=6.0, room=0.8, lowpass=2600.0)


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


class Bubbles:
    def __init__(self, style: Style):
        self.s = style

    def bubble(self, f0, f1, dur=0.14, tau=0.05, gain=0.7):
        """A sine whose pitch glides f0 → f1 in a few ms: a bloop."""
        s = self.s
        f1 = f0 + (f1 - f0) * s.glide
        f0, f1 = f0 * s.pitch, f1 * s.pitch
        t = _t(dur * s.length)
        f = f1 + (f0 - f1) * np.exp(-t / 0.018)
        phase = 2 * np.pi * np.cumsum(f) / SR
        x = np.sin(phase) * np.exp(-t / (tau * s.decay)) * _attack(t, s.attack_ms)
        if s.lowpass:
            x = _lowpass(x.astype(np.float32), s.lowpass)
        return (x * gain).astype(np.float32)

    def thump(self, freq=220.0, dur=0.05, tau=0.012, gain=0.9):
        """A low, dry tap for a button under the finger."""
        s = self.s
        t = _t(dur * s.length)
        x = np.sin(2 * np.pi * freq * s.pitch * t) * np.exp(-t / (tau * s.decay)) * _attack(t, 0.8)
        click = rng.standard_normal(int(SR * 0.0015)).astype(np.float32) * 0.25
        x[: len(click)] += _lowpass(click, 5000)
        return (x * gain).astype(np.float32)

    def mix(self, parts, tail=0.05):
        """parts: [(start_seconds, array)] summed in time; starts scale with length."""
        s = self.s
        end = max(int(SR * st * s.length) + len(a) for st, a in parts) + int(SR * tail)
        out = np.zeros(end, dtype=np.float32)
        for st, a in parts:
            i = int(SR * st * s.length)
            out[i:i + len(a)] += a
        return out

    def room(self, x):
        """A touch of body: two short, quiet echoes."""
        amount = self.s.room
        out = np.zeros(len(x) + int(SR * 0.045), dtype=np.float32)
        out[: len(x)] += x
        for delay, amp in ((0.023, 0.18), (0.041, 0.08)):
            i = int(SR * delay)
            out[i:i + len(x)] += x * amp * amount
        return out


def render(style: Style = SOFT):
    b = Bubbles(style)
    up, down, mix, room, thump = b.bubble, b.bubble, b.mix, b.room, b.thump
    return {
        "dot_fill": room(up(620, 1040, dur=0.10, tau=0.04, gain=0.75)),
        "dot_erase": room(down(760, 430, dur=0.11, tau=0.045, gain=0.6)),
        "tracker_open": room(mix([(0.0, up(420, 760, dur=0.14, tau=0.06)), (0.09, up(640, 1150, dur=0.14, tau=0.07, gain=0.6))])),
        "tracker_close": room(mix([(0.0, down(1150, 640, dur=0.14, tau=0.06, gain=0.6)), (0.09, down(760, 420, dur=0.14, tau=0.07))])),
        "dialog_open": room(up(520, 940, tau=0.06)),
        "dialog_close": room(down(940, 520, tau=0.05, gain=0.55)),
        "tracker_create": room(mix([(0.0, up(480, 820, dur=0.12, tau=0.05)), (0.08, up(640, 1100, dur=0.12, tau=0.05)), (0.16, up(820, 1480, dur=0.16, tau=0.08))])),
        "legend_add": room(up(900, 1500, dur=0.10, tau=0.045, gain=0.65)),
        "press": thump(),
        "panel_open": room(up(380, 640, dur=0.10, tau=0.04, gain=0.6)),
        "panel_close": room(down(640, 380, dur=0.10, tau=0.04, gain=0.55)),
        "drag_pick": room(mix([(0.0, up(420, 700, dur=0.07, tau=0.03, gain=0.6)), (0.05, up(700, 1100, dur=0.09, tau=0.04, gain=0.6))])),
        "drag_hover": up(900, 1200, dur=0.05, tau=0.02, gain=0.5),
        "drag_drop": room(mix([(0.0, down(900, 520, dur=0.09, tau=0.04, gain=0.6)), (0.03, thump(freq=180.0, gain=0.6))])),
        "select": up(700, 1150, dur=0.07, tau=0.03, gain=0.7),
        "step_next": up(560, 840, dur=0.06, tau=0.03, gain=0.6),
        "step_prev": down(840, 560, dur=0.06, tau=0.03, gain=0.6),
    }
