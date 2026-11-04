# Corrections r1 — ensembles-perso

| # | Décision | Preuve |
|---|---|---|
| 1 MAJOR | **Corrigé.** Même motif que Paramètres : `PopScope(canPop: false)` qui appelle la fonction locale `back()`, partagée avec `AppBackButton` (destination = bouton visible). Joueurs → Paramètres, ou ensembles en Personnalisé ; Équipes → Joueurs ; Mots → Joueurs (mots sauvegardés). Pas de test (motif épinglé par `settings_system_back_test.dart`). | `players_screen.dart`, `teams_screen.dart`, `words_screen.dart` (`void back()` + `PopScope` dans `build`) |
| 2 MAJOR | **Corrigé.** L'éditeur remonte à chaque rendu `onDirty` (saisie ≠ ce qui a été chargé, comparaison JSON des règles + nom ; ouvrir/fermer un réglage ne compte pas). L'écran confirme « Abandonner les modifications ? » (`AppConfirmDialog`, style de l'app) avant : Modifier un autre, Annuler, Retour (bouton **et** système), Suivant. Sélectionner un ensemble pendant une modification → même confirmation puis éditeur remis en « nouvel ensemble ». Modifier sélectionne aussi l'ensemble modifié. L'écran ne montre donc jamais un éditeur qui contredit la sélection. Pas de test (UI de confirmation, pas un invariant de zone risquée) : à vérifier en recette. | `fiesta_ensembles_screen.dart` `_confirmDiscard`, `_back`, `_select`, `_edit`, `_cancelEdit`, `_next` ; `fiesta_ensemble_editor.dart` `onDirty` |
| 3 MAJOR | **Corrigé en partie.** Nouveau test « Personnalisé : « Suivant » des Paramètres mène à l'écran des ensembles » depuis l'app complète sur Paramètres (surface 700 × 1300). Le « Continuer » de l'avertissement n'est **pas** couvert : le comptage des mots (`getTotalWordsCountAsync`) ne se termine pas sous l'horloge simulée du test (essayé, l'écran reste sur Paramètres) ; le test passe donc en mots écrits à la main. Les deux sorties appellent la même `_goNext`. | `test/screens/fiesta_ensembles_flow_test.dart` |
| 4 MINOR | **Corrigé.** Commentaire de `fiesta_ensemble.dart` réécrit ; spec 2-3 marquée « Remplacé par `feat/ensembles-perso` (2026-11-04) ». | `fiesta_ensemble.dart:28`, spec 2-3 §Notes d'implémentation |

## Mutation des tests

- Test de route : `_goNext` renvoie aux Joueurs même en Personnalisé → **rouge** (reste sur
  `players`). Rétabli → vert.
- Test de non-régression (r1) : `_onSaved` ne sélectionne plus l'ensemble enregistré → **rouge**
  (« Suivant » grisé). Rouge aussi sur `origin/main` (écrit avant le correctif).

## Hors demande, tranché seul

- « Suivant » demande aussi la confirmation si une saisie est en cours (même perte silencieuse).
