# Revue Codex r1 — reglages-catalogue (copie du rapport du reviewer)

## BLOCKER

Aucun.

## MAJOR

1. **Parties Fiesta Auto suspendues non stables après ajout du catalogue** — [symmetric_draw.dart:110](/home/florent19961/guess-it-all-reglages/lib/models/fiesta/symmetric_draw.dart:110), [round_transition.dart:66](/home/florent19961/guess-it-all-reglages/lib/models/fiesta/round_transition.dart:66), [modifier_recap.dart:61](/home/florent19961/guess-it-all-reglages/lib/models/fiesta/modifier_recap.dart:61).  
   Les nouveaux ids sont ajoutés à la liste mélangée avec la même graine (`candidates.shuffle`). Une règle Auto suspendue ne porte pas de version de catalogue et recalculera donc des tirages, offres/boosts et récapitulatifs différents après mise à jour. La documentation le reconnaît elle-même [tracking_evolution.md:778](/home/florent19961/guess-it-all-reglages/docs/tracking_evolution.md:778). Cela contredit « suspendues non affectées ».  
   Correction : versionner/geler le catalogue par partie, ou persister les résultats de tirage/offres ; sinon assumer explicitement cette rupture pré-release.

2. **`oneMimeAtMost` ne conserve pas nécessairement le mime que l’ancien jeu appliquait** — [fiesta_ensemble.dart:41](/home/florent19961/guess-it-all-reglages/lib/models/fiesta/fiesta_ensemble.dart:41), [symmetric_draw.dart:128](/home/florent19961/guess-it-all-reglages/lib/models/fiesta/symmetric_draw.dart:128).  
   En l’absence de fixé, la normalisation garde le premier id dans l’ordre du catalogue. Or l’ancien tirage mélangeait les candidats par graine avant `canAdd`; un ancien ensemble avec plusieurs mimes en `draw` pouvait donc appliquer un autre membre. La promesse documentaire « celui que le jeu appliquait déjà » [tracking_evolution.md:772](/home/florent19961/guess-it-all-reglages/docs/tracking_evolution.md:772) est fausse pour ce cas.  
   Correction : soit conserver la configuration legacy et appliquer une règle explicitement versionnée au tirage, soit assumer/documenter le choix catalogue comme une migration comportementale — mais ne pas le présenter comme une conservation du résultat historique.

## MINOR

1. **Validation non exactement cohérente avec le stepper “autre langue”** — [ensemble_validation.dart:67](/home/florent19961/guess-it-all-reglages/lib/models/fiesta/ensemble_validation.dart:67).  
   L’UI borne bien un fixe ou départ à 2 au plus [fiesta_ensemble_editor_screen.dart:310](/home/florent19961/guess-it-all-reglages/lib/screens/fiesta_ensemble_editor_screen.dart:310), mais `fixedRound: 4` passe `validateEnsemble` : seul `== 3` est refusé. L’ensemble est enregistrable mais le modificateur ne peut jamais arriver.  
   Correction : valider les plages selon l’arrivée : fixe/draw 1–2, offer 2.

2. **La nouvelle action “Réinitialiser les paramètres” est sous 44 px** — [settings_screen.dart:606](/home/florent19961/guess-it-all-reglages/lib/screens/settings_screen.dart:606), [app_button.dart:89](/home/florent19961/guess-it-all-reglages/lib/widgets/common/app_button.dart:89).  
   `AppButtonSize.small` donne 8 px de padding vertical et une police 14 px : sa zone tactile est inférieure à 44 px.  
   Correction : utiliser une taille avec hauteur minimale 44 px, sans réduire la zone de hit-test.

## Réponses aux questions

1. **Règle 7 / persistance : partiel.** Les ids existants restent dans le même ordre et les trois nouveaux sont ajoutés en fin [modifier_catalog.dart:130](/home/florent19961/guess-it-all-reglages/lib/models/fiesta/modifier_catalog.dart:130). Un ancien ensemble avec deux fixés M3 est relu sans crash et normalisé de façon déterministe ; le test couvre ce cas [fiesta_ensemble_service_test.dart:69](/home/florent19961/guess-it-all-reglages/test/services/fiesta_ensemble_service_test.dart:69).  
   En revanche, la sélection legacy sans fixé n’est pas sémantiquement conservée (MAJOR-2). La normalisation est également écrite lors de toute mutation du store — y compris `markUsed` après “Jouer” — pas seulement lors d’“Enregistrer” [fiesta_ensemble_service.dart:127](/home/florent19961/guess-it-all-reglages/lib/services/fiesta_ensemble_service.dart:127), [fiesta_ensembles_screen.dart:66](/home/florent19961/guess-it-all-reglages/lib/screens/fiesta_ensembles_screen.dart:66).  
   Les payloads Firestore d’analytics conservent leur forme : ils stockent les `FiestaRules`, pas la liste du catalogue [game_provider.dart:539](/home/florent19961/guess-it-all-reglages/lib/providers/game_provider.dart:539). Les parties suspendues Auto, elles, ne sont pas comportementalement inchangées (MAJOR-1).

