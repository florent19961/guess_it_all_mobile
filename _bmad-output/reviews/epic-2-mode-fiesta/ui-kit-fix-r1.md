# Fix r1 — lane « kit visuel Fiesta »

Chaque finding re-tracé avant correction.

| Finding | Re-trace | Correctif |
|---|---|---|
| MAJOR-1 reverrouillage de la carte B passée en tête | Confirmé : identité par position → `didUpdateWidget` relance animation + verrou. Doublons impossibles : `words_screen.dart:123-146` refuse les doublons (insensible à la casse) et 2-11 impose A ≠ B. | `key: ValueKey(word)` sur les deux cartes de `TwoWordsLayout`. `FiestaWordCard` seule garde `didUpdateWidget`. |
| MINOR-1 CLAUDE.md « branché par 2-8 » | Confirmé : 2-8 limite l'effet à `turn_screen.dart:330`. | `FiestaWordCard` → 2-11 ; ligne « 2-8 n'utilise que `reversedWordDisplay` ». |
| MINOR-2 nom spec ≠ code | Confirmé (une occurrence, 2-8 §Tests). | Spec 2-8 renommée en `reversedWordDisplay`, test signalé comme déjà livré. |
| MINOR-3 petit écran + grand texte | Confirmé (colonnes `min`, pas de `Flexible`) ; non vérifiable depuis WSL. | Ajouté à la recette device n°6 de 2-11, avec la piste de correctif. Code inchangé. |
| MINOR-4 `CurvedAnimation` non libérée | Confirmé. | `_curve.dispose()` ; tweens d'opacité/échelle créés une fois (`late final`). |
| MINOR-5 effet d'appui pendant le verrou | Confirmé. | `IgnorePointer(ignoring: _entry.isAnimating)` via `AnimatedBuilder` sur la rangée de boutons. `_locked` conservé : il couvre l'appui commencé avant le changement et relâché après (le hit-test est fait au pointer down). |
| Qualité : `icons` = les `round3Only` | — | Commentaire ajouté. |
