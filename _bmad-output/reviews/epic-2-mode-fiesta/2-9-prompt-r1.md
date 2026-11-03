# Revue r1 — story 2-9 « Mot compte double » (tier risqué : scoring ②, machine à états ①, analytics ⑤)

Tu es le reviewer Opus adversarial de la lane. Tu lis **le patch** `2-9-patch-r1.diff` (même
dossier), calculé contre `git merge-base origin/main HEAD` (`e5d81c9`, 2-8 mergée). Ne lance
jamais `git diff` toi-même. Lis le code **avant** la spec, puis confronte les deux. Écris ton
rapport dans `2-9-review-r1.md` (même dossier). Le **mutation testing est obligatoire** sur les
tests ajoutés.

## Objectif de la story

Spec : `_bmad-output/specs/fiesta/2-9-mot-compte-double.md` (AC 1 à 8). Epic :
`_bmad-output/specs/fiesta/epic-fiesta.md` (catalogue `double_points`, Q8). Journal :
`_bmad-output/reviews/epic-2-mode-fiesta/journal-arbitrages.md` (2-8 : un seul « tour »).
Maquette : écrans `cd`, `turn`, `verif`, `results`.

## Décisions déjà prises (ne pas rouvrir)

- Dépense au départ du tour (`startTurnTimer`), pas à l'interrupteur.
- `resolveTurn` reste pur, multiplicateur en paramètre (défaut 1).
- Une partie Classique reste strictement inchangée ; scores dans `Team` ; règle 7 : champs
  additifs optionnels seulement, pas de bump de `kCurrentSchemaVersion`.
- Un tour = tour de fin de manche + sa continuation en N+1 (journal, 2-8).
- Tests au minimum, niveau provider seulement.

## Interprétations de l'implémenteur (à challenger)

1. **Armement dans `fiesta.turn['doublePoints']`** : `'armed'` à l'interrupteur, `'spent'` au
   départ. Survit au kill (AC7), effacé par le snapshot (AC4), vidé par `_fiestaAfterTurn`.
2. **Nouvelle clé optionnelle `fiesta.chargesUsed`** (`[{catalogId, teamId, round}]`, omise si
   vide) : une instance tirée/fixée est `both`, partagée par toutes les équipes, donc le décompte
   par équipe ne peut pas vivre sur l'instance. Charges restantes = charges des instances
   `double_points` de l'équipe − dépenses de **cette** manche : la perte en fin de manche (AC6)
   est automatique, rien à remettre à zéro. La même liste alimente « Bonus utilisés » au récap.
   Lead prévenu (forme du blob Fiesta seulement, Classique n'a pas de clé `fiesta`).
3. **Continuation** : un tour joué à ×2 qui finit la manche reste ×2 en continuation (même
   tour), sans dépenser la charge de N+1, et l'entrée de récap reste en M_N. Un tour non activé
   peut s'activer en continuation avec une charge de N+1 (AC8, lu avec la définition 2-8).
4. **Q8** : refus si l'équipe a déjà ≥ 2 autres modificateurs en jeu (`turnModifiers`, sans
   `double_points`). Une charge disponible mais non activée ne compte pas comme modificateur.
   Ce cas n'arrive pas avec le tirage actuel (`canAdd` plafonne déjà) ; il protège 2-10.
5. **Analytics (contrat 2-7)** : `double_points` n'est dans `WordEvent.modifiers` que si le ×2
   s'applique au tour (`'spent'`), y compris en continuation. Badges du tour : idem, libellé
   « ×2 Mot compte double ».
6. **Vérification** : l'aperçu « Score : N points » applique ×2, et une ligne « Mots devinés 5 ·
   Mot compte double ×2 · Points du tour 10 » s'affiche seulement si ×2. Classique : texte
   identique.
7. **Avant-tour** : carte « Bonus » avec l'interrupteur, visible si charge restante ou déjà armé ;
   figée (« Mot compte double activé ») une fois dépensée ; refus Q8 expliqué en texte.
8. **Pas de test ajouté dans `turn_resolution_test.dart`** (consigne lead : provider seulement) ;
   le multiplicateur est couvert par les tests provider (mutants : multiplicateur forcé à 1,
   dépense retirée, filtre de manche retiré → tous rouges).

## Questions précises

- **Double comptage** : après `restorePreValidationState` depuis la transition (fin de manche à
  ×2) ou depuis l'avant-tour suivant, `chargesUsed` et les scores valent-ils ceux du snapshot ?
  Une charge peut-elle être dépensée deux fois (double `startTurnTimer`, reprise après kill
  pendant le compte à rebours) ?
- **`chargesUsed` (demande du lead)** : relecture tolérante quand la clé est absente (partie
  Fiesta écrite avant 2-9) ou corrompue (pas une liste, entrée illisible, types faux) : jamais
  de throw, entrée illisible ignorée seule ? Le retour arrière (`restorePreValidationState`)
  restaure-t-il exactement la liste du snapshot (dépense annulée si le tour est rejoué, conservée
  sinon) ? Note : le blob `fiesta` n'a jamais été publié en store (lead), le risque règle 7 est nul.
- **Charges** : peut-on armer sans charge (UI vs provider), ou désarmer après dépense ?
- **Continuation** : `turn` est-il bien conservé dans la branche fin de manche et vidé à la vraie
  fin ? Retour arrière depuis la continuation ?
- **Classique** : `startTurnTimer` ne lit plus `_teams` hors Fiesta (régression trouvée par la
  suite complète puis corrigée) ; état persisté identique, aucune clé `fiesta`.
- **Récap** : nom d'équipe renommée, équipe absente.
- Deux plateformes : rien de `Platform.*`.

## Format attendu

Pour chaque finding : sévérité (BLOCKER / MAJOR / MINOR / NIT), `fichier:ligne`, scénario
concret, correction proposée. Verdict final : READY ou NOT READY.
