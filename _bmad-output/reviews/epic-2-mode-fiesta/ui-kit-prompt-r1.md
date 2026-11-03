# Revue r1 — lane D « kit visuel Fiesta » (tier standard)

Tu es le reviewer Opus adversarial de la lane. Tu lis **le patch** `ui-kit-patch-r1.diff` (même
dossier), calculé sur la merge-base avec `origin/main` — jamais `git diff` toi-même. Tu lis le
code **avant** la spec, puis tu confrontes. Rapport dans `ui-kit-review-r1.md` (même dossier).

## Objectif de la lane

Préparer, **sans les brancher**, les briques visuelles que 2-8 et 2-11 câbleront dans
`turn_screen.dart` (les stories cœur sont sérialisées sur `game_provider` / `game_state`) :

1. `lib/utils/reversed_word.dart` — `reversedWordDisplay(String)` : MAJUSCULES puis inversion de
   la chaîne entière **par graphèmes** (« Star Wars » → « SRAW RATS »).
2. `lib/widgets/fiesta/fiesta_turn_widgets.dart` :
   - `FiestaWordCard` : un mot (option `reversed`), actions Passer / « Trouvé ✓ » en callbacks
     (`null` = désactivé), animation d'apparition + **verrou des taps ~0,3 s** à chaque nouveau
     mot (2-11 critère 9) ;
   - `TwoWordsLayout` : deux cartes empilées, callbacks indépendants, **une seule carte sans
     place vide** si `secondWord == null` ;
   - `MimeConstraintBanner` : bandeau statique pour `mime_no_arms`, `mime_no_fists`,
     `mime_eyes_closed`, `draw`, textes du catalogue.

Specs : `_bmad-output/specs/fiesta/2-8-effets-de-tour-catalogue.md` (`reversed`, contraintes
annoncées, piège « graphèmes »), `_bmad-output/specs/fiesta/2-11-deux-mots-a-la-fois.md` (deux
cartes, verrou 0,3 s). Maquette : écrans « Mot à l'envers » et « Deux mots » (carte blanche, mot
en Bangers, « Passer · −3 s » gris / « Trouvé ✓ » cyan, animation `pop` 0,94 → 1).

## Décisions déjà prises (ne pas rouvrir)

- Périmètre : nouveaux fichiers sous `lib/widgets/fiesta/` + un helper pur sous `lib/utils/`.
  Aucun écran, provider ni modèle existant touché. Pas d'annonce d'avant-tour ni de badges (2-5).
- Tests : **un seul** test pur (`test/utils/reversed_word_test.dart`), aucun widget test.
- Pas de `Platform.*`, thème existant (`AppColors`, `AppTextStyles`).

## Interprétations de l'implémenteur (à challenger)

1. Nom `reversedWordDisplay` (consigne de la lane) ; la spec 2-8 dit `reverseForDisplay`.
2. Le verrou = l'animation d'entrée (`AnimationController` 300 ms) : taps ignorés tant qu'elle
   tourne. Déclenché au montage et quand `word` change (`didUpdateWidget`), pas sur un changement
   de `reversed`. Pas de `ValueKey(word)` (des mots en double dans le pool feraient des clés
   dupliquées) : conséquence assumée, quand B glisse en position A (dernier mot), la carte se
   ré-anime et se reverrouille 300 ms.
3. Pendant le verrou, les boutons gardent leur apparence active (verrou invisible, très court).
4. Textes du bandeau = `name` / `description` du catalogue 2-2, pas ceux de la maquette.
   Ids non supportés → `assert` (scénario impossible côté appelant, qui filtre sur
   `MimeConstraintBanner.icons.keys`).
5. `passLabel` libre fourni par l'appelant (« Passer · −3 s », « Passer (bloqué) »,
   « Passer · gratuit ») : la carte ne calcule rien.

## À chercher en priorité

- Inversion : graphèmes cassés (accent combiné, emoji ZWJ, drapeaux), `toUpperCase` qui change
  la longueur (« ß » → « SS ») avant le découpage.
- Verrou : un tap qui passe quand même (callback capturé, double tap pendant `forward(from: 0)`),
  fuite d'`AnimationController`, verrou qui ne se relance pas quand le mot change.
- Débordement sur petit écran (deux cartes + chrono + badges sans défilement, 2-11 recette 6).
- Tout ce qui ferait de la logique de jeu dans ces widgets.

Verdict attendu : READY ou NOT READY, findings classés (bloquant / important / mineur), chacun
avec fichier:ligne et correctif minimal.
