# Revue — kit d'aide (prise en main), round 1

**Tier** : standard (UI) + 3 clés booléennes neuves `SharedPreferences`.
**Patch** : `_bmad-output/reviews/prise-en-main/help-kit-patch-r1.diff` (merge-base `origin/main`, `lib test docs`).
Lis le patch, pas `git diff`. Lecture seule. Rapport dans `help-kit-review-r1.md` à côté.

## Objectif de la lane

Kit d'aide **réutilisable**, branché seulement sur Règles (3 boutons) et Accueil (prompt
« Première partie ? » sur le premier « Jouer »). Les autres écrans seront branchés plus tard
d'après `lib/widgets/help/WIRING.md`.

## Décisions (Florent, prioritaires sur la maquette)

1. Pas de voile automatique à la première ouverture d'un écran : un « ? » par écran rejoue l'aide.
2. Seule aide automatique : première partie du téléphone, au premier tour de chaque joueur,
   avant-tour + vérification (`FirstGameHelp`). Vérification très explicite (vert / rouge /
   toucher pour corriger / faire défiler).
3. Tuto 4 cartes : carte « principe » réécrite ; carte « Trouvé / Passer » avec la pénalité
   enregistrée (`GameSettings.passPenalty`), « Passer ne coûte rien » à 0 s.
4. Aucun texte d'aide ne parle d'un score entre deux tours ou manches (scores cachés en jeu).
5. Pas de suggestions de joueurs connus.
6. Clés neuves `guessItAll_tutorialSeen`, `guessItAll_fiestaTutorialSeen`,
   `guessItAll_firstGameDone`, absentes = false (règle 7 : additif, pas de migration).
7. Tests minimaux : flags (absent = false, écrire puis relire) + phrase de pénalité 0/3/5 s.
   Un test existant (`home_screen_new_game_test.dart`) a été ajusté : il sème
   `tutorialSeen = true` pour suivre le chemin après le prompt.

## Questions précises

1. `CoachMarks` : mesure de la cible après `Scrollable.ensureVisible` — correcte si la cible est
   dans une liste défilante, ou si elle n'est pas montée (saut d'étape) ? Fuite ou boucle
   possible dans `_next` / `_focusCurrent` ?
2. Placement de la bulle (au-dessus / au-dessous / en bas pour une grande cible) : un cas où
   elle sort de l'écran ou masque totalement la cible sur petit téléphone ?
3. Retour système Android sur l'overlay et sur les tutos : ferme proprement ? iOS : pas de
   geste retour nécessaire (bouton Passer) — OK pour la règle 8 ?
4. `FirstGamePrompt.maybeShow` marque le flag AVANT la question : acceptable ?
5. Joueurs existants (déjà en store) : `firstGameDone` absent = false, donc leur prochaine partie
   affichera les aides automatiques à chaque joueur. Est-ce un problème à remonter ?
6. Textes de `help_content.dart` : un texte faux par rapport au comportement réel de l'écran
   (vérifie contre les écrans existants) ? Un texte qui mentionne un score en cours de partie ?
7. Tests : redondants, échafaudage, ou trop faibles ?

## Format attendu

Par finding : sévérité (BLOCKER / MAJOR / MINOR / NIT), `fichier:ligne`, constat, correction
proposée. Verdict final READY / NOT READY.
