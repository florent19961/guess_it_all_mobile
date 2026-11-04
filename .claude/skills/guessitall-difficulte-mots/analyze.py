"""Agrège games.json en données par mot et par niveau de difficulté.
Usage : python3 analyze.py <games.json> <dossier words/fr du repo> <sortie data.json>"""
import json, sys, glob, os, statistics as st
from collections import defaultdict

games = json.load(open(sys.argv[1]))
files = [f for f in glob.glob(os.path.join(sys.argv[2], "*.json")) if not f.endswith("_annotated.json")]

# Difficulté actuelle, lue dans les fichiers de mots du repo.
current = {}
for f in files:
    d = json.load(open(f))
    for w in d["words"]:
        current[(d["categoryId"], w["word"])] = w.get("difficulty")

words = {}  # clé (catégorie, mot)
times = defaultdict(list)  # (niveau, manche) -> durées en s des mots devinés
outcomes = defaultdict(lambda: defaultdict(int))  # (niveau, manche) -> compteurs
dropped = 0
for g in games:
    meta = g.get("wordMetadata", {})
    limit = (g.get("turnDuration") or 60) * 1000
    invalid = {(e["round"], e["turn"], e["word"]) for e in g["events"] if e["eventType"] == "invalidated"}
    for e in g["events"]:
        m = meta.get(e["word"]) or {}
        cat = m.get("categoryId")
        if cat is None:
            continue  # mot personnalisé : pas de difficulté à juger
        key = (cat, e["word"])
        level = current.get(key, m.get("difficulty"))
        w = words.setdefault(key, {"word": e["word"], "cat": cat, "level": level,
                                   "playedLevel": m.get("difficulty"), "games": set(),
                                   "r1": [], "guessed": [0, 0, 0], "passed": [0, 0, 0], "expired": [0, 0, 0], "invalidated": 0})
        w["games"].add(g["gameId"])
        r = min(max(e["round"], 1), 3) - 1
        t = e["eventType"]
        outcomes[(level, e["round"])][t] += 1
        if t in ("passed", "expired"):
            w[t][r] += 1
        elif t == "invalidated":
            w["invalidated"] += 1
        elif t == "guessed":
            if (e["round"], e["turn"], e["word"]) in invalid:
                continue
            w["guessed"][r] += 1
            d = e.get("durationMs")
            if d is None or d <= 0 or d > limit:
                dropped += 1
                continue
            times[(level, e["round"])].append(d / 1000)
            if e["round"] == 1:
                w["r1"].append(round(d / 1000, 1))

def summary(xs):
    if not xs: return None
    return {"n": len(xs), "mean": round(st.mean(xs), 2), "median": round(st.median(xs), 2),
            "sd": round(st.pstdev(xs), 2), "values": sorted(round(x, 1) for x in xs)}

levels = sorted({l for (l, _) in times if l})
rounds = sorted({r for (_, r) in times})
out_words = []
for w in words.values():
    if sum(w["guessed"]) + sum(w["passed"]) == 0:
        continue
    w["games"] = len(w["games"])
    out_words.append(w)
json.dump({
    "generatedAt": max(g.get("syncedAt") or "" for g in games),
    "games": len(games), "droppedDurations": dropped,
    "levels": levels, "rounds": rounds,
    "times": {f"{l}-{r}": summary(times[(l, r)]) for l in levels for r in rounds},
    "outcomes": {f"{l}-{r}": dict(outcomes[(l, r)]) for l in levels for r in rounds},
    "words": out_words,
}, open(sys.argv[3], "w"), ensure_ascii=False)
print(len(out_words), "mots ; durées écartées :", dropped)
for l in levels:
    print(l, [(r, (times[(l, r)] and round(st.median(times[(l, r)]), 1)), len(times[(l, r)])) for r in rounds])
