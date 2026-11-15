# Corrections r1 — L-TOMBE-MODÈLE

Base : branche rebasée sur `origin/main` 3562b9b (après L-CACHE). Chaque mutation ci-dessous a été appliquée seule
par script, puis `cartridge_drop_test`, `ensemble_validation_test` et `cartridge_gifts_test` ont été lancés via
`with-test-slot`, et le fichier a été restauré : **6 mutations sur 6 tuées**.

| Finding | Décision | Preuve |
|---|---|---|
| MAJOR — ensemble dont le seul réglage est `dropFrequency` non testé | Corrigé | `test/models/fiesta/ensemble_validation_test.dart`, test « cartouches qui tombent, seul réglage : enregistrable, clé à part, doublon au même cran ». Il vérifie : `hasActiveSetting` vrai ; `validateEnsemble` vide ; `settingsKey` différente d'un ensemble vide et de Souvent ; doublon refusé au même cran ; pas de clé `dropFrequency` à Jamais. Mutations tuées : `dropFrequency` retiré de `hasActiveSetting` ; retiré de `settingsKey`. |
| MINOR — `giftPool` appelé avec `teamId: ''` / `{'*'}` | Corrigé | Le filtre commun est extrait dans `randomPool(rules, round, roundRules, gap, includeBlockGuesser)` (`lib/models/fiesta/cartridge_gifts.dart`). `giftPool` garde sa signature et son comportement : il lui passe `blockableTeamIds.any((id) => id != teamId)`. `dropPool` lui passe `guesserIds.length >= 2`, sans sentinelle. Appelants existants (`roundGifts`, `planChallenge`, `game_provider`) inchangés. Mutations tuées : `includeBlockGuesser` de `giftPool` forcé à vrai (test « Bloquer un devineur seulement si une AUTRE équipe a 3 joueurs ») ; celui du drop passé à `>= 1`. |
| MINOR — `gameId` de la graine et valeurs des chances non testés | Corrigé | `cartridge_drop_test.dart` : le tirage change avec `gameId: 'h'`, et les chances valent exactement `[0, 1/6, 1/4, 1/2]`. Mutations tuées : `gameId` retiré de `dropSeed` ; trois chances décalées en gardant leur ordre (1/5, 1/4, 1/3). |
| MINOR — `tracking_evolution` annonce une graine incomplète | Corrigé | `docs/tracking_evolution.md` : « `(gameId, tour, joueur, sauts de l'équipe)` ». `lib/models/CLAUDE.md` cite aussi `randomPool`. |
