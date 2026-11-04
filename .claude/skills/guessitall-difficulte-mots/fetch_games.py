"""Télécharge la collection Firestore `games` (lecture seule) en JSON simple.
Usage : python3 fetch_games.py <clé SA> <sortie.json>. N'affiche jamais la clé."""
import json, sys, time, urllib.request, urllib.parse, jwt

key = json.load(open(sys.argv[1]))
now = int(time.time())
assertion = jwt.encode({"iss": key["client_email"], "scope": "https://www.googleapis.com/auth/datastore",
                        "aud": "https://oauth2.googleapis.com/token", "iat": now, "exp": now + 3600},
                       key["private_key"], algorithm="RS256")
tok = json.load(urllib.request.urlopen("https://oauth2.googleapis.com/token", urllib.parse.urlencode(
    {"grant_type": "urn:ietf:params:oauth:grant-type:jwt-bearer", "assertion": assertion}).encode()))["access_token"]

def val(v):
    (k, x), = v.items()
    if k == "mapValue": return {a: val(b) for a, b in x.get("fields", {}).items()}
    if k == "arrayValue": return [val(i) for i in x.get("values", [])]
    if k == "integerValue": return int(x)
    if k == "nullValue": return None
    return x

base = f"https://firestore.googleapis.com/v1/projects/{key['project_id']}/databases/(default)/documents/games"
games, page = [], None
while True:
    url = base + "?pageSize=300" + (f"&pageToken={page}" if page else "")
    r = json.load(urllib.request.urlopen(urllib.request.Request(url, headers={"Authorization": "Bearer " + tok})))
    games += [{k: val(v) for k, v in d.get("fields", {}).items()} for d in r.get("documents", [])]
    page = r.get("nextPageToken")
    if not page: break
json.dump(games, open(sys.argv[2], "w"), ensure_ascii=False)
print(len(games), "parties")
