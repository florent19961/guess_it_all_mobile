---
name: teach-back
description: Contrôle de compréhension utilisateur AVANT tout closeout de PR Guess It All (guessitall-workflow §7) — vérifie que Florent comprend ce qui vient d'être implémenté avant que ça soit mergé. S'auto-déclenche quand un closeout approche ("on merge ?", "lance le closeout", PR prête + go imminent) SAUF skip explicite ou story triviale (dosage). Aussi sur demande — "teach-back", "explique-moi ce qu'on a fait", "est-ce que j'ai bien compris".
---

# teach-back — le propriétaire comprend ce qu'il merge

**But** : transférer la propriété mentale du changement, pas évaluer. Le code est
vérifié par la revue du tier (reviewer Opus) ; CE contrôle vérifie l'humain. Sortie réussie =
Florent peut reformuler le changement en 2-3 phrases ET répondre aux
questions-scénario clés. C'est aussi le dernier détecteur de désalignement
produit : une réponse « hein ? non, je pensais que ça faisait X » n'est pas un
trou de compréhension, c'est un finding.

## Quand (et quand PAS)

- **Défaut : avant CHAQUE closeout de PR** (story ou epic). L'agent qui
  s'apprête à invoquer `guessitall-pr-closeout` lance teach-back d'abord.
- **Skip AUTO** si la story est triviale au sens du dosage (fix mécanique,
  1 fichier, 0 contrat) — ne pas demander, skipper.
- **Skip sur demande** : « pas de teach-back », « merge direct » → skip sans débat.
- **Profondeur dosée** : story simple = 2-3 questions ; story risquée
  (machine à états, scoring, persistance, sync) = 4-6 ; closeout d'epic = 5-8, centrées sur les
  invariants transverses.

## Protocole

1. **Synthèse d'ancrage (30 s de lecture, PAS un cours)** : 3-5 phrases —
   ce qui change pour l'utilisateur du produit, ce qui change dans le système,
   le compromis principal accepté. Puis on passe aux questions.
2. **Questions UNE PAR UNE** (jamais de rafale), du concret vers le pourquoi :
   - *Comportement* : « Maintenant, si un utilisateur fait X, il se passe quoi ? »
   - *Frontière* : « Et dans le cas limite Y (offline, app tuée en pleine partie, double-tap…) ? »
   - *Localisation* : « Si ça casse en prod, tu regardes où en premier ? »
   - *Design* : « Pourquoi on a fait Z plutôt que l'alternative évidente ? »
   Privilégier les scénarios ; jamais de question de définition ou de par-cœur.
3. **Trou de compréhension ≠ échec** : réponse absente ou fausse → explication
   COURTE ancrée (fichier:ligne, invariant, mémoire `[[...]]`), puis re-poser
   la même question sous un autre angle plus tard. On ne passe pas à la suite
   sur un « ok ok ».
4. **Désalignement produit détecté** (la réponse révèle que Florent ATTENDAIT
   un autre comportement) → **STOP, le closeout est suspendu** : ce n'est plus
   un problème de compréhension, c'est un finding de revue. Retour boucle
   (correction ou décision explicite d'assumer), teach-back reprend après.
5. **Clôture = teach-back inversé** : « Reformule-moi le changement comme tu
   l'expliquerais à un dev qui arrive. » 2-3 phrases correctes → ✅ go closeout.
   Les points restés flous sont listés en une ligne chacun (pas de fichier .md —
   règle projet #3) ; si un gotcha mérite de survivre à la session → mémoire
   agent ou skill de synthèse, pas un doc.

## Interdits

- Ne PAS re-litiger la qualité du code (c'est la revue) ni rejouer la spec.
- Ne PAS transformer en cours magistral : ratio questions/explications ≥ 2:1.
- Ne PAS bloquer sur la perfection : 80 % de compréhension + les invariants
  critiques sus = go. Le but est l'autonomie, pas l'exhaustivité.
