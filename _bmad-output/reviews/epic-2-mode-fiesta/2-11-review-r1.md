# Revue 2-11 — Deux mots à la fois (r1)

**Revue statique uniquement.** Lecture du patch fourni contre `6816b43`, du code
concerné et des contrats fournis ; aucune commande Flutter/Dart ni aucun test n'a
été exécuté.

## Verdict : READY

Pas de **BLOCKER** ni de **MAJOR** dans le diff 2-11.

## Vérifications

- Le pool conserve les deux cartes jusqu'à leur traitement. Une action sur A ou
  B retire seulement sa cible, `drawOtherCard` exclut l'autre carte et ne recycle
  les passés que lorsqu'il n'existe plus de troisième mot. Le dernier mot retombe
  bien dans le chemin historique à une carte ; un tap portant un mot sorti des
  cartes est ignoré par le provider.
- À l'expiration, A reste `expiredWord` et B est déplacé atomiquement dans
  `fiesta.turn.secondExpiredWord`. `resolveTurn(expiredWords:)` les dépouille
  individuellement, y compris avec x2, puis la branche de continuation retire
  B expirée sans vider `twoWords=spent` ni dépenser une nouvelle charge.
- `free_pass` passe par la même mutation de compteur quel que soit le côté visé ;
  `no_pass` reste bloquant avant l'analytics. Les incompatibilités et le plafond
  Q8 sont appliqués par `canAdd`/les deux getters de plafond.
- L'horodatage analytics est désormais propre à chaque mot (`_shownAt`) et est
  consommé au terminal event. La carte conservée ne perd donc pas son timestamp
  quand l'autre est remplacée. Un redémarrage réel remet la map à zéro via
  `_clearTrackingState`, conformément au contrat documenté (pas de durée inventée).
- Les trois nouvelles clés sont additives dans `fiesta.turn`, lues comme chaînes
  uniquement, et passent par le snapshot JSON existant. La sérialisation
  Classique et les clés `guessItAll_*` ne changent pas.

## Findings

### MINOR — le scénario nommé « kill » ne simule pas un kill du tracker analytics

- **Emplacement :** `test/providers/fiesta_two_words_test.dart:138-145`
- **Scénario :** ce test réinstancie `GameProvider`, mais conserve le singleton
  `AnalyticsService` en mémoire. Il vérifie correctement la relecture des deux
  cartes depuis `SharedPreferences`, mais ne peut pas prouver que `_shownAt` ne
  survit pas à un processus tué ni le contrat « événement terminal abandonné
  faute de `shown` après kill ».
- **Correctif :** ajouter un test analytics séparé qui persiste le jeu analytics,
  appelle `AnalyticsService().forgetCurrentGame()`, recharge, puis vérifie la
  politique documentée pour les cartes restaurées (aucun timestamp hérité et pas
  de durée fabriquée).

### MINOR — la frontière Q8 des deux interrupteurs n'est pas directement épinglée

- **Emplacement :** `test/providers/fiesta_two_words_test.dart:43-50`,
  `lib/providers/game_provider.dart:1412-1476`
- **Scénario :** le test couvre la coexistence licite x2 + deux mots, mais pas
  le refus d'un troisième modificateur ni les deux ordres d'activation au
  plafond. Une régression des additions croisées dans `doublePointsCapped` /
  `twoWordsCapped` ne serait donc pas détectée par les quatre tests de la lane.
- **Correctif :** construire une équipe avec un modificateur de manche déjà
  comptabilisé, armer l'un des deux bonus, puis vérifier que l'autre est refusé
  (et répéter l'ordre inverse).

## Qualité du diff

Le changement est focalisé. `drawOtherCard` isole la règle de pool et `_armCharge`
supprime de la duplication entre x2 et deux mots ; aucune nouvelle couche
artificielle, conversion non typée additionnelle, ni branche dispersée n'est
introduite. `game_provider.dart` était déjà très grand avant ce patch : le diff
ne franchit pas le seuil des 1 000 lignes et sa logique ajoutée reste regroupée.
