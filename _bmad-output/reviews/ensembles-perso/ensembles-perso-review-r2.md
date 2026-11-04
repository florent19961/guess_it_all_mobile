# Revue Codex r2 — ensembles-perso

> Copie des findings tels que relayés par la session principale (2026-11-04) ; le rapport
> brut du reviewer n'a pas été transmis à la lane.

**Verdict : NOT READY.** Validé : retours système (Joueurs, Équipes, Mots), détection de
brouillon, test depuis Paramètres, « Continuer » = même `_goNext`, confirmation sur Suivant.

1. **MAJOR** (2ᵉ finding sur le même mécanisme) — `_select` (`fiesta_ensembles_screen.dart:139`,
   `:311`) ne confirme que si `_editing != null` : un brouillon NEUF modifié peut être perdu ou
   contredire la sélection ; « Dupliquer » (`:174`) ne confirme jamais. → Simplifier la racine :
   une seule porte (`_leaveDraft()`) qui ne regarde que « l'éditeur est-il modifié ? »,
   confirme, remet l'éditeur à l'état voulu ; supprimer les vérifications éparpillées.
2. **MINOR** — spec 2-3 (`:4`, `:39`, `:126`) : bandeau « Remplacé par feat/ensembles-perso
   (2026-11-04) » tout en haut, statut `superseded`.
