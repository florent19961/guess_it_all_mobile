# Rend en WAV les sons validés (même synthèse que la page de comparaison).
import sys, wave, numpy as np
SR = 44100

def env(n_t, t0, gain, attack, dur):
    t = n_t - t0
    e = np.zeros_like(t)
    a = (t >= 0) & (t < attack)
    e[a] = 1e-4 * (gain / 1e-4) ** (t[a] / attack)
    d = (t >= attack) & (t < dur)
    e[d] = gain * (1e-4 / gain) ** ((t[d] - attack) / (dur - attack))
    return e

def wave_of(kind, f, t):
    ph = 2 * np.pi * f * t
    if kind == "sine":
        return np.sin(ph)
    if kind == "triangle":  # additif, limité en bande comme Web Audio
        s = np.zeros_like(t)
        k = 1
        while k * f < SR / 2:
            s += ((-1) ** ((k - 1) // 2)) * np.sin(k * ph) / k**2
            k += 2
        return s * 8 / np.pi**2

def tone(buf, t, t0, f, gain, dur, kind="sine", attack=0.004):
    buf += wave_of(kind, f, t - t0) * env(t, t0, gain, attack, dur)

def bell(buf, t, t0, f, gain=0.28, dur=0.55):
    tone(buf, t, t0, f, gain, dur)
    tone(buf, t, t0, f * 2.76, gain * 0.18, dur * 0.45)
    tone(buf, t, t0, f * 5.4, gain * 0.06, dur * 0.2)

def render(length, fn, path, peak=0.89):
    t = np.arange(int(SR * length)) / SR
    buf = np.zeros_like(t)
    fn(buf, t)
    buf *= peak / np.max(np.abs(buf))
    pcm = (buf * 32767).astype("<i2")
    with wave.open(path, "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR); w.writeframes(pcm.tobytes())

def ding(buf, t):  # A · Cloche douce
    bell(buf, t, 0.0, 1318.5, 0.24)
    bell(buf, t, 0.075, 1975.5, 0.22, 0.6)

def gong(buf, t):  # A · Gong de fin
    for i, f in enumerate([784, 659.3, 523.3]):
        tone(buf, t, i * 0.14, f, 0.3, 0.32, "triangle")
    for f in [261.6, 329.6, 392, 523.3]:
        bell(buf, t, 0.44, f, 0.17, 1.3)

out = sys.argv[1]
render(0.72, ding, out + "/ding.wav")
render(1.78, gong, out + "/end_of_turn.wav")
