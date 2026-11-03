# Corrections — kit d'aide, round 1

Chaque finding re-tracé dans le code avant correction.

| # | Décision | Preuve |
|---|---|---|
| **M1** bulle hors écran / voile sans bulle | **Corrigé.** La `Positioned` est bornée en haut ET en bas (zone sous la cible, au-dessus, ou tout l'écran pour une grande cible), le contenu est aligné vers la cible, le texte est dans `Flexible` + `SingleChildScrollView` : l'en-tête et les boutons restent toujours visibles. Cible démontée, ou sans taille, après `ensureVisible` → `_next()` au lieu de `return`. | `lib/widgets/help/coach_marks.dart` `_focusCurrent`, `_bubble` |
| **M2** déduction pas « une fois » | **Corrigé (racine simplifiée).** Re-tracé : `startNewGame` / `restartWithSamePlayers` → `_analytics.endGame()` → `incrementWords` (`game_provider.dart`, `analytics_service.dart:139-142`). Désormais `StorageService.initHelpFlags(playedBefore:)` écrit chaque flag absent à `true` **ou `false`** au premier démarrage, puis ne recalcule plus jamais. Commentaire et `WIRING.md` corrigés. Test : install neuve → false, puis `playedBefore: true` au démarrage suivant → reste false. | `storage_service.dart` `initHelpFlags`, `first_game_help.dart` `initAtStartup`, `test/services/help_flags_test.dart` |
| m1 tuto Fiesta faux en Auto | **Corrigé.** Ligne 2 : « Entre deux manches — Personnalisé : les équipes menées choisissent 1 carte parmi 3. Auto : l'app leur donne un coup de pouce. » (pluriel pour 3+ équipes). Cohérent avec la carte 3. | `lib/screens/fiesta_tutorial_screen.dart` |
| m2 tu / vous mélangés | **Corrigé.** Tutoiement adressé au porteur du téléphone partout dans les aides et les tutos (vérification, résultats, accueil, paramètres, carte 4 du tuto, carte 3 Fiesta). Les règles détaillées existantes (« vous ») ne sont pas touchées : hors périmètre. | `help_content.dart`, `rules_tutorial_screen.dart`, `fiesta_tutorial_screen.dart` |
| m3 pénalité à passer à `turnHelp` | **Corrigé (doc).** `WIRING.md` : `provider.currentPassPenalty` ; malus « Interdit de passer » → ne pas poser la clé `pass`. | `lib/widgets/help/WIRING.md` |
| m4 « Revoir les aides » promet un comportement pas encore branché | **Résidu assumé.** La lane `feat/help-wiring` est empilée sur celle-ci ; **pas de release entre ce merge et le branchement** (à tenir par l'orchestrateur). | — |
| m5 `_shown` perdu après un kill | **Accepté** (le relecteur l'accepte aussi) ; noté dans `WIRING.md` §Limites. | `WIRING.md` |
| m6 points du tuto roses en Fiesta | **Corrigé** : `widget.accent`. | `tutorial_pager.dart` |
| m7 couches / second parseur | **Corrigé.** La déduction sort de `StorageService` (qui n'écrit plus que les flags) vers `FirstGameHelp.initAtStartup()`, qui lit `WordHistoryService().hasHistory` (cache, déjà initialisé : tâches locales séquentielles) et `GameHistoryService`. `storageKey` public et l'alias supprimés. | `first_game_help.dart`, `word_history_service.dart`, `main.dart` |
| m8 mesure prise une fois | **Accepté**, noté dans `WIRING.md` §Limites (portrait bloqué). | `WIRING.md` |
| NIT enum / sentinel `right == null` | **Résidu** : chaînes const suffisantes pour 2 valeurs ; sentinel documenté. | — |
| NIT « équipe menée » révèle le classement | **À trancher par Florent** ; texte de la maquette conservé. | — |

Tests : `help_flags_test` (cas « une fois » ajouté, cas lecture-déduction retiré), aucun autre ajout.
