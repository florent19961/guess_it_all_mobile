"""Agrège games.json en données par mot et par niveau de difficulté.
Usage : python3 analyze.py <games.json> <dossier words/fr du repo> <sortie data.json>

Unité de mesure : un mot dans une manche d'une partie (« passage »). Son temps est le
CUMUL de tous ses affichages dans la manche (passes et fins de tour comprises) jusqu'à
ce qu'il soit trouvé. Un passage jamais trouvé dans la manche est « non trouvé ».
Un passage trouvé en moins de MIN_S secondes cumulées est écarté (tap accidentel)."""
import json, sys, glob, os, statistics as st
from collections import defaultdict

MIN_S = 1.0
games = json.load(open(sys.argv[1]))
files = [f for f in glob.glob(os.path.join(sys.argv[2], "*.json")) if not f.endswith("_annotated.json")]

# Difficulté actuelle, lue dans les fichiers de mots du repo.
current = {}
for f in files:
    d = json.load(open(f))
    for w in d["words"]:
        current[(d["categoryId"], w["word"])] = w.get("difficulty")

words = {}
times = defaultdict(list)          # (niveau, manche) -> temps cumulés des passages trouvés
lv = defaultdict(lambda: defaultdict(int))  # (niveau, manche) -> compteurs de passages
dropped = {"tooFast": 0, "noDuration": 0}

for g in games:
    meta = g.get("wordMetadata", {})
    limit = (g.get("turnDuration") or 60) * 1000
    invalid = {(e["round"], e["turn"], e["word"]) for e in g["events"] if e["eventType"] == "invalidated"}
    passages = defaultdict(list)
    for e in sorted(g["events"], key=lambda e: e["timestamp"]):
        if e["eventType"] in ("guessed", "passed", "expired"):
            passages[(e["round"], e["word"])].append(e)
    for (rnd, word), evs in passages.items():
        m = meta.get(word) or {}
        cat = m.get("categoryId")
        if cat is None:
            continue  # mot personnalisé : pas de difficulté à juger
        key = (cat, word)
        level = current.get(key, m.get("difficulty"))
        r = min(max(rnd, 1), 3) - 1
        w = words.setdefault(key, {"word": word, "cat": cat, "level": level, "games": set(),
                                   "shows": [0, 0, 0], "passes": [0, 0, 0], "found": [0, 0, 0],
                                   "notFound": [0, 0, 0], "r1": []})
        w["games"].add(g["gameId"])
        total, known, found, shows, passes = 0, True, False, 0, 0
        for e in evs:
            shows += 1
            d = e.get("durationMs")
            if d is None or d < 0 or d > limit:
                known = False
            else:
                total += d
            if e["eventType"] == "passed":
                passes += 1
            if e["eventType"] == "guessed" and (rnd, e["turn"], word) not in invalid:
                found = True
                break
        secs = total / 1000
        if found and known and secs < MIN_S:
            dropped["tooFast"] += 1
            continue
        w["shows"][r] += shows
        w["passes"][r] += passes
        c = lv[(level, rnd)]
        c["passages"] += 1; c["shows"] += shows; c["passes"] += passes
        if not found:
            w["notFound"][r] += 1; c["notFound"] += 1
            continue
        w["found"][r] += 1; c["found"] += 1
        if not known:
            dropped["noDuration"] += 1
            continue
        times[(level, rnd)].append(secs)
        if rnd == 1:
            w["r1"].append(round(secs, 1))

def summary(xs):
    if not xs: return None
    return {"n": len(xs), "mean": round(st.mean(xs), 2), "median": round(st.median(xs), 2),
            "sd": round(st.pstdev(xs), 2), "values": sorted(round(x, 1) for x in xs)}

levels = sorted({l for (l, _) in lv if l})
rounds = sorted({r for (_, r) in lv})
out_words = []
for w in words.values():
    if sum(w["found"]) + sum(w["passes"]) == 0:
        continue
    w["games"] = len(w["games"])
    out_words.append(w)
json.dump({
    "generatedAt": max(g.get("syncedAt") or "" for g in games),
    "games": len(games), "minSeconds": MIN_S, "dropped": dropped,
    "levels": levels, "rounds": rounds,
    "times": {f"{l}-{r}": summary(times[(l, r)]) for l in levels for r in rounds},
    "counts": {f"{l}-{r}": dict(lv[(l, r)]) for l in levels for r in rounds},
    "words": out_words,
}, open(sys.argv[3], "w"), ensure_ascii=False)
print(len(out_words), "mots ; écartés :", dropped)
for l in levels:
    print(l, [(r, times[(l, r)] and round(st.median(times[(l, r)]), 1), dict(lv[(l, r)])) for r in rounds])
