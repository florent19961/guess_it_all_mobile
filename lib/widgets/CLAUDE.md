# widgets/

Widgets reutilisables organises en deux sous-repertoires.

## Sous-repertoires

| Repertoire | Role |
|------------|------|
| `common/` | Composants UI reutilisables (boutons, inputs, modals, sliders, toggles) |
| `effects/` | Effets visuels et animations de fond |
| `fiesta/` | Squelette et cartes des ecrans de choix du mode Fiesta (retour systeme Android gere) ; kit visuel du tour Fiesta (`fiesta_turn_widgets.dart`) ; annonces de partie (2-5) : `ModifierBadge(s)`, `ModifierCard`, `RoundDrawCard` (« Tirage de la manche N », avant-tour M1) / `RoundDrawLine` (même tirage en une ligne, transition), `MalusReveal` (plein ecran avant le tour, reutilisable 2-8 / 2-10), `TurnTimeCard` (« Temps du tour », detail + total, avant-tour) `CatchUpLine` (« Rattrapage » en une ligne, transition) et `BlockedGuesser` (selecteur « Les adversaires choisissent » + annonce « X ne repond pas », 2-8) ; kit 2-10 (`offer_widgets.dart`, sans Provider) : `PickThreeCard`, `PassPhonePanel`, `OfferChoiceBody` (sélection tenue par l'appelant), `AppBoostLine` (une ligne, transition) ; `FiestaInfoLine` (`fiesta_setup_widgets.dart`) = gabarit « Libellé : … » de ces lignes |
| `help/` | Aides de prise en main : `HelpButton` (« ? »), `CoachMarks` (voile + bulle, étapes `CoachStep` ciblées par `GlobalKey`), textes par écran (`help_content.dart`), `TutorialPager`, `FirstGamePrompt` (tuto des règles d'office au 1er « Jouer »), `FirstGameHelp` (aides auto de la 1re partie). Branchement écran par écran → `help/WIRING.md` |

## Kit visuel du tour Fiesta (`fiesta/fiesta_turn_widgets.dart`)

Purement presentationnel : aucune logique de jeu, tout passe par des callbacks (`null` = bouton
desactive). Pas encore branche : les stories du tour le cablent dans `turn_screen.dart`.

| Widget | Constructeur | Branche par |
|--------|--------------|-------------|
| `FiestaWordCard` | `({required String word, bool reversed = false, VoidCallback? onGuessed, VoidCallback? onPass, String passLabel = 'Passer', String? label, double fontSize = 56})` | 2-11 |
| `TwoWordsLayout` | `({required String firstWord, String? secondWord, bool reversed = false, onGuessedFirst, onPassFirst, onGuessedSecond, onPassSecond, String passLabel = 'Passer'})` | 2-11 |
| `MimeConstraintBanner` | `({required String modifierId})` ; ids acceptes = `MimeConstraintBanner.icons.keys` | 2-8 |

- `FiestaWordCard` anime chaque nouveau mot et **ignore les taps pendant `kWordCardLock`
  (300 ms)** (2-11 critere 9). Etat de widget seulement : rien de persiste, chrono intact.
- `TwoWordsLayout` : une seule carte, sans place vide, quand `secondWord == null`. Cartes cles par
  leur mot : la carte B qui passe seule en tete garde son etat (pas de re-verrou).
- 2-8 ne branche **aucun** de ces widgets : le tour a un mot garde son rendu, 2-8 n'utilise que
  `reversedWordDisplay`.
- Textes du bandeau = `name` / `description` du catalogue (`modifier_catalog.dart`).
- Inversion de l'affichage : `utils/reversed_word.dart` (`reversedWordDisplay`).
