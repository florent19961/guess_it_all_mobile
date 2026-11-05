#!/usr/bin/env python3
"""Rend assets/sounds/reveal_music.mp3 : composition originale de la révélation
des scores (percussions, flûte, puis gong et accord final, queue d'environ 3 s).

Même synthèse que `music(sec)` de la maquette (Web Audio), sec = 4,5 : le gong
tombe exactement à 4,5 s, à la fin de l'animation (`ScoreRevealScreen`).

Usage : scripts/render_reveal_music.py <chemin de ffmpeg>   (numpy requis)
"""
import pathlib, subprocess, sys
import numpy as np

SR = 44100
SEC = 4.5
TAIL = 3.2
PEAK = 0.89  # environ -1 dBFS : le gong saturerait au gain de la maquette.
OUT = pathlib.Path(__file__).resolve().parent.parent / "assets/sounds/reveal_music.mp3"

buf = np.zeros(int(SR * (SEC + TAIL)))


def add(signal, t0):
    start = int(round(t0 * SR))
    end = min(len(buf), start + len(signal))
    buf[start:end] += signal[: end - start]


def times(duration):
    return np.arange(int(duration * SR)) / SR


def exp_ramp(t, v0, v1, duration):
    """Comme `exponentialRampToValueAtTime` : tient [v1] après [duration]."""
    return v0 * (v1 / v0) ** (np.minimum(t, duration) / duration)


def wave_of(kind, f, t):
    ph = 2 * np.pi * f * t
    if kind == "sine":
        return np.sin(ph)
    s = np.zeros_like(t)  # additif, limité en bande comme Web Audio
    k = 1
    while k * f < SR / 2:
        if kind == "sawtooth":
            s += (-1) ** (k + 1) * np.sin(k * ph) / k
            k += 1
        else:  # triangle
            s += (-1) ** ((k - 1) // 2) * np.sin(k * ph) / k**2
            k += 2
    return s * (2 / np.pi if kind == "sawtooth" else 8 / np.pi**2)


def tone(f, t0, d, kind, g):
    t = times(d + 0.02)
    env = exp_ramp(np.maximum(t - 0.012, 0), g, 0.0008, d - 0.012)
    env = np.where(t < 0.012, g * t / 0.012, env)
    add(wave_of(kind, f, t) * env, t0)


def drum(f, t0, g):
    t = times(0.36)
    freq = exp_ramp(t, f * 2.1, f, 0.09)
    phase = 2 * np.pi * np.cumsum(freq) / SR
    add(np.sin(phase) * exp_ramp(t, g, 0.001, 0.34), t0)


def highpass(x, f, q_db=1.0):
    """Filtre passe-haut du `BiquadFilterNode` de Web Audio (Q en dB)."""
    w = 2 * np.pi * f / SR
    alpha = np.sin(w) / (2 * 10 ** (q_db / 20))
    a0 = 1 + alpha
    b0, b1, b2 = (1 + np.cos(w)) / 2 / a0, -(1 + np.cos(w)) / a0, (1 + np.cos(w)) / 2 / a0
    a1, a2 = -2 * np.cos(w) / a0, (1 - alpha) / a0
    y = np.zeros_like(x)
    for n in range(len(x)):
        y[n] = (
            b0 * x[n]
            + b1 * (x[n - 1] if n > 0 else 0)
            + b2 * (x[n - 2] if n > 1 else 0)
            - a1 * (y[n - 1] if n > 0 else 0)
            - a2 * (y[n - 2] if n > 1 else 0)
        )
    return y


# Graine fixe : régénérer redonne le même son.
NOISE = highpass(np.random.default_rng(19961).uniform(-1, 1, int(0.09 * SR)), 5200)


def shake(t0, g):
    add(NOISE * exp_ramp(times(0.09), g, 0.001, 0.07), t0)


def flute(f, t0, d, g):
    t = times(d + 0.02)
    freq = f + f * 0.012 * np.sin(2 * np.pi * 5.6 * t)
    env = np.where(
        t < 0.05,
        0.001 + (g - 0.001) * t / 0.05,
        np.where(t < d * 0.7, g, exp_ramp(np.maximum(t - d * 0.7, 0), g, 0.001, d * 0.3)),
    )
    add(np.sin(2 * np.pi * np.cumsum(freq) / SR) * env, t0)


def music(sec):
    st = 0.2
    lo = [1, 0, 0, 1, 0, 0, 1, 0]
    hi = [0, 0, 1, 0, 0, 1, 0, 1]
    tune = [(0, 440, 3), (3, 523.3, 1), (4, 587.3, 2), (6, 659.3, 2),
            (8, 587.3, 2), (10, 523.3, 2), (12, 440, 3), (15, 392, 1)]
    steps = int(sec / st)
    for i in range(steps):
        t, p = i * st, i / steps
        g = 0.42 + 0.4 * p
        if lo[i % 8]:
            drum(62, t, g)
        if hi[i % 8]:
            drum(118, t, g * 0.62)
        shake(t, 0.05 + 0.05 * p)
        if p > 0.8 and i % 2 == 1:
            drum(92, t + st / 2, g * 0.5)
    for b in range(int(np.ceil(steps / 16))):
        for s, f, length in tune:
            i = b * 16 + s
            if i < steps:
                flute(f, i * st, length * st * 1.05, 0.14)
    for f in (55, 82.4, 110):
        drum(f, sec, 0.95)
    for j, f in enumerate((110, 167, 231, 307, 419)):
        tone(f, sec, 3 - j * 0.3, "sine", 0.2 - j * 0.025)
    for f in (220, 277.2, 329.6, 440):
        tone(f, sec + 0.04, 1.5, "sawtooth", 0.07)
        tone(f, sec + 0.04, 1.7, "triangle", 0.13)


music(SEC)
buf *= PEAK / np.max(np.abs(buf))
pcm = (buf * 32767).astype("<i2").tobytes()
subprocess.run(
    [sys.argv[1], "-y", "-loglevel", "error", "-f", "s16le", "-ar", str(SR), "-ac", "1",
     "-i", "pipe:0", "-map_metadata", "-1", "-codec:a", "libmp3lame", "-b:a", "128k", str(OUT)],
    input=pcm, check=True,
)
print(f"{OUT.name} : {len(buf) / SR:.2f} s")
