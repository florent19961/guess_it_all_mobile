# Revue ensembles-perso r3 (orchestrateur)

Verdict : **READY** (3ᵉ tour, relu par la session principale, sans Codex).

- La racine est simplifiée : une seule porte `_leaveDraft({editing})` regarde uniquement « éditeur modifié ? », confirme, puis remet l'éditeur vierge ou chargé ; sélectionner, Modifier, Dupliquer, Supprimer, Annuler, Retour et Suivant la traversent ; seul l'enregistrement remet à zéro sans elle (rien à abandonner). Les vérifications éparpillées (`_editing != null`, remise à zéro spéciale de `_delete`) sont supprimées.
- `mounted` vérifié dans la porte ; un refus annule l'action sans rien changer.
- Résidu assumé : Supprimer un ensemble sans rapport pendant un brouillon modifié enchaîne deux confirmations (« Abandonner ? » puis « Supprimer ? ») — rare, jamais silencieux.
- Spec 2-3 marquée `superseded` avec bandeau en tête.