2. **Exclusivité de famille : oui pour les nouveaux parcours de génération.** `areCompatible` refuse toute paire de famille, y compris `(x, x)` [modifier_catalog.dart:187](/home/florent19961/guess-it-all-reglages/lib/models/fiesta/modifier_catalog.dart:187); tous les chemins de création passent par `canAdd` : fixés/tirage [symmetric_draw.dart:79](/home/florent19961/guess-it-all-reglages/lib/models/fiesta/symmetric_draw.dart:79), [symmetric_draw.dart:133](/home/florent19961/guess-it-all-reglages/lib/models/fiesta/symmetric_draw.dart:133), offres/boost [offers.dart:179](/home/florent19961/guess-it-all-reglages/lib/models/fiesta/offers.dart:179). L’éditeur coupe les frères actifs [fiesta_ensemble_editor_screen.dart:271](/home/florent19961/guess-it-all-reglages/lib/screens/fiesta_ensemble_editor_screen.dart:271).  
   Exception assumée : une `FiestaState` déjà gelée est relue sans normalisation [fiesta_state.dart:80](/home/florent19961/guess-it-all-reglages/lib/models/fiesta/fiesta_state.dart:80), donc une ancienne partie déjà active avec deux mimes les conserve. Si « EVERY path » inclut la reprise legacy, la règle n’est pas universelle.

3. **`other_language` ne peut pas apparaître en M3 par les parcours normaux.** `isEligibleForRound` l’exclut en M3 [symmetric_draw.dart:26](/home/florent19961/guess-it-all-reglages/lib/models/fiesta/symmetric_draw.dart:26), et fixés, tirages, offres et boosts l’emploient. Le stepper limite bien à 2. La validation couvre M3 exactement, mais pas les valeurs hors plage (MINOR-1).

4. **Nouveaux ensembles : conforme.** `catchUp: kCatchUpOff`, `symmetric: true`, et seul `draw` est actif dans la famille [fiesta_ensemble.dart:64](/home/florent19961/guess-it-all-reglages/lib/models/fiesta/fiesta_ensemble.dart:64).

5. **Réglages Android/iOS : ordre correct ; mesures non certifiables statiquement.** L’ordre est Joueurs → Équipes → Mode de jeu → Choix des mots → Catégories [settings_screen.dart:143](/home/florent19961/guess-it-all-reglages/lib/screens/settings_screen.dart:143), et les sliders compacts sont bien utilisés dans Avancés [settings_screen.dart:534](/home/florent19961/guess-it-all-reglages/lib/screens/settings_screen.dart:534). Les compteurs, toggles et sliders ont des zones de 44/48 px ou davantage.  
   **Hypothèse statique :** les hauteurs annoncées (709/402 px) sont plausibles mais non vérifiables sans rendu avec les polices réelles, interdit ici. Le défaut certain est le bouton Reset sous 44 px. Le titre est placé après 48 px, donc ne paraît pas passer sous les boutons supérieurs.

6. **Tests/mutations : couverture statiquement convaincante, exécution non vérifiée.**  
   - Famille : le test catalogue vérifie chaque paire [fiesta_catalog_test.dart:60](/home/florent19961/guess-it-all-reglages/test/models/fiesta/fiesta_catalog_test.dart:60).  
   - Exclusion M3 : la matrice de tirage vérifie tous les tours et 200 graines [symmetric_draw_test.dart:45](/home/florent19961/guess-it-all-reglages/test/models/fiesta/symmetric_draw_test.dart:45), et le validateur est ciblé [ensemble_validation_test.dart:146](/home/florent19961/guess-it-all-reglages/test/models/fiesta/ensemble_validation_test.dart:146).  
   - Appel de normalisation et préférence fixé : le test de service les tue logiquement [fiesta_ensemble_service_test.dart:83](/home/florent19961/guess-it-all-reglages/test/services/fiesta_ensemble_service_test.dart:83).  
   - Les deux attentes adaptées dans `offers_test` restent significatives : elles épinglent l’éligibilité/force et le mélange incluant `other_language` [offers_test.dart:100](/home/florent19961/guess-it-all-reglages/test/models/fiesta/offers_test.dart:100), [offers_test.dart:169](/home/florent19961/guess-it-all-reglages/test/models/fiesta/offers_test.dart:169). Le fixture provider désactive au contraire `other_language` pour préserver son scénario historique [fiesta_pick_three_test.dart:47](/home/florent19961/guess-it-all-reglages/test/providers/fiesta_pick_three_test.dart:47) : il reste utile pour la file de choix, mais n’est pas une couverture intégrée du nouveau modificateur.  
   Aucun test Flutter ni mutation n’a été exécuté, conformément à la consigne ; il n’existe pas dans le diff de preuve exécutable des résultats “tous tués”.

7. **Pass qualité limité au diff.** Pas de paire mime résiduelle dans les sources actives ; les nouveaux ids ont une icône badge et une icône/bannière de contrainte [modifier_badge.dart:20](/home/florent19961/guess-it-all-reglages/lib/widgets/fiesta/modifier_badge.dart:20), [fiesta_turn_widgets.dart:276](/home/florent19961/guess-it-all-reglages/lib/widgets/fiesta/fiesta_turn_widgets.dart:276). L’aide suit le nouvel ordre [help_content.dart:70](/home/florent19961/guess-it-all-reglages/lib/widgets/help/help_content.dart:70). Les forces déclarées sont bien câblées pour offres et boost : drap forte, dos/langue moyenne [offers.dart:19](/home/florent19961/guess-it-all-reglages/lib/models/fiesta/offers.dart:19). Ce calibrage est explicitement subjectif, donc pas invalidable statiquement.

Les décisions “autre langue compatible avec tout”, forces déclarées, Dessiner seul actif par défaut, icônes et ordre de l’aide sont cohérentes dans le code. Les deux décisions non tenables telles que formulées sont la stabilité des sessions Auto suspendues et la prétendue conservation du mime historiquement tiré.

**Verdict : NOT READY.**

