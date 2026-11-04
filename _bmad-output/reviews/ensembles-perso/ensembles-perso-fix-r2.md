# Corrections r2 — ensembles-perso

## 1 MAJOR — une seule porte (`_leaveDraft`) : racine simplifiée

**Pourquoi simplifier plutôt que corriger.** C'est le 2ᵉ finding sur le même mécanisme (perte
silencieuse du brouillon) : r1 avait ajouté une confirmation par action, avec des conditions
propres à chacune (`_editing != null` dans `_select`, rien dans `_duplicate`, reset ad hoc dans
`_delete`, `_cancelEdit` séparé). Chaque condition était un cas à oublier. Règle « même
mécanisme qui revient → simplifier la racine » : une seule fonction, une seule question.

**Décision.** `Future<bool> _leaveDraft({FiestaEnsemble? editing})` :
- ne regarde que `_dirty` (« l'éditeur diffère-t-il de ce qu'il a chargé ? »), jamais `_editing`
  — brouillon neuf ou modification, même traitement ;
- si modifié : « Abandonner les modifications ? » ; refus → `false`, rien ne bouge ;
- sinon / accepté : l'éditeur repart vierge, ou chargé avec `editing` (Modifier) → `true`.

Appelants, tous sans condition propre : sélectionner (`_select`), Modifier (`_edit`, qui
sélectionne aussi l'ensemble), Dupliquer, Supprimer (avant la confirmation de suppression),
Annuler (`onCancel: _leaveDraft`), Retour bouton et système (`_back`), Suivant (`_next`).
Supprimés : `_confirmDiscard`, `_resetEditor`, `_cancelEdit`, le test `_editing != null` de
`_select`, le reset spécial de `_delete`. Seul `_onSaved` remet l'éditeur à zéro sans porte
(rien à abandonner : c'est enregistré).

**Choix assumé.** Toute action de la liste passe la porte, même Supprimer ou Dupliquer un
ensemble sans rapport avec le brouillon : une règle sans exception plutôt qu'un cas par action.
Coût : une confirmation de plus dans ce cas rare, jamais une perte silencieuse.

**Preuve.** `lib/screens/fiesta_ensembles_screen.dart` `_leaveDraft` et ses appelants ;
`lib/screens/CLAUDE.md` (ligne de l'écran). Pas de test ajouté (UI de confirmation) : recette.

## 2 MINOR — spec 2-3

**Corrigé.** Statut `superseded`, bandeau en tête juste après le front-matter (parcours et
contrat → `lib/screens/CLAUDE.md` ; le stockage décrit reste valable). L'ancienne note
« Point d'entrée pour 2-4 » renvoie au bandeau.

## Tests

Inchangés ; la suite complète passe. Les deux tests du flux restent verts : le premier traverse
la porte (Enregistrer → `_onSaved`, puis Suivant → `_leaveDraft` sans brouillon).
