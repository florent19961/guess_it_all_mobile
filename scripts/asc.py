#!/usr/bin/env python3
"""Lecture de l'API App Store Connect avec la clé d'équipe locale (runbook :
docs/releases-stores.md §App Store Connect depuis WSL).

    python3 -I scripts/asc.py builds      # derniers builds reçus par Apple
    python3 -I scripts/asc.py versions    # versions App Store et leur état
    python3 -I scripts/asc.py get <chemin>  # GET brut, ex. /v1/apps/6756429415

LECTURE SEULE : aucune requête d'écriture ici. Le contenu de la clé et le jeton
ne sont jamais affichés. Dépendance : PyJWT avec cryptography (ES256).
"""

import json
import os
import sys
import time
import urllib.error
import urllib.request

import jwt

KEY_ID = os.environ.get("ASC_KEY_ID", "3HXC7Q7999")
ISSUER_ID = os.environ.get("ASC_ISSUER_ID", "87c6e544-ee5c-4964-93ac-4d4fef23acb7")
KEY_PATH = os.environ.get(
    "ASC_KEY_PATH", f"/mnt/c/Users/flore/.stores/AuthKey_{KEY_ID}.p8")
APP_ID = "6756429415"  # Guess It All, com.guessitall.guessItAllMobile


def get(path):
    with open(KEY_PATH) as f:
        key = f.read()
    now = int(time.time())
    token = jwt.encode(
        {"iss": ISSUER_ID, "iat": now, "exp": now + 600,
         "aud": "appstoreconnect-v1"},
        key, algorithm="ES256", headers={"kid": KEY_ID, "typ": "JWT"})
    request = urllib.request.Request(
        "https://api.appstoreconnect.apple.com" + path,
        headers={"Authorization": f"Bearer {token}"})
    try:
        with urllib.request.urlopen(request) as response:
            return json.load(response)
    except urllib.error.HTTPError as error:
        sys.exit(f"HTTP {error.code} : {error.read()[:500].decode()}")


def builds():
    data = get(f"/v1/builds?filter[app]={APP_ID}&sort=-uploadedDate&limit=6"
               "&fields[builds]=version,processingState,uploadedDate,expired,"
               "preReleaseVersion&include=preReleaseVersion"
               "&fields[preReleaseVersions]=version")
    versions = {x["id"]: x["attributes"]["version"]
                for x in data.get("included", [])}
    for build in data["data"]:
        a = build["attributes"]
        pre = build.get("relationships", {}).get(
            "preReleaseVersion", {}).get("data") or {}
        print(f'{versions.get(pre.get("id"), "?")}+{a["version"]}  '
              f'{a["processingState"]}  {a["uploadedDate"]}'
              f'{"  expiré" if a["expired"] else ""}')


def versions():
    data = get(f"/v1/apps/{APP_ID}/appStoreVersions?limit=6"
               "&fields[appStoreVersions]=versionString,appStoreState,build"
               "&include=build&fields[builds]=version")
    numbers = {x["id"]: x["attributes"]["version"]
               for x in data.get("included", [])}
    for version in data["data"]:
        a = version["attributes"]
        build = version.get("relationships", {}).get(
            "build", {}).get("data") or {}
        attached = numbers.get(build.get("id"))
        print(f'{a["versionString"]}  {a["appStoreState"]}  '
              f'build {"+" + attached if attached else "aucun"}')


if __name__ == "__main__":
    match sys.argv[1:]:
        case ["builds"]:
            builds()
        case ["versions"]:
            versions()
        case ["get", path]:
            print(json.dumps(get(path), ensure_ascii=False, indent=1))
        case _:
            sys.exit(__doc__)
